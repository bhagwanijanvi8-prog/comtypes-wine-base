FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV WINEARCH=win64
ENV WINEPREFIX=/root/.wine
ENV WINEDEBUG=-all
ENV DISPLAY=:0

# System packages + wine64 from Debian repos (not WineHQ)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git xvfb \
    bash build-essential python3 \
    wine64 \
    && rm -rf /var/lib/apt/lists/*

# Create wine prefix manually without wineboot
RUN mkdir -p /root/.wine && \
    Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    WINEARCH=win64 wine64 wineboot --init || true && \
    sleep 15 && \
    wineserver -k || true

# Install Python 3.13 for Windows (64-bit) inside Wine
RUN wget -q -O /tmp/python313.exe \
    "https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe" && \
    Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    wine64 /tmp/python313.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_launcher=0 && \
    sleep 15 && wineserver -k || true && \
    rm /tmp/python313.exe

# Install uv and coverage into Wine Python
RUN Xvfb :0 -screen 0 1024x768x24 -nolisten tcp & sleep 2 && \
    wine64 python -m pip install --quiet uv coverage && \
    sleep 5 && wineserver -k || true

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
    wine64 python -m pip install --quiet -e /app && \
    sleep 5 && wineserver -k || true

CMD ["bash"]
