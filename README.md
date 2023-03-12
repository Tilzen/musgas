# Musgas
A program for downloading music.

Musgas uses a CSV file with the video url, name, start and end times to download the video, convert to mp3, and cut at the specified times.

## Installation

Requirements:
- Crystal language (`1.7.2`)
- ffmpeg (` n5.1.2 `)
- yt-dlp (`2023.02.17`)

```console
make setup
```

## Usage

CSV file example:

```csv
musga 1, https://www.youtube.com/watch?v=xpto, 0:00, 4:00
musga 2, https://www.youtube.com/watch?v=bla, 0:27, 1:16
```

Example of use:

```console
musgas download -f ~/musgas.csv
```

