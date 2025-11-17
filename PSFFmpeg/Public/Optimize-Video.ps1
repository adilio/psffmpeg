function Optimize-Video {
    <#
    .SYNOPSIS
        Optimizes a video file for size, quality, or web streaming.

    .DESCRIPTION
        Intelligently optimizes video files by analyzing content and applying appropriate encoding settings.
        Can optimize for file size reduction, quality improvement, web streaming, or mobile devices.
        Automatically selects optimal codecs, bitrates, and encoding parameters.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputPath
        The path for the output optimized video file.

    .PARAMETER OptimizationTarget
        The optimization goal: 'FileSize', 'Quality', 'WebStreaming', 'Mobile', or 'Balanced'. Default is 'Balanced'.

    .PARAMETER VideoCodec
        Force specific video codec. If not specified, automatically selects best codec for target.

    .PARAMETER AudioCodec
        Force specific audio codec. If not specified, automatically selects best codec for target.

    .PARAMETER TargetSize
        Target file size in MB. Will calculate appropriate bitrates to achieve approximate target size.

    .PARAMETER TwoPass
        Uses two-pass encoding for better quality at given bitrate (slower but better results).

    .PARAMETER HardwareAcceleration
        Use hardware acceleration if available: 'nvenc', 'qsv', 'vaapi', 'videotoolbox'.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Optimize-Video -InputPath "large_video.mp4" -OutputPath "optimized.mp4" -OptimizationTarget FileSize
        Optimizes video for smallest file size

    .EXAMPLE
        Optimize-Video -InputPath "video.avi" -OutputPath "web.mp4" -OptimizationTarget WebStreaming
        Optimizes video for web streaming with fast start

    .EXAMPLE
        Optimize-Video -InputPath "raw.mov" -OutputPath "mobile.mp4" -OptimizationTarget Mobile
        Optimizes video for mobile device playback

    .EXAMPLE
        Optimize-Video -InputPath "source.mp4" -OutputPath "output.mp4" -TargetSize 50 -TwoPass
        Optimizes to approximately 50MB using two-pass encoding

    .NOTES
        Author: PSFFmpeg Contributors
        Name: Optimize-Video
        Version: 1.0.0
        Requires: FFmpeg

    .LINK
        https://github.com/adilio/psffmpeg

    .LINK
        Convert-Media

    .LINK
        Convert-VideoCodec

    .LINK
        https://ffmpeg.org/
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Input file not found: $_"
            }
            return $true
        })]
        [Alias('FullName')]
        [string]$InputPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [ValidateSet('FileSize', 'Quality', 'WebStreaming', 'Mobile', 'Balanced')]
        [string]$OptimizationTarget = 'Balanced',

        [Parameter()]
        [ValidateSet('h264', 'h265', 'hevc', 'vp9', 'av1')]
        [string]$VideoCodec,

        [Parameter()]
        [ValidateSet('aac', 'opus', 'mp3')]
        [string]$AudioCodec,

        [Parameter()]
        [ValidateRange(1, 10000)]
        [int]$TargetSize,

        [Parameter()]
        [switch]$TwoPass,

        [Parameter()]
        [ValidateSet('nvenc', 'qsv', 'vaapi', 'videotoolbox')]
        [string]$HardwareAcceleration,

        [Parameter()]
        [switch]$Overwrite
    )

    begin {
        if (-not (Test-FFmpegInstalled)) {
            throw "FFmpeg is not installed. Please install FFmpeg from https://ffmpeg.org/"
        }
    }

    process {
        try {
            $ResolvedInput = Resolve-Path -Path $InputPath -ErrorAction Stop

            # Check if output exists
            if ((Test-Path $OutputPath) -and -not $Overwrite -and -not $PSCmdlet.ShouldProcess($OutputPath, "Overwrite existing file")) {
                Write-Warning "Output file already exists: $OutputPath. Use -Overwrite to replace it."
                return
            }

            Write-Verbose "Optimizing video: $ResolvedInput -> $OutputPath (Target: $OptimizationTarget)"

            # Get media info to inform optimization decisions
            $mediaInfo = Get-MediaInfo -Path $ResolvedInput
            Write-Verbose "Input video: $($mediaInfo.VideoWidth)x$($mediaInfo.VideoHeight), Duration: $($mediaInfo.Duration), Size: $([Math]::Round($mediaInfo.Size / 1MB, 2))MB"

            # Determine optimal settings based on target
            $settings = @{}

            switch ($OptimizationTarget) {
                'FileSize' {
                    $settings.VideoCodec = $VideoCodec ?? 'h265'
                    $settings.AudioCodec = $AudioCodec ?? 'opus'
                    $settings.VideoCRF = 28
                    $settings.AudioBitrate = '96k'
                    $settings.Preset = 'slow'
                    $settings.ScaleFilter = $null
                    Write-Verbose "FileSize optimization: Prioritizing compression"
                }

                'Quality' {
                    $settings.VideoCodec = $VideoCodec ?? 'h265'
                    $settings.AudioCodec = $AudioCodec ?? 'aac'
                    $settings.VideoCRF = 18
                    $settings.AudioBitrate = '256k'
                    $settings.Preset = 'slow'
                    $settings.ScaleFilter = $null
                    Write-Verbose "Quality optimization: Prioritizing visual quality"
                }

                'WebStreaming' {
                    $settings.VideoCodec = $VideoCodec ?? 'h264'
                    $settings.AudioCodec = $AudioCodec ?? 'aac'
                    $settings.VideoCRF = 23
                    $settings.AudioBitrate = '128k'
                    $settings.Preset = 'medium'
                    $settings.FastStart = $true
                    # Scale down if larger than 1080p
                    if ($mediaInfo.VideoHeight -gt 1080) {
                        $settings.ScaleFilter = 'scale=-2:1080'
                    }
                    Write-Verbose "WebStreaming optimization: H.264 with fast start"
                }

                'Mobile' {
                    $settings.VideoCodec = $VideoCodec ?? 'h264'
                    $settings.AudioCodec = $AudioCodec ?? 'aac'
                    $settings.VideoCRF = 26
                    $settings.AudioBitrate = '128k'
                    $settings.Preset = 'medium'
                    $settings.Profile = 'baseline'
                    $settings.Level = '3.0'
                    # Scale down to 720p max for mobile
                    if ($mediaInfo.VideoHeight -gt 720) {
                        $settings.ScaleFilter = 'scale=-2:720'
                    }
                    Write-Verbose "Mobile optimization: Compatible H.264 baseline profile"
                }

                'Balanced' {
                    $settings.VideoCodec = $VideoCodec ?? 'h264'
                    $settings.AudioCodec = $AudioCodec ?? 'aac'
                    $settings.VideoCRF = 23
                    $settings.AudioBitrate = '192k'
                    $settings.Preset = 'medium'
                    $settings.ScaleFilter = $null
                    Write-Verbose "Balanced optimization: Good quality and size balance"
                }
            }

            # Calculate bitrates if target size specified
            if ($TargetSize) {
                $durationSeconds = $mediaInfo.DurationSeconds
                $targetBitsTotal = ($TargetSize * 8 * 1024 * 1024) / $durationSeconds
                $audioBitrate = [int]($settings.AudioBitrate -replace '\D')
                $videoBitrate = [int]($targetBitsTotal - ($audioBitrate * 1000))

                Write-Verbose "Target size: ${TargetSize}MB, Calculated video bitrate: ${videoBitrate}bps"

                $settings.VideoBitrate = "${videoBitrate}"
                $settings.Remove('VideoCRF')  # Use bitrate instead of CRF
            }

            # Build codec name
            $codecName = switch ($settings.VideoCodec) {
                'h264' {
                    if ($HardwareAcceleration) {
                        "${_}_$HardwareAcceleration"
                    }
                    else { 'libx264' }
                }
                { $_ -in @('h265', 'hevc') } {
                    if ($HardwareAcceleration) {
                        "hevc_$HardwareAcceleration"
                    }
                    else { 'libx265' }
                }
                'vp9' { 'libvpx-vp9' }
                'av1' { 'libaom-av1' }
            }

            # Build FFmpeg arguments
            $ffmpegArgs = @('-i', $ResolvedInput)

            # Add filters
            $filters = @()
            if ($settings.ScaleFilter) {
                $filters += $settings.ScaleFilter
            }

            if ($filters.Count -gt 0) {
                $ffmpegArgs += @('-vf', ($filters -join ','))
            }

            # Add video codec
            $ffmpegArgs += @('-c:v', $codecName)

            # Add CRF or bitrate
            if ($settings.VideoCRF) {
                $ffmpegArgs += @('-crf', [string]$settings.VideoCRF)
            }
            elseif ($settings.VideoBitrate) {
                $ffmpegArgs += @('-b:v', $settings.VideoBitrate)
            }

            # Add preset
            if ($codecName -match 'x264|x265|nvenc') {
                $ffmpegArgs += @('-preset', $settings.Preset)
            }

            # Add profile/level for mobile
            if ($settings.Profile) {
                $ffmpegArgs += @('-profile:v', $settings.Profile)
            }
            if ($settings.Level) {
                $ffmpegArgs += @('-level', $settings.Level)
            }

            # Add audio codec and bitrate
            $ffmpegArgs += @('-c:a', $settings.AudioCodec, '-b:a', $settings.AudioBitrate)

            # Add fast start for web
            if ($settings.FastStart) {
                $ffmpegArgs += @('-movflags', '+faststart')
            }

            # Add pixel format for compatibility
            $ffmpegArgs += @('-pix_fmt', 'yuv420p')

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Optimize video")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg optimization failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Video optimized successfully"

                # Show size comparison
                $outputFile = Get-Item -Path $OutputPath
                $inputSize = $mediaInfo.Size / 1MB
                $outputSize = $outputFile.Length / 1MB
                $reduction = [Math]::Round((($inputSize - $outputSize) / $inputSize) * 100, 2)

                Write-Verbose "Size reduction: $([Math]::Round($inputSize, 2))MB -> $([Math]::Round($outputSize, 2))MB ($reduction% smaller)"

                # Return the output file
                return $outputFile
            }
        }
        catch {
            Write-Error "Failed to optimize video '$InputPath': $_"
        }
    }
}
