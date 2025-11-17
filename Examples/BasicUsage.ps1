# PSFFmpeg Basic Usage Examples
# This file demonstrates common usage patterns for the PSFFmpeg module

# Import the module
Import-Module PSFFmpeg

# ============================================
# Example 1: Get Media Information
# ============================================

Write-Host "`n=== Example 1: Get Media Information ===" -ForegroundColor Cyan

# Get basic information about a video
$info = Get-MediaInfo -Path "video.mp4"
Write-Host "File: $($info.FileName)"
Write-Host "Duration: $($info.Duration)"
Write-Host "Resolution: $($info.VideoWidth)x$($info.VideoHeight)"
Write-Host "Video Codec: $($info.VideoCodec)"
Write-Host "Audio Codec: $($info.AudioCodec)"

# Get information for all videos in a directory
Get-ChildItem *.mp4 | Get-MediaInfo | Format-Table FileName, Duration, VideoWidth, VideoHeight, VideoCodec

# ============================================
# Example 2: Simple Format Conversion
# ============================================

Write-Host "`n=== Example 2: Format Conversion ===" -ForegroundColor Cyan

# Convert AVI to MP4
Convert-Media -InputPath "input.avi" -OutputPath "output.mp4" -Overwrite

# Convert with quality preset
Convert-Media -InputPath "input.mp4" -OutputPath "output_high.mp4" -Quality high -Overwrite

# Convert to WebM with VP9 codec
Convert-Media -InputPath "input.mp4" -OutputPath "output.webm" -VideoCodec vp9 -AudioCodec opus -Overwrite

# ============================================
# Example 3: Video Resizing
# ============================================

Write-Host "`n=== Example 3: Video Resizing ===" -ForegroundColor Cyan

# Resize to 720p using preset
Resize-Video -InputPath "input.mp4" -OutputPath "output_720p.mp4" -Scale 720p -Overwrite

# Resize to specific dimensions
Resize-Video -InputPath "input.mp4" -OutputPath "output_custom.mp4" -Width 1280 -Height 720 -Overwrite

# Resize width only, maintain aspect ratio
Resize-Video -InputPath "input.mp4" -OutputPath "output_scaled.mp4" -Width 1920 -Height -1 -Overwrite

# Use different scaling algorithm
Resize-Video -InputPath "input.mp4" -OutputPath "output_bicubic.mp4" -Scale 1080p -ScaleAlgorithm bicubic -Overwrite

# ============================================
# Example 4: Audio Extraction
# ============================================

Write-Host "`n=== Example 4: Audio Extraction ===" -ForegroundColor Cyan

# Extract audio as MP3
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3" -Overwrite

# Extract with high quality
Extract-Audio -InputPath "video.mp4" -OutputPath "audio_high.mp3" -AudioQuality ultra -Overwrite

# Extract as lossless FLAC
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.flac" -AudioCodec flac -Overwrite

# Batch extract audio from all videos
Get-ChildItem *.mp4 | ForEach-Object {
    $audioFile = $_.BaseName + ".mp3"
    Extract-Audio -InputPath $_.FullName -OutputPath $audioFile -AudioQuality high -Overwrite
}

# ============================================
# Example 5: Video Editing (Trimming)
# ============================================

Write-Host "`n=== Example 5: Video Editing ===" -ForegroundColor Cyan

# Extract 30 seconds starting at 1 minute
Edit-Video -InputPath "input.mp4" -OutputPath "clip1.mp4" -StartTime "00:01:00" -Duration "00:00:30" -Overwrite

# Extract from second 10 to second 40
Edit-Video -InputPath "input.mp4" -OutputPath "clip2.mp4" -StartTime "10" -EndTime "40" -Overwrite

# Fast seek (quicker but less accurate)
Edit-Video -InputPath "input.mp4" -OutputPath "clip3.mp4" -StartTime "60" -Duration "120" -FastSeek -Overwrite

# ============================================
# Example 6: Merging Videos
# ============================================

Write-Host "`n=== Example 6: Merging Videos ===" -ForegroundColor Cyan

# Merge multiple videos
Merge-Video -InputPaths "part1.mp4", "part2.mp4", "part3.mp4" -OutputPath "complete.mp4" -Overwrite

# Merge all MP4 files in directory (in alphabetical order)
$videos = Get-ChildItem *.mp4 | Sort-Object Name | Select-Object -ExpandProperty FullName
Merge-Video -InputPaths $videos -OutputPath "merged.mp4" -Overwrite

# Merge videos with different formats (re-encode)
Merge-Video -InputPaths "video1.mp4", "video2.avi", "video3.mkv" -OutputPath "merged_all.mp4" -ReEncode -Overwrite

# ============================================
# Example 7: Thumbnail Generation
# ============================================

Write-Host "`n=== Example 7: Thumbnail Generation ===" -ForegroundColor Cyan

# Create thumbnail from middle of video
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg" -Overwrite

# Create thumbnail at specific time
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb_5sec.jpg" -Time "5" -Overwrite

# Create small thumbnail
New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb_small.jpg" -Width 320 -Height 240 -Overwrite

# Generate thumbnails for all videos
Get-ChildItem *.mp4 | ForEach-Object {
    $thumbFile = $_.BaseName + "_thumb.jpg"
    New-VideoThumbnail -InputPath $_.FullName -OutputPath $thumbFile -Overwrite
}

# ============================================
# Example 8: Codec Conversion
# ============================================

Write-Host "`n=== Example 8: Codec Conversion ===" -ForegroundColor Cyan

# Convert to H.265/HEVC for better compression
Convert-VideoCodec -InputPath "input.mp4" -OutputPath "output_hevc.mp4" -Codec hevc -Overwrite

# Convert with specific quality (CRF)
Convert-VideoCodec -InputPath "input.mp4" -OutputPath "output_crf20.mp4" -Codec h264 -CRF 20 -Overwrite

# Use hardware acceleration (NVIDIA)
Convert-VideoCodec -InputPath "input.mp4" -OutputPath "output_nvenc.mp4" -Codec h264 -HardwareAcceleration nvenc -Overwrite

# Convert to VP9 for web
Convert-VideoCodec -InputPath "input.mp4" -OutputPath "output_web.webm" -Codec vp9 -CRF 31 -Overwrite

# ============================================
# Example 9: Adding/Replacing Audio
# ============================================

Write-Host "`n=== Example 9: Audio Operations ===" -ForegroundColor Cyan

# Replace video's audio with music
Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "music.mp3" -OutputPath "video_with_music.mp4" -ReplaceAudio -Overwrite

# Mix narration with original audio
Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "narration.mp3" -OutputPath "video_narrated.mp4" -AudioVolume 3 -VideoVolume -5 -Overwrite

# Add audio to silent video, end when shortest stream ends
Add-AudioToVideo -VideoPath "silent_video.mp4" -AudioPath "soundtrack.mp3" -OutputPath "video_with_audio.mp4" -Shortest -Overwrite

# ============================================
# Example 10: Advanced Pipeline Operations
# ============================================

Write-Host "`n=== Example 10: Pipeline Operations ===" -ForegroundColor Cyan

# Find all videos longer than 10 minutes
Get-ChildItem *.mp4 |
    Get-MediaInfo |
    Where-Object { $_.DurationSeconds -gt 600 } |
    Format-Table FileName, Duration

# Batch convert and resize videos
Get-ChildItem *.avi | ForEach-Object {
    $temp = $_.BaseName + "_temp.mp4"
    $final = $_.BaseName + "_720p.mp4"

    # Convert to MP4
    Convert-Media -InputPath $_.FullName -OutputPath $temp -Overwrite

    # Resize to 720p
    Resize-Video -InputPath $temp -OutputPath $final -Scale 720p -Overwrite

    # Clean up temp file
    Remove-Item $temp
}

# Create a video catalog with thumbnails
Get-ChildItem *.mp4 | ForEach-Object {
    $info = Get-MediaInfo -Path $_.FullName
    $thumb = $_.BaseName + "_thumb.jpg"

    New-VideoThumbnail -InputPath $_.FullName -OutputPath $thumb -Overwrite

    [PSCustomObject]@{
        File = $_.Name
        Duration = $info.Duration
        Resolution = "$($info.VideoWidth)x$($info.VideoHeight)"
        Codec = $info.VideoCodec
        Size = "{0:N2} MB" -f ($_.Length / 1MB)
        Thumbnail = $thumb
    }
} | Format-Table -AutoSize

# ============================================
# Example 11: Error Handling
# ============================================

Write-Host "`n=== Example 11: Error Handling ===" -ForegroundColor Cyan

# Using try/catch for error handling
try {
    Convert-Media -InputPath "nonexistent.mp4" -OutputPath "output.mp4"
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Using -ErrorAction to control behavior
Convert-Media -InputPath "nonexistent.mp4" -OutputPath "output.mp4" -ErrorAction SilentlyContinue

# Check if file exists before processing
if (Test-Path "input.mp4") {
    Convert-Media -InputPath "input.mp4" -OutputPath "output.mp4" -Overwrite
}
else {
    Write-Host "Input file not found!" -ForegroundColor Red
}

# ============================================
# Example 12: Using -WhatIf and -Verbose
# ============================================

Write-Host "`n=== Example 12: WhatIf and Verbose ===" -ForegroundColor Cyan

# See what would happen without actually executing
Convert-Media -InputPath "input.mp4" -OutputPath "output.mp4" -WhatIf

# Get detailed information about what's happening
Convert-Media -InputPath "input.mp4" -OutputPath "output.mp4" -Verbose -Overwrite

Write-Host "`n=== Examples Complete ===" -ForegroundColor Green
Write-Host "For more information, use: Get-Help <cmdlet-name> -Full" -ForegroundColor Yellow
