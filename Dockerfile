FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEARCH=win64
ENV WINEPREFIX=/root/.wine
ENV WINEDEBUG=-all
ENV DISPLAY=:0

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg2 git xvfb \
    bash build-essential python3 && rm -rf /var/lib/apt/lists/*

# Wine (WineHQ stable with i386 support)
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    wget -qO /etc/apt/trusted.gpg.d/winehq.asc https://dl.winehq.org/wine-builds/winehq.key && \
    echo "deb https://dl.winehq.org/wine-builds/debian/ bookworm main" > /etc/apt/sources.list.d/winehq.list && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-stable && \
    rm -rf /var/lib/apt/lists/*

# winetricks
RUN wget -q -O /usr/local/bin/winetricks \
    https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks

# Initialize Wine prefix (64-bit only, longer timeout for CI)
RUN Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    WINEARCH=win64 WINEPREFIX=/root/.wine wineboot --init && \
    while pgrep -f wineserver > /dev/null; do sleep 2; done && \
    sleep 5

# Install Python 3.13 for Windows (64-bit) inside Wine
RUN wget -q -O /tmp/python313.exe \
    "https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe" && \
    Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    wine /tmp/python313.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0 && \
    while pgrep -f wineserver > /dev/null; do sleep 2; done && \
    sleep 5 && rm /tmp/python313.exe

# Install uv and coverage into Wine Python
RUN Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    wine python -m pip install --quiet uv coverage && \
    while pgrep -f wineserver > /dev/null; do sleep 2; done

# Clone comtypes
RUN git clone https://github.com/enthought/comtypes.git /app

WORKDIR /app

# Pin to a known-good commit
RUN git checkout 4cdbb4fe2f8e6b786d02a50bb3cc5b67a5e5de6c || git checkout main

# Set up upstream remote
RUN git remote rename origin upstream && \
    git remote add origin https://github.com/enthought/comtypes.git || true

# Install comtypes in editable mode
RUN Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    wine python -m pip install --quiet -e /app && \
    while pgrep -f wineserver > /dev/null; do sleep 2; done

CMD ["bash"]
