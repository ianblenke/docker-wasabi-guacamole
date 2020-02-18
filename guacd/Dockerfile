FROM ianblenke/guacamole-server

RUN apt-get update \
 && apt-get install -y jq torsocks

ADD run.sh /run.sh

CMD /run.sh
