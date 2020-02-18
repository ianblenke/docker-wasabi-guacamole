FROM ianblenke/guacamole-server

RUN apt-get update \
 && apt-get install -y jq

ADD run.sh /run.sh
RUN chmod 755 /run.sh

CMD /run.sh
