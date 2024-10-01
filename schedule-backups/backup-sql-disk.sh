#!/bin/bash
set -eo pipefail

# all variables needed in the project to execute properly "variable=GCPvariable"
project=${GC_PROJECT}
db=${GC_DB}
db_async=${GC_DB_ASYNC}
db_identity=${GC_DB_IDENTITY}
db_async_identity=${GC_DB_IDENTITY_ASYNC}
db_location=${GC_DB_location}
disk=${GC_DISK}
disk_regional=${GC_DISK_REGIONAL}
disk_zone=${GC_DISK_ZONE}
disk_storage_location=${GC_DISK_STORAGE_LOCATION}
disk_solr=${GC_DISK_SOLR}
disk_regional_solr=${GC_DISK_REGIONAL_SOLR}
disk_zone_solr=${GC_DISK_ZONE_SOLR}
disk_storage_location_solr=${GC_DISK_STORAGE_LOCATION_SOLR}
disk_ldap=${GC_DISK_LDAP}
disk_ldap_regional=${GC_DISK_LDAP_REGIONAL}
disk_ldap_zone=${GC_DISK_LDAP_ZONE}
disk_ldap_storage_location=${GC_DISK_LDAP_STORAGE_LOCATION}
clean_days=${GC_CLEAN_DAYS}

clean_date=$(date '+%Y-%m-%d' --date='-'$clean_days' day')


# Screen information to check the execution of the task
echo "Starting Job"
echo "Project: $project"
echo "DB: $db"
echo "DB Async: $db_async"
echo "DB: $db_identity"
echo "DB Async: $db_async_identity"
echo "DB Location: $db_location"
echo "Disk: $disk"
echo "Disk reginal: $disk_regional"
echo "Disk Zone: $disk_zone"
echo "Disk Storage Location: $disk_storage_location"
echo "Disk ldap: $disk_ldap"
echo "Disk ldap reginal: $disk_ldap_regional"
echo "Disk ldap Zone: $disk_ldap_zone"
echo "Disk ldap Storage Location: $disk_ldap_storage_location"
echo "Disk SOLR: $disk_solr"
echo "Disk SOLR reginal: $disk_regional_solr"
echo "Disk Zone SOLR: $disk_zone_solr"
echo "Disk Storage Location SOLR: $disk_storage_location_solr"
echo "Clean date: $clean_date"

#Processing backups of the databse

#Backup main DB with a conditional between regional and zonal
if [[ -n $db ]]
then
  if [[ $db_async -eq 1 ]]
  then
      echo "Creating DB Backup async..."
      gcloud sql backups create --async --project="$project" --instance="$db" --location="$db_location" --description="Automated backup plan"
  else
      echo "Creating DB Backup..."
      gcloud sql backups create --project="$project" --instance="$db" --location="$db_location" --description="Automated backup plan"
      echo "Created DB Backup"
  fi
fi

sleep 5

#Backup identity DB with a conditional between regional and zonal
if [[ -n $db_identity ]]
then
  if [[ $db_async_identity -eq 1 ]]
  then
      echo "Creating identity DB Backup async..."
      gcloud sql backups create --async --project="$project" --instance="$db_identity" --location="$db_location" --description="Automated identity backup plan"
  else
      echo "Creating identity DB Backup..."
      gcloud sql backups create --project="$project" --instance="$db_identity" --location="$db_location" --description="Automated identity backup plan"
      echo "Created DB Backup"
  fi
fi
sleep 5

#Processing backups of the compute engine disk

#Backup infrastructure with a conditional between regional and zonal
if [[ -n $disk ]]
then
  if [[ $disk_regional -eq 1 ]]
  then
      echo "Creating regional Disk Snapshot..."
      gcloud compute snapshots create "$disk"-"$(date '+%Y-%m-%d-%H-%M-%S')" --project="$project" --source-disk="$disk" --source-disk-region="$disk_zone" --storage-location="$disk_storage_location"
      echo "Created Disk Snapshot"
  else
      echo "Creating zonal Disk Snapshot..."
      gcloud compute snapshots create "$disk"-"$(date '+%Y-%m-%d-%H-%M-%S')" --project="$project" --source-disk="$disk" --source-disk-zone="$disk_zone" --storage-location="$disk_storage_location"
      echo "Created Disk Snapshot"
  fi
fi
#Backup ldap with a conditional between regional and zonal
if [[ -n $disk_ldap ]]
then
  if [[ $disk_ldap_regional -eq 1 ]]
  then
      echo "Creating regional SOLR Disk Snapshot..."
      gcloud compute snapshots create "$disk_ldap"-"$(date '+%Y-%m-%d-%H-%M-%S')" --project="$project" --source-disk="$disk_ldap" --source-disk-region="$disk_ldap_zone" --storage-location="$disk_ldap_storage_location"
      echo "Created SOLR Disk Snapshot"
  else
      echo "Creating zonal SOLR Disk Snapshot..."
      gcloud compute snapshots create "$disk_ldap"-"$(date '+%Y-%m-%d-%H-%M-%S')" --project="$project" --source-disk="$disk_ldap" --source-disk-zone="$disk_ldap_zone" --storage-location="$disk_ldap_storage_location"
      echo "Created SOLR Disk Snapshot"
  fi
fi
#Backup solr with a conditional between regional and zonal
if [[ -n $disk_solr ]]
then
  if [[ $disk_regional_solr -eq 1 ]]
  then
      echo "Creating regional SOLR Disk Snapshot..."
      gcloud compute snapshots create "$disk_solr"-"$(date '+%Y-%m-%d-%H-%M-%S')" --project="$project" --source-disk="$disk_solr" --source-disk-region="$disk_zone_solr" --storage-location="$disk_storage_location_solr"
      echo "Created SOLR Disk Snapshot"
  else
      echo "Creating zonal SOLR Disk Snapshot..."
      gcloud compute snapshots create "$disk_solr"-"$(date '+%Y-%m-%d-%H-%M-%S')" --project="$project" --source-disk="$disk_solr" --source-disk-zone="$disk_zone_solr" --storage-location="$disk_storage_location_solr"
      echo "Created SOLR Disk Snapshot"
  fi
fi
#Cleaning the database backups

#clean main DB with a specific age and description
if [[ -n $db ]]
then
  echo "Cleaning old BD Backups..."
  for value in $(gcloud sql backups list -i $db --filter="startTime<'$clean_date' AND description='Automated backup plan' AND type='ON_DEMAND'" --format="value(id)")
  do
      gcloud sql backups delete -i $db $value || true
  done
  echo "Cleaned old BD Backups"
fi

#clean Identity DB with a specific age and description
if [[ -n $db_identity ]]
then
  echo "Cleaning old identity BD Backups..."
  for value in $(gcloud sql backups list -i $db_identity --filter="startTime<'$clean_date' AND description='Automated identity backup plan' AND type='ON_DEMAND'" --format="value(id)")
  do
      gcloud sql backups delete -i $db_identity $value || true
  done
  echo "Cleaned old identity BD Backups"
fi
#Cleaning the disk backups

#clean infrastructure DISK with a specific age
if [[ -n $disk ]]
then
  if [[ $disk_regional -eq 1 ]]
  then
      echo "Cleaning old regional disk snapshots..."
      gcloud compute snapshots list --filter="creationTimestamp<'$clean_date' AND sourceDisk='https://www.googleapis.com/compute/v1/projects/$project/regions/$disk_zone/disks/$disk'" --uri | xargs gcloud compute snapshots delete || true
      echo "Cleaned old disk snapshots"
  else
      echo "Cleaning old zonal disk snapshots..."
      gcloud compute snapshots list --filter="creationTimestamp<'$clean_date' AND sourceDisk='https://www.googleapis.com/compute/v1/projects/$project/zones/$disk_zone/disks/$disk'" --uri | xargs gcloud compute snapshots delete || true
      echo "Cleaned old disk snapshots"
  fi
fi

#clean ldap disk with a specific age
if [[ -n $disk_ldap ]]
then
  if [[ $disk_ldap_regional -eq 1 ]]
  then
      echo "Cleaning old regional ldap disk snapshots..."
      gcloud compute snapshots list --filter="creationTimestamp<'$clean_date' AND sourceDisk='https://www.googleapis.com/compute/v1/projects/$project/regions/$disk_ldap_zone/disks/$disk_ldap'" --uri | xargs gcloud compute snapshots delete || true
      echo "Cleaned old ldap disk snapshots"
  else
      echo "Cleaning old zonal ldap disk snapshots..."
      gcloud compute snapshots list --filter="creationTimestamp<'$clean_date' AND sourceDisk='https://www.googleapis.com/compute/v1/projects/$project/zones/$disk_ldap_zone/disks/$disk_ldap'" --uri | xargs gcloud compute snapshots delete || true
      echo "Cleaned old ldap disk snapshots"
  fi
fi

#clean solr disk with a specific age
if [[ -n $disk_solr ]]
then
  if [[ $disk_regional_solr -eq 1 ]]
  then
      echo "Cleaning old regional SOLR disk snapshots..."
      gcloud compute snapshots list --filter="creationTimestamp<'$clean_date' AND sourceDisk='https://www.googleapis.com/compute/v1/projects/$project/regions/$disk_zone_solr/disks/$disk_solr'" --uri | xargs gcloud compute snapshots delete || true
      echo "Cleaned old SOLR disk snapshots"
  else
      echo "Cleaning old zonal SOLR disk snapshots..."
      gcloud compute snapshots list --filter="creationTimestamp<'$clean_date' AND sourceDisk='https://www.googleapis.com/compute/v1/projects/$project/zones/$disk_zone_solr/disks/$disk_solr'" --uri | xargs gcloud compute snapshots delete || true
      echo "Cleaned old SOLR disk snapshots"
  fi
fi

echo "Completed Job"


#Test code to check funcionality
#if [[ $retVal -eq 0 ]]
#then
#    echo "Completed Task."
#else
#    echo "Task failed."
#fi