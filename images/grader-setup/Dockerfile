ARG BASE_IMAGE=python:3.8
FROM "${BASE_IMAGE}"

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install unzip -y

# app folder
RUN mkdir /illumidesk

WORKDIR /tmp

# install packages with pip. makes sure pip is up to date.
COPY requirements.txt /tmp/
RUN python -m pip install --upgrade pip \
 && pip install -r /tmp/requirements.txt

# illumidesk package release
ARG ILLUMIDESK_VERSION=1.0.0

# fetch and unpack illumidesk package
RUN wget "https://github.com/IllumiDesk/illumidesk/archive/v${ILLUMIDESK_VERSION}.zip" \
 && unzip "https://github.com/IllumiDesk/illumidesk/archive/v${ILLUMIDESK_VERSION}.zip"
COPY "/tmp/illumidesk-${ILLUMIDESK_VERSION}/src/grader-setup-service/app" /illumidesk/app/

WORKDIR /illumidesk

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app.wsgi:app"]

HEALTHCHECK CMD curl --fail http://localhost:8000/healthcheck || exit 1
