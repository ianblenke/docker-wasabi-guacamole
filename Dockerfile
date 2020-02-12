FROM mcr.microsoft.com/dotnet/core/sdk:3.1
RUN apt-get update; \
    apt-get install -y git
RUN git clone https://github.com/zkSNACKs/WalletWasabi /wasabi
WORKDIR /wasabi
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
RUN dotnet restore
RUN dotnet publish -o /publish

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1
RUN apt-get update \
 && apt-get install -y apt-transport-https ca-certificates curl gnupg gnupg-agent software-properties-common \
 && apt-get install -y supervisor
ADD xorgxrdp /etc/apt/preferences.d/xorgxrdp
#RUN add-apt-repository ppa:martinx/xrdp-next
#RUN add-apt-repository ppa:martinx/xrdp-hwe-18.04
#RUN perl -pi -e 's/focal/bionic/g' /etc/apt/sources.list.d/*.list
#RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 91F1B266D01CEBCD
#RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y xrdp xfce4 xfce4-terminal xorgxrdp
RUN sed -i.bak '/fi/a #xrdp multiple users configuration \n xfce-session \n' /etc/xrdp/startwm.sh

RUN mkdir -p /etc/apt/sources-list.d \
 && echo deb https://deb.torproject.org/torproject.org stretch main > /etc/apt/sources-list.d/torproject.list \
 && curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import \
 && gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add - \
 && apt-get update \
 && apt-get install -y tor

EXPOSE 3389

#ADD logo.bmp /usr/local/share/xrdp/logo.bmp

ADD run.sh /run.sh
COPY --from=0 /publish/ /publish/
WORKDIR /publish/
CMD /run.sh

