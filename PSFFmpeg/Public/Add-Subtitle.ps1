function Add-Subtitle {
    <#
    .SYNOPSIS
        Adds subtitles to a video file.

    .DESCRIPTION
        Embeds or burns-in subtitles to a video. Supports both soft subtitles (embedded as a stream)
        and hard subtitles (burned into the video). Supports SRT, ASS, SSA, and VTT subtitle formats.

    .PARAMETER VideoPath
        The path to the input video file.

    .PARAMETER SubtitlePath
        The path to the subtitle file (SRT, ASS, SSA, or VTT format).

    .PARAMETER OutputPath
        The path for the output video file.

    .PARAMETER BurnIn
        Burns the subtitles directly into the video (hard subtitles). Cannot be turned off by the player.

    .PARAMETER Language
        The language code for the subtitle track (e.g., 'eng', 'spa', 'fra'). Used for soft subtitles.

    .PARAMETER Title
        The title/name for the subtitle track. Used for soft subtitles.

    .PARAMETER SubtitleCodec
        The subtitle codec to use for soft subtitles. Default is 'mov_text' for MP4, 'srt' for others.

    .PARAMETER FontName
        Font name to use when burning in subtitles. Default is 'Arial'.

    .PARAMETER FontSize
        Font size for burned-in subtitles. Default is 24.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Add-Subtitle -VideoPath "movie.mp4" -SubtitlePath "movie.srt" -OutputPath "movie_subbed.mp4"
        Adds soft subtitles to the video

    .EXAMPLE
        Add-Subtitle -VideoPath "video.mp4" -SubtitlePath "subs.srt" -OutputPath "output.mp4" -BurnIn -FontSize 28
        Burns subtitles into the video with size 28 font

    .EXAMPLE
        Add-Subtitle -VideoPath "film.mkv" -SubtitlePath "english.srt" -OutputPath "film_eng.mkv" -Language "eng" -Title "English"
        Adds soft subtitles with language metadata

    .NOTES
        Author: PSFFmpeg Contributors
        Name: Add-Subtitle
        Version: 1.0.0
        Requires: FFmpeg

    .LINK
        https://github.com/adilio/psffmpeg

    .LINK
        Add-AudioToVideo

    .LINK
        Convert-Media

    .LINK
        https://ffmpeg.org/
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Video file not found: $_"
            }
            return $true
        })]
        [string]$VideoPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Subtitle file not found: $_"
            }
            return $true
        })]
        [string]$SubtitlePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [switch]$BurnIn,

        [Parameter()]
        [string]$Language,

        [Parameter()]
        [string]$Title,

        [Parameter()]
        [ValidateSet('mov_text', 'srt', 'ass', 'ssa', 'webvtt', 'subrip')]
        [string]$SubtitleCodec,

        [Parameter()]
        [string]$FontName = 'Arial',

        [Parameter()]
        [ValidateRange(6, 96)]
        [int]$FontSize = 24,

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
            $ResolvedVideo = Resolve-Path -Path $VideoPath -ErrorAction Stop
            $ResolvedSubtitle = Resolve-Path -Path $SubtitlePath -ErrorAction Stop

            # Check if output exists
            if ((Test-Path $OutputPath) -and -not $Overwrite -and -not $PSCmdlet.ShouldProcess($OutputPath, "Overwrite existing file")) {
                Write-Warning "Output file already exists: $OutputPath. Use -Overwrite to replace it."
                return
            }

            Write-Verbose "Adding subtitles: Video=$ResolvedVideo, Subtitle=$ResolvedSubtitle, BurnIn=$BurnIn"

            # Build FFmpeg arguments
            $ffmpegArgs = @(
                '-i', $ResolvedVideo,
                '-i', $ResolvedSubtitle
            )

            if ($BurnIn) {
                # Burn-in subtitles using subtitles filter
                Write-Verbose "Burning in subtitles with font=$FontName, size=$FontSize"

                # Escape the subtitle path for filter
                $escapedSubPath = $ResolvedSubtitle.Path.Replace('\', '/').Replace(':', '\\:')

                $subtitlesFilter = "subtitles='$escapedSubPath':force_style='FontName=$FontName,FontSize=$FontSize'"

                $ffmpegArgs += @(
                    '-vf', $subtitlesFilter,
                    '-c:v', 'libx264',
                    '-c:a', 'copy'
                )
            }
            else {
                # Soft subtitles (embedded as stream)
                Write-Verbose "Adding soft subtitles"

                # Determine subtitle codec if not specified
                if (-not $SubtitleCodec) {
                    $outputExt = [System.IO.Path]::GetExtension($OutputPath).ToLower()
                    $SubtitleCodec = if ($outputExt -eq '.mp4') { 'mov_text' } else { 'srt' }
                }

                $ffmpegArgs += @(
                    '-map', '0:v',
                    '-map', '0:a?',
                    '-map', '1:s',
                    '-c:v', 'copy',
                    '-c:a', 'copy',
                    '-c:s', $SubtitleCodec
                )

                # Add metadata if specified
                if ($Language) {
                    $ffmpegArgs += @('-metadata:s:s:0', "language=$Language")
                }

                if ($Title) {
                    $ffmpegArgs += @('-metadata:s:s:0', "title=$Title")
                }
            }

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Add subtitles to video")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg subtitle addition failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Subtitles added successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to add subtitles to video: $_"
        }
    }
}
