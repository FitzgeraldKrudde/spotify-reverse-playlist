# spotify-reverse-playlist
This Linux bash script reverses the tracks in a playlist.
It creates a new playlist with all tracks reversed.

Just invoke the script reverse-playlist.sh to get the usage information.

The script uses the [Spotify REST API](https://developer.spotify.com/web-api/). Therefore it requires curl and a few other (standard) binaries. The script will check for these pre-reqs.

Pure bash-ish, no need for temp files etc.

On Mac you will need homebrew and install the following packages: coreutils, findutils and jq.
Also make sure their directories are in front of your PATH by adding this to your ${HOME}/.bashrc
```
# add GNU coreutils and findutils in front of the PATH
export PATH=/usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/findutils/libexec/gnubin:${PATH}
```

On Windows you will need WSL (Windows Subsystem for Linux), see:  https://docs.microsoft.com/en-us/windows/wsl/

## Dutch NPO Top 2000

As quite some people want to use this script to reverse the tracks but might not have Linux (or Mac) here are also links to public paylists (I have created) with the tracks already reversed:

* 2023 https://open.spotify.com/playlist/0AntHD0ZXY56KD37QRiPRH
* 2022 https://open.spotify.com/playlist/7xmAGBLOlDJuOTEe7p5eoW?si=b3b7ccd086e54ca0
* 2021 https://open.spotify.com/playlist/246fBA9TOn1XdCMkFFT31k?si=e7e7612c16b44f52
* 2019 https://open.spotify.com/playlist/7hzpUZ650hMN25p4OYQW7q?si=bd95bb7cc1c243c9
