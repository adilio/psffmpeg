function Convert-Media {
    <#
    .SYNOPSIS
        Converts a media file to a different format or codec.

    .DESCRIPTION
        Converts video and audio files between different formats and codecs using FFmpeg.
        Supports quality control, bitrate settings, and custom FFmpeg arguments.

    .PARAMETER InputPath
        The path to the input media file.

    .PARAMETER OutputPath
        The path for the output file. The extension determines the output format.

    .PARAMETER VideoCodec
        The video codec to use (e.g., 'h264', 'hevc', 'vp9', 'copy'). Use 'copy' to copy without re-encoding.

    .PARAMETER AudioCodec
        The audio codec to use (e.g., 'aac', 'mp3', 'opus', 'copy'). Use 'copy' to copy without re-encoding.

    .PARAMETER VideoBitrate
        The video bitrate (e.g., '2M', '5000k').

    .PARAMETER AudioBitrate
        The audio bitrate (e.g., '192k', '320k').

    .PARAMETER Quality
        Preset quality level: 'low', 'medium', 'high', or 'ultra'. Overrides codec-specific settings.

    .PARAMETER Preset
        FFmpeg encoding preset: 'ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow'.

    .PARAMETER AdditionalArguments
        Additional FFmpeg arguments as a string array.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Convert-Media -InputPath "video.avi" -OutputPath "video.mp4"
        Converts AVI to MP4 using default settings

    .EXAMPLE
        Convert-Media -InputPath "video.mp4" -OutputPath "video.webm" -VideoCodec vp9 -AudioCodec opus -Quality high
        Converts to WebM with VP9 video and Opus audio at high quality

    .EXAMPLE
        Convert-Media -InputPath "video.mp4" -OutputPath "output.mp4" -VideoBitrate "5M" -AudioBitrate "320k"
        Converts with specific bitrates
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Input file not found: $_"
            }
            return $true
        })]
        [Alias('FullName')]
        [string]$InputPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter()]
        [ValidateSet('h264', 'h265', 'hevc', 'vp8', 'vp9', 'av1', 'mpeg4', 'copy', 'libx264', 'libx265', 'libvpx', 'libvpx-vp9', 'libaom-av1')]
        [string]$VideoCodec,

        [Parameter()]
        [ValidateSet('aac', 'mp3', 'opus', 'vorbis', 'flac', 'ac3', 'copy', 'libmp3lame', 'libopus', 'libvorbis')]
        [string]$AudioCodec,

        [Parameter()]
        [string]$VideoBitrate,

        [Parameter()]
        [string]$AudioBitrate,

        [Parameter()]
        [ValidateSet('low', 'medium', 'high', 'ultra')]
        [string]$Quality,

        [Parameter()]
        [ValidateSet('ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow')]
        [string]$Preset = 'medium',

        [Parameter()]
        [string[]]$AdditionalArguments,

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

            Write-Verbose "Converting: $ResolvedInput -> $OutputPath"

            # Build FFmpeg arguments
            $ffmpegArgs = @('-i', $ResolvedInput)

            # Apply quality presets if specified
            if ($Quality) {
                switch ($Quality) {
                    'low' {
                        if (-not $VideoBitrate) { $VideoBitrate = '1M' }
                        if (-not $AudioBitrate) { $AudioBitrate = '128k' }
                    }
                    'medium' {
                        if (-not $VideoBitrate) { $VideoBitrate = '2.5M' }
                        if (-not $AudioBitrate) { $AudioBitrate = '192k' }
                    }
                    'high' {
                        if (-not $VideoBitrate) { $VideoBitrate = '5M' }
                        if (-not $AudioBitrate) { $AudioBitrate = '256k' }
                    }
                    'ultra' {
                        if (-not $VideoBitrate) { $VideoBitrate = '10M' }
                        if (-not $AudioBitrate) { $AudioBitrate = '320k' }
                    }
                }
            }

            # Add video codec
            if ($VideoCodec) {
                $ffmpegArgs += @('-c:v', $VideoCodec)

                # Add preset for applicable codecs
                if ($VideoCodec -in @('h264', 'h265', 'hevc', 'libx264', 'libx265') -and $VideoCodec -ne 'copy') {
                    $ffmpegArgs += @('-preset', $Preset)
                }
            }

            # Add video bitrate
            if ($VideoBitrate -and $VideoCodec -ne 'copy') {
                $ffmpegArgs += @('-b:v', $VideoBitrate)
            }

            # Add audio codec
            if ($AudioCodec) {
                $ffmpegArgs += @('-c:a', $AudioCodec)
            }

            # Add audio bitrate
            if ($AudioBitrate -and $AudioCodec -ne 'copy') {
                $ffmpegArgs += @('-b:a', $AudioBitrate)
            }

            # Add additional arguments
            if ($AdditionalArguments) {
                $ffmpegArgs += $AdditionalArguments
            }

            # Add overwrite flag and output path
            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }
            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Convert media file")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg conversion failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Conversion completed successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to convert media file '$InputPath': $_"
        }
    }
}
