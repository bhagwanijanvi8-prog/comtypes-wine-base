FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEARCH=win64
ENV WINEPREFIX=/root/.wine
ENV WINEDEBUG=-all
ENV DISPLAY=:0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg2 git xvfb cabextract unzip \
    bash build-essential python3 && rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 && apt-get update && \
    wget -qO /etc/apt/trusted.gpg.d/winehq.asc https://dl.winehq.org/wine-builds/winehq.key && \
    echo "deb https://dl.winehq.org/wine-builds/debian/ bookworm main" > /etc/apt/sources.list.d/winehq.list && \
    apt-get update && apt-get install -y --install-recommends winehq-stable && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q -O /usr/local/bin/winetricks \
    https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks

RUN Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 4 && wineboot --init && sleep 6

RUN Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 3 && \
    winetricks -q --no-isolate vcrun2019 && sleep 3

RUN wget -q -O /tmp/python313.exe \
    "https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe" && \
    Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 3 && \
    wine /tmp/python313.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0 && \
    sleep 8 && rm /tmp/python313.exe

RUN Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    wine python -m pip install --quiet uv coverage && sleep 3

RUN git clone https://github.com/enthought/comtypes.git /app

WORKDIR /app

RUN git checkout 4cdbb4fe2f8e6b786d02a50bb3cc5b67a5e5de6c || git checkout main

RUN git remote rename origin upstream && \
    git remote add origin https://github.com/enthought/comtypes.git || true

RUN Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    wine python -m pip install --quiet -e /app && sleep 4

CMD ["bash"]
