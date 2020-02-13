FROM debian:buster

#FROM buildpack-deps:buster-curl

RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		wget \
	&& rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	if ! command -v gpg > /dev/null; then \
		apt-get update; \
		apt-get install -y --no-install-recommends \
			gnupg2 \
			dirmngr \
		; \
		rm -rf /var/lib/apt/lists/*; \
	fi

#FROM buildpack-deps:buster-scm

# procps is very common in build systems, and is a reasonably small package
RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
		mercurial \
		openssh-client \
		subversion \
		\
		procps \
	&& rm -rf /var/lib/apt/lists/*
#FROM mcr.microsoft.com/dotnet/core/sdk:3.1

ENV \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetCoreSDK-Debian-10

# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu63 \
        libssl1.1 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK as multi-arch
RUN dotnet_sdk_version=3.1.101 \
 && case $(uname -m) in \
      x86_64) \
          ARCH=x64 ;\
          dotnet_sha512='eeee75323be762c329176d5856ec2ecfd16f06607965614df006730ed648a5b5d12ac7fd1942fe37cfc97e3013e796ef278e7c7bc4f32b8680585c4884a8a6a1' ; \
          ;; \
      aarch64) \
          ARCH=arm64 ; \
          dotnet_sha512='03ea4cc342834a80f29b3b59ea1d7462e1814311dc6597bf2333359061b9b24f5ce98ed6ebf8d7ca05d42db31baba8ed8d4dec30a576fd818b3c0041c86d2937' ; \
          ;; \
      *) \
	  echo "Unsupported arch:" $(uname -m) ; \
	  false ; \
	  ;; \
    esac \
 && curl -kSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-${ARCH}.tar.gz \
 && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
 && mkdir -p /usr/share/dotnet \
 && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
 && rm dotnet.tar.gz \
 && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
 # Trigger first run experience by running arbitrary cmd
 && dotnet help

# Install PowerShell global tool
RUN powershell_version=7.0.0-rc.1 \
 && case $(uname -m) in \
      x86_64) \
          ARCH=x64 ;\
          powershell_sha512='0af45c1aca64b99a611987ac77f2143621a77f03073f17c6bf1e225bb5e82c574db67362b1c941d27214a2a4830de6ecf33ac5d0079e55223b8b02d3c86076c8' ; \
          ;; \
      aarch64) \
          ARCH=arm64 ;\
          powershell_sha512='fa803da3df38dde9b0812c787572034fc2166a3fed10f05f4576766aba6b66fe8c073ab56dda252dd02bcc40295bab757c5ba1f667a2355d139ca67652d9014c' ; \
          ;; \
      *) \
	  echo "Unsupported arch:" $(uname -m) ; \
	  false ; \
	  ;; \
    esac \
  && curl -kSL --output PowerShell.Linux.${ARCH}.$powershell_version.nupkg https://pwshtool.blob.core.windows.net/tool/$powershell_version/PowerShell.Linux.${ARCH}.$powershell_version.nupkg \
  && echo "$powershell_sha512  PowerShell.Linux.${ARCH}.$powershell_version.nupkg" | sha512sum -c - \
  && mkdir -p /usr/share/powershell \
  && dotnet tool install --add-source / --tool-path /usr/share/powershell --version $powershell_version PowerShell.Linux.${ARCH} \
  && dotnet nuget locals all --clear \
  && rm PowerShell.Linux.${ARCH}.$powershell_version.nupkg \
  && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
  && chmod 755 /usr/share/powershell/pwsh \
  # To reduce image size, remove the copy nupkg that nuget keeps.
  && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm

# Install git
RUN apt-get update \
 && apt-get install -y git \
 && rm -rf /var/lib/apt/lists/*

# Build Wasabi Wallet and publish to /publish
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
RUN git clone https://github.com/zkSNACKs/WalletWasabi /wasabi \
 && cd /wasabi \
 && dotnet restore \
 && dotnet publish -o /publish  \
 && cd /publish \
 && rm -fr /wasabi

#FROM mcr.microsoft.com/dotnet/core/aspnet:3.1
RUN apt-get update \
 && apt-get install -y apt-transport-https ca-certificates curl gnupg gnupg-agent software-properties-common \
 && apt-get install -y supervisor
ADD xorgxrdp /etc/apt/preferences.d/xorgxrdp
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
#COPY --from=0 /publish/ /publish/
WORKDIR /publish/
CMD /run.sh

