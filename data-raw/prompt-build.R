# List text files in the specified directory
files <- fs::dir_ls("/home/jtimm/pCloudDrive/GitHub/packages/prompts/prompts", regexp = "\\.txt$")

# Read each file into a character vector
prompts <- lapply(files, readLines, warn = FALSE)

# Collapse the content of each file into a single string
prompts <- lapply(prompts, paste, collapse = "\n")

# Name the list elements by their file names minus the .txt extension
names(prompts) <- gsub("\\.txt$", "", basename(files))

# Save the named list to an .rda file in the 'data' directory
usethis::use_data(prompts, overwrite = TRUE)