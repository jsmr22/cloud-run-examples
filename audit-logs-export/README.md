# GCP Schedule Cloud Run Job Backup

This is a docketized sh script for running GCP Cloud SQL and Disk Snapshots on-demand backups.

It is designed to work on Cloud Run Jobs services.

## Getting Started 📖

Software requirements:

* Docker
* Python

## Deployment 🚀

Build and tag image:

**You will need to change the tag according to your needs.*

```sh
docker build . -t eu.gcr.io/XXX/shedule-backups
```

Push image to GCR

```sh
docker push eu.gcr.io/XXX/shedule-backups:latest
```

## Usage ✏️

A Cloud Run Job must be created using the uploaded image.

The following environment variables are required:

* GC_PROJECT: *Name of the project where the resources are located*
* GC_DB: *DB that you want to back up*
* GC_DB_ASYNC: *'1' if you want an asynchronous DB copy / '0' if you want to wait for the DB copy to finish*
* GC_DB_location: *Location you want to store the database backup, default store in eu multi-region*
* GC_DISK: *Name of the disk to back up*
* GC_DISK_REGIONAL: *'1' regional / '0' zonal*
* GC_DISK_ZONE: *Current zone or region of the disk*
* GC_DISK_STORAGE_LOCATION: *Where you want to host the backup*
* GC_CLEAN_DAYS: *Number of days to retain backups*
* GC_DISK_SOLR: *Name of the solr disk to back up*
* GC_DISK_REGIONAL_SOLR: *'1' regional / '0' zonal*
* GC_DISK_ZONE_SOLR: *Current zone or region of the disk*
* GC_DISK_STORAGE_LOCATION_SOLR: *Where you want to host the solr backup*

The following environment variables are optional only use in case have this services:

* GC_DB_IDENTITY: *Where you want to host the solr backup*
* GC_DB_IDENTITY_ASYNC: *Where you want to host the solr backup*
* GC_DISK_LDAP: *Name of the ldap disk to back up*
* GC_DISK_LDAP_REGIONAL: *'1' regional / '0' zona*
* GC_DISK_LDAP_ZONE: *Current zone or region of the disk*
* GC_DISK_LDAP_STORAGE_LOCATION: *Where you want to host the ldap backup*


Finally, a trigger can be scheduled to execute the task periodically.

## Author 🐒

* javiersainzmaza@gmail.com