# PSFFmpeg Examples

## about_PSFFmpeg_Examples

## SHORT DESCRIPTION
Comprehensive examples and common use cases for the PSFFmpeg module.

## LONG DESCRIPTION
This topic provides detailed examples demonstrating how to use PSFFmpeg cmdlets for common video and audio processing tasks. Examples progress from basic to advanced usage patterns.

## BASIC EXAMPLES

### Example 1: Get Media Information
```powershell
# Get information about a single file
$info = Get-MediaInfo -Path "C:\Videos\movie.mp4"
Write-Host "Duration: $($info.Duration)"
Write-Host "Resolution: $($info.VideoWidth)x$($info.VideoHeight)"
Write-Host "Video Codec: $($info.VideoCodec)"
Write-Host "Audio Codec: $($info.AudioCodec)"

# Get information in JSON format
Get-MediaInfo -Path "movie.mp4" -Json | ConvertFrom-Json
```

### Example 2: Simple Format Conversion
```powershell
# Convert AVI to MP4
Convert-Media -InputPath "video.avi" -OutputPath "video.mp4"

# Convert with quality preset
Convert-Media -InputPath "video.mov" -OutputPath "video.mp4" -Quality high

# Convert with specific codecs
Convert-Media -InputPath "video.mp4" -OutputPath "video.webm" `
    -VideoCodec vp9 -AudioCodec opus
```

### Example 3: Extract Video Clips
```powershell
# Extract first 30 seconds
Edit-Video -InputPath "movie.mp4" -OutputPath "intro.mp4" -Duration 30

# Extract clip from specific time
Edit-Video -InputPath "movie.mp4" -OutputPath "scene.mp4" `
    -StartTime "00:10:30" -Duration 45

# Extract multiple clips
$clips = @(
    @{Start = "00:05:00"; Duration = 30; Output = "clip1.mp4"},
    @{Start = "00:15:00"; Duration = 45; Output = "clip2.mp4"},
    @{Start = "00:25:00"; Duration = 60; Output = "clip3.mp4"}
)

foreach ($clip in $clips) {
    Edit-Video -InputPath "movie.mp4" -OutputPath $clip.Output `
        -StartTime $clip.Start -Duration $clip.Duration
}
```

## BATCH PROCESSING EXAMPLES

### Example 4: Convert Multiple Files
```powershell
# Convert all AVI files to MP4
Get-ChildItem -Path "C:\Videos" -Filter "*.avi" | ForEach-Object {
    $outputPath = Join-Path "C:\Videos\Converted" ($_.BaseName + ".mp4")
    Convert-Media -InputPath $_.FullName -OutputPath $outputPath -Quality high
}

# Convert with progress indication
$aviFiles = Get-ChildItem -Path "C:\Videos" -Filter "*.avi"
$total = $aviFiles.Count
$current = 0

foreach ($file in $aviFiles) {
    $current++
    Write-Progress -Activity "Converting Videos" `
        -Status "Processing $($file.Name)" `
        -PercentComplete (($current / $total) * 100)

    $outputPath = Join-Path "C:\Videos\Converted" ($file.BaseName + ".mp4")
    Convert-Media -InputPath $file.FullName -OutputPath $outputPath -Quality high
}
```

### Example 5: Batch Create Thumbnails
```powershell
# Create thumbnails for all MP4 files
Get-ChildItem -Path "C:\Videos" -Filter "*.mp4" | ForEach-Object {
    $thumbPath = Join-Path "C:\Videos\Thumbnails" ($_.BaseName + ".jpg")
    New-VideoThumbnail -InputPath $_.FullName -OutputPath $thumbPath `
        -Time "00:00:05" -Width 1280
}

# Create multiple thumbnails per video
$videos = Get-ChildItem -Path "C:\Videos" -Filter "*.mp4"
$times = @("00:00:05", "00:01:00", "00:05:00", "00:10:00")

foreach ($video in $videos) {
    $index = 0
    foreach ($time in $times) {
        $thumbPath = Join-Path "C:\Thumbnails" "$($video.BaseName)_$index.jpg"
        New-VideoThumbnail -InputPath $video.FullName -OutputPath $thumbPath -Time $time
        $index++
    }
}
```

## ADVANCED EXAMPLES

### Example 6: Video Optimization Pipeline
```powershell
# Optimize videos for web delivery
Get-ChildItem -Path "C:\Videos\Raw" -Filter "*.mp4" |
    Where-Object { $_.Length -gt 100MB } |
    ForEach-Object {
        $outputPath = Join-Path "C:\Videos\Web" $_.Name

        # Get original info
        $info = Get-MediaInfo -Path $_.FullName

        # Optimize based on resolution
        if ($info.VideoWidth -gt 1920) {
            Resize-Video -InputPath $_.FullName -OutputPath $outputPath `
                -Width 1920 -Height -1 -Quality high
        } else {
            Optimize-Video -InputPath $_.FullName -OutputPath $outputPath `
                -Quality medium
        }

        Write-Host "Optimized: $($_.Name)" -ForegroundColor Green
        Write-Host "  Original size: $([math]::Round($_.Length / 1MB, 2)) MB" -ForegroundColor Gray

        $newFile = Get-Item $outputPath
        Write-Host "  New size: $([math]::Round($newFile.Length / 1MB, 2)) MB" -ForegroundColor Gray
    }
```

### Example 7: Audio Extraction and Conversion
```powershell
# Extract audio from videos and convert to MP3
Get-ChildItem -Path "C:\Videos" -Filter "*.mp4" | ForEach-Object {
    $audioPath = Join-Path "C:\Audio" ($_.BaseName + ".mp3")
    Extract-Audio -InputPath $_.FullName -OutputPath $audioPath `
        -Format mp3 -Bitrate "320k"
}

# Extract audio only from videos with specific duration
Get-ChildItem -Path "C:\Videos" -Filter "*.mp4" |
    Get-MediaInfo |
    Where-Object { $_.Duration.TotalMinutes -ge 5 -and $_.Duration.TotalMinutes -le 60 } |
    ForEach-Object {
        $audioPath = Join-Path "C:\Audio" ([System.IO.Path]::GetFileNameWithoutExtension($_.FileName) + ".mp3")
        Extract-Audio -InputPath $_.FileName -OutputPath $audioPath -Format mp3 -Bitrate "192k"
    }
```

### Example 8: Create GIF Animations
```powershell
# Create GIF from video highlight
New-VideoGif -InputPath "gameplay.mp4" -OutputPath "highlight.gif" `
    -StartTime "00:05:30" -Duration 10 `
    -Width 640 -FrameRate 15 -Quality high -OptimizePalette

# Create multiple GIFs from different parts of a video
$gifSegments = @(
    @{Start = "00:01:00"; Duration = 5; Output = "intro.gif"},
    @{Start = "00:05:00"; Duration = 8; Output = "action.gif"},
    @{Start = "00:10:00"; Duration = 6; Output = "outro.gif"}
)

foreach ($segment in $gifSegments) {
    New-VideoGif -InputPath "video.mp4" -OutputPath $segment.Output `
        -StartTime $segment.Start -Duration $segment.Duration `
        -Width 480 -Quality medium
}

# Create optimized social media GIF
New-VideoGif -InputPath "video.mp4" -OutputPath "social.gif" `
    -StartTime 30 -Duration 5 `
    -Width 480 -FrameRate 12 `
    -MaxColors 128 -Quality high `
    -Loop 0 -OptimizePalette
```

### Example 9: Merge Videos
```powershell
# Merge multiple video files
$videos = @("intro.mp4", "main.mp4", "outro.mp4")
Merge-Video -InputPaths $videos -OutputPath "complete.mp4"

# Merge all videos in a directory (sorted by name)
$clips = Get-ChildItem -Path "C:\Clips" -Filter "clip_*.mp4" |
    Sort-Object Name |
    Select-Object -ExpandProperty FullName

Merge-Video -InputPaths $clips -OutputPath "C:\Final\merged.mp4"
```

### Example 10: Split Video into Segments
```powershell
# Split video into 5-minute segments
Split-Video -InputPath "long-video.mp4" -OutputDirectory "C:\Segments" `
    -SegmentDuration 300

# Split video at specific timestamps
$timestamps = @("00:05:00", "00:15:30", "00:28:45")
Split-Video -InputPath "movie.mp4" -OutputDirectory "C:\Chapters" `
    -SplitTimes $timestamps
```

## ADVANCED SCENARIOS

### Example 11: Conditional Processing Based on Media Info
```powershell
# Process videos based on their properties
Get-ChildItem -Path "C:\Videos" -Filter "*.mp4" | ForEach-Object {
    $info = Get-MediaInfo -Path $_.FullName

    # Convert to different codec if using old codec
    if ($info.VideoCodec -eq "mpeg4") {
        $outputPath = Join-Path "C:\Converted" $_.Name
        Convert-VideoCodec -InputPath $_.FullName -OutputPath $outputPath `
            -Codec h264 -Quality high
        Write-Host "Converted $($_.Name) from mpeg4 to h264" -ForegroundColor Green
    }

    # Resize if resolution is too high
    if ($info.VideoWidth -gt 3840) {
        $outputPath = Join-Path "C:\Resized" $_.Name
        Resize-Video -InputPath $_.FullName -OutputPath $outputPath `
            -Width 3840 -Height -1
        Write-Host "Resized $($_.Name) from $($info.VideoWidth)x$($info.VideoHeight)" -ForegroundColor Yellow
    }

    # Extract audio if video is too large
    if ($_.Length -gt 500MB -and $info.HasAudio) {
        $audioPath = Join-Path "C:\Audio" ($_.BaseName + ".mp3")
        Extract-Audio -InputPath $_.FullName -OutputPath $audioPath -Format mp3
        Write-Host "Extracted audio from large file: $($_.Name)" -ForegroundColor Cyan
    }
}
```

### Example 12: Create Video from Images
```powershell
# Create video from numbered image sequence
$images = Get-ChildItem -Path "C:\Images" -Filter "frame_*.jpg" | Sort-Object Name
New-VideoFromImages -InputPattern "C:\Images\frame_%03d.jpg" `
    -OutputPath "animation.mp4" `
    -FrameRate 30 -Quality high

# Create slideshow with custom duration per image
New-VideoFromImages -InputPattern "C:\Photos\*.jpg" `
    -OutputPath "slideshow.mp4" `
    -FrameRate 1 -Quality high

# Create timelapse from photos
New-VideoFromImages -InputPattern "C:\Timelapse\IMG_%04d.jpg" `
    -OutputPath "timelapse.mp4" `
    -FrameRate 60 -Quality ultra
```

### Example 13: Add Audio and Subtitles
```powershell
# Add background music to video
Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "music.mp3" `
    -OutputPath "video-with-music.mp4" -AudioVolume 0.5

# Add subtitles to video
Add-Subtitle -InputPath "video.mp4" -SubtitlePath "subtitles.srt" `
    -OutputPath "video-with-subs.mp4" -Style "FontName=Arial,FontSize=24,PrimaryColour=&Hffffff"
```

### Example 14: Set Video Metadata
```powershell
# Set metadata for a video
Set-VideoMetadata -InputPath "video.mp4" -OutputPath "tagged.mp4" `
    -Title "My Awesome Video" `
    -Author "John Doe" `
    -Copyright "2024" `
    -Comment "Created with PSFFmpeg" `
    -Year 2024

# Batch update metadata
$videos = Get-ChildItem -Path "C:\Videos" -Filter "*.mp4"
foreach ($video in $videos) {
    $outputPath = Join-Path "C:\Tagged" $video.Name
    Set-VideoMetadata -InputPath $video.FullName -OutputPath $outputPath `
        -Author "Content Creator" `
        -Year 2024
}
```

### Example 15: Parallel Processing (PowerShell 7+)
```powershell
# Process videos in parallel for better performance
$videos = Get-ChildItem -Path "C:\Videos" -Filter "*.mov"

$videos | ForEach-Object -Parallel {
    $outputPath = Join-Path "C:\Converted" ($_.BaseName + ".mp4")

    # Import module in parallel scope
    Import-Module PSFFmpeg

    Convert-Media -InputPath $_.FullName -OutputPath $outputPath `
        -VideoCodec h264 -AudioCodec aac -Quality high

    Write-Host "Converted: $($_.Name)" -ForegroundColor Green
} -ThrottleLimit 4

Write-Host "All conversions complete!" -ForegroundColor Cyan
```

## PIPELINE EXAMPLES

### Example 16: Complex Pipeline
```powershell
# Find, analyze, filter, and process videos
Get-ChildItem -Path "C:\Videos" -Recurse -Include *.mp4,*.avi,*.mov |
    Get-MediaInfo |
    Where-Object {
        $_.VideoCodec -ne 'h264' -and
        $_.Duration.TotalMinutes -gt 5
    } |
    ForEach-Object {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.FileName)
        $outputPath = Join-Path "C:\Optimized" "$baseName.mp4"

        Write-Host "Processing: $($_.FileName)" -ForegroundColor Yellow
        Write-Host "  Codec: $($_.VideoCodec) -> h264" -ForegroundColor Gray
        Write-Host "  Duration: $($_.Duration)" -ForegroundColor Gray

        Convert-VideoCodec -InputPath $_.FileName -OutputPath $outputPath `
            -Codec h264 -Quality high -Overwrite
    }
```

### Example 17: Generate Report
```powershell
# Generate detailed report of all media files
$report = Get-ChildItem -Path "C:\Videos" -Recurse -Include *.mp4,*.avi,*.mov |
    Get-MediaInfo |
    Select-Object FileName,
                  @{N='Duration';E={$_.Duration.ToString()}},
                  @{N='Size(MB)';E={[math]::Round($_.Size / 1MB, 2)}},
                  VideoCodec,
                  AudioCodec,
                  @{N='Resolution';E={"$($_.VideoWidth)x$($_.VideoHeight)"}},
                  @{N='FPS';E={$_.VideoFrameRate}}

# Export to CSV
$report | Export-Csv -Path "C:\Reports\media-inventory.csv" -NoTypeInformation

# Display summary
$report | Format-Table -AutoSize

# Show statistics
Write-Host "`nSummary Statistics:" -ForegroundColor Cyan
Write-Host "Total files: $($report.Count)" -ForegroundColor Gray
Write-Host "Total size: $([math]::Round(($report | Measure-Object 'Size(MB)' -Sum).Sum, 2)) MB" -ForegroundColor Gray
Write-Host "Total duration: $(($report | ForEach-Object { [TimeSpan]::Parse($_.Duration) } | Measure-Object -Sum Ticks).Sum / 10000000 / 3600) hours" -ForegroundColor Gray
```

## ERROR HANDLING EXAMPLES

### Example 18: Robust Error Handling
```powershell
# Process files with proper error handling
$videos = Get-ChildItem -Path "C:\Videos" -Filter "*.mp4"
$successCount = 0
$failureCount = 0
$errors = @()

foreach ($video in $videos) {
    try {
        $outputPath = Join-Path "C:\Converted" ($video.BaseName + "_converted.mp4")

        Convert-Media -InputPath $video.FullName -OutputPath $outputPath `
            -Quality high -ErrorAction Stop

        $successCount++
        Write-Host "Success: $($video.Name)" -ForegroundColor Green
    }
    catch {
        $failureCount++
        $errors += @{
            File = $video.Name
            Error = $_.Exception.Message
        }
        Write-Host "Failed: $($video.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Report results
Write-Host "`nProcessing Complete:" -ForegroundColor Cyan
Write-Host "  Successful: $successCount" -ForegroundColor Green
Write-Host "  Failed: $failureCount" -ForegroundColor Red

if ($errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Yellow
    $errors | ForEach-Object {
        Write-Host "  $($_.File): $($_.Error)" -ForegroundColor Gray
    }
}
```

## SEE ALSO

- about_PSFFmpeg
- Get-Help <CommandName> -Examples
- https://github.com/adilio/psffmpeg

## KEYWORDS
- Examples
- Usage
- Scenarios
- Pipeline
- Batch Processing
