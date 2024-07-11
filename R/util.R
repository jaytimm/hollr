#' Validate JSON String
#'
#' This function checks if a given string is a valid JSON.
#'
#' @param json_string The string to validate.
#' @return TRUE if the string is valid JSON, FALSE otherwise.
#' @importFrom jsonlite fromJSON
#' @noRd

.is_valid_json <- function(json_string) {
  tryCatch({ jsonlite::fromJSON(json_string); TRUE }, error = function(e) { FALSE })
}




#' Generate Random IDs
#'
#' This function generates a specified number of random IDs.
#'
#' @param n The number of IDs to generate.
#' @return A vector of random IDs.
#' @noRd
.generate_random_ids <- function(n) {
  replicate(n, paste0(sample(c(0:9, letters, LETTERS), 10, replace = TRUE), collapse = ""))
}



#' Process Results from LLM Completions
#'
#' This internal function processes the results from LLM completions,
#' ensuring consistent structure and output.
#'
#' @param results A list of results to be processed.
#' @param force_json A logical indicating whether the output should be JSON.
#' @return A data.table containing the processed results.
#' @noRd
.process_results <- function(results, force_json, flatten_json) {
  processed_list <- lapply(results, function(element) {
    # Initialize an empty list for the response
    response_list <- list()
    
    # Check if JSON output is expected and the response is a character
    # if (force_json && is.character(element$response)) {
    if (flatten_json && is.character(element$response)) {
      
      response_list <- tryCatch({
        jsonlite::fromJSON(element$response)  # Directly return the parsed JSON
      }, error = function(e) {
        list(raw_output = element$response)  # Return the raw response as raw_output if error
      })
    } else {
      # Directly assign the response to 'raw_output' key if JSON is not required
      response_list$raw_output <- element$response
    }
    
    # Convert the list to a data table
    response_df <- data.table::as.data.table(response_list)
    
    # Assign metadata
    response_df[, id := element$id]
    response_df[, annotator_id := element$annotator_id]
    response_df[, attempts := element$attempts]
    response_df[, success := element$success]
    
    return(response_df)
  })
  
  # Combine all data tables into a single data table and ensure id is the first column
  df <- data.table::rbindlist(processed_list, fill = TRUE)
  data.table::setcolorder(df, c("id", "annotator_id", "attempts", "success", 
                                names(df)[!(names(df) %in% c("id", "annotator_id", "attempts", "success"))]))
  
  return(df)
}





#' Validate JSON Output and Track Metrics
#'
#' This function validates the JSON output and attempts to regenerate if the output is invalid.
#' It also tracks the number of attempts required for successful JSON validation.
#'
#' @param make_call A function that makes the API call or generates the output.
#' @param force_json A logical indicating whether the output should be JSON.
#' @param max_attempts The maximum number of attempts to make for generating valid output.
#' @return A list containing the validated JSON output (or NA if validation fails) and the number of attempts.
#' @importFrom jsonlite fromJSON
#' @importFrom httr content
#' @noRd

.validate_json_output <- function(make_call,
                                  force_json,
                                  max_attempts) {
  attempt <- 1  # Initialize the attempt counter

  while (attempt <= max_attempts) {
    output <- make_call()  # Call the make_call function to get output

    if (force_json) {  # Check if JSON output is expected
      if (.is_valid_json(output)) {
        return(list(response = output,
                    attempts = attempt,
                    success = TRUE))
      } else {
        cat("Attempt ", attempt, ": Invalid JSON received. Regenerating...\n")
        attempt <- attempt + 1  # Increment attempt only if JSON is invalid
      }
    } else {
      # If JSON output is not expected, return success without incrementing the attempt counter
      return(list(response = output,
                  attempts = attempt,
                  success = TRUE))
    }
  }

  # After exhausting all attempts without success
  cat("Failed to receive valid JSON after ", max_attempts, " attempts. Carrying on ...\n")
  return(list(response = output,
              attempts = max_attempts,
              success = FALSE))
}




#' OpenAI Chat Completions
#'
#' This function interacts with the OpenAI API to generate text completions.
#'
#' @param model The model to use for the API call.
#' @param system_message The message provided by the system (e.g., instructions or context).
#' @param user_message The message provided by the user.
#' @param temperature The temperature for the model's output.
#' @param top_p The top-p sampling value.
#' @param max_tokens The maximum number of tokens to generate.
#' @param openai_api_key The API key for the OpenAI API.
#' @param openai_organization The organization ID for the OpenAI API.
#' @param force_json A logical indicating whether the output should be JSON.
#' @param max_attempts The maximum number of attempts to make for generating valid output.
#' @return The generated text.
#' @importFrom httr POST add_headers content http_error status_code
#' @importFrom jsonlite fromJSON
#' @noRd
.openai_chat_completions <- function(model = 'gpt-3.5-turbo',
                                     system_message = '',
                                     user_message = '',
                                     temperature = 1,
                                     top_p = 1,
                                     max_tokens = NULL,
                                     openai_api_key,
                                     openai_organization,
                                     force_json = TRUE) {
  
  if (is.null(openai_api_key) || openai_api_key == "") {
    stop("OpenAI API key is missing.", call. = FALSE)
  }
  
  messages <- list(
    list("role" = "system", "content" = system_message),
    list("role" = "user", "content" = user_message)
  )
  
  response <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    httr::add_headers("Authorization" = paste("Bearer", openai_api_key),
                      "Content-Type" = "application/json"),
    body = list(model = model,
                messages = messages,
                temperature = temperature,
                top_p = top_p,
                max_tokens = max_tokens),
    encode = "json"
  )
  
  if (httr::http_error(response)) {
    error_content <- httr::content(response, "text", encoding = "UTF-8")
    cat("API request failed with status code:", httr::status_code(response), "\n")
    cat("Error response content:\n", error_content, "\n")
    stop("API request failed with status code: ", httr::status_code(response), call. = FALSE)
  }
  
  httr::content(response, "text", encoding = "UTF-8")
}


#' Get or Initialize Local Model
#'
#' This function gets the initialized local model pipeline or initializes it if not already done.
#'
#' @param model_name The name of the model to initialize.
#' @return The initialized local model pipeline.
#' @importFrom reticulate source_python
#' @noRd
.get_local_model <- function(model) {
  if (exists("local_model_pipeline", envir = .GlobalEnv)) {
    return(get("local_model_pipeline", envir = .GlobalEnv))
  } else {
    local_model_pipeline <- reticulate::py$initialize_model(model)
    assign("local_model_pipeline", local_model_pipeline, envir = .GlobalEnv)
    return(local_model_pipeline)
  }
}
