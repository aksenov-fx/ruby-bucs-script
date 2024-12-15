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