# PSFFmpeg

The PowerShell FFmpeg Module - A comprehensive PowerShell wrapper for FFmpeg providing easy-to-use cmdlets for media conversion, editing, and processing tasks.

## Features

- **Media Information**: Extract detailed metadata from video and audio files
- **Format Conversion**: Convert between various video and audio formats
- **Video Resizing**: Scale videos to different resolutions with multiple algorithms
- **Audio Extraction**: Extract audio streams from videos
- **Video Editing**: Trim, cut, and split videos
- **Video Merging**: Concatenate multiple videos into one
- **Thumbnail Generation**: Create thumbnails from videos
- **Codec Conversion**: Convert between different video codecs with hardware acceleration support
- **Audio Overlay**: Add or replace audio tracks in videos
- **Pipeline Support**: All cmdlets support PowerShell pipeline operations
- **Full Test Coverage**: Comprehensive Pester tests included

## Prerequisites

- PowerShell 5.1 or later
- FFmpeg installed and available in PATH
  - Download from: https://ffmpeg.org/download.html
  - Installation guides: https://ffmpeg.org/

## Installation

### From Source

```powershell
# Clone the repository
git clone https://github.com/adilio/psffmpeg.git

# Import the module
Import-Module ./psffmpeg/PSFFmpeg/PSFFmpeg.psd1
```

### Manual Installation

```powershell
# Copy the PSFFmpeg folder to your PowerShell modules directory
Copy-Item -Path ./PSFFmpeg -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\" -Recurse

# Import the module
Import-Module PSFFmpeg
```

## Quick Start

```powershell
# Import the module
Import-Module PSFFmpeg

# Get information about a video file
Get-MediaInfo -Path "video.mp4"

# Convert a video to different format
Convert-Media -InputPath "video.avi" -OutputPath "video.mp4" -Quality high

# Resize a video to 720p
Resize-Video -InputPath "video.mp4" -OutputPath "video_720p.mp4" -Scale 720p

# Extract audio from a video
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3" -AudioQuality high

# Trim a video
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "00:01:00" -Duration "00:00:30"

# Create a thumbnail
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg" -Time "00:00:05"
```

## Cmdlets

### Get-MediaInfo

Retrieves detailed information about a media file including format, duration, codec, resolution, and more.

```powershell
# Basic usage
Get-MediaInfo -Path "video.mp4"

# Get raw JSON output
Get-MediaInfo -Path "video.mp4" -Json

# Pipeline support
Get-ChildItem *.mp4 | Get-MediaInfo
```

### Convert-Media

Converts media files between different formats and codecs with quality control.

```powershell
# Simple conversion
Convert-Media -InputPath "video.avi" -OutputPath "video.mp4"

# High-quality conversion
Convert-Media -InputPath "video.mp4" -OutputPath "video.webm" -VideoCodec vp9 -AudioCodec opus -Quality ultra

# Custom bitrates
Convert-Media -InputPath "video.mp4" -OutputPath "output.mp4" -VideoBitrate "5M" -AudioBitrate "320k"

# Quality presets: low, medium, high, ultra
Convert-Media -InputPath "video.mp4" -OutputPath "output.mp4" -Quality high
```

### Resize-Video

Resizes videos to different dimensions with various scaling algorithms.

```powershell
# Resize to specific dimensions
Resize-Video -InputPath "video.mp4" -OutputPath "small.mp4" -Width 640 -Height 480

# Use preset resolutions
Resize-Video -InputPath "video.mp4" -OutputPath "hd.mp4" -Scale 1080p

# Maintain aspect ratio
Resize-Video -InputPath "video.mp4" -OutputPath "wide.mp4" -Width 1280 -Height -1

# Available presets: 4K, 1080p, 720p, 480p, 360p
# Available algorithms: bilinear, bicubic, lanczos, neighbor, area, gauss, sinc, spline
```

### Extract-Audio

Extracts audio streams from video files.

```powershell
# Extract to MP3
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3"

# Extract to lossless format
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.flac" -AudioCodec flac

# Extract with quality preset
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3" -AudioQuality ultra

# Quality presets: low (128k), medium (192k), high (256k), ultra (320k)
```

### Edit-Video

Trims or cuts videos to specific time ranges.

```powershell
# Extract 30 seconds starting at 1 minute
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "00:01:00" -Duration "00:00:30"

# Extract from second 60 to second 120
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "60" -EndTime "120"

# Fast seeking (less accurate but faster)
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "10" -Duration "30" -FastSeek
```

### Merge-Video

Merges multiple video files into a single video.

```powershell
# Merge videos
Merge-Video -InputPaths "part1.mp4", "part2.mp4", "part3.mp4" -OutputPath "complete.mp4"

# Merge all MP4 files in directory
Merge-Video -InputPaths (Get-ChildItem *.mp4 | Select-Object -ExpandProperty FullName) -OutputPath "merged.mp4"

# Re-encode if videos have different formats
Merge-Video -InputPaths "video1.mp4", "video2.avi" -OutputPath "output.mp4" -ReEncode
```

### New-VideoThumbnail

Generates thumbnail images from videos.

```powershell
# Create thumbnail from middle of video
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg"

# Create thumbnail at specific time
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.png" -Time "00:01:30"

# Create resized thumbnail
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg" -Width 320 -Height 240 -Quality 2
```

### Convert-VideoCodec

Converts videos to different codecs with encoding control.

```powershell
# Convert to H.265/HEVC
Convert-VideoCodec -InputPath "video.mp4" -OutputPath "video_h265.mp4" -Codec hevc

# Convert with specific quality (CRF)
Convert-VideoCodec -InputPath "video.mp4" -OutputPath "video_vp9.webm" -Codec vp9 -CRF 30

# Use hardware acceleration
Convert-VideoCodec -InputPath "video.mp4" -OutputPath "output.mp4" -Codec h264 -HardwareAcceleration nvenc

# Available codecs: h264, h265, hevc, vp8, vp9, av1, mpeg4
# Hardware acceleration: nvenc (NVIDIA), qsv (Intel), vaapi (Linux), videotoolbox (macOS)
```

### Add-AudioToVideo

Adds or replaces audio in video files.

```powershell
# Replace video's audio
Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "music.mp3" -OutputPath "output.mp4" -ReplaceAudio

# Mix audio tracks with volume control
Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "narration.mp3" -OutputPath "output.mp4" -AudioVolume 2 -VideoVolume -3

# Add audio to silent video
Add-AudioToVideo -VideoPath "silent.mp4" -AudioPath "soundtrack.mp3" -OutputPath "output.mp4" -Shortest
```

## Common Parameters

Most cmdlets support these common parameters:

- `-Overwrite`: Overwrites output file without prompting
- `-WhatIf`: Shows what would happen without executing
- `-Verbose`: Shows detailed operation information
- `-ErrorAction`: Controls error handling behavior

## Pipeline Examples

```powershell
# Get info for all videos in a directory
Get-ChildItem *.mp4 | Get-MediaInfo | Format-Table FileName, Duration, VideoWidth, VideoHeight

# Batch convert all AVI files to MP4
Get-ChildItem *.avi | ForEach-Object {
    $output = $_.BaseName + ".mp4"
    Convert-Media -InputPath $_.FullName -OutputPath $output -Quality high
}

# Create thumbnails for all videos
Get-ChildItem *.mp4 | ForEach-Object {
    $thumb = $_.BaseName + "_thumb.jpg"
    New-VideoThumbnail -InputPath $_.FullName -OutputPath $thumb
}

# Extract audio from all videos
Get-ChildItem *.mp4 | ForEach-Object {
    $audio = $_.BaseName + ".mp3"
    Extract-Audio -InputPath $_.FullName -OutputPath $audio -AudioQuality high
}
```

## Testing

The module includes comprehensive Pester tests for all cmdlets.

```powershell
# Run unit tests
Invoke-Pester -Path ./Tests/PSFFmpeg.Tests.ps1

# Run integration tests (requires FFmpeg)
Invoke-Pester -Path ./Tests/Integration.Tests.ps1

# Run all tests
Invoke-Pester -Path ./Tests/
```

## Examples

See the [Examples](./Examples/) directory for more detailed usage examples.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for release history.

## License

This project is licensed under the terms specified in the [LICENSE](./LICENSE) file.

## Requirements

- **PowerShell**: 5.1 or later
- **FFmpeg**: Latest version recommended
  - Windows: Download from https://ffmpeg.org/download.html or install via Chocolatey (`choco install ffmpeg`)
  - macOS: Install via Homebrew (`brew install ffmpeg`)
  - Linux: Install via package manager (`apt install ffmpeg` or `yum install ffmpeg`)

## Troubleshooting

### FFmpeg not found

If you get an error that FFmpeg is not installed:

1. Verify FFmpeg is installed: `ffmpeg -version`
2. Ensure FFmpeg is in your system PATH
3. Restart your PowerShell session after installing FFmpeg

### Permission Errors

If you encounter permission errors when importing the module:

```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Get Help

```powershell
# Get help for any cmdlet
Get-Help Get-MediaInfo -Full
Get-Help Convert-Media -Examples
Get-Help Resize-Video -Parameter Width
```

## Support

- Report issues: https://github.com/adilio/psffmpeg/issues
- FFmpeg documentation: https://ffmpeg.org/documentation.html

## Authors

- PSFFmpeg Contributors

## Acknowledgments

- FFmpeg project and contributors
- PowerShell community
