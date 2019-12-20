# Change the below variables to fit your needs --> Read the README for instructions and additional information

$requested_project_name   = "Central - Posters" #Example: "Central - Posting"
$requested_issue_name     = "Rally Export" #Exmaple: "QA - Write Functional Test Cases for XYZ application"
$attachement_location     = "C:\\Users\\itjxm03\\Desktop\\Ruby\\RallyExportTool\\Rally-Export-Attachments\\Saved_Attachments_DEMO\\Central Posters 2019\\TESTING\\testing.txt" #Make sure the escape your backslashes Example: "C:\\[location]\\filename.ext"
$username                 = "jaycen.milling@railinc.com" #Example: "john.doe@domain.com"
$api_token                = "Wji1XB7fBlwpUgmxIj3rDBCB" #See README to learn how to create an API token in Jira  Example: "Ajh1XB27AlgpUvmxIj36DnDe"
$site					  = "https://railinc.jira.com" #Example: "https://mysite.jira.com"

#------------------------------------------------------------------------
#
#
#
#             DO NOT CHANGE ANYTHING BELOW THIS LINE
#
#
#
#------------------------------------------------------------------------

require 'pp'
require 'jira-ruby'
require 'fileutils'
require 'logger'

options = {
	:username        => "#{$username}",
	:password        => "#{$api_token}",
	:site            => "#{$site}",
	:context_path    => '',
	:rest_base_path  => '/rest/api/2',
	:auth_type       => :basic
}

$client = JIRA::Client.new(options)
$log_path = ""
$log = ""
$upload_failed = false

#Tests Jira connection
def test_connection()
	
	connected = false
	if "#{$username}" == "" || "#{$api_token}" == "" || "#{$username}" == " " || "#{$api_token}" == " "
		throw_connection_error()
		
	else
		connection = "#{$client.Status.all}"
	
		if "#{connection.length}" != "2"
			puts "Connection successful"
			write_to_file("#{$username} connected to Jira Successfully", "info")
			connected = true
		else
			throw_connection_error()
		end
	end
	
	
	return connected
end

#Handles connection error
def throw_connection_error()
	begin
		raise "Jira Connection Error"
		rescue
			puts "#------------------------------------------------------------------------------------------------------------------"
			puts "#"
			puts "#Connection to Jira was Unsuccessful please verify Username and API Token on lines #4 and #5 respectively"
			puts "#"
			puts "#------------------------------------------------------------------------------------------------------------------"
			write_to_file("Connection to Jira was unsuccessful", "error")
	end

end

#Returns a hash containing all Project names in Subscription
def getAllProjects()
	listOfProjects = {}
	projects = $client.Project.all
	i = 0
	projects.each do |project|
		#puts "Project Name: #{project.name}"
		listOfProjects["#{i}"] = project.name
		i += 1
	end
	return listOfProjects
end

#Returns the project id provided the project name supplied
def getProjectId(project_name)
	projects = $client.Project.all
	id = ""
	projects.each do |project|
		if project.name == project_name
			id = project.id		
			write_to_file("Project id #{id} was successfully found for #{project_name}", "info")
		end 
	end
	return id
end

#Returns an issue object provided the issue id supplied
def findIssue(issue) 
	issueFound = $client.Issue.find(issue)
	return issueFound
end

#Returns an issue id provided the project id and issue name supplied
def getIssueId(project_id)
	issue_id = ""
	project = $client.Project.find(project_id)
	project.issues.each do |issue|
		if "#{issue.summary}" == $requested_issue_name
			issue_id = "#{issue.id}"
			write_to_file("Story id #{issue_id} was successfully found for #{$requested_issue_name}", "info")
		end
	end
	return issue_id
end

#Adds the attachment to the issue provided the file and issue object supplied
def addAttachmentToIssue(issueObj)
	attachment = JIRA::Resource::Attachment.new $client, issue: issueObj
	
	attachment_arr = "#{$attachement_location}".split("\\")
	attachment_name = "#{attachment_arr[attachment_arr.length() - 1]}"
	
	saved = attachment.save! 'file' => $attachement_location
	if "#{saved}" == "true"
		puts "File attachment[SUCCESSFUL] -- #{attachment_name} was uploaded successfully."
		write_to_file("File attachment[SUCCESSFUL] -- #{attachment_name} was uploaded successfully.", "info")
	else
		$upload_failed = true
		puts "File attachment[FAILED] -- #{attachment_name} upload failed."
		write_to_file("File attachment[FAILED] -- #{attachment_name} upload failed.", "error")
	end
end

#Handles log writes
def write_to_file(content, type)	
	if "#{type}" == "error"
		$log.error "#{content}"
	elsif "#{type}" == "debug"
		$log.debug "#{content}"
	elsif "#{type}" == "info"
		$log.info "#{content}"
	elsif "#{type}" == "warn"
		$log.warn "#{content}"
	elsif "#{type}" == "fatal"
		$log.fatal "#{content}"
	end
end

#Creates log if it doesn't exists
def log_file_creation()
	current_path = File.dirname(File.realpath(__FILE__))
	$csv_path = "#{current_path}/Attachments.csv"
	if !File.directory?("#{current_path}/logs")
		FileUtils.mkdir_p "#{current_path}/logs"
	end
	$log_path = "#{current_path}/logs/jira-attachment-upload.txt"
	$log = Logger.new("#{current_path}/logs/jira-attachment-upload.txt", 'daily')
end

#Utilizes the above methods to attach the specified file to the specified issue within the specified project.
def attach(project_name)
	log_file_creation()
	$log.unknown "---------------------------------------------SCRIPT STARTED---------------------------------------------"
	
	if test_connection()
		project_id = getProjectId(project_name)
		issue_id = ""
		issue = ""
		if project_id != ""
			# Get all issues assigned to the project id
			issue_id = getIssueId(project_id)
			if issue_id != ""
				issue = findIssue(issue_id)
				addAttachmentToIssue(issue)
				
				if $upload_failed
					puts "----------------------------------------------------------------------------------------------------------"
					puts ""
					puts "Script completed with errors: Not all files were uploaded successfully, please check log file for more details --- #{$log_path}"
					puts ""
					puts "----------------------------------------------------------------------------------------------------------"
				else
					puts "----------------------------------------------------------------------------------------------------------"
					puts ""
					puts "                  Script completed without error: The file was uploaded successfully."
					puts ""
					puts "----------------------------------------------------------------------------------------------------------"
				end
			else
				puts "No issue with the name: #{$requested_issue_name} found in project: #{$requested_project_name}"
				write_to_file("No issue with the name: #{$requested_issue_name} found in project: #{$requested_project_name}", "error")
			end
		else
			projects = getAllProjects()
			puts "------------------------------------------------------------------------------------------"
			puts ""
			puts "Project Name [#{project_name}] was not found, below are a list of projects."
			puts ""
			for project in projects
				puts "#{project}"
			end
			puts ""
			puts "------------------------------------------------------------------------------------------"
			write_to_file("Project: #{project_name} was not found in subscription.", "error")
		end
	end
	$log.unknown "---------------------------------------------SCRIPT ENDED---------------------------------------------"
	$log.close()
end

#-----------------------------------------------------------------------------------
# Script Starts Here
#

attach($requested_project_name)

# 
# Script Ends Here
#-----------------------------------------------------------------------------------