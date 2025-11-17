# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-01-17

### Added
- Initial release of PSFFmpeg module
- **Get-MediaInfo**: Retrieve detailed information about media files
  - Supports JSON output
  - Pipeline input support
  - Extracts format, codec, resolution, duration, and more
- **Convert-Media**: Universal media file conversion
  - Support for multiple video and audio codecs
  - Quality presets (low, medium, high, ultra)
  - Custom bitrate settings
  - Encoding preset control
- **Resize-Video**: Video resizing and scaling
  - Preset resolutions (4K, 1080p, 720p, 480p, 360p)
  - Custom dimensions with aspect ratio preservation
  - Multiple scaling algorithms (lanczos, bicubic, bilinear, etc.)
- **Extract-Audio**: Audio extraction from video files
  - Support for multiple audio formats (MP3, AAC, FLAC, etc.)
  - Quality presets
  - Custom bitrate control
- **Edit-Video**: Video trimming and cutting
  - Time-based trimming (start time + duration or end time)
  - Fast seeking option
  - Frame-accurate cutting
- **Merge-Video**: Concatenate multiple videos
  - Fast concat (no re-encoding)
  - Re-encode option for mixed formats
  - Support for unlimited number of videos
- **New-VideoThumbnail**: Thumbnail generation
  - Auto-detect middle frame
  - Custom time selection
  - Resize support
  - Multiple image format support (JPG, PNG, BMP, WebP)
- **Convert-VideoCodec**: Codec conversion
  - Support for H.264, H.265/HEVC, VP8, VP9, AV1, MPEG4
  - CRF quality control
  - Hardware acceleration support (NVENC, QSV, VAAPI, VideoToolbox)
  - Encoding preset control
- **Add-AudioToVideo**: Audio overlay and replacement
  - Replace existing audio
  - Mix multiple audio tracks
  - Volume control for each track
  - Shortest stream option
- Comprehensive Pester test suite
  - Unit tests for all cmdlets
  - Integration tests with real FFmpeg operations
  - Mocked tests for CI/CD environments
- Full documentation
  - Detailed README with examples
  - Comment-based help for all cmdlets
  - Usage examples file
  - Contributing guidelines
- Pipeline support for all cmdlets
- PowerShell 5.1+ compatibility
- Cross-platform support (Windows, macOS, Linux)

### Technical Features
- Proper error handling and validation
- SupportsShouldProcess for destructive operations
- Verbose logging throughout
- Parameter validation
- Pipeline input support via ValueFromPipeline
- File path validation
- FFmpeg installation detection

## [0.1.0] - Development

### Added
- Project initialization
- Basic project structure
- License and README

---

## Release Notes

### Version 1.0.0

This is the initial stable release of PSFFmpeg, a comprehensive PowerShell wrapper for FFmpeg. The module provides easy-to-use cmdlets for common media processing tasks while maintaining full access to FFmpeg's powerful features.

**Key Features:**
- 9 cmdlets covering all major media processing operations
- Full pipeline support for batch operations
- Quality presets for common use cases
- Hardware acceleration support
- Comprehensive error handling and validation
- Extensive test coverage (unit and integration tests)
- Complete documentation with examples

**Requirements:**
- PowerShell 5.1 or later
- FFmpeg installed and available in system PATH

**Installation:**
```powershell
# Clone and import
git clone https://github.com/adilio/psffmpeg.git
Import-Module ./psffmpeg/PSFFmpeg/PSFFmpeg.psd1
```

**Quick Example:**
```powershell
# Convert video to 720p MP4
Convert-Media -InputPath "input.avi" -OutputPath "output.mp4" -Quality high
Resize-Video -InputPath "output.mp4" -OutputPath "output_720p.mp4" -Scale 720p
```

For more information, see the [README](README.md) and [Examples](Examples/BasicUsage.ps1).

---

[Unreleased]: https://github.com/adilio/psffmpeg/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/adilio/psffmpeg/releases/tag/v1.0.0
[0.1.0]: https://github.com/adilio/psffmpeg/releases/tag/v0.1.0
