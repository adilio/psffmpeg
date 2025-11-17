function Convert-VideoCodec {
    <#
    .SYNOPSIS
        Converts a video to a different codec while keeping the same container.

    .DESCRIPTION
        Transcodes video to a different codec with control over encoding parameters.
        Useful for compatibility, compression, or quality improvements.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputPath
        The path for the output video file.

    .PARAMETER Codec
        The target video codec (e.g., 'h264', 'hevc', 'vp9', 'av1').

    .PARAMETER CRF
        Constant Rate Factor (0-51 for h264/hevc, 0-63 for vp9). Lower values mean better quality.
        Default: 23 for h264/hevc, 31 for vp9.

    .PARAMETER Preset
        Encoding preset: 'ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow'.

    .PARAMETER HardwareAcceleration
        Use hardware acceleration: 'nvenc' (NVIDIA), 'qsv' (Intel), 'vaapi' (Linux), 'videotoolbox' (macOS).

    .PARAMETER AudioCodec
        Audio codec to use (default: copy). Use 'copy' to keep original audio.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Convert-VideoCodec -InputPath "video.mp4" -OutputPath "video_h265.mp4" -Codec hevc
        Converts video to H.265/HEVC codec

    .EXAMPLE
        Convert-VideoCodec -InputPath "video.mp4" -OutputPath "video_vp9.webm" -Codec vp9 -CRF 30
        Converts to VP9 codec with CRF 30

    .EXAMPLE
        Convert-VideoCodec -InputPath "video.mp4" -OutputPath "output.mp4" -Codec h264 -HardwareAcceleration nvenc
        Uses NVIDIA hardware acceleration for H.264 encoding
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('h264', 'h265', 'hevc', 'vp8', 'vp9', 'av1', 'mpeg4')]
        [string]$Codec,

        [Parameter()]
        [int]$CRF,

        [Parameter()]
        [ValidateSet('ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow')]
        [string]$Preset = 'medium',

        [Parameter()]
        [ValidateSet('nvenc', 'qsv', 'vaapi', 'videotoolbox')]
        [string]$HardwareAcceleration,

        [Parameter()]
        [ValidateSet('copy', 'aac', 'mp3', 'opus', 'vorbis')]
        [string]$AudioCodec = 'copy',

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

            Write-Verbose "Converting codec: $ResolvedInput -> $OutputPath (Codec: $Codec)"

            # Determine the actual codec name to use
            $codecName = switch ($Codec) {
                'h264' {
                    if ($HardwareAcceleration) {
                        switch ($HardwareAcceleration) {
                            'nvenc' { 'h264_nvenc' }
                            'qsv' { 'h264_qsv' }
                            'vaapi' { 'h264_vaapi' }
                            'videotoolbox' { 'h264_videotoolbox' }
                        }
                    }
                    else { 'libx264' }
                }
                { $_ -in @('h265', 'hevc') } {
                    if ($HardwareAcceleration) {
                        switch ($HardwareAcceleration) {
                            'nvenc' { 'hevc_nvenc' }
                            'qsv' { 'hevc_qsv' }
                            'vaapi' { 'hevc_vaapi' }
                            'videotoolbox' { 'hevc_videotoolbox' }
                        }
                    }
                    else { 'libx265' }
                }
                'vp8' { 'libvpx' }
                'vp9' { 'libvpx-vp9' }
                'av1' { 'libaom-av1' }
                'mpeg4' { 'mpeg4' }
            }

            # Set default CRF if not specified
            if (-not $CRF) {
                $CRF = switch ($Codec) {
                    { $_ -in @('h264', 'h265', 'hevc') } { 23 }
                    'vp9' { 31 }
                    'av1' { 30 }
                    default { 23 }
                }
            }

            Write-Verbose "Using codec: $codecName, CRF: $CRF, Preset: $Preset"

            # Build FFmpeg arguments
            $ffmpegArgs = @('-i', $ResolvedInput)

            # Add video codec
            $ffmpegArgs += @('-c:v', $codecName)

            # Add CRF
            $ffmpegArgs += @('-crf', [string]$CRF)

            # Add preset (if applicable)
            if ($codecName -match 'x264|x265|nvenc|qsv') {
                $ffmpegArgs += @('-preset', $Preset)
            }

            # Add audio codec
            $ffmpegArgs += @('-c:a', $AudioCodec)

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Convert video codec")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg codec conversion failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Codec conversion completed successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to convert video codec for '$InputPath': $_"
        }
    }
}
