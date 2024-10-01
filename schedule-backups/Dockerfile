FROM google/cloud-sdk:latest

# Execute next commands in the directory /workspace
WORKDIR /workspace

# Copy over the script to the /workspace directory
COPY backup-sql-disk.sh .

# Just in case the script doesn't have the executable bit set
RUN chmod +x ./backup-sql-disk.sh

# Run the script when starting the container
CMD [ "./backup-sql-disk.sh" ]