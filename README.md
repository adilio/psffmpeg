# PSFFmpeg

The PowerShell FFmpeg Module - A comprehensive PowerShell wrapper for FFmpeg providing easy-to-use cmdlets for media conversion, editing, and processing tasks.

## Features

- **Media Information**: Extract detailed metadata from video and audio files
- **Format Conversion**: Convert between various video and audio formats
- **Video Resizing**: Scale videos to different resolutions with multiple algorithms
- **Audio Extraction**: Extract audio streams from videos
- **Video Editing**: Trim, cut, and split videos
- **Video Merging**: Concatenate multiple videos into one
- **Thumbnail Generation**: Create thumbnails from videos at any timestamp
- **Codec Conversion**: Convert between different video codecs with hardware acceleration support
- **Audio Overlay**: Add or replace audio tracks in videos
- **Subtitle Support**: Add soft or hard-coded subtitles to videos
- **GIF Creation**: Create optimized animated GIFs from videos
- **Video from Images**: Generate videos from image sequences
- **Video Splitting**: Split videos into multiple segments
- **Video Optimization**: Smart optimization for file size, quality, or streaming
- **Metadata Editing**: Set and update video metadata tags
- **Capability Testing**: Check FFmpeg codec and format support
- **Version Information**: Get detailed FFmpeg version and build info
- **Pipeline Support**: All cmdlets support PowerShell pipeline operations
- **Best Practices**: Follows PowerShell best practices from PoshCode style guide
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

## Cmdlets Reference

### Core Media Information

#### Get-MediaInfo

Retrieves detailed information about a media file including format, duration, codec, resolution, and more.

```powershell
# Basic usage
Get-MediaInfo -Path "video.mp4"

# Get raw JSON output
Get-MediaInfo -Path "video.mp4" -Json

# Pipeline support
Get-ChildItem *.mp4 | Get-MediaInfo
```

#### Get-FFmpegVersion

Gets detailed version information about installed FFmpeg, FFprobe, and FFplay components.

```powershell
# Get version info for all components
Get-FFmpegVersion

# Get detailed build information
Get-FFmpegVersion -Detailed

# Get version for specific component
Get-FFmpegVersion -Component FFmpeg
```

#### Test-FFmpegCapability

Tests for specific FFmpeg capabilities and features.

```powershell
# Test if a codec is supported
Test-FFmpegCapability -Type Codec -Name h264

# Test for hardware acceleration
Test-FFmpegCapability -Type Encoder -Name hevc_nvenc

# List all available codecs
Test-FFmpegCapability -Type Codec -ListAll

# List all supported formats
Test-FFmpegCapability -Type Format -ListAll
```

### Media Conversion

#### Convert-Media

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

#### Convert-VideoCodec

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

#### Optimize-Video

Intelligently optimizes video files for size, quality, or web streaming.

```powershell
# Optimize for smallest file size
Optimize-Video -InputPath "large_video.mp4" -OutputPath "optimized.mp4" -OptimizationTarget FileSize

# Optimize for web streaming
Optimize-Video -InputPath "video.avi" -OutputPath "web.mp4" -OptimizationTarget WebStreaming

# Optimize for mobile devices
Optimize-Video -InputPath "raw.mov" -OutputPath "mobile.mp4" -OptimizationTarget Mobile

# Optimize to specific file size
Optimize-Video -InputPath "source.mp4" -OutputPath "output.mp4" -TargetSize 50 -TwoPass

# Targets: FileSize, Quality, WebStreaming, Mobile, Balanced
```

### Video Manipulation

#### Resize-Video

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

#### Edit-Video

Trims or cuts videos to specific time ranges.

```powershell
# Extract 30 seconds starting at 1 minute
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "00:01:00" -Duration "00:00:30"

# Extract from second 60 to second 120
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "60" -EndTime "120"

# Fast seeking (less accurate but faster)
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "10" -Duration "30" -FastSeek
```

#### Split-Video

Splits a video into multiple segments.

```powershell
# Split into 5-minute segments
Split-Video -InputPath "movie.mp4" -SegmentDuration 300

# Split into 4 equal parts
Split-Video -InputPath "video.mp4" -SegmentCount 4 -FastSplit

# Split at specific time ranges
Split-Video -InputPath "video.mp4" -TimeRanges "0-60", "60-120", "120-180"

# Custom output location and naming
Split-Video -InputPath "lecture.mp4" -SegmentDuration 600 -OutputDirectory "C:\Clips" -OutputPrefix "Lecture_Part"
```

#### Merge-Video

Merges multiple video files into a single video.

```powershell
# Merge videos
Merge-Video -InputPaths "part1.mp4", "part2.mp4", "part3.mp4" -OutputPath "complete.mp4"

# Merge all MP4 files in directory
Merge-Video -InputPaths (Get-ChildItem *.mp4 | Select-Object -ExpandProperty FullName) -OutputPath "merged.mp4"

# Re-encode if videos have different formats
Merge-Video -InputPaths "video1.mp4", "video2.avi" -OutputPath "output.mp4" -ReEncode
```

### Audio Operations

#### Extract-Audio

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

#### Add-AudioToVideo

Adds or replaces audio in video files.

```powershell
# Replace video's audio
Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "music.mp3" -OutputPath "output.mp4" -ReplaceAudio

# Mix audio tracks with volume control
Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "narration.mp3" -OutputPath "output.mp4" -AudioVolume 2 -VideoVolume -3

# Add audio to silent video
Add-AudioToVideo -VideoPath "silent.mp4" -AudioPath "soundtrack.mp3" -OutputPath "output.mp4" -Shortest
```

### Image & Thumbnail Operations

#### New-VideoThumbnail

Generates thumbnail images from videos.

```powershell
# Create thumbnail from middle of video
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg"

# Create thumbnail at specific time
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.png" -Time "00:01:30"

# Create resized thumbnail
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg" -Width 320 -Height 240 -Quality 2
```

#### New-VideoFromImages

Creates a video from a sequence of images.

```powershell
# Create video from sequentially numbered images
New-VideoFromImages -ImagePattern "frame_%04d.png" -OutputPath "output.mp4"

# Create slideshow from all JPG files
New-VideoFromImages -ImageDirectory "C:\Images" -ImagePattern "*.jpg" -OutputPath "slideshow.mp4" -FrameRate 2

# High-quality HEVC video from images
New-VideoFromImages -ImagePattern "img*.png" -OutputPath "video.mp4" -VideoCodec hevc -Quality ultra
```

#### New-VideoGif

Creates animated GIFs from video files with optimization.

```powershell
# Create 5-second GIF from start of video
New-VideoGif -InputPath "video.mp4" -OutputPath "animation.gif"

# Create GIF from specific time range
New-VideoGif -InputPath "video.mp4" -OutputPath "clip.gif" -StartTime "30" -Duration "10" -Width 640 -FrameRate 15

# High-quality optimized GIF
New-VideoGif -InputPath "video.mp4" -OutputPath "optimized.gif" -Quality high -MaxColors 128 -OptimizePalette

# Small looping GIF for web
New-VideoGif -InputPath "clip.mp4" -OutputPath "banner.gif" -Width 300 -FrameRate 8 -Loop 0
```

### Subtitle & Metadata Operations

#### Add-Subtitle

Adds subtitles to video files (soft or hard-coded).

```powershell
# Add soft subtitles
Add-Subtitle -VideoPath "movie.mp4" -SubtitlePath "movie.srt" -OutputPath "movie_subbed.mp4"

# Burn subtitles into video
Add-Subtitle -VideoPath "video.mp4" -SubtitlePath "subs.srt" -OutputPath "output.mp4" -BurnIn -FontSize 28

# Add subtitles with language metadata
Add-Subtitle -VideoPath "film.mkv" -SubtitlePath "english.srt" -OutputPath "film_eng.mkv" -Language "eng" -Title "English"
```

#### Set-VideoMetadata

Sets or updates metadata tags in video files.

```powershell
# Set basic metadata
Set-VideoMetadata -InputPath "video.mp4" -OutputPath "tagged.mp4" -Title "My Video" -Artist "John Doe" -Year 2025

# Set genre and description
Set-VideoMetadata -InputPath "movie.mp4" -OutputPath "movie_tagged.mp4" -Title "Amazing Film" -Genre "Documentary" -Description "A film about..."

# Set custom metadata
$metadata = @{
    'episode_id' = 'S01E01'
    'network' = 'MyNetwork'
}
Set-VideoMetadata -InputPath "show.mp4" -OutputPath "show_tagged.mp4" -CustomMetadata $metadata

# Clear and reset metadata
Set-VideoMetadata -InputPath "old.mp4" -OutputPath "new.mp4" -ClearExisting -Title "Fresh Start"
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
