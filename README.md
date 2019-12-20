# JiraAttachmentUploader

### Ruby script to upload Attachments to a Jira story.

### Note that there are two different versions of this script. There is a script for a single file upload, and one for a multi-upload that uses a csv file to map our all files and stories.  

##### This was developed and tested with Ruby 2.6.5
```
	1.Install the jira-ruby gem (developed and tested with version 1.7.1)

		    gem install jira-ruby
	
	2.Open this link: https://id.atlassian.com/manage/api-tokens

	3.Login if necessary

	4.Click "Create API token" 

	5.Give it a label

	6.Click "Copy to clipboard" 

	7.Edit the ruby script you intend to use
	
	8.Paste the copied token from step 6 into the $api_token field
```
	
### For the Single File upload script 
```
		A. Change the following variables 
	
			a. $requested_project_name
			b. $requested_issue_name 
			c. $attachement_location 
			d. $username 
			e. $api_token 
			f. $site	
```

### For the CSV file upload script 
```
		A. Change the following variables
		
			a. $username 
			b. $api_token  
			c. $site
				NOTE: This is your Jira site https://myworkplace.jira.com			
		
		B. Update the Attachments.CSV to include all required attachments.
		
			a. First column is: full path of attachment
			
				Note that if all attachments in the directory need to be uploaded to the same Jira
				story, put the directory as the full path -- For a single file, add "\[filename.ext]" at the end.
				
				example: "C:\[PATH]"
				
			b. Second column is: jira project name	
				
				example: "Central - Posters"
			
			a. Third column is: jira story name
				
				example: "QA - Write Functional Test Cases for XYZ Application"
```
```
	9.Run script

		    cd c:\[location]
		
		    ruby jira_attachment_importer-[version].rb
```