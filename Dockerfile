FROM python:3.7.2-slim

RUN mkdir /app
WORKDIR /app

ENV MONGODB_PACKAGE_VERSION 4.0
ENV MONGODB_VERSION 4.0.6

RUN apt-get update && apt-get install --no-install-recommends -y \
  dirmngr \
  gnupg2 \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv 9DA31620334BD75D9DCB49F368818C72E52529D4 \
  && echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/${MONGODB_PACKAGE_VERSION} main" \
  | tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_PACKAGE_VERSION}.list \
  && apt-get update && apt-get install --no-install-recommends -y \
  mongodb-org-shell=${MONGODB_VERSION} \
  && apt-get remove -y \
  dirmngr \
  gnupg2 \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/*

COPY mflix-python/requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY mflix-python .

EXPOSE 5000/tcp
EXPOSE 8888/tcp

LABEL VERSION="1.0.0" \
  COURSE="M220P"

CMD ["run.py"]
