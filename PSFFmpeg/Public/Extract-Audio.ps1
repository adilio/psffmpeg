function Extract-Audio {
    <#
    .SYNOPSIS
        Extracts audio from a video file.

    .DESCRIPTION
        Extracts the audio stream from a video file and saves it as an audio file.
        Supports various audio formats and quality settings.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputPath
        The path for the output audio file. The extension determines the audio format.

    .PARAMETER AudioCodec
        The audio codec to use (e.g., 'mp3', 'aac', 'opus', 'flac', 'copy'). Use 'copy' to copy without re-encoding.

    .PARAMETER AudioBitrate
        The audio bitrate (e.g., '192k', '320k'). Not used with 'copy' codec.

    .PARAMETER AudioQuality
        Quality preset: 'low' (128k), 'medium' (192k), 'high' (256k), 'ultra' (320k).

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3"
        Extracts audio to MP3 format with default settings

    .EXAMPLE
        Extract-Audio -InputPath "video.mp4" -OutputPath "audio.flac" -AudioCodec flac
        Extracts audio to lossless FLAC format

    .EXAMPLE
        Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3" -AudioQuality ultra
        Extracts audio to MP3 at 320k bitrate
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
        [ValidateSet('mp3', 'aac', 'opus', 'vorbis', 'flac', 'wav', 'ac3', 'copy', 'libmp3lame', 'libopus', 'libvorbis')]
        [string]$AudioCodec,

        [Parameter()]
        [string]$AudioBitrate,

        [Parameter()]
        [ValidateSet('low', 'medium', 'high', 'ultra')]
        [string]$AudioQuality,

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

            Write-Verbose "Extracting audio: $ResolvedInput -> $OutputPath"

            # Apply quality presets if specified
            if ($AudioQuality -and -not $AudioBitrate) {
                switch ($AudioQuality) {
                    'low'    { $AudioBitrate = '128k' }
                    'medium' { $AudioBitrate = '192k' }
                    'high'   { $AudioBitrate = '256k' }
                    'ultra'  { $AudioBitrate = '320k' }
                }
            }

            # Build FFmpeg arguments
            $ffmpegArgs = @(
                '-i', $ResolvedInput,
                '-vn'  # No video
            )

            # Add audio codec
            if ($AudioCodec) {
                $ffmpegArgs += @('-c:a', $AudioCodec)
            }

            # Add audio bitrate (not for copy or lossless codecs)
            if ($AudioBitrate -and $AudioCodec -notin @('copy', 'flac', 'wav')) {
                $ffmpegArgs += @('-b:a', $AudioBitrate)
            }

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Extract audio")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg audio extraction failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Audio extraction completed successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to extract audio from '$InputPath': $_"
        }
    }
}
