def approve_or_apply_batch(action, batchId)

  #[1] Set variables
  body = "{'BatchId':'#{batchId}'}"
  headers = "\"Authorization: Bearer #{$token}&Cookie: #{$azure[:auth_url]}=#{$token}&Content-Type: application/json; charset=UTF-8\""

  parent_dir = File.expand_path('..', __dir__)
  command = "\"#{parent_dir}/apply-batch/HTTPRequester.exe\" #{$endpoint_url}#{action} --body=#{body} --headers=#{headers}"
  result = `#{command}`

end