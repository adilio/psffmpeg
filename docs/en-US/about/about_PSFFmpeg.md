# PSFFmpeg

## about_PSFFmpeg

## SHORT DESCRIPTION
PSFFmpeg is a PowerShell module that provides a comprehensive set of cmdlets for working with audio and video files using FFmpeg.

## LONG DESCRIPTION
PSFFmpeg wraps FFmpeg functionality in idiomatic PowerShell cmdlets, making it easy to perform common video and audio processing tasks without dealing with complex FFmpeg command-line syntax.

The module provides cmdlets for:
- **Media Information**: Get detailed metadata about video and audio files
- **Conversion**: Convert between different media formats and codecs
- **Editing**: Cut, trim, merge, and split video files
- **Audio Processing**: Extract audio, add audio to video, manage audio streams
- **Video Processing**: Resize, create thumbnails, generate GIFs, optimize videos
- **Metadata**: Set and manage video metadata and tags
- **Subtitles**: Add subtitles to videos
- **Image Sequences**: Create videos from image sequences

All cmdlets follow PowerShell best practices including:
- Pipeline support with ValueFromPipeline and ValueFromPipelineByPropertyName
- Comprehensive parameter validation
- SupportsShouldProcess for operations that modify files
- Verbose output for troubleshooting
- Consistent error handling
- Type safety with OutputType attributes

## PREREQUISITES

### FFmpeg Installation
PSFFmpeg requires FFmpeg to be installed and available in your system PATH. You can download FFmpeg from:
- https://ffmpeg.org/download.html

To verify FFmpeg is installed:
```powershell
Test-FFmpegInstalled
Get-FFmpegVersion
```

### PowerShell Version
- PowerShell 5.1 or higher
- PowerShell Core 7.0 or higher (recommended)

## INSTALLATION

### From PowerShell Gallery (when published)
```powershell
Install-Module -Name PSFFmpeg -Scope CurrentUser
```

### Manual Installation
1. Clone the repository:
   ```powershell
   git clone https://github.com/adilio/psffmpeg.git
   ```

2. Import the module:
   ```powershell
   Import-Module ./psffmpeg/PSFFmpeg/PSFFmpeg.psd1
   ```

## GETTING STARTED

### Basic Example - Get Media Information
```powershell
# Get information about a video file
$info = Get-MediaInfo -Path "video.mp4"
$info | Format-List

# Get info for multiple files
Get-ChildItem *.mp4 | Get-MediaInfo | Format-Table FileName, Duration, VideoCodec
```

### Basic Example - Convert Media
```powershell
# Convert AVI to MP4
Convert-Media -InputPath "video.avi" -OutputPath "video.mp4"

# Convert with specific quality
Convert-Media -InputPath "video.mov" -OutputPath "video.mp4" -Quality high

# Convert with custom codecs
Convert-Media -InputPath "video.mp4" -OutputPath "video.webm" `
    -VideoCodec vp9 -AudioCodec opus -Quality high
```

### Basic Example - Edit Video
```powershell
# Extract a 30-second clip starting at 1 minute
Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" `
    -StartTime "00:01:00" -Duration 30

# Extract just the first 10 seconds
Edit-Video -InputPath "long-video.mp4" -OutputPath "intro.mp4" `
    -Duration 10
```

### Basic Example - Create GIF
```powershell
# Create a GIF from a video segment
New-VideoGif -InputPath "video.mp4" -OutputPath "animation.gif" `
    -StartTime 10 -Duration 5 -Width 480

# Create high-quality optimized GIF
New-VideoGif -InputPath "video.mp4" -OutputPath "clip.gif" `
    -StartTime 30 -Duration 10 -Quality high -OptimizePalette
```

## PIPELINE SUPPORT

All cmdlets support the PowerShell pipeline:

```powershell
# Convert all AVI files to MP4
Get-ChildItem *.avi | Convert-Media -OutputPath { $_.BaseName + ".mp4" }

# Get info about all media files in a directory
Get-ChildItem -Path "C:\Videos" -Include *.mp4,*.avi,*.mov -Recurse |
    Get-MediaInfo |
    Where-Object { $_.Duration.TotalMinutes -gt 10 } |
    Format-Table FileName, Duration, VideoCodec, AudioCodec
```

## BEST PRACTICES

### 1. Use -WhatIf and -Confirm for Safety
Many cmdlets support ShouldProcess for previewing operations:
```powershell
# Preview what would happen
Convert-Media -InputPath "video.avi" -OutputPath "video.mp4" -WhatIf

# Confirm before processing
Convert-Media -InputPath "video.avi" -OutputPath "video.mp4" -Confirm
```

### 2. Use -Verbose for Troubleshooting
Enable verbose output to see FFmpeg commands being executed:
```powershell
Convert-Media -InputPath "video.avi" -OutputPath "video.mp4" -Verbose
```

### 3. Handle Errors Properly
Use try/catch blocks for robust error handling:
```powershell
try {
    $info = Get-MediaInfo -Path "video.mp4" -ErrorAction Stop
    # Process $info
}
catch {
    Write-Error "Failed to get media info: $_"
}
```

### 4. Use Quality Presets
Most cmdlets provide quality presets for common scenarios:
```powershell
# Use quality preset instead of manual settings
Convert-Media -InputPath "video.mov" -OutputPath "video.mp4" -Quality high
```

### 5. Leverage Pipeline Parameters
Use pipeline parameters to process multiple files:
```powershell
# Process all videos in a directory
Get-ChildItem *.mp4 |
    Where-Object { $_.Length -gt 100MB } |
    Optimize-Video -Quality medium -Overwrite
```

## COMMON SCENARIOS

### Scenario 1: Batch Convert Videos
```powershell
# Convert all MOV files to MP4
Get-ChildItem *.mov | ForEach-Object {
    $outputPath = Join-Path "converted" ($_.BaseName + ".mp4")
    Convert-Media -InputPath $_.FullName -OutputPath $outputPath -Quality high
}
```

### Scenario 2: Extract Audio from Videos
```powershell
# Extract audio from all MP4 files
Get-ChildItem *.mp4 | ForEach-Object {
    $audioPath = Join-Path "audio" ($_.BaseName + ".mp3")
    Extract-Audio -InputPath $_.FullName -OutputPath $audioPath -Format mp3
}
```

### Scenario 3: Create Thumbnails
```powershell
# Create thumbnails for all videos
Get-ChildItem *.mp4 | ForEach-Object {
    $thumbPath = Join-Path "thumbnails" ($_.BaseName + ".jpg")
    New-VideoThumbnail -InputPath $_.FullName -OutputPath $thumbPath -Time "00:00:05"
}
```

### Scenario 4: Optimize Videos for Web
```powershell
# Optimize all videos for web delivery
Get-ChildItem *.mp4 | ForEach-Object {
    $outputPath = Join-Path "web" $_.Name
    Optimize-Video -InputPath $_.FullName -OutputPath $outputPath `
        -Quality medium -MaxWidth 1920
}
```

## GETTING HELP

### Command Help
Use Get-Help to get detailed information about any cmdlet:
```powershell
# Get basic help
Get-Help Convert-Media

# Get detailed help with examples
Get-Help Convert-Media -Detailed

# Get full help including parameter details
Get-Help Convert-Media -Full

# Get examples only
Get-Help Convert-Media -Examples

# Open online help (if available)
Get-Help Convert-Media -Online
```

### List All Commands
```powershell
# List all PSFFmpeg commands
Get-Command -Module PSFFmpeg

# List commands with descriptions
Get-Command -Module PSFFmpeg | Get-Help | Format-Table Name, Synopsis
```

### Update Help
If the module supports updatable help:
```powershell
Update-Help -Module PSFFmpeg
```

## TROUBLESHOOTING

### FFmpeg Not Found
If you get errors about FFmpeg not being found:
1. Verify FFmpeg is installed: `ffmpeg -version`
2. Ensure FFmpeg is in your PATH
3. Use `Test-FFmpegInstalled` to verify
4. Use `Get-FFmpegVersion` to check the version

### Conversion Failures
If conversions fail:
1. Use `-Verbose` to see FFmpeg commands
2. Verify the input file is valid
3. Check available disk space
4. Ensure output directory exists
5. Try with simpler parameters first

### Performance Issues
For better performance:
1. Use lower quality presets for faster processing
2. Use `-Preset fast` or `-Preset ultrafast` for encoding
3. Use `-VideoCodec copy` to avoid re-encoding when possible
4. Process files in parallel using `ForEach-Object -Parallel` (PowerShell 7+)

## SEE ALSO

### Related About Topics
- about_PSFFmpeg_Examples
- about_PSFFmpeg_Installation

### Online Resources
- GitHub Repository: https://github.com/adilio/psffmpeg
- FFmpeg Documentation: https://ffmpeg.org/documentation.html
- FFmpeg Wiki: https://trac.ffmpeg.org/wiki

### Key Cmdlets
- Get-MediaInfo
- Convert-Media
- Edit-Video
- New-VideoGif
- Optimize-Video
- Extract-Audio

## KEYWORDS
- FFmpeg
- Video
- Audio
- Media
- Conversion
- Encoding
