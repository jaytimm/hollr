#' Political Ideology Dataset
#'
#' A dataset containing information on political ideology articles from PubMed.
#'
#' @format A data.table with 250 rows and 5 variables:
#' \describe{
#'   \item{pmid}{Character: PubMed ID}
#'   \item{year}{Character: Year of publication}
#'   \item{journal}{Character: Name of the journal}
#'   \item{articletitle}{Character: Title of the article}
#'   \item{abstract}{Character: Abstract of the article}
#' }
#' @source \url{https://pubmed.ncbi.nlm.nih.gov/}
"political_ideology"


#' Prompts Data Set
#'
#' This data set contains a list of character strings, each representing the content of a text file.
#' The text files are prompts that can be used for various purposes, such as testing and examples.
#'
#' @format A named list where each element is a character string representing the content of a text file. The names of the elements correspond to the file names without the .txt extension.
#' \describe{
#'   \item{\code{prompt1}}{The content of the first text file.}
#'   \item{\code{prompt2}}{The content of the second text file.}
#'   ...
#' }
#' @source The text files were obtained from the directory `/home/jtimm/pCloudDrive/GitHub/packages/prompts/prompts`.
#'
#' @examples
#' data(prompts)
#' print(prompts[["prompt1"]])
#'
"prompts"
