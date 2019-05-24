#------------------------------------------------------------------------------#
# A script to generate Clear Water Predictions
# This script checks the data portal to see if today's DNA test results are posted
# If yes, then it upserts the predictions to the data portal
# It is run every 5 minutes
#
# Author: Nick Lucius
#------------------------------------------------------------------------------#

rm(list=ls())

#------------------------------------------------------------------------------#
# Source Functions                                                             
#------------------------------------------------------------------------------#

sourceDir <- function(path, trace = TRUE, ...) {
  for (nm in list.files(path, pattern = "\\.[Rr]$")) {
    if(trace) cat(nm,":")           
    source(file.path(path, nm), ...)
    if(trace) cat("\n")
  }
}

sourceDir(paste(getwd(),"/Functions",sep=""))

#------------------------------------------------------------------------------#
# Load libraries                                                             
#------------------------------------------------------------------------------#

usePackage("RSocrata")
usePackage("randomForest")

#------------------------------------------------------------------------------#
# Set variables                                                             
#------------------------------------------------------------------------------#

datasetUrl <- "https://data.cityofchicago.org/Parks-Recreation/Beach-Lab-Data/2ivx-z93u"
modelPath <- paste0(getwd(),"/data/model.Rds")
today <- Sys.Date()


# Socrata variables
app_token <- readLines("credentials/token.txt")
email <- readLines("credentials/email.txt")
password <- readLines("credentials/password.txt")

# bring in lat/longs for each beach, which must be included in the upsert
cleanBeachNames <- read.csv("csv/cleanbeachnames.csv")
locationLookup <- cleanBeachNames[,c("Short_Names","Latitude","Longitude")]
locationLookup <- unique(locationLookup)
for (row in c(1:length(locationLookup$Short_Names))) {
  locationLookup$Location[row] <- paste0("(", locationLookup$Latitude[row], ", ", locationLookup$Longitude[row], ")")
}
displayNames <- read.csv("csv/beach-display-names.csv")

beaches <- c("12th","31st","39th","57th","Albion","Foster","Howard","Jarvis","Juneway","Leone",       
             "North Avenue","Oak Street","Ohio","Osterman","Rogers") # beaches being predicted
allBeaches <- c("12th","31st","39th","57th","63rd","Albion","Calumet","Foster",
                "Howard","Jarvis","Juneway","Leone","Montrose","North Avenue","Oak Street",
                "Ohio","Osterman","Rainbow","Rogers","South Shore") # all beaches
beaches <- factor(beaches, levels = allBeaches)

#------------------------------------------------------------------------------#
# Download data needed for the model                                                             
#------------------------------------------------------------------------------#

#Pull latest DNA tests from Data Portal and determine if we have the 5 beaches that the model needs
labPortal <- read.socrata(datasetUrl,
                          app_token = app_token)
dates <- labPortal$dna_sample_timestamp 
dates <- strftime(dates, format = "%Y-%m-%d")
todaysLabs <- labPortal[dates == today & !is.na(dates),]
readyToModel <- "Calumet" %in% todaysLabs$beach & 
  "63rd Street" %in% todaysLabs$beach & 
  "Rainbow" %in% todaysLabs$beach & 
  "Montrose" %in% todaysLabs$beach & 
  "South Shore" %in% todaysLabs$beach

#------------------------------------------------------------------------------#
# Generate Predictions                                                             
#------------------------------------------------------------------------------

# if we have all the inputs, run the model and send predictions to Data Portal
if (readyToModel) {

  input <- data.frame("Client.ID" = beaches,
                      "Date" = today,
                      "n63rd_DNA.Geo.Mean" = todaysLabs[todaysLabs$beach == "63rd Street","dna_reading_mean"][length(todaysLabs[todaysLabs$beach == "63rd Street","dna_reading_mean"])],
                      "South_Shore_DNA.Geo.Mean" = todaysLabs[todaysLabs$beach == "South Shore","dna_reading_mean"][length(todaysLabs[todaysLabs$beach == "South Shore","dna_reading_mean"])],
                      "Montrose_DNA.Geo.Mean" = todaysLabs[todaysLabs$beach == "Montrose","dna_reading_mean"][length(todaysLabs[todaysLabs$beach == "Montrose","dna_reading_mean"])],
                      "Calumet_DNA.Geo.Mean" = todaysLabs[todaysLabs$beach == "Calumet","dna_reading_mean"][length(todaysLabs[todaysLabs$beach == "Calumet","dna_reading_mean"])],
                      "Rainbow_DNA.Geo.Mean" = todaysLabs[todaysLabs$beach == "Rainbow","dna_reading_mean"][length(todaysLabs[todaysLabs$beach == "Rainbow","dna_reading_mean"])])
  model <- readRDS(modelPath)
  predictions <- cbind(input,"prediction" = predict(model,input))
  
  # format output
  output <- predictions[,c(1,2,8)]
  names(output)[1:3] <- c("beach_name", "date", "predicted_level")
  output$predicted_level <- round(output$predicted_level, digits = 1)
  output$prediction_source <- "DNA Model"
  output <- output[,c(1,2,4,3)]
  output <- merge(output, locationLookup, by.x = "beach_name", by.y = "Short_Names")
  
  # change beach_name to match current names
  output <- merge(output, displayNames, by = "beach_name")
  output$beach_name <- output$display_name
  output$display_name <- NULL
  
  # add record ID
  output$recordid <- paste0(gsub(" ", "", output$beach_name, fixed = TRUE), strftime(today, format = "%Y%m%d"))
  output$recordid <- gsub("\\(", "", output$recordid)
  output$recordid <- gsub("\\)", "", output$recordid)
  
  catch <- try({
    result <- write.socrata(dataframe = output, 
                            dataset_json_endpoint = "https://data.cityofchicago.org/resource/xvsz-3xcj.json", 
                            update_mode = "UPSERT",
                            email = email,
                            password = password,
                            app_token = app_token)
  })
  print(paste0("Predictions for ", today, " sent to Data Portal"))
  print(result)
  if(inherits(catch, "try-error")){
    msg <- "write.socrata failed when trying to update the Data Portal."
    subj <- "'Clear Water Predictions - Failed to Update'"
  } else {
    subj <- "'Clear Water Predictions - Updated'"
    msg <- jsonlite::fromJSON(rawToChar(result$content))
    msg <- paste(names(msg), msg, collapse = " ")
  }
  
} else {
  result <- paste0("Not enough DNA test results to issue a prediction at ", Sys.time())
  print(result)
  subj <- "'Clear Water Predictions - Not Ready'"
  msg <- result
}

cmd <- paste("echo", msg, "| mail -s", subj, "-r", "data-science-bot@cityofchicago.org", "%s")
system(sprintf(cmd, "datascience@cityofchicago.org"))
