# This simple script will display the crontabs for each user.
# Useful for when you can't remember where you scheduled a cron job.
# Tip: You may need to add 'sudo' in front of the crontab command.

for user in $(cut -f1 -d: /etc/passwd)
do
  echo To edit, use: crontab -u $user -e
  crontab -u $user -l
done
