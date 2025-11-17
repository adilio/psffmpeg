function Edit-Video {
    <#
    .SYNOPSIS
        Trims or cuts a video to a specific duration or time range.

    .DESCRIPTION
        Extracts a portion of a video by specifying start time and duration or end time.
        Supports fast seeking and precise frame-accurate cutting.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputPath
        The path for the output video file.

    .PARAMETER StartTime
        The start time as a TimeSpan or string (e.g., '00:01:30', '90', '1:30').

    .PARAMETER Duration
        The duration to extract as a TimeSpan or string. Cannot be used with EndTime.

    .PARAMETER EndTime
        The end time as a TimeSpan or string. Cannot be used with Duration.

    .PARAMETER FastSeek
        Uses fast seeking (less accurate but much faster). Good for rough cuts.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "00:01:00" -Duration "00:00:30"
        Extracts 30 seconds starting at 1 minute

    .EXAMPLE
        Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "60" -EndTime "120"
        Extracts from second 60 to second 120

    .EXAMPLE
        Edit-Video -InputPath "video.mp4" -OutputPath "clip.mp4" -StartTime "10" -Duration "30" -FastSeek
        Fast extraction of 30 seconds starting at 10 seconds
    #>
    [CmdletBinding(DefaultParameterSetName = 'Duration', SupportsShouldProcess = $true)]
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
        [string]$StartTime,

        [Parameter(ParameterSetName = 'Duration')]
        [string]$Duration,

        [Parameter(ParameterSetName = 'EndTime')]
        [string]$EndTime,

        [Parameter()]
        [switch]$FastSeek,

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

            Write-Verbose "Editing video: $ResolvedInput -> $OutputPath"

            # Build FFmpeg arguments
            $ffmpegArgs = @()

            # Add start time (before or after input for fast/precise seeking)
            if ($FastSeek) {
                # Fast seek: -ss before -i (less accurate but faster)
                $ffmpegArgs += @('-ss', $StartTime, '-i', $ResolvedInput)
            }
            else {
                # Precise seek: -ss after -i (frame-accurate but slower)
                $ffmpegArgs += @('-i', $ResolvedInput, '-ss', $StartTime)
            }

            # Add duration or calculate from end time
            if ($Duration) {
                $ffmpegArgs += @('-t', $Duration)
            }
            elseif ($EndTime) {
                # Calculate duration from end time
                # Parse start and end times to calculate duration
                $startSeconds = if ($StartTime -match '^\d+$') {
                    [int]$StartTime
                }
                elseif ($StartTime -match '^(\d+):(\d+)$') {
                    [int]$Matches[1] * 60 + [int]$Matches[2]
                }
                elseif ($StartTime -match '^(\d+):(\d+):(\d+)$') {
                    [int]$Matches[1] * 3600 + [int]$Matches[2] * 60 + [int]$Matches[3]
                }
                else {
                    throw "Invalid StartTime format. Use seconds (e.g., '90') or HH:MM:SS format."
                }

                $endSeconds = if ($EndTime -match '^\d+$') {
                    [int]$EndTime
                }
                elseif ($EndTime -match '^(\d+):(\d+)$') {
                    [int]$Matches[1] * 60 + [int]$Matches[2]
                }
                elseif ($EndTime -match '^(\d+):(\d+):(\d+)$') {
                    [int]$Matches[1] * 3600 + [int]$Matches[2] * 60 + [int]$Matches[3]
                }
                else {
                    throw "Invalid EndTime format. Use seconds (e.g., '120') or HH:MM:SS format."
                }

                $durationSeconds = $endSeconds - $startSeconds
                if ($durationSeconds -le 0) {
                    throw "EndTime must be greater than StartTime"
                }

                $ffmpegArgs += @('-t', [string]$durationSeconds)
            }

            # Copy streams for fast processing
            $ffmpegArgs += @('-c', 'copy')

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Edit video")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg edit failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Video edit completed successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to edit video '$InputPath': $_"
        }
    }
}
