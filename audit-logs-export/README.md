# GCP Schedule Cloud Run Job Backup

This is a docketized python script for exporting the audit logs from Alfresco

It is designed to work on Cloud Run Jobs services.

## Getting Started 📖

Software requirements:

* Docker
* Python

## Deployment 🚀

Build and tag image:

**You will need to change the tag according to your needs.*

```sh
docker build . -t eu.gcr.io/XXX/audit-logs-export:latest
```

Push image to GCR

```sh
docker push eu.gcr.io/XXX/audit-logs-export:latest
```

## Usage ✏️

A Cloud Run Job must be created using the uploaded image.

The following environment variables are required:

* GC_PROJECT: *Name of the project where the resources are located*
* ALFRESCO_PASSWORD: *Alfresco password (use a secret on cloud run)*
* ALFRESCO_USERNAME: *Alfresco username (use a secret on cloud run)*
* BUCKET_NAME: *Name of the bucket where the audits logs will be stored*
* ALFRESCO_BASE_URL: *Domain of Alfresco app*
* DAYS_BACK: *Number of days that the tool will export the audit logs*
* DELETE_AFTER_EXPORT: *True or False, if True the audit logs will be removed from the database after the exporting to cloud storage*


Finally, a trigger can be scheduled to execute the task periodically.

## Author 🐒

* Javier Sainz Maza
