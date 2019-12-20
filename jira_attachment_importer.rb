# Change the below variables to fit your needs --> Read the README for instructions and additional information


$username                 = "" #Example: "john.doe@domain.com"
$password                 = "" #This will not be your password, this will be an API token See README to learn how to create an API token in Jira  Example: "Ajh1XB27AlgpUvmxIj36DnDe"
$site					  = "" #Example: "https://mysite.jira.com"

# ------------------------------------------------------------------------------
#
#
#					DO NOT CHANGE ANYTHING BELOW THIS LINE
#
#
# ------------------------------------------------------------------------------

require 'pp'
require 'jira-ruby'
require 'csv'
require 'fileutils'
require 'logger'

options = {
	:username        => "#{$username}",
	:password        => "#{$password}",
	:site            => "#{$site}",
	:context_path    => '',
	:rest_base_path  => '/rest/api/2',
	:auth_type       => :basic
}

$client = JIRA::Client.new(options)
$log_path = ""
$log = ""
$upload_failed_count = 0

def test_connection()
	
	connected = false
	if "#{$username}" == "" || "#{$password}" == "" || "#{$username}" == " " || "#{$password}" == " "
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

def throw_connection_error()
	begin
		raise "Jira Connection Error"
		rescue
			puts "#------------------------------------------------------------------------------------------------------------------"
			puts "#"
			puts "#Connection to Jira was Unsuccessful please verify Username and Password (API Token) on lines #4 and #5 respectively"
			puts "#"
			puts "#------------------------------------------------------------------------------------------------------------------"
			write_to_file("Connection to Jira was unsuccessful", "error")
	end

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
def getIssueId(project_id, issue_name)
	issue_id = ""
	project = $client.Project.find(project_id)
	project.issues.each do |issue|
		if "#{issue.summary}" == "#{issue_name}"
			issue_id = "#{issue.id}"
			write_to_file("Story id #{issue_id} was successfully found for #{issue_name}", "info")
		end
	end
	return issue_id
end

#Utilizes the above methods to attach the specified file to the specified issue within the specified project.
def attach(project_name, issue_name, attachment_path)

	project_id = getProjectId(project_name)
	attachment_arr = "#{attachment_path}".split("\\")
	attachment_name = "#{attachment_arr[attachment_arr.length() - 1]}"
			
	if "#{project_id}" != ""
		issue_id = getIssueId(project_id, issue_name)
		if "#{issue_id}" != ""
			issueObj = findIssue(issue_id)
			
			attachment = JIRA::Resource::Attachment.new $client, issue: issueObj
			
			#saved = attachment.save! 'file' => attachment_path
			saved = "true"
				
			if "#{saved}" == "true"
				puts "File attachment[SUCCESSFUL] -- #{attachment_name} was uploaded to the #{issue_name} story."
				write_to_file("File attachment[SUCCESSFUL] -- #{attachment_name} was uploaded to the #{issue_name} story.", "info")
			else
				#write which file was not uploaded successfully to error log in main dir
				puts "File attachment[FAILED] -- Could not upload #{attachment_name} to the #{issue_name} story." 
				$upload_failed_count += 1
				write_to_file("File attachment[FAILED] -- Could not upload #{attachment_name} to the #{issue_name} story.", "error")
			end
		else
			#Write Error to log
			#increment error count
			puts "Issue #{issue_name} was not found in the #{project_name} project scope -- Could not upload the #{attachment_name} to it."
			$upload_failed_count += 1
			write_to_file("Issue #{issue_name} was not found in the #{project_name} project scope -- Could not upload the #{attachment_name} to it.", "error")
		end
	else 
		#Write Error to log
		#increment error count
		puts "Project #{project_name} was not found -- Could not upload the #{attachment_name} File to the #{issue_name} story."
		$upload_failed_count += 1
		write_to_file("Project #{project_name} was not found -- Could not upload the #{attachment_name} File to the #{issue_name} story.", "error")
	end
end

def write_to_file(content, type)
	#File.open("#{$log_path.path}", "w") do |file|
	#	time = Time.new
	#	timestamp = "#{time.year}-#{time.month}-#{time.day} [#{time.hour}:#{time.min}:#{time.sec}.#{time.usec}] ------ "
	#	file.write "#{content}"
	#end
	
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

def log_file_creation()
	current_path = File.dirname(File.realpath(__FILE__))
	$csv_path = "#{current_path}/Attachments.csv"
	if !File.directory?("#{current_path}/logs")
		FileUtils.mkdir_p "#{current_path}/logs"
	end
	$log_path = "#{current_path}/logs/jira-attachment-upload.txt"
	$log = Logger.new("#{current_path}/logs/jira-attachment-upload.txt", 'daily')
end

#Iterates over each row in CSV file to upload each attachment. 
def uploadCSV()
	log_file_creation()
	$log.unknown "---------------------------------------------SCRIPT STARTED---------------------------------------------"
	if test_connection()
		attachments_to_upload = CSV.read("#{$csv_path}", headers: true)
		
		attachments_to_upload.each do |attachment|
			#convert row from string to array
			attachment_arr = "#{attachment}".split(',')
			
			path = "#{attachment_arr[0]}".strip
			project_name = "#{attachment_arr[1]}".strip
			issue_name = "#{attachment_arr[2]}".strip
			
			path_arr = "#{path}".split('\\')
			#check if path has a filename with extention -- includes a period or not 
			if "#{path_arr[path_arr.length() - 1]}".include? "." 
				#if it does -- need to grab that individual file and upload it.
				attach(project_name, issue_name, path)
			else 
				#if it doesn't -- need to iterate over all attachments in directory
				#begin
					files_in_dir = Dir.entries(path)
					for file in files_in_dir do
						if "#{file}" != "." && "#{file}" != ".."
							file_path = "#{path}\\" + file
							attach(project_name, issue_name, file_path)
						end
					end
				#rescue
				#	puts "Directory #{path} does not exist."
				#	$upload_failed_count += 1
				#	write_to_file("Directory #{path} does not exist", "error")
				#end
			end
		end	
			
		if "#{$upload_failed_count}" != "0"
			puts "----------------------------------------------------------------------------------------------------------"
			puts ""
			puts "Script completed with errors: Not all files were uploaded successfully, please check log file for more details --- #{$log_path}"
			puts ""
			puts "----------------------------------------------------------------------------------------------------------"
		else
			puts "----------------------------------------------------------------------------------------------------------"
			puts ""
			puts "                  Script completed with no errors: All files were uploaded successfully."
			puts ""
			puts "----------------------------------------------------------------------------------------------------------"

		end
	end
	$log.unknown "---------------------------------------------SCRIPT ENDED---------------------------------------------"
	$log.close()
end

#-----------------------------------------------------------------------------------
# Script Starts Here
#

uploadCSV()

# 
# Script Ends Here
#-----------------------------------------------------------------------------------