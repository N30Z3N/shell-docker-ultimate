FROM spiderxd/ffmpeg-ubuntu:latest as ffmpeg

FROM python:3.8.5-slim-buster

#install Ultimate ffmpeg
RUN mkdir -p /usr/local
WORKDIR /usr/local/
COPY --from=ffmpeg /usr/local . 
RUN ln -s /opt/ffmpeg/share/model /usr/local/share/
RUN ldconfig
ENV PATH="/opt/ffmpeg/bin:$PATH"

# Install all the required packages
WORKDIR /usr/src/app
RUN chmod 777 /usr/src/app
RUN apt-get -qq update
RUN apt-get -qq install -y --no-install-recommends curl git gnupg2 unzip wget pv jq

# add mkvtoolnix
RUN wget -q -O - https://mkvtoolnix.download/gpg-pub-moritzbunkus.txt | apt-key add - && \
    wget -qO - https://ftp-master.debian.org/keys/archive-key-10.asc | apt-key add -
RUN sh -c 'echo "deb https://mkvtoolnix.download/debian/ buster main" >> /etc/apt/sources.list.d/bunkus.org.list' && \
    sh -c 'echo deb http://deb.debian.org/debian buster main contrib non-free | tee -a /etc/apt/sources.list' && apt update && apt install -y mkvtoolnix

# install required packages
RUN apt-get update && apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/* && \
    apt-add-repository non-free && \
    apt-get -qq update && apt-get -qq install -y --no-install-recommends \
    # this package is required to fetch "contents" via "TLS"
    apt-transport-https \
    # install coreutils
    coreutils aria2 jq pv gcc g++ \
    # install encoding tools
    mediainfo \
    # miscellaneous
    neofetch python3-dev python3 python3-pip git bash build-essential nodejs npm ruby python-minimal python-pip locales python-lxml qbittorrent-nox \
    # install extraction tools
    p7zip-full p7zip-rar rar unrar zip unzip \
    # miscellaneous helpers
    megatools mediainfo && \
    # clean up the container "layer", after we are done
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV LANG C.UTF-8

# we don't have an interactive xTerm
ENV DEBIAN_FRONTEND noninteractive

# sets the TimeZone, to be used inside the container
ENV TZ Asia/Kolkata

# rclone ,gclone and fclone
RUN curl https://rclone.org/install.sh | bash && \
    aria2c https://git.io/gclone.sh && bash gclone.sh && \
    aria2c https://github.com/mawaya/rclone/releases/download/fclone-v0.4.1/fclone-v0.4.1-linux-amd64.zip && \
    unzip fclone-v0.4.1-linux-amd64.zip && mv fclone-v0.4.1-linux-amd64/fclone /usr/bin/ && chmod +x /usr/bin/fclone && rm -r fclone-v0.4.1-linux-amd64

#drive downloader
RUN aria2c https://github.com/jaskaranSM/drive-dl-go/releases/download/1.1/drive-dl-go-linux-64bit.zip && \
    unzip drive-dl-go-linux-64bit.zip && mv linux-64bit/drivedl /usr/bin/ && chmod +x /usr/bin/drivedl && rm -r linux-64bit

#ngrok
RUN aria2c https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip && unzip ngrok-stable-linux-amd64.zip && mv ngrok /usr/bin/ && chmod +x /usr/bin/ngrok

#install rmega
RUN gem install rmega

# Copies config(if it exists)
COPY . .

# Install requirements and start the bot
RUN npm install

#install requirements
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# setup workdir

RUN dpkg --add-architecture i386 && apt-get update && apt-get -y dist-upgrade

CMD ["bash", "start.sh"]
