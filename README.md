# Notes

The file ```model.Rds``` is obtained by running ```Master.R``` in the 
[E. coli Model](https://github.com/Chicago/e-coli-beach-predictions).
The model object is created in the ```modelEcoli.R``` [file](https://github.com/Chicago/e-coli-beach-predictions/blob/master/Functions/modelEcoli.R). Add a line of code
to save the model object as an Rds file, and configure the training set in the ```Master.R``` [file](https://github.com/Chicago/e-coli-beach-predictions/blob/master/Master.R). Make sure you set the
[kFolds variable](https://github.com/Chicago/e-coli-beach-predictions/blob/master/Master.R#L51) to FALSE.

# Socrata Credentials

To authenticate with Socrata and upload predictions, create files to save login 
and app token details in the `credentials` folder, named as follows:

* `email.txt`
* `password.txt`
* `token.txt`

```App.R``` will read these credentials and use them to make send the data
to the Socrata dataset.
