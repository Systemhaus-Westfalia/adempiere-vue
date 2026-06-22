FROM nginx:1.27.0

LABEL maintainer="Elsiosanches@gmail.com; EdwinBetanc0urt@outlook.com;" \
	description="ADempiere-Vue."


# Init ENV with default values
ENV PUBLIC_PATH="/" \
	API_URL="http://localhost/api/" \
	TASK_MANAGER_URL="http://localhost/v1" \
	TZ="America/Caracas"


# Add operative system dependencies
RUN apt-get update && \
	apt-get install -y \
		bash \
		tzdata && \
	rm -rf /var/lib/apt/lists/* \
	rm -rf /tmp/* && \
	echo "Set Timezone..." && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone


# Copy src files
COPY build/start.sh .
COPY dist/ /usr/share/nginx/html/


# Add adempiere as user
RUN addgroup adempiere && \
	adduser --disabled-password --gecos "" --ingroup adempiere --no-create-home adempiere && \
	chown -R adempiere:adempiere /usr/share/nginx/html/ && \
	chown -R adempiere:adempiere /var/cache/nginx && \
	chown adempiere:adempiere start.sh && \
	chmod +x *.sh

USER adempiere


ENTRYPOINT ["sh" , "start.sh"]
