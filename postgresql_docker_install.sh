#!/bin/sh

echo "Updating and installing Docker"
sudo yum update -y
sudo yum upgrade -y

sudo yum remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine

sudo yum install -y yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    
sudo yum install docker-ce docker-ce-cli containerd.io

echo "Starting and enabling Docker"
sudo systemctl start docker
sudo systemctl enable docker

echo "Configure database user"
read -p "Postgres user name: " name
read -s -p "Postgres user password: " password

export POSTGRES_USER=$name
export POSTGRES_PASSWORD=$password

sudo docker rm --force postgres || true

echo "Creating database container (and seed 'sample' database)"
sudo docker volume create pg-data
sudo docker run -d \
  --name postgres \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=sample \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  -v "pg-data:/var/lib/postgresql/data" \
  -p "80:5432" \ #you can change the port mapping here
  --restart always \
  postgres:9.6-alpine

sleep 20 # Ensure enough time for postgres database to initialize and create role

# Modify according to your requirements
sudo docker exec -i postgres psql -U $POSTGRES_USER -d sample <<-EOF
create table employees (
  id INT,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(50),
  gender VARCHAR(50),
  favorite_color VARCHAR(50)
);
insert into employees (id, first_name, last_name, email, gender, favorite_color) values (1, 'Lauralee', 'Morkham', 'lmorkham0@example.com', 'Female', '#878922');
insert into employees (id, first_name, last_name, email, gender, favorite_color) values (2, 'Hillery', 'Langland', 'hlangland1@example.com', 'Male', '#6fd569');
insert into employees (id, first_name, last_name, email, gender, favorite_color) values (3, 'Regan', 'Kroger', 'rkroger2@example.com', 'Male', '#d9c547');
EOF
