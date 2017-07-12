# Clear Water App

This is a companion repository to the [Clear Water model repo](https://github.com/Chicago/clear-water/) for predicting beach water quality.
It can be used as a production-ready solution to deliver model predictions
to a [Socrata data portal](https://data.cityofchicago.org/Parks-Recreation/Beach-E-coli-Predictions/xvsz-3xcj/data) and [map](https://data.cityofchicago.org/Parks-Recreation/Clear-Water-Map/mf7j-mc8j). 

## Notes

The file ```model.Rds``` is obtained by running ```Master.R``` in the 
[Clear Water model repo](https://github.com/Chicago/clear-water/).
To generate the file, set the ```productionMode``` [variable](https://github.com/Chicago/clear-water/blob/master/Master.R#L85) in the model repo to TRUE. Place the file in the ```data``` directory of this repo.

Make sure you also set the ```datasetUrl``` [variable](https://github.com/Chicago/clear-water-app/blob/master/app.R#L37) in ```app.R```.

## Socrata Credentials

To upload predictions to a Socrata portal, this application uses Chicago's 
[RSocrata](https://github.com/Chicago/RSocrata)
[R package](https://cran.r-project.org/web/packages/RSocrata/index.html). You will have to authenticate with your data portal creditionals in order to add data to a predictions dataset. To authenticate with Socrata and upload predictions using this
automated app, create files to save login and app token details in the `credentials` folder, named as follows:

* `email.txt`
* `password.txt`
* `token.txt`

```App.R``` will read these credentials and use them to send the data
to the Socrata dataset.

## Model Settings

This app is currently configured to predict water quality at beaches within a regional system. Specifically, it predicts the quality of some beaches along Chicago's Lake Michigan coastline based on the same-day bacteria observed at 5 predictor beaches.
