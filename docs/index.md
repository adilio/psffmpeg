---
layout: default
title: PSFFmpeg - PowerShell FFmpeg Module
---

# PSFFmpeg

A comprehensive PowerShell wrapper for FFmpeg providing easy-to-use cmdlets for media conversion, editing, and processing tasks.

## Quick Links

- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Examples](#examples)
- [Installation](#installation)
- [GitHub Repository](https://github.com/adilio/psffmpeg)

## Overview

PSFFmpeg makes FFmpeg accessible through PowerShell's familiar cmdlet interface, following PowerShell best practices and providing full pipeline support.

### Key Features

- **Media Information** - Extract detailed metadata from video and audio files
- **Format Conversion** - Convert between various video and audio formats
- **Video Editing** - Trim, cut, split, and merge videos
- **Audio Processing** - Extract, overlay, and manipulate audio tracks
- **Thumbnail Generation** - Create thumbnails and animated GIFs
- **Subtitle Support** - Add soft or hard-coded subtitles
- **Hardware Acceleration** - Support for NVIDIA, Intel, and other hardware encoders
- **Pipeline Support** - Full PowerShell pipeline integration
- **Best Practices** - Follows PoshCode PowerShell style guide

## Getting Started

### Prerequisites

- PowerShell 5.1 or later
- FFmpeg installed and available in PATH
  - [Download FFmpeg](https://ffmpeg.org/download.html)

### Installation

```powershell
# Clone the repository
git clone https://github.com/adilio/psffmpeg.git

# Import the module
Import-Module ./psffmpeg/PSFFmpeg/PSFFmpeg.psd1
```

### Quick Example

```powershell
# Get information about a video
Get-MediaInfo -Path "video.mp4"

# Convert video format
Convert-Media -InputPath "video.avi" -OutputPath "video.mp4" -Quality high

# Create a thumbnail
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg" -Time "00:01:30"

# Trim a video
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "00:01:00" -Duration "00:00:30"
```

## Documentation

### Conceptual Help

- [**About PSFFmpeg**](en-US/about/about_PSFFmpeg.html) - Module overview, prerequisites, and best practices
- [**Examples**](en-US/about/about_PSFFmpeg_Examples.html) - Comprehensive usage examples from basic to advanced
- [**Documentation Guide**](README.html) - How to build and maintain documentation

### Cmdlet Reference

Detailed documentation for each cmdlet is available in the cmdlet reference section. After building the documentation with PlatyPS, individual cmdlet help files will be available in the `cmdlets/` directory.

To view cmdlet help in PowerShell:

```powershell
# Get help for any cmdlet
Get-Help Convert-Media -Full

# See examples
Get-Help New-VideoGif -Examples

# List all available cmdlets
Get-Command -Module PSFFmpeg
```

### PowerShell Help System

PSFFmpeg includes full comment-based help that integrates with PowerShell's help system:

```powershell
# Get detailed help
Get-Help <cmdlet-name> -Full

# See just examples
Get-Help <cmdlet-name> -Examples

# View about topics
Get-Help about_PSFFmpeg
```

## Examples

### Media Information

```powershell
# Get detailed media information
$info = Get-MediaInfo -Path "movie.mp4"
Write-Host "Duration: $($info.Duration)"
Write-Host "Resolution: $($info.VideoWidth)x$($info.VideoHeight)"
```

### Batch Processing

```powershell
# Convert all AVI files to MP4
Get-ChildItem *.avi | ForEach-Object {
    $output = $_.BaseName + ".mp4"
    Convert-Media -InputPath $_.FullName -OutputPath $output -Quality high
}
```

### Video Editing Pipeline

```powershell
# Extract audio, trim video, and create thumbnail in a workflow
$video = "presentation.mp4"

# Extract audio
Extract-Audio -InputPath $video -OutputPath "audio.mp3" -AudioQuality high

# Create a 30-second highlight clip
Edit-Video -InputPath $video -OutputPath "highlight.mp4" -StartTime "00:05:00" -Duration "00:00:30"

# Generate thumbnail for the clip
New-VideoThumbnail -InputPath "highlight.mp4" -OutputPath "highlight_thumb.jpg"
```

### Advanced Optimization

```powershell
# Optimize video for web streaming
Optimize-Video -InputPath "raw_video.mov" `
    -OutputPath "web_optimized.mp4" `
    -OptimizationTarget WebStreaming `
    -Verbose

# Create a GIF from video segment
New-VideoGif -InputPath "video.mp4" `
    -OutputPath "animation.gif" `
    -StartTime "30" `
    -Duration "5" `
    -Width 640 `
    -FrameRate 15 `
    -OptimizePalette
```

## Cmdlet Categories

### Information & Diagnostics
- `Get-MediaInfo` - Extract detailed metadata from media files
- `Get-FFmpegVersion` - Get FFmpeg version and build information
- `Test-FFmpegCapability` - Test for codec and format support

### Media Conversion
- `Convert-Media` - Convert between formats with quality control
- `Convert-VideoCodec` - Convert video codecs with hardware acceleration
- `Optimize-Video` - Smart optimization for size, quality, or streaming

### Video Manipulation
- `Resize-Video` - Scale videos to different resolutions
- `Edit-Video` - Trim and cut videos
- `Split-Video` - Split videos into segments
- `Merge-Video` - Concatenate multiple videos

### Audio Operations
- `Extract-Audio` - Extract audio from videos
- `Add-AudioToVideo` - Add or replace audio tracks

### Image & Thumbnails
- `New-VideoThumbnail` - Generate thumbnail images
- `New-VideoFromImages` - Create videos from image sequences
- `New-VideoGif` - Create animated GIFs from videos

### Metadata & Subtitles
- `Add-Subtitle` - Add soft or hard-coded subtitles
- `Set-VideoMetadata` - Set and update video metadata

## Installation

### From Source

```powershell
# Clone the repository
git clone https://github.com/adilio/psffmpeg.git
cd psffmpeg

# Import the module
Import-Module ./PSFFmpeg/PSFFmpeg.psd1

# Verify installation
Get-Command -Module PSFFmpeg
```

### Manual Installation

```powershell
# Copy to PowerShell modules directory
Copy-Item -Path ./PSFFmpeg -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\" -Recurse

# Import the module
Import-Module PSFFmpeg
```

## Building Documentation

This documentation is built using [platyPS](https://github.com/PowerShell/platyPS):

```powershell
# Install platyPS
Install-Module -Name platyPS -Scope CurrentUser

# Build all documentation
.\Build-Documentation.ps1 -All
```

See the [Documentation Guide](README.html) for more details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## Support & Resources

- **GitHub Issues**: [Report bugs or request features](https://github.com/adilio/psffmpeg/issues)
- **Discussions**: [Ask questions or share ideas](https://github.com/adilio/psffmpeg/discussions)
- **FFmpeg Documentation**: [https://ffmpeg.org/documentation.html](https://ffmpeg.org/documentation.html)
- **PowerShell Best Practices**: [PoshCode Style Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle)

## License

This project is licensed under the terms specified in the [LICENSE](../LICENSE) file.

## Authors

PSFFmpeg Contributors

---

**[View on GitHub](https://github.com/adilio/psffmpeg)** | **[Report an Issue](https://github.com/adilio/psffmpeg/issues)** | **[Documentation](README.html)**
