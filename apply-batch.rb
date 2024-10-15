require 'json'
require 'date'
require 'clipboard'
require 'optparse'

require_relative "apply-batch/messenger"

# --------------------------------- # 
=begin
 
# Description
    A script to approve BUCS
    The script accepts BUCS ID/IDs as an argument. Each ID should be on new line
    It can be used in combination with "External application button" extension for Chrome/Firefox/Opera
    The extension allows to add a context menu item that sends selected text with IDs as an argument to this script

# Script structure
    - Initialization:
    [1] Validate GUIDs
    [2] Set target server (prod/pred) to use in [4], [5], [6]
    [3] Get authorization token to use in [4], [5]

    - Defining methods
    [4] Define [approve_or_apply_batch] method to approve batch
    [5] Define [get_batch] method to get batch status
    [6] Define [messenger] method to print messages on batch status
    [7] Define [process_batch] method - using methods [4], [5], [6]

    - Process BUCS
    [8] Call [7] [process_batch] on each batch Id
    [9] Output results
    
# Approve batch workflow
    [8] [main] calls [process_batch] on each Id
        [7] [process_batch] calls [get_batch] on Id to check current status for the batch
            [5] [get_batch] returns {batch_status}, {batch_start_date} to [process_batch]
        [7] [process_batch] calls [approve_or_apply_batch] on Id
            [4] [approve_or_apply_batch] approves batch and returns to [process_batch]
        [7] [process_batch] calls [get_batch] on Id to check new status for the batch
            [5] [get_batch] returns {new_batch_status} to [process_batch]
        [7] [process_batch] calls [messenger] on id to print batch status message
            [6] [messenger] prints status message and returns to [process_batch]

# History
    Version 1.0 - initial release
    Version 1.1 - added multiple batch Id handling
    Version 1.2 - code refactoring
    Version 1.3 - code refactoring

=end

# --------------------------------- # 

#Process arguments

    #With one batchId the script expects to receive --reporter argument like "Doe, John" and ARGV like ["b9256f4d-fd3e-48a6-adf3-b1bd008fe395"]
    #JS script that gets the --reporter:
        #var reporterVal = document.getElementById('reporter-val');    
        #var textContent = reporterVal.querySelector('.user-hover-replaced').childNodes;
        #var reporterName = Array.from(textContent).find(node => node.nodeType === Node.TEXT_NODE && node.textContent.trim().length > 0).textContent.trim();
        #document.currentScript.output = reporterName;

        options = {}
        OptionParser.new do |opts|
            opts.on("--reporter reporter", "Reporter's name") do |reporter|
                options[:reporter] = reporter
            end
        end.parse!
        
        if options[:reporter] == "" || options[:reporter] == nil 
            $reporter = "Username"
        else
            $reporter = options[:reporter]
            $reporter = $reporter.split(", ")
            $reporter = $reporter[1]
        end

        #puts "Name: #{$reporter}"

# --------------------------------- # 
 
#Set environment variables

    target = "prod"
    batchIds = ARGV
    $message = []

    # Uncomment for debugging
    #target = "pred"
    #$reporter = "Joe"
    #batchIds = ["42dc27ab-928e-46ff-a79c-b1bd00cdb701","58e9fc8f-b05e-45a6-89b7-b1bd00fab696"]
    #batchIds = ["aa7fbfcf-098f-4e06-8d28-b1fd00e3f9e6"]

# --------------------------------- # 

#[1]# Validate GUIDs

    uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
    batchIds.each do |batchId|
        unless uuid_regex.match?(batchId.downcase.strip)
            puts "Invalid batch ID: #{batchId}"
            loop { sleep 10 }
        end
    end

# --------------------------------- #

#[2]# Set target server (ed-prod/ed-pred) to use in [4], [5], [6]

    cookie_parameters = File.read("#{__dir__}/apply-batch/#{target}.json")
    $azure = JSON.parse(cookie_parameters, symbolize_names: true)

    endpoints = File.read("#{__dir__}/apply-batch/endpoints.json")
    $endpoints = JSON.parse(endpoints, symbolize_names: true)
    $endpoint_url = "#{$azure[:url]}/#{$endpoints[:approve_or_apply]}" 

# --------------------------------- #

#[3]# Get authorization token to use in [4], [5]

    command = "\"#{__dir__}/apply-batch/azurecooker/AzureCooker.exe\" #{$azure[:tenant_id]} #{$azure[:client_id]} #{$azure[:scope]} #{$azure[:url]}"
    $token = `#{command}`
    $token = $token.split("\n").first

# --------------------------------- #

#[4]# Define [approve_or_apply_batch] method to approve batch
 def approve_or_apply_batch(action, batchId)

    #[1] Set variables
    body = "{'BatchId':'#{batchId}'}"
    headers = "\"Authorization: Bearer #{$token}&Cookie: #{$azure[:auth_url]}=#{$token}&Content-Type: application/json; charset=UTF-8\""

    #[2] Construct and run api request to apply batch
    command = "\"#{__dir__}/apply-batch/HTTPRequester.exe\" #{$endpoint_url}#{action} --body=#{body} --headers=#{headers}"
    result = `#{command}`

 end

# --------------------------------- #

#[5]# Define [get_batch] method to get batch status
 def get_batch(batchId)

    #[1] Set body and headers variables for API request
    body = "{'Id':'#{batchId}'}"
    headers = "\"Authorization: Bearer #{$token}&Cookie: #{$azure[:auth_url]}=#{$token}&Content-Type: application/json; charset=UTF-8\""

    #[2] Construct api request to check batch status
    command = "\"#{__dir__}/apply-batch/httprequester.exe\" #{$endpoint_url}#{$endpoints[:get_batch]} --body=#{body} --headers=#{headers}"

    #[3] Run api request to check batch status
    begin
        result = `#{command}`
        result = JSON.parse(result)
    rescue => $e
        return "batch_status_failure", "batch_start_date_failure"
    end

    #[4] Parse batch start date
    batch_start_date = result['Date']
    batch_start_date.gsub!("T00:00:00Z", "")
    batch_start_date = Date.parse(batch_start_date)

    #[5] Return batch status, batch_start_date
    return result['Status'], batch_start_date

 end

# --------------------------------- #

#[6]# Define [messenger] method to print messages on batch status

    # [messenger] was moved to messenger.rb

# --------------------------------- #

#[7]# Define [process_batch] method - using methods [4], [5], [6]
 
 def process_batch(batchId)

    #[1] Get batch status
    batch_status, batch_start_date = get_batch(batchId.strip)

    #[2] Process batch based on status
    case 

    #Applied
    when batch_status == 7
        messenger(batchId, batch_status)

    #Pre-approved and Start date has come
    when (batch_status == 9) && (batch_start_date <= Date.today) 
        approve_or_apply_batch("ApproveBatch", batchId) 
        new_batch_status, _ = get_batch(batchId.strip)
        messenger(batchId, new_batch_status)

    #Pre-approved and Start date has not come
    when (batch_status == 9) && (batch_start_date > Date.today)
        messenger(batchId, "date_has_not_come_yet", batch_start_date)

    #Overdue
    when batch_status == 6
        approve_or_apply_batch("ApplyBatch", batchId)
        new_batch_status, _ = get_batch(batchId.strip)
        messenger(batchId, new_batch_status)
    
    else
        messenger(batchId, batch_status)
    end

 end

# --------------------------------- #

#[8] Call [7] [process_batch] on each batch Id
    puts "Working..."

    batchIds.each do |batchId|
        process_batch(batchId)
    end

# --------------------------------- #

#[9] Output results
    
    if $message.size > 1 && $message.all? { |element| element.include?("BUCS was Applied") }
        $message = ["BUCS were applied"]
    end

    $message.unshift("Hello, #{$reporter}.")
    Clipboard.copy($message.join("\n"))
    
    puts "This window can be closed now"
    loop { sleep 10 }