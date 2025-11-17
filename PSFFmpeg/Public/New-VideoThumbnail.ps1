function New-VideoThumbnail {
    <#
    .SYNOPSIS
        Generates a thumbnail image from a video.

    .DESCRIPTION
        Extracts a frame from a video at a specified time and saves it as an image.
        Supports various image formats and quality settings.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputPath
        The path for the output thumbnail image.

    .PARAMETER Time
        The time in the video to capture (e.g., '00:01:30', '90'). Defaults to middle of video.

    .PARAMETER Width
        The thumbnail width in pixels. Use -1 to maintain aspect ratio.

    .PARAMETER Height
        The thumbnail height in pixels. Use -1 to maintain aspect ratio.

    .PARAMETER Quality
        JPEG quality (1-31, lower is better quality). Only applies to JPEG output.

    .PARAMETER Format
        Output format: 'jpg', 'png', 'bmp', 'webp'. Auto-detected from OutputPath extension if not specified.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg"
        Creates a thumbnail from the middle of the video

    .EXAMPLE
        New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.png" -Time "00:01:30" -Width 320 -Height 240
        Creates a 320x240 thumbnail at 1 minute 30 seconds

    .EXAMPLE
        New-VideoThumbnail -InputPath "video.mp4" -OutputPath "thumb.jpg" -Time "60" -Quality 2
        Creates a high-quality thumbnail at 60 seconds
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
        [string]$Time,

        [Parameter()]
        [int]$Width = -1,

        [Parameter()]
        [int]$Height = -1,

        [Parameter()]
        [ValidateRange(1, 31)]
        [int]$Quality = 2,

        [Parameter()]
        [ValidateSet('jpg', 'jpeg', 'png', 'bmp', 'webp')]
        [string]$Format,

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

            # If no time specified, get middle of video
            if (-not $Time) {
                Write-Verbose "No time specified, extracting frame from middle of video"
                $mediaInfo = Get-MediaInfo -Path $ResolvedInput
                if ($mediaInfo -and $mediaInfo.DurationSeconds) {
                    $Time = [string]([math]::Floor($mediaInfo.DurationSeconds / 2))
                    Write-Verbose "Calculated middle time: $Time seconds"
                }
                else {
                    $Time = '0'
                    Write-Verbose "Could not determine duration, using first frame"
                }
            }

            Write-Verbose "Creating thumbnail: $ResolvedInput -> $OutputPath at time $Time"

            # Build FFmpeg arguments
            $ffmpegArgs = @(
                '-ss', $Time,
                '-i', $ResolvedInput,
                '-vframes', '1'
            )

            # Add scale filter if dimensions specified
            if ($Width -ne -1 -or $Height -ne -1) {
                $scaleFilter = "scale=${Width}:${Height}"
                $ffmpegArgs += @('-vf', $scaleFilter)
            }

            # Add quality setting for JPEG
            $outputExt = [System.IO.Path]::GetExtension($OutputPath).TrimStart('.').ToLower()
            if ($outputExt -in @('jpg', 'jpeg') -or $Format -in @('jpg', 'jpeg')) {
                $ffmpegArgs += @('-q:v', [string]$Quality)
            }

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Create video thumbnail")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg thumbnail generation failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Thumbnail created successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to create thumbnail from '$InputPath': $_"
        }
    }
}
