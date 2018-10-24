#!/bin/sh

### DATABASE CONNECTION ###

COUNT=20

for i in $(seq 1 1 $COUNT)
do
	echo "Trying to connect to database: try $i..."
		mysql -B --connect-timeout=1 -h $DB_HOST  -P $DB_PORT -u $DB_USER -p$DB_PASSWORD -e "SELECT VERSION();" $DB_DATABASE 
	
	if [ "$?" = "0" ]; then
		echo "[i] Successfully connected to database!"
		break
	else
		if [ "$i" = "$COUNT" ]; then
			echo "[FAIL] The database is not ready."
			exit 0
		else
			sleep 5
		fi
	fi
done

### CONFIGURING FIR ###

# Configure fir access to database"
sed -i "s/'NAME': '',/'NAME': '$DB_DATABASE',/;s/'USER': '',/'USER': '$DB_USER',/;s/'PASSWORD': '',/'PASSWORD': '$DB_PASSWORD',/;s/'HOST': '',/'HOST': '$DB_HOST',/; s/'PORT': '',/'PORT': '$DB_PORT',/" fir/config/production.py

echo "Create tables in the database"
./manage.py migrate --settings fir.config.production
echo "Import initial data"
./manage.py loaddata incidents/fixtures/seed_data.json --settings fir.config.production
./manage.py loaddata incidents/fixtures/dev_users.json --settings fir.config.production
echo "Collect static files"
./manage.py collectstatic --settings fir.config.production

# Change permissions 
chown www-data logs/errors.log uploads
chmod 750 logs/errors.log uploads

# Internationalization
cd incidents
django-admin.py compilemessages
cd ..

### CONFIGURING NGINX ###

# Generate Certificate
mkdir /etc/nginx/conf.d/ssl/
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/conf.d/ssl/fir-server.key -out /etc/nginx/conf.d/ssl/fir-server.crt -subj "/C=ES/ST=Pontevedra/L=Vigo/O=organization/OU=organizationU/CN=fir.organization.es"

# Enable configuration
mkdir -p /run/nginx/
ln -s /etc/nginx/sites-available/fir /etc/nginx/conf.d/fir.conf
rm /etc/nginx/conf.d/default.conf
nginx

### CONFIGURING uWSGI ###

chown www-data run
# Launch uwsgi
/usr/bin/uwsgi --socket /app/FIR/run/fir.sock --chdir /app/FIR/ --module fir.wsgi --uid www-data --gid www-data --chmod-socket=664