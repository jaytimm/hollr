

# hollr_local_batches <- function(id,
#                                 user_message = '',
#                                 annotators = 1,
#                                 model,
#                                 temperature = 1,
#                                 top_p = 1,
#                                 max_new_tokens = 50,
#                                 max_length = NULL,
#                                 system_message = '',
#                                 batch_size = 10) {
#   # Prepare data
#   text_df <- data.table::data.table(id = rep(id, annotators),
#                                     annotator_id = .generate_random_ids(annotators),
#                                     user_message = rep(user_message, annotators))
#   
#   # Load Python functions and initialize model
#   #reticulate::source_python(system.file("python", "llm_functions.py", package = "hollr"))
#   reticulate::py_run_file("/home/jtimm/pCloudDrive/GitHub/packages/hollr/inst/python/llm_functions.py")
# 
#   model_pipeline <- .get_local_model(model)
#   
#   # Check if pad_token is set and set it if necessary
#   if (is.null(model_pipeline$tokenizer$pad_token)) {
#     pad_token_dict <- reticulate::dict(pad_token = "[PAD]")
#     model_pipeline$tokenizer$add_special_tokens(pad_token_dict)
#   }
#   
#   # Create batches
#   batches <- split(text_df, ceiling(seq_along(text_df$user_message) / batch_size))
#   
#   # Initialize a list to collect responses
#   all_responses <- list()
#   
#   # Process each batch
#   for (i in seq_along(batches)) {
#     batch <- batches[[i]]
#     
#     # Calculate the input length and set max_length if not provided
#     max_input_length <- max(nchar(batch$user_message))
#     if (is.null(max_length)) {
#       max_length <- max_input_length + max_new_tokens  # Ensure max_length accommodates both input and output
#     }
#     
#     # Generate text for the current batch with specified max_new_tokens
#     response <- reticulate::py$generate_text_batch(model_pipeline,
#                                                    batch$user_message,
#                                                    temperature = temperature,
#                                                    max_length = max_length,
#                                                    max_new_tokens = max_new_tokens)
#     
#     # Combine the response with id and annotator_id
#     batch_output <- data.table::data.table(
#       id = batch$id,
#       annotator_id = batch$annotator_id,
#       response = response
#     )
#     
#     # Collect responses ensuring they are properly structured
#     all_responses <- c(all_responses, list(batch_output))
#   }
#   
#   # Combine all responses into a single data table
#   final_responses <- data.table::rbindlist(all_responses, fill = TRUE)
#   
#   return(final_responses)
# }


hollr_local_batches <- function(id,
                                user_message = '',
                                annotators = 1,
                                model,
                                temperature = 1,
                                top_p = 1,
                                max_new_tokens = 50,
                                max_length = NULL,
                                system_message = '',
                                batch_size = 10) {
  # Prepare data
  text_df <- data.table::data.table(id = rep(id, annotators),
                                    annotator_id = .generate_random_ids(annotators),
                                    user_message = rep(user_message, annotators))
  
  # Load Python functions and initialize model
  reticulate::py_run_file("/home/jtimm/pCloudDrive/GitHub/packages/hollr/inst/python/llm_functions.py")
  model_pipeline <- .get_local_model(model)
  
  # Check if pad_token is set and set it if necessary
  if (is.null(model_pipeline$tokenizer$pad_token)) {
    pad_token_dict <- reticulate::dict(pad_token = "[PAD]")
    model_pipeline$tokenizer$add_special_tokens(pad_token_dict)
  }
  
  # Create batches
  batches <- split(text_df, ceiling(seq_along(text_df$user_message) / batch_size))
  
  # Process each batch in parallel with progress bar
  all_responses <- pbapply::pblapply(batches, function(batch) {
    # Calculate the input length and set max_length if not provided
    max_input_length <- max(nchar(batch$user_message))
    if (is.null(max_length)) {
      max_length <- max_input_length + max_new_tokens  # Ensure max_length accommodates both input and output
    }
    
    # Generate text for the current batch with specified max_new_tokens
    response <- reticulate::py$generate_text_batch(model_pipeline,
                                                   batch$user_message,
                                                   temperature = temperature,
                                                   max_length = max_length,
                                                   max_new_tokens = max_new_tokens)
    
    # Combine the response with id and annotator_id
    data.table::data.table(
      id = batch$id,
      annotator_id = batch$annotator_id,
      response = response
    )
  })
  
  # Combine all responses into a single data table
  final_responses <- data.table::rbindlist(all_responses, fill = TRUE)
  
  return(final_responses)
}
