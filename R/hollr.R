#' LLM Completions
#'
#' This function generates text using either the OpenAI API or a local model.
#'
#' @param id A unique identifier for the request.
#' @param user_message The message provided by the user.
#' @param annotators The number of annotators (default is 1).
#' @param model The name of the model to use.
#' @param temperature The temperature for the model's output (default is 1).
#' @param top_p The top-p sampling value (default is 1).
#' @param max_tokens The maximum number of tokens to generate (default is NULL).
#' @param max_length The maximum length of the input prompt (default is 1024, for local models only).
#' @param max_new_tokens The maximum number of new tokens to generate (default is NULL, for local models only).
#' @param system_message The message provided by the system (default is '').
#' @param force_json A logical indicating whether the output should be JSON (default is TRUE).
#' @param flatten_json A logical indicating whether the output should be converted to DF (default is TRUE).
#' @param max_attempts The maximum number of attempts to make for generating valid output (default is 10).
#' @param openai_api_key The API key for the OpenAI API (default is retrieved from environment variables).
#' @param openai_organization The organization ID for the OpenAI API (default is NULL).
#' @param cores The number of cores to use for parallel processing (default is 1).
#' @return A data.table containing the generated text and metadata.
#' @examples
#' \dontrun{
#' hollr(id = "example_id", user_message = "What is the capital of France?", model = "gpt-3.5-turbo", openai_api_key = "your_api_key")
#' }
#' @import data.table
#' @importFrom parallel makeCluster clusterExport stopCluster
#' @importFrom pbapply pblapply
#' @importFrom httr POST add_headers content http_error status_code
#' @importFrom jsonlite fromJSON
#' @export
hollr <- function(id,
                  user_message = '',
                  annotators = 1,
                  model,
                  temperature = 1,
                  top_p = 1,
                  max_tokens = NULL,
                  max_length = 1024,
                  max_new_tokens = NULL,
                  system_message = '',
                  force_json = TRUE,
                  flatten_json = TRUE,
                  max_attempts = 10,
                  openai_api_key = Sys.getenv("OPENAI_API_KEY"),
                  openai_organization = NULL,
                  cores = 1) {
  
  # Determine if the model is OpenAI or local
  is_openai_model <- grepl("gpt-3.5-turbo|gpt-4|gpt-4o|gpt-4o-mini", model, ignore.case = TRUE)
  
  # Prepare data
  text_df <- data.table::data.table(id = rep(id, annotators),
                                    annotator_id = .generate_random_ids(annotators),
                                    user_message = rep(user_message, annotators))
  
  # Define the processing function
  process_function <- function(row) {
    make_call <- function() {
      if (is_openai_model) {
        response <- .openai_chat_completions(model = model,
                                             system_message = system_message,
                                             user_message = row$user_message,
                                             temperature = temperature,
                                             top_p = top_p,
                                             max_tokens = max_tokens,
                                             openai_api_key = openai_api_key,
                                             openai_organization = openai_organization,
                                             force_json = force_json)
        
        # may make more sense to output 'response' as json string here -- 
        # if we wanted to include 'metadata' associated with openai api calls in output -- 
        # at present, we return 'content' as json -- to match local implementation --
        parsed_output <- jsonlite::fromJSON(response)
        response <- parsed_output$choices$message$content
        
        
      } else {
        reticulate::source_python(system.file("python", "llm_functions.py", package = "hollr"))
        model_pipeline <- .get_local_model(model)
        response <- reticulate::py$generate_text(model_pipeline,
                                                 row$user_message,
                                                 temperature,
                                                 max_length,
                                                 max_new_tokens,
                                                 max_attempts,
                                                 force_json)
      }
      
      response
    }
    
    validation_result <- .validate_json_output(make_call, 
                                               force_json, 
                                               max_attempts)
    
    cleaned_response <- gsub("^```json|```$", "", validation_result$response) # valid json, but shite
    
    list(id = row$id,
         annotator_id = row$annotator_id,
         response = cleaned_response,
         attempts = validation_result$attempts,
         success = validation_result$success)
  }
  
  # Parallel processing for OpenAI cloud-based models only -- 
  if (cores > 1 & is_openai_model) {
    
    cl <- parallel::makeCluster(cores)
    parallel::clusterExport(cl, varlist = c(".openai_chat_completions", 
                                            ".is_valid_json", 
                                            ".validate_json_output"), 
                            envir = environment())
    
    results <- pbapply::pblapply(split(text_df, seq(nrow(text_df))), 
                                 function(row) process_function(row), cl = cl)
    
    parallel::stopCluster(cl)
    
  } else { # cores = 1 and model = cloud. or model = local AND batch_size = 1
    results <- pbapply::pblapply(split(text_df, seq(nrow(text_df))), 
                                 function(row) process_function(row))
  }
  
  # model = local AND batch_size > 1
  # results <- pbapply::pblapply(split(text_df, seq(1, nrow(text_df), by=batch_size)), 
  # function(rows) process_function(rows))
  
  # Process results
  processed_results <- .process_results(results, 
                                        force_json, 
                                        flatten_json)
  
  return(processed_results)
}
