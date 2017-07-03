#!/bin/bash
#==========================================================================
# chosedb.sh for Linux - Version 1.0
# Author   : Michael Milette, www.tngconsulting.ca
# Date     : 2017-07-03 (initial release)
# Purpose  : Linux console based tool which displays a menu to select a MySQL database.
# Copyright (c) 2005-2017 TNG Consulting Inc. All rights reserved.
# License  : GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
#==========================================================================

# ===================================================================
# Configurable settings
# ===================================================================
# Note: You can customize the list of databases to be excluded in the dialog_getdb() function.
DIALOG="dialog"
DBSERVER="-h 127.0.0.1 -P 3306 "
DBUSERPWD="root"
DB=""

# ===================================================================
# Function:   dialog_getdb()
# Purpose:    Have user choose a database.
# Parameter:  $1 Dialogue box Title
# Globals:    $DBUSERPWD - contains username followed optionally by a space and -p and the password.
#             $DBSERVER - Contains optional parameters to specify server. Must be blank or end with a space.
# Example:    DBUSERPWD = "dbuser -pPassWord"  # or just DBUSERPWD="dbuser" if there is no password.
#             DBSERVER="-h 127.0.0.1 -P 3306 " # or just DBSERVER="".
#             dialog_getdb "Database Chooser"
# Return:     0 if successful, 1 if user cancelled.
#             global $DB which will contain the name of the selected database.
# Dependency: apt-get install dialog # on Debian or Ubuntu.
#             yum install dialog # on CentOS or Redhat.
# Notes:      Only tested on Debian/Ubuntu and Cygwin.
# ===================================================================
function dialog_getdb()
{
    local excludeDBS=(information_schema mysql performance_schema) # list of databases to ignore.
    local MENUITEMS=() # define working array
    local errorlevel # Return value from running executables.
    local count=0  # Count of database names.
    local skipdb=0 # Used to flag exclusion of database from menu list.
    
    
    # Retrieve list of databases from MySQL server.
    local DBS=$(mysql -u $DBUSERPWD $DBSERVER--batch --silent -e 'SHOW DATABASES;')
    errorlevel=$?
    if [ $errorlevel -ne 0 ]; then # Display error message.
        $DIALOG --title "$1" --msgbox "Could not connect to MySQL." 6 45
        return 1;
    fi

    # Only add databases to the menu list which are not in the excludeDBS array.
    for db in $DBS; do
        skipdb=-1
        if [ ${#excludeDBS[@]} != 0 ]; then # Not empty.
            # Make sure this database isn't in the exclude list.
            for ignoreDB in ${excludeDBS[@]}; do
                if [ "$ignoreDB" == "$db" ]; then
                    skipdb=1
                    break
                fi
            done
        fi

        if [ "$skipdb" == "-1" ]; then
            # Add database to menu.
            MENUITEMS+=("$((++count))" $db)
        fi
    done

    # Display dialog menu.
    DB=$(
        $DIALOG --title "$1" --menu "Select a database" 24 40 17 \
            "${MENUITEMS[@]}" 3>&2 2>&1 1>&3
    )
    errorlevel=$?
    clear
    
    # User pressed Cancel or ESC.
    if [ $errorlevel -ne 0 ]; then
        DB=""
        return 1
    fi

    # Return database name only.
    DB=${MENUITEMS[`expr $DB*2-1`]}
    return 0
}

# ===================================================================
# Main code.
# ===================================================================

dialog_getdb "Database Chooser" # returns $DB

if [ $? -ne 0 ]; then
    echo "You did not select any database."
    exit 1
else
    echo "You selected the $DB database."
fi

exit 0
