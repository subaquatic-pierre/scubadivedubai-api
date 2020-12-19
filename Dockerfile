### Build and install packages
FROM python:3.8 as build-python

RUN apt-get -y update \
  && apt-get install -y gettext \
  # Cleanup apt cache
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements_dev.txt /app/
WORKDIR /app
RUN pip install -r requirements_dev.txt

### Final image
FROM python:3.8-slim

RUN groupadd -r saleor && useradd -r -g saleor saleor

RUN apt-get update \
  && apt-get install -y \
  libxml2 \
  libssl1.1 \
  libcairo2 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libgdk-pixbuf2.0-0 \
  shared-mime-info \
  mime-support \
  curl \
  build-essential \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash \
  && apt install nodejs -y

COPY . /app
COPY --from=build-python /usr/local/lib/python3.8/site-packages/ /usr/local/lib/python3.8/site-packages/
COPY --from=build-python /usr/local/bin/ /usr/local/bin/
WORKDIR /app

EXPOSE 3000

ARG DATABASE_URL
ARG EMAIL_URL
ARG DEFAULT_FROM_EMAIL
ARG STATIC_URL
ARG MEDIA_URL
ARG CREATE_IMAGES_ON_DEMAND
ARG API_URI
ARG APP_MOUNT_URI
ARG JAEGER_AGENT_HOST
ARG REDIS_URL
ARG PORT
ARG PYTHONUNBUFFERED
ARG PROCESSES
ARG OPENEXCHANGERATES_API_KEY
ARG SECRET_KEY
ARG DEBUG
ARG ALLOWED_HOSTS
ARG PLAYGROUND_ENABLED
ARG AWS_MEDIA_BUCKET_NAME
ARG AWS_STORAGE_BUCKET_NAME
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_MEDIA_CUSTOM_DOMAIN
ARG AWS_STATIC_CUSTOM_DOMAIN
ARG ALLOWED_CLIENT_HOSTS
ARG DEFAULT_COUNTRY
ARG DEFAULT_CURRENCY
ARG GOOGLE_ANALYTICS_TRACKING_ID

# Environment vars for application, must be moved to secrets
# ------
ENV DATABASE_URL=$DATABASE_URL
ENV EMAIL_URL=$EMAIL_URL
ENV DEFAULT_FROM_EMAIL=$DEFAULT_FROM_EMAIL
ENV STATIC_URL=$STATIC_URL
ENV MEDIA_URL=$MEDIA_URL
ENV CREATE_IMAGES_ON_DEMAND=$CREATE_IMAGES_ON_DEMAND
ENV API_URI=$API_URI
ENV APP_MOUNT_URI=$APP_MOUNT_URI
ENV JAEGER_AGENT_HOST=$JAEGER_AGENT_HOST
ENV REDIS_URL=$REDIS_URL
ENV PORT=$PORT
ENV PYTHONUNBUFFERED=$PYTHONUNBUFFERED
ENV PROCESSES=$PROCESSES
ENV OPENEXCHANGERATES_API_KEY=$OPENEXCHANGERATES_API_KEY
ENV SECRET_KEY=$SECRET_KEY
ENV DEBUG=$DEBUG
ENV ALLOWED_HOSTS=$ALLOWED_HOSTS
ENV PLAYGROUND_ENABLED=$PLAYGROUND_ENABLED
ENV AWS_MEDIA_BUCKET_NAME=$AWS_MEDIA_BUCKET_NAME
ENV AWS_STORAGE_BUCKET_NAME=$AWS_STORAGE_BUCKET_NAME
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_MEDIA_CUSTOM_DOMAIN=$AWS_MEDIA_CUSTOM_DOMAIN
ENV AWS_STATIC_CUSTOM_DOMAIN=$AWS_STATIC_CUSTOM_DOMAIN
ENV ALLOWED_CLIENT_HOSTS=$ALLOWED_CLIENT_HOSTS
ENV DEFAULT_COUNTRY=$DEFAULT_COUNTRY
ENV DEFAULT_CURRENCY=$DEFAULT_CURRENCY
ENV GOOGLE_ANALYTICS_TRACKING_ID=$GOOGLE_ANALYTICS_TRACKING_ID
# ------

RUN pip install -r requirements.txt

RUN npm install \ 
  && npm run build-schema \
  && npm run build-emails

RUN echo $DEBUG

RUN python3 manage.py collectstatic --no-input
RUN echo ${EMAIL_URL}
RUN echo "Defualt from email " ${DEFAULT_FROM_EMAIL}

CMD ["uwsgi", "--ini", "/app/saleor/wsgi/uwsgi.ini"]

