

wine1 <- read.csv('/home/jtimm/pCloudDrive/recipes/wine-corpus/winemag-data_first150k.csv')

# Replace empty strings with NA
wine1[wine1 == ""] <- NA

# Remove the 'region_2' column
wine1$region_2 <- NULL

# Filter rows where all cells are complete
wine_filtered <- wine1[complete.cases(wine1), ]

# Sample 250 rows from the filtered dataset
set.seed(123) # Setting seed for reproducibility, optional
wine <- wine_filtered[sample(nrow(wine_filtered), 250), ]

# save(ws, file = "data/wine.rda")

# Use usethis to save the dataset
usethis::use_data(wine, overwrite = TRUE, internal = FALSE)