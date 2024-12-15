require 'json'
require 'date'
require 'clipboard'
require 'optparse'

require_relative "_includes/get_batch"
require_relative "_includes/process_batch"
require_relative "_includes/approve_or_apply_batch"
require_relative "apply-batch/messenger"

# --------------------------------- # 

#[0]#Process arguments

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

# --------------------------------- # 
 
#[1]# Set environment variables

    target = "prod"
    batchIds = ARGV
    $message = []

    # Uncomment for debugging
    #target = "pred"
    #$reporter = "Joe"
    #batchIds = ["42dc27ab-928e-46ff-a79c-b1bd00cdb701","58e9fc8f-b05e-45a6-89b7-b1bd00fab696"]

# --------------------------------- # 

#[2]# Validate GUIDs

    uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
    batchIds.each do |batchId|
        unless uuid_regex.match?(batchId.downcase.strip)
            puts "Invalid batch ID: #{batchId}"
            loop { sleep 10 }
        end
    end

# --------------------------------- #

#[3]# Set target server (ed-prod/ed-pred) to use in [4], [5], [6]

    cookie_parameters = File.read("#{__dir__}/apply-batch/#{target}.json")
    $azure = JSON.parse(cookie_parameters, symbolize_names: true)

    endpoints = File.read("#{__dir__}/apply-batch/endpoints.json")
    $endpoints = JSON.parse(endpoints, symbolize_names: true)
    $endpoint_url = "#{$azure[:url]}/#{$endpoints[:approve_or_apply]}" 

# --------------------------------- #

#[4]# Get authorization token to use in [4], [5]

    command = "\"#{__dir__}/apply-batch/azurecooker/AzureCooker.exe\" #{$azure[:tenant_id]} #{$azure[:client_id]} #{$azure[:scope]} #{$azure[:url]}"
    $token = `#{command}`
    $token = $token.split("\n").first

# --------------------------------- #

#[5] Call [process_batch] on each batch Id

    puts "Working..."

    batchIds.each do |batchId|
        process_batch(batchId)
    end

# --------------------------------- #

#[6] Output results
    
    if $message.size > 1 && $message.all? { |element| element.include?("BUCS was Applied") }
        $message = ["BUCS were applied"]
    end

    $message.unshift("Hello, #{$reporter}.")
    Clipboard.copy($message.join("\n"))
    
    puts "This window can be closed now"
    loop { sleep 10 }