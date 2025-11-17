function Add-AudioToVideo {
    <#
    .SYNOPSIS
        Adds or replaces audio in a video file.

    .DESCRIPTION
        Combines a video file with an audio file. Can replace existing audio or add audio to
        a silent video. Supports mixing multiple audio tracks and controlling audio levels.

    .PARAMETER VideoPath
        The path to the input video file.

    .PARAMETER AudioPath
        The path to the audio file to add.

    .PARAMETER OutputPath
        The path for the output video file.

    .PARAMETER ReplaceAudio
        Replaces the existing audio instead of mixing with it.

    .PARAMETER AudioVolume
        Audio volume adjustment in dB (e.g., '5' to increase, '-5' to decrease).

    .PARAMETER VideoVolume
        Original video audio volume in dB. Only used when mixing (not replacing).

    .PARAMETER Shortest
        End output when the shortest input ends (video or audio).

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "music.mp3" -OutputPath "output.mp4" -ReplaceAudio
        Replaces video's audio with music.mp3

    .EXAMPLE
        Add-AudioToVideo -VideoPath "video.mp4" -AudioPath "narration.mp3" -OutputPath "output.mp4" -AudioVolume 2 -VideoVolume -3
        Mixes narration with original audio, boosting narration by 2dB and reducing original by 3dB

    .EXAMPLE
        Add-AudioToVideo -VideoPath "silent.mp4" -AudioPath "soundtrack.mp3" -OutputPath "output.mp4" -Shortest
        Adds audio to silent video, ending when the shorter stream ends
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Video file not found: $_"
            }
            return $true
        })]
        [string]$VideoPath,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "Audio file not found: $_"
            }
            return $true
        })]
        [string]$AudioPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter()]
        [switch]$ReplaceAudio,

        [Parameter()]
        [double]$AudioVolume,

        [Parameter()]
        [double]$VideoVolume,

        [Parameter()]
        [switch]$Shortest,

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
            $ResolvedAudio = Resolve-Path -Path $AudioPath -ErrorAction Stop

            # Check if output exists
            if ((Test-Path $OutputPath) -and -not $Overwrite -and -not $PSCmdlet.ShouldProcess($OutputPath, "Overwrite existing file")) {
                Write-Warning "Output file already exists: $OutputPath. Use -Overwrite to replace it."
                return
            }

            Write-Verbose "Adding audio: Video=$ResolvedVideo, Audio=$ResolvedAudio -> $OutputPath"

            # Build FFmpeg arguments
            $ffmpegArgs = @(
                '-i', $ResolvedVideo,
                '-i', $ResolvedAudio
            )

            if ($ReplaceAudio) {
                # Replace audio: take video from first input, audio from second
                Write-Verbose "Replacing audio"

                # Apply volume adjustment if specified
                if ($AudioVolume) {
                    $ffmpegArgs += @(
                        '-filter:a', "volume=${AudioVolume}dB",
                        '-map', '0:v',
                        '-map', '1:a'
                    )
                }
                else {
                    $ffmpegArgs += @(
                        '-map', '0:v',
                        '-map', '1:a'
                    )
                }

                $ffmpegArgs += @('-c:v', 'copy')
            }
            else {
                # Mix audio tracks
                Write-Verbose "Mixing audio tracks"

                $filterParts = @()

                # Build audio filters
                if ($VideoVolume) {
                    $filterParts += "[0:a]volume=${VideoVolume}dB[a0]"
                }
                else {
                    $filterParts += "[0:a]anull[a0]"
                }

                if ($AudioVolume) {
                    $filterParts += "[1:a]volume=${AudioVolume}dB[a1]"
                }
                else {
                    $filterParts += "[1:a]anull[a1]"
                }

                $filterParts += "[a0][a1]amix=inputs=2:duration=longest[aout]"

                $filterComplex = $filterParts -join ';'

                $ffmpegArgs += @(
                    '-filter_complex', $filterComplex,
                    '-map', '0:v',
                    '-map', '[aout]',
                    '-c:v', 'copy'
                )
            }

            # Add shortest flag if specified
            if ($Shortest) {
                $ffmpegArgs += '-shortest'
            }

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Add audio to video")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg audio addition failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Audio addition completed successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to add audio to video: $_"
        }
    }
}
