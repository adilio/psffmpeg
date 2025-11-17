function New-VideoFromImages {
    <#
    .SYNOPSIS
        Creates a video from a sequence of images.

    .DESCRIPTION
        Generates a video file from a directory of images or a specified image sequence.
        Supports various image formats and allows control over frame rate, codec, and quality.

    .PARAMETER ImagePattern
        The pattern matching the images (e.g., 'image_%03d.png', '*.jpg'). Can use FFmpeg pattern syntax.

    .PARAMETER ImageDirectory
        The directory containing the images. Defaults to current directory.

    .PARAMETER OutputPath
        The path for the output video file.

    .PARAMETER FrameRate
        The frame rate for the output video. Default is 25 fps.

    .PARAMETER VideoCodec
        The video codec to use (e.g., 'h264', 'hevc', 'vp9'). Default is 'h264'.

    .PARAMETER Quality
        Quality preset: 'low', 'medium', 'high', 'ultra'. Default is 'high'.

    .PARAMETER Preset
        FFmpeg encoding preset. Default is 'medium'.

    .PARAMETER Resolution
        Force specific resolution (e.g., '1920x1080'). If not specified, uses image dimensions.

    .PARAMETER Duration
        Total duration of the video in seconds. Overrides FrameRate calculation.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        New-VideoFromImages -ImagePattern "frame_%04d.png" -OutputPath "output.mp4"
        Creates video from sequentially numbered PNG files

    .EXAMPLE
        New-VideoFromImages -ImageDirectory "C:\Images" -ImagePattern "*.jpg" -OutputPath "slideshow.mp4" -FrameRate 2
        Creates a 2 fps slideshow from all JPG files

    .EXAMPLE
        New-VideoFromImages -ImagePattern "img*.png" -OutputPath "video.mp4" -VideoCodec hevc -Quality ultra
        Creates high-quality HEVC video from PNG images

    .NOTES
        Author: PSFFmpeg Contributors
        Name: New-VideoFromImages
        Version: 1.0.0
        Requires: FFmpeg

    .LINK
        https://github.com/adilio/psffmpeg

    .LINK
        New-VideoThumbnail

    .LINK
        Convert-Media

    .LINK
        https://ffmpeg.org/
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ImagePattern,

        [Parameter()]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Container)) {
                throw "Directory not found: $_"
            }
            return $true
        })]
        [string]$ImageDirectory = (Get-Location).Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [ValidateRange(1, 120)]
        [int]$FrameRate = 25,

        [Parameter()]
        [ValidateSet('h264', 'h265', 'hevc', 'vp8', 'vp9', 'av1', 'mpeg4')]
        [string]$VideoCodec = 'h264',

        [Parameter()]
        [ValidateSet('low', 'medium', 'high', 'ultra')]
        [string]$Quality = 'high',

        [Parameter()]
        [ValidateSet('ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow')]
        [string]$Preset = 'medium',

        [Parameter()]
        [ValidatePattern('^\d+x\d+$')]
        [string]$Resolution,

        [Parameter()]
        [ValidateRange(0.1, 3600)]
        [double]$Duration,

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
            # Check if output exists
            if ((Test-Path $OutputPath) -and -not $Overwrite -and -not $PSCmdlet.ShouldProcess($OutputPath, "Overwrite existing file")) {
                Write-Warning "Output file already exists: $OutputPath. Use -Overwrite to replace it."
                return
            }

            $ResolvedDir = Resolve-Path -Path $ImageDirectory

            # Determine codec name
            $codecName = switch ($VideoCodec) {
                'h264' { 'libx264' }
                { $_ -in @('h265', 'hevc') } { 'libx265' }
                'vp8' { 'libvpx' }
                'vp9' { 'libvpx-vp9' }
                'av1' { 'libaom-av1' }
                'mpeg4' { 'mpeg4' }
            }

            # Set CRF based on quality
            $crf = switch ($Quality) {
                'low' { 28 }
                'medium' { 23 }
                'high' { 18 }
                'ultra' { 15 }
            }

            Write-Verbose "Creating video from images: Pattern=$ImagePattern, Output=$OutputPath, FPS=$FrameRate"

            # Construct input pattern
            if ($ImagePattern -match '%\d*d') {
                # Sequential pattern (e.g., image_%03d.png)
                $inputPattern = $ImagePattern
            }
            elseif ($ImagePattern -match '\*') {
                # Glob pattern - use image2 with glob
                $inputPattern = Join-Path $ResolvedDir $ImagePattern
            }
            else {
                # Assume sequential pattern
                $inputPattern = $ImagePattern
            }

            # Build FFmpeg arguments
            $ffmpegArgs = @(
                '-framerate', [string]$FrameRate
            )

            # Add pattern or glob
            if ($ImagePattern -match '\*') {
                $ffmpegArgs += @('-pattern_type', 'glob', '-i', $inputPattern)
            }
            else {
                Push-Location $ResolvedDir
                try {
                    $ffmpegArgs += @('-i', $inputPattern)
                }
                finally {
                    Pop-Location
                }
            }

            # Add video codec
            $ffmpegArgs += @('-c:v', $codecName)

            # Add CRF
            $ffmpegArgs += @('-crf', [string]$crf)

            # Add preset
            if ($codecName -match 'x264|x265') {
                $ffmpegArgs += @('-preset', $Preset)
            }

            # Add pixel format for compatibility
            $ffmpegArgs += @('-pix_fmt', 'yuv420p')

            # Add resolution if specified
            if ($Resolution) {
                $ffmpegArgs += @('-s', $Resolution)
            }

            # Add duration if specified
            if ($Duration) {
                $ffmpegArgs += @('-t', [string]$Duration)
            }

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Create video from images")) {
                # Change to image directory if using non-glob pattern
                if ($ImagePattern -notmatch '\*') {
                    Push-Location $ResolvedDir
                }

                try {
                    # Execute FFmpeg
                    $output = & ffmpeg @ffmpegArgs 2>&1

                    if ($LASTEXITCODE -ne 0) {
                        throw "FFmpeg video creation failed with exit code $LASTEXITCODE. Output: $output"
                    }

                    Write-Verbose "Video created successfully from images"

                    # Return the output file
                    Get-Item -Path $OutputPath
                }
                finally {
                    if ($ImagePattern -notmatch '\*') {
                        Pop-Location
                    }
                }
            }
        }
        catch {
            Write-Error "Failed to create video from images: $_"
        }
    }
}
