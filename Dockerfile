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

# Environment vars for application, must be moved to secrets
# ------
ENV DATABASE_URL=postgres://scubadivedubai:ScubaDiveDubai0!@scubadivedubai-db.cluster-cguhuytcxcub.us-east-1.rds.amazonaws.com:5432/scubadivedubai_shop
ENV EMAIL_URL=smtp://AKIAQPIWRSOPQGTLNIVV:BM1OBPMJzVv4V3rSvA2Zv663y9CzOgrrZNuRj4oR0SyY@email-smtp.us-east-1.amazonaws.com:587/?tls=True
ENV DEFAULT_FROM_EMAIL=pierre@divesandybeach.com
ENV STATIC_URL=/static/
ENV MEDIA_URL=/media/
ENV CREATE_IMAGES_ON_DEMAND=True
ENV API_URI=https://api.scubadivedubai.com/graphql/
ENV APP_MOUNT_URI=https://dashboard.scubadivedubai.com
ENV JAEGER_AGENT_HOST=jaeger
ENV REDIS_URL=redis://redis:6379/0
ENV PORT=3000
ENV PYTHONUNBUFFERED=1
ENV PROCESSES=4
ENV OPENEXCHANGERATES_API_KEY=026bbc0c5d22447ca082d6d50e575211
ENV SECRET_KEY=supersecretkey
ENV DEBUG=False
ENV ALLOWED_HOSTS=api.scubadivedubai.com,dashboard.scubadivedubai.com,media.scubadivedubai.com,scubadivedubai.com
ENV PLAYGROUND_ENABLED=True
ENV AWS_MEDIA_BUCKET_NAME=scubadivedubai-api-media
ENV AWS_STORAGE_BUCKET_NAME=scubadivedubai-api-static
ENV AWS_ACCESS_KEY_ID=AKIAQPIWRSOP5NHI6LVH
ENV AWS_SECRET_ACCESS_KEY=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
ENV AWS_MEDIA_CUSTOM_DOMAIN=media.scubadivedubai.com
ENV AWS_STATIC_CUSTOM_DOMAIN=static.scubadivedubai.com
ENV ALLOWED_CLIENT_HOSTS=api.scubadivedubai.com,dashboard.scubadivedubai.com,media.scubadivedubai.com,scubadivedubai.com
ENV DEFAULT_COUNTRY=AE
ENV DEFAULT_CURRENCY=AED
ENV GOOGLE_ANALYTICS_TRACKING_ID=somegoogletag
# ------

RUN pip install -r requirements.txt

RUN npm install \ 
  && npm run build-schema \
  && npm run build-emails

RUN echo $DEBUG

RUN python3 manage.py collectstatic --no-input

CMD ["uwsgi", "--ini", "/app/saleor/wsgi/uwsgi.ini"]

