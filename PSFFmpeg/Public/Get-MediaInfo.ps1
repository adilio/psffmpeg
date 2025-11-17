function Get-MediaInfo {
    <#
    .SYNOPSIS
        Retrieves detailed information about a media file.

    .DESCRIPTION
        Uses ffprobe to extract comprehensive metadata from video and audio files including
        format, duration, bitrate, codec information, resolution, and more.

    .PARAMETER Path
        The path to the media file to analyze.

    .PARAMETER Json
        Returns the raw JSON output from ffprobe instead of a parsed object.

    .OUTPUTS
        PSCustomObject or String (if -Json is specified)

    .EXAMPLE
        Get-MediaInfo -Path "video.mp4"
        Retrieves information about video.mp4

    .EXAMPLE
        Get-MediaInfo -Path "audio.mp3" -Json
        Returns raw JSON output from ffprobe

    .EXAMPLE
        Get-ChildItem *.mp4 | Get-MediaInfo
        Gets information for all MP4 files in the current directory
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject], [string])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "File not found: $_"
            }
            return $true
        })]
        [Alias('FullName')]
        [string]$Path,

        [Parameter()]
        [switch]$Json
    )

    begin {
        if (-not (Test-FFmpegInstalled)) {
            throw "FFmpeg is not installed. Please install FFmpeg from https://ffmpeg.org/"
        }
    }

    process {
        try {
            $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop

            Write-Verbose "Analyzing media file: $ResolvedPath"

            # Use ffprobe to get media information in JSON format
            $ffprobeArgs = @(
                '-v', 'quiet',
                '-print_format', 'json',
                '-show_format',
                '-show_streams',
                $ResolvedPath
            )

            $output = & ffprobe @ffprobeArgs 2>&1

            if ($LASTEXITCODE -ne 0) {
                throw "FFprobe failed with exit code $LASTEXITCODE. Output: $output"
            }

            if ($Json) {
                return $output
            }

            # Parse JSON output
            $mediaData = $output | ConvertFrom-Json

            # Extract relevant information
            $format = $mediaData.format
            $videoStream = $mediaData.streams | Where-Object { $_.codec_type -eq 'video' } | Select-Object -First 1
            $audioStream = $mediaData.streams | Where-Object { $_.codec_type -eq 'audio' } | Select-Object -First 1

            # Build result object
            $result = [PSCustomObject]@{
                FileName = $format.filename
                Format = $format.format_name
                Duration = [TimeSpan]::FromSeconds([double]$format.duration)
                DurationSeconds = [double]$format.duration
                Size = [long]$format.size
                BitRate = [long]$format.bit_rate
                HasVideo = $null -ne $videoStream
                HasAudio = $null -ne $audioStream
            }

            # Add video information if available
            if ($videoStream) {
                $result | Add-Member -NotePropertyMembers @{
                    VideoCodec = $videoStream.codec_name
                    VideoCodecLong = $videoStream.codec_long_name
                    VideoWidth = [int]$videoStream.width
                    VideoHeight = [int]$videoStream.height
                    VideoAspectRatio = $videoStream.display_aspect_ratio
                    VideoFrameRate = if ($videoStream.r_frame_rate) {
                        $parts = $videoStream.r_frame_rate -split '/'
                        if ($parts.Count -eq 2 -and $parts[1] -ne '0') {
                            [math]::Round([double]$parts[0] / [double]$parts[1], 2)
                        }
                        else {
                            $null
                        }
                    }
                    else { $null }
                    VideoPixelFormat = $videoStream.pix_fmt
                    VideoBitRate = if ($videoStream.bit_rate) { [long]$videoStream.bit_rate } else { $null }
                }
            }

            # Add audio information if available
            if ($audioStream) {
                $result | Add-Member -NotePropertyMembers @{
                    AudioCodec = $audioStream.codec_name
                    AudioCodecLong = $audioStream.codec_long_name
                    AudioSampleRate = if ($audioStream.sample_rate) { [int]$audioStream.sample_rate } else { $null }
                    AudioChannels = [int]$audioStream.channels
                    AudioChannelLayout = $audioStream.channel_layout
                    AudioBitRate = if ($audioStream.bit_rate) { [long]$audioStream.bit_rate } else { $null }
                }
            }

            return $result
        }
        catch {
            Write-Error "Failed to get media info for '$Path': $_"
        }
    }
}
