function Split-Video {
    <#
    .SYNOPSIS
        Splits a video into multiple segments.

    .DESCRIPTION
        Divides a video file into multiple parts based on duration, number of segments, or custom time ranges.
        Useful for creating clips, dividing long videos, or processing video in chunks.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputDirectory
        The directory where split video files will be saved. Defaults to input file directory.

    .PARAMETER OutputPrefix
        The prefix for output files. Default is the input filename.

    .PARAMETER SegmentDuration
        Duration of each segment in seconds.

    .PARAMETER SegmentCount
        Number of equal segments to split the video into.

    .PARAMETER TimeRanges
        Array of custom time ranges in format 'StartTime-EndTime' (e.g., '00:00:00-00:05:00', '5:00-10:00').

    .PARAMETER FastSplit
        Uses stream copy for fast splitting (no re-encoding). May be less accurate at boundaries.

    .PARAMETER Overwrite
        Overwrites output files if they exist without prompting.

    .OUTPUTS
        System.IO.FileInfo[]
        Returns array of created video segment files.

    .EXAMPLE
        Split-Video -InputPath "movie.mp4" -SegmentDuration 300
        Splits video into 5-minute (300 second) segments

    .EXAMPLE
        Split-Video -InputPath "video.mp4" -SegmentCount 4 -FastSplit
        Splits video into 4 equal parts using fast stream copy

    .EXAMPLE
        Split-Video -InputPath "video.mp4" -TimeRanges "0-60", "60-120", "120-180"
        Splits video at specific time ranges

    .EXAMPLE
        Split-Video -InputPath "lecture.mp4" -SegmentDuration 600 -OutputDirectory "C:\Clips" -OutputPrefix "Lecture_Part"
        Splits into 10-minute segments with custom output location and naming

    .NOTES
        Author: PSFFmpeg Contributors
        Name: Split-Video
        Version: 1.0.0
        Requires: FFmpeg

    .LINK
        https://github.com/adilio/psffmpeg

    .LINK
        Edit-Video

    .LINK
        Merge-Video

    .LINK
        https://ffmpeg.org/
    #>
    [CmdletBinding(DefaultParameterSetName = 'Duration', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.IO.FileInfo[]])]
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

        [Parameter()]
        [string]$OutputDirectory,

        [Parameter()]
        [string]$OutputPrefix,

        [Parameter(ParameterSetName = 'Duration', Mandatory = $true)]
        [ValidateRange(1, 36000)]
        [int]$SegmentDuration,

        [Parameter(ParameterSetName = 'Count', Mandatory = $true)]
        [ValidateRange(2, 100)]
        [int]$SegmentCount,

        [Parameter(ParameterSetName = 'CustomRanges', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$TimeRanges,

        [Parameter()]
        [switch]$FastSplit,

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
            $inputFile = Get-Item $ResolvedInput

            # Set output directory
            if (-not $OutputDirectory) {
                $OutputDirectory = $inputFile.DirectoryName
            }
            else {
                if (-not (Test-Path $OutputDirectory)) {
                    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
                }
                $OutputDirectory = Resolve-Path $OutputDirectory
            }

            # Set output prefix
            if (-not $OutputPrefix) {
                $OutputPrefix = $inputFile.BaseName
            }

            Write-Verbose "Splitting video: $ResolvedInput"

            # Get media info to determine duration
            $mediaInfo = Get-MediaInfo -Path $ResolvedInput
            $totalDuration = $mediaInfo.DurationSeconds

            # Generate split segments based on method
            $segments = @()

            switch ($PSCmdlet.ParameterSetName) {
                'Duration' {
                    $segmentNum = 0
                    $currentTime = 0

                    while ($currentTime -lt $totalDuration) {
                        $segmentNum++
                        $duration = [Math]::Min($SegmentDuration, $totalDuration - $currentTime)

                        $segments += [PSCustomObject]@{
                            Number = $segmentNum
                            StartTime = $currentTime
                            Duration = $duration
                            OutputPath = Join-Path $OutputDirectory "${OutputPrefix}_Part${segmentNum}$($inputFile.Extension)"
                        }

                        $currentTime += $SegmentDuration
                    }
                }

                'Count' {
                    $segmentDuration = $totalDuration / $SegmentCount

                    for ($i = 0; $i -lt $SegmentCount; $i++) {
                        $startTime = $i * $segmentDuration
                        $duration = if ($i -eq ($SegmentCount - 1)) {
                            $totalDuration - $startTime
                        }
                        else {
                            $segmentDuration
                        }

                        $segments += [PSCustomObject]@{
                            Number = $i + 1
                            StartTime = $startTime
                            Duration = $duration
                            OutputPath = Join-Path $OutputDirectory "${OutputPrefix}_Part$($i + 1)$($inputFile.Extension)"
                        }
                    }
                }

                'CustomRanges' {
                    for ($i = 0; $i -lt $TimeRanges.Count; $i++) {
                        $range = $TimeRanges[$i]

                        if ($range -match '^(.+)-(.+)$') {
                            $startTime = $Matches[1]
                            $endTime = $Matches[2]

                            # Convert to seconds
                            $startSeconds = if ($startTime -match '^\d+$') {
                                [double]$startTime
                            }
                            elseif ($startTime -match '^(\d+):(\d+)$') {
                                [double]$Matches[1] * 60 + [double]$Matches[2]
                            }
                            elseif ($startTime -match '^(\d+):(\d+):(\d+)$') {
                                [double]$Matches[1] * 3600 + [double]$Matches[2] * 60 + [double]$Matches[3]
                            }
                            else {
                                throw "Invalid start time format in range: $range"
                            }

                            $endSeconds = if ($endTime -match '^\d+$') {
                                [double]$endTime
                            }
                            elseif ($endTime -match '^(\d+):(\d+)$') {
                                [double]$Matches[1] * 60 + [double]$Matches[2]
                            }
                            elseif ($endTime -match '^(\d+):(\d+):(\d+)$') {
                                [double]$Matches[1] * 3600 + [double]$Matches[2] * 60 + [double]$Matches[3]
                            }
                            else {
                                throw "Invalid end time format in range: $range"
                            }

                            $duration = $endSeconds - $startSeconds

                            $segments += [PSCustomObject]@{
                                Number = $i + 1
                                StartTime = $startSeconds
                                Duration = $duration
                                OutputPath = Join-Path $OutputDirectory "${OutputPrefix}_Part$($i + 1)$($inputFile.Extension)"
                            }
                        }
                        else {
                            throw "Invalid time range format: $range. Use 'StartTime-EndTime' format."
                        }
                    }
                }
            }

            Write-Verbose "Will create $($segments.Count) segments"

            # Process each segment
            $outputFiles = @()

            foreach ($segment in $segments) {
                # Check if output exists
                if ((Test-Path $segment.OutputPath) -and -not $Overwrite) {
                    Write-Warning "Segment file already exists: $($segment.OutputPath). Use -Overwrite to replace it."
                    continue
                }

                Write-Verbose "Creating segment $($segment.Number): Start=$($segment.StartTime)s, Duration=$($segment.Duration)s"

                # Build FFmpeg arguments
                $ffmpegArgs = @(
                    '-ss', [string]$segment.StartTime,
                    '-i', $ResolvedInput,
                    '-t', [string]$segment.Duration
                )

                if ($FastSplit) {
                    $ffmpegArgs += @('-c', 'copy')
                }

                if ($Overwrite) {
                    $ffmpegArgs += '-y'
                }

                $ffmpegArgs += $segment.OutputPath

                Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

                if ($PSCmdlet.ShouldProcess($segment.OutputPath, "Create video segment $($segment.Number)")) {
                    # Execute FFmpeg
                    $output = & ffmpeg @ffmpegArgs 2>&1

                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "FFmpeg failed to create segment $($segment.Number). Output: $output"
                        continue
                    }

                    $outputFiles += Get-Item -Path $segment.OutputPath
                }
            }

            Write-Verbose "Video split completed. Created $($outputFiles.Count) segments."

            return $outputFiles
        }
        catch {
            Write-Error "Failed to split video '$InputPath': $_"
        }
    }
}
