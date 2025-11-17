function Resize-Video {
    <#
    .SYNOPSIS
        Resizes a video to new dimensions.

    .DESCRIPTION
        Scales a video to specified dimensions while maintaining or adjusting aspect ratio.
        Supports various scaling algorithms and quality settings.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputPath
        The path for the output video file.

    .PARAMETER Width
        The target width in pixels. Use -1 to maintain aspect ratio.

    .PARAMETER Height
        The target height in pixels. Use -1 to maintain aspect ratio.

    .PARAMETER Scale
        Predefined scale options: '4K', '1080p', '720p', '480p', '360p'.

    .PARAMETER ScaleAlgorithm
        The scaling algorithm: 'bilinear', 'bicubic', 'lanczos', 'neighbor', 'area', 'gauss', 'sinc', 'spline'.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Resize-Video -InputPath "video.mp4" -OutputPath "small.mp4" -Width 640 -Height 480
        Resizes video to 640x480

    .EXAMPLE
        Resize-Video -InputPath "video.mp4" -OutputPath "hd.mp4" -Scale 1080p
        Resizes video to 1080p (1920x1080)

    .EXAMPLE
        Resize-Video -InputPath "video.mp4" -OutputPath "wide.mp4" -Width 1280 -Height -1
        Resizes to 1280 width, maintains aspect ratio for height
    #>
    [CmdletBinding(DefaultParameterSetName = 'Dimensions', SupportsShouldProcess = $true)]
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

        [Parameter(ParameterSetName = 'Dimensions')]
        [int]$Width = -1,

        [Parameter(ParameterSetName = 'Dimensions')]
        [int]$Height = -1,

        [Parameter(ParameterSetName = 'Preset', Mandatory = $true)]
        [ValidateSet('4K', '1080p', '720p', '480p', '360p')]
        [string]$Scale,

        [Parameter()]
        [ValidateSet('bilinear', 'bicubic', 'lanczos', 'neighbor', 'area', 'gauss', 'sinc', 'spline')]
        [string]$ScaleAlgorithm = 'lanczos',

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

            # Handle preset scales
            if ($Scale) {
                switch ($Scale) {
                    '4K'    { $Width = 3840; $Height = 2160 }
                    '1080p' { $Width = 1920; $Height = 1080 }
                    '720p'  { $Width = 1280; $Height = 720 }
                    '480p'  { $Width = 854;  $Height = 480 }
                    '360p'  { $Width = 640;  $Height = 360 }
                }
            }

            # Validate dimensions
            if ($Width -eq -1 -and $Height -eq -1) {
                throw "Either Width or Height must be specified (use -1 for the other to maintain aspect ratio)"
            }

            Write-Verbose "Resizing video: $ResolvedInput -> $OutputPath (${Width}x${Height})"

            # Map algorithm names to FFmpeg flags
            $algorithmMap = @{
                'bilinear' = 'bilinear'
                'bicubic' = 'bicubic'
                'lanczos' = 'lanczos'
                'neighbor' = 'neighbor'
                'area' = 'area'
                'gauss' = 'gauss'
                'sinc' = 'sinc'
                'spline' = 'spline'
            }

            $scaleFilter = "scale=${Width}:${Height}:flags=$($algorithmMap[$ScaleAlgorithm])"

            # Build FFmpeg arguments
            $ffmpegArgs = @(
                '-i', $ResolvedInput,
                '-vf', $scaleFilter,
                '-c:a', 'copy'
            )

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Resize video")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg resize failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Resize completed successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to resize video '$InputPath': $_"
        }
    }
}
