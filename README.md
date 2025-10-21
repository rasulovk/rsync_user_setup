Overview
setup_syncuser.sh is a Bash script designed to create a restricted user account (syncuser) on a Linux system. This user is granted limited access to a specified source folder via a restricted rsync wrapper, allowing secure file synchronization.

Features
Prompts for the source folder path to restrict rsync access.
Creates a new user with a specified password if it does not already exist.
Installs a public SSH key for secure access.
Sets up a restricted rsync wrapper to limit access to the specified folder.
Optionally configures sudo permissions for the new user.
Usage
Make the script executable:
Run the script:
Follow the prompts to enter the source folder path, user password, and public SSH key.
Requirements
rsync must be installed on the system.
sudo must be installed for configuring permissions.
Note
After running the script, remember to edit the sudo permissions for the syncuser as instructed at the end of the script.
