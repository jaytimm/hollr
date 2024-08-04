#' Batch Processing for Local LLM
#'
#' This function generates text in batches using a local model.
#'
#' @param id A unique identifier for the request.
#' @param user_message The message provided by the user.
#' @param annotators The number of annotators (default is 1).
#' @param model The name of the model to use.
#' @param temperature The temperature for the model's output (default is 1).
#' @param top_p The top-p sampling value (default is 1).
#' @param max_new_tokens The maximum number of new tokens to generate (default is 100).
#' @param max_length The maximum length of the input prompt (default is NULL).
#' @param system_message The message provided by the system (default is '').
#' @param batch_size The number of messages to process in each batch (default is 10).
#' @return A list containing the generated responses for each batch.
#' @examples
#' \dontrun{
#' hollr_local_batches(id = "example_id", 
#' user_message = "Hello, how are you?", 
#' model = "local_model")
#' }
#' @import data.table
#' @importFrom reticulate source_python py
#' @export
hollr_local_batches <- function(id,
                                user_message = '',
                                annotators = 1,
                                model,
                                temperature = 1,
                                top_p = 1,
                                max_new_tokens = 100,
                                max_length = NULL,
                                system_message = '',
                                batch_size = 10) {
  # Prepare data
  text_df <- data.table::data.table(id = rep(id, annotators),
                                    annotator_id = .generate_random_ids(annotators),
                                    user_message = rep(user_message, annotators))
  
  # Load Python functions and initialize model
  reticulate::source_python(system.file("python", "llm_functions.py", package = "hollr"))
  model_pipeline <- .get_local_model(model)
  
  # Check if pad_token is set and set it if necessary
  if (is.null(model_pipeline$tokenizer$pad_token)) {
    pad_token_dict <- reticulate::dict(pad_token = "[PAD]")
    model_pipeline$tokenizer$add_special_tokens(pad_token_dict)
  }
  
  # Create batches
  batches <- split(text_df, ceiling(seq_along(text_df$user_message) / batch_size))
  
  # Initialize a list to collect responses
  all_responses <- list()
  
  # Process each batch
  for (i in seq_along(batches)) {
    batch <- batches[[i]]
    
    # Calculate the input length and set max_length if not provided
    max_input_length <- max(nchar(batch$user_message))
    if (is.null(max_length)) {
      max_length <- max_input_length + max_new_tokens  # Ensure max_length accommodates both input and output
    }
    
    # Generate text for the current batch with specified max_new_tokens
    response <- reticulate::py$generate_text_batch(model_pipeline,
                                                   batch$user_message,
                                                   temperature,
                                                   max_length,
                                                   max_new_tokens)
    
    # Collect responses ensuring they are properly structured
    all_responses <- c(all_responses, list(response))
  }
  
  return(all_responses)
}
