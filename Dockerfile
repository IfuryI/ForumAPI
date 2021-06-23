FROM ubuntu:18.04

MAINTAINER Ilya Afimin

ENV TZ=Russia/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# Обвновление списка пакетов
RUN apt-get -y update



ENV PGVER 10
RUN apt-get install -y postgresql-$PGVER

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-$PGVER`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker &&\
    /etc/init.d/postgresql stop

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/$PGVER/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/$PGVER/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "max_connections = 32" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "shared_buffers = 512MB" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "effective_cache_size = 1536MB" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "maintenance_work_mem = 128MB" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "checkpoint_completion_target = 0.9" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "wal_buffers = 16MB" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "default_statistics_target = 100" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "random_page_cost = 1.1" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "effective_io_concurrency = 200" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "work_mem = 4MB" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "min_wal_size = 1GB" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "max_wal_size = 4GB" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "max_worker_processes = 8" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "max_parallel_workers_per_gather = 4" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "max_parallel_workers = 8" >> /etc/postgresql/$PGVER/main/postgresql.conf
RUN echo "max_parallel_maintenance_workers = 4" >> /etc/postgresql/$PGVER/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Back to the root user
USER root


RUN apt-get install -y curl
RUN curl —silent —location https://deb.nodesource.com/setup_13.x | bash -
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential

# создание директории приложения
WORKDIR /usr/src/app

# установка зависимостей
# символ астериск ("*") используется для того чтобы по возможности
# скопировать оба файла: package.json и package-lock.json
COPY package*.json ./

RUN npm install
# Если вы создаете сборку для продакшн
# RUN npm ci --only=production

# копируем исходный код
COPY . .

EXPOSE 5000

ENV PGPASSWORD docker

CMD service postgresql start && psql -h localhost -d docker -U docker -p 5432 -a -q -f ./database/db_script.sql && node ./dist/bundle.js
