def get_batch(batchId)
  
  #[1] Set body and headers variables for API request
  body = "{'Id':'#{batchId}'}"
  headers = "\"Authorization: Bearer #{$token}&Cookie: #{$azure[:auth_url]}=#{$token}&Content-Type: application/json; charset=UTF-8\""

  #[2] Construct api request to check batch status
  parent_dir = File.expand_path('..', __dir__)
  command = "\"#{parent_dir}/apply-batch/httprequester.exe\" #{$endpoint_url}#{$endpoints[:get_batch]} --body=#{body} --headers=#{headers}"

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