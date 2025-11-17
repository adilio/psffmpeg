function New-VideoGif {
    <#
    .SYNOPSIS
        Creates an animated GIF from a video file.

    .DESCRIPTION
        Converts a video or video segment into an animated GIF with control over quality, size,
        frame rate, and color palette. Optimizes output for file size while maintaining quality.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputPath
        The path for the output GIF file.

    .PARAMETER StartTime
        The start time in the video (e.g., '00:00:10', '10'). Default is start of video.

    .PARAMETER Duration
        The duration to convert to GIF in seconds. Default is 5 seconds.

    .PARAMETER Width
        The width in pixels. Use -1 to maintain aspect ratio. Default is 480.

    .PARAMETER Height
        The height in pixels. Use -1 to maintain aspect ratio.

    .PARAMETER FrameRate
        Frame rate for the GIF. Default is 10 fps. Lower values create smaller files.

    .PARAMETER Quality
        Quality preset: 'low' (fast, larger), 'medium' (balanced), 'high' (slow, smaller). Default is 'medium'.

    .PARAMETER MaxColors
        Maximum number of colors in the palette (2-256). Default is 256. Lower values create smaller files.

    .PARAMETER Loop
        Number of times to loop the GIF. 0 = infinite loop (default), -1 = no loop.

    .PARAMETER OptimizePalette
        Generates an optimized color palette for better quality. Enabled by default for 'high' quality.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        New-VideoGif -InputPath "video.mp4" -OutputPath "animation.gif"
        Creates a 5-second GIF from the start of the video

    .EXAMPLE
        New-VideoGif -InputPath "video.mp4" -OutputPath "clip.gif" -StartTime "30" -Duration "10" -Width 640 -FrameRate 15
        Creates a 10-second, 640px wide GIF at 15 fps starting at 30 seconds

    .EXAMPLE
        New-VideoGif -InputPath "video.mp4" -OutputPath "optimized.gif" -Quality high -MaxColors 128 -OptimizePalette
        Creates a high-quality, optimized GIF with 128 colors

    .EXAMPLE
        New-VideoGif -InputPath "clip.mp4" -OutputPath "banner.gif" -Width 300 -FrameRate 8 -Loop 0
        Creates a small, looping GIF suitable for web banners

    .NOTES
        Author: PSFFmpeg Contributors
        Name: New-VideoGif
        Version: 1.0.0
        Requires: FFmpeg

    .LINK
        https://github.com/adilio/psffmpeg

    .LINK
        Edit-Video

    .LINK
        Resize-Video

    .LINK
        https://ffmpeg.org/
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
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
        [ValidatePattern('\.gif$')]
        [string]$OutputPath,

        [Parameter()]
        [string]$StartTime = '0',

        [Parameter()]
        [ValidateRange(0.1, 300)]
        [double]$Duration = 5,

        [Parameter()]
        [ValidateRange(-1, 4096)]
        [int]$Width = 480,

        [Parameter()]
        [ValidateRange(-1, 4096)]
        [int]$Height = -1,

        [Parameter()]
        [ValidateRange(1, 50)]
        [int]$FrameRate = 10,

        [Parameter()]
        [ValidateSet('low', 'medium', 'high')]
        [string]$Quality = 'medium',

        [Parameter()]
        [ValidateRange(2, 256)]
        [int]$MaxColors = 256,

        [Parameter()]
        [ValidateRange(-1, 65535)]
        [int]$Loop = 0,

        [Parameter()]
        [switch]$OptimizePalette,

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

            Write-Verbose "Creating GIF: Input=$ResolvedInput, Output=$OutputPath"
            Write-Verbose "Parameters: StartTime=$StartTime, Duration=$Duration, Width=$Width, FPS=$FrameRate, Colors=$MaxColors"

            # Apply quality presets
            $usePalette = $OptimizePalette -or ($Quality -eq 'high')

            # Determine dither mode based on quality
            $ditherMode = switch ($Quality) {
                'low' { 'none' }
                'medium' { 'bayer:bayer_scale=3' }
                'high' { 'sierra2_4a' }
            }

            if ($usePalette) {
                # Two-pass with optimized palette
                Write-Verbose "Using two-pass encoding with optimized palette"

                # Create temp file for palette
                $palettePath = [System.IO.Path]::GetTempFileName() + '.png'

                try {
                    # Pass 1: Generate palette
                    $paletteFilter = "fps=$FrameRate,scale=${Width}:${Height}:flags=lanczos,palettegen=max_colors=$MaxColors"

                    if ($Quality -eq 'high') {
                        $paletteFilter += ":stats_mode=diff"
                    }

                    $paletteArgs = @(
                        '-ss', $StartTime,
                        '-t', [string]$Duration,
                        '-i', $ResolvedInput,
                        '-vf', $paletteFilter
                    )

                    if ($Overwrite) {
                        $paletteArgs += '-y'
                    }

                    $paletteArgs += $palettePath

                    Write-Verbose "Generating palette..."
                    $output1 = & ffmpeg @paletteArgs 2>&1

                    if ($LASTEXITCODE -ne 0) {
                        throw "FFmpeg palette generation failed with exit code $LASTEXITCODE. Output: $output1"
                    }

                    # Pass 2: Create GIF using palette
                    $gifFilter = "fps=$FrameRate,scale=${Width}:${Height}:flags=lanczos[x];[x][1:v]paletteuse=dither=$ditherMode"

                    $gifArgs = @(
                        '-ss', $StartTime,
                        '-t', [string]$Duration,
                        '-i', $ResolvedInput,
                        '-i', $palettePath,
                        '-filter_complex', $gifFilter,
                        '-loop', [string]$Loop
                    )

                    if ($Overwrite) {
                        $gifArgs += '-y'
                    }

                    $gifArgs += $OutputPath

                    Write-Verbose "Creating GIF with optimized palette..."
                    Write-Verbose "FFmpeg arguments: $($gifArgs -join ' ')"

                    if ($PSCmdlet.ShouldProcess($OutputPath, "Create animated GIF")) {
                        $output2 = & ffmpeg @gifArgs 2>&1

                        if ($LASTEXITCODE -ne 0) {
                            throw "FFmpeg GIF creation failed with exit code $LASTEXITCODE. Output: $output2"
                        }

                        Write-Verbose "GIF created successfully"

                        # Return the output file
                        Get-Item -Path $OutputPath
                    }
                }
                finally {
                    # Clean up palette file
                    if (Test-Path $palettePath) {
                        Remove-Item -Path $palettePath -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            else {
                # Single-pass, faster but lower quality
                Write-Verbose "Using single-pass encoding (faster)"

                $gifFilter = "fps=$FrameRate,scale=${Width}:${Height}:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=$MaxColors[p];[s1][p]paletteuse=dither=$ditherMode"

                $gifArgs = @(
                    '-ss', $StartTime,
                    '-t', [string]$Duration,
                    '-i', $ResolvedInput,
                    '-filter_complex', $gifFilter,
                    '-loop', [string]$Loop
                )

                if ($Overwrite) {
                    $gifArgs += '-y'
                }

                $gifArgs += $OutputPath

                Write-Verbose "FFmpeg arguments: $($gifArgs -join ' ')"

                if ($PSCmdlet.ShouldProcess($OutputPath, "Create animated GIF")) {
                    $output = & ffmpeg @gifArgs 2>&1

                    if ($LASTEXITCODE -ne 0) {
                        throw "FFmpeg GIF creation failed with exit code $LASTEXITCODE. Output: $output"
                    }

                    Write-Verbose "GIF created successfully"

                    # Return the output file
                    Get-Item -Path $OutputPath
                }
            }
        }
        catch {
            Write-Error "Failed to create GIF from video '$InputPath': $_"
        }
    }
}
