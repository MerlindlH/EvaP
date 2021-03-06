#!/bin/bash
set -e # abort on error
cd `dirname $0`/.. # change to root directory

# argument 1 is the filename for the backupfile.
# if no argument is present, no backup will be created.
if [ $# -eq 1 ] # if there is exactly one argument
    then
        echo Creating backup.
        set -x # print executed commands. enable this here to not print the if above.
        sudo -u evap ./manage.py dumpdata --indent 2 --output $1
    else
        echo No backup file specified, skipping backup creation.
        set -x # print executed commands
fi

sudo -u evap git fetch
sudo -u evap git checkout origin/release
sudo pip3 install -r requirements.txt
sudo -u evap ./manage.py compilemessages
sudo -u evap ./manage.py collectstatic --noinput
sudo -u evap ./manage.py compress --verbosity=0
sudo -u evap ./manage.py migrate
# reload only after static files are updated, so the new code finds all the files it expects.
# also, reload after migrations happened. see https://github.com/fsr-itse/EvaP/pull/817 for a discussion.
sudo service apache2 reload
# update caches. this can take minutes but doesn't need a reload.
sudo -u evap ./manage.py clear_cache
sudo -u evap ./manage.py refresh_results_cache

{ set +x; } 2>/dev/null # don't print the echo command, and don't print the 'set +x' itself

echo Update completed.
