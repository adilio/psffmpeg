function Merge-Video {
    <#
    .SYNOPSIS
        Merges multiple video files into a single video.

    .DESCRIPTION
        Concatenates multiple video files into one output file. All videos should have the same
        codec, resolution, and frame rate for best results. Supports both concat demuxer (fast)
        and concat filter (re-encodes).

    .PARAMETER InputPaths
        An array of paths to the video files to merge, in the order they should be concatenated.

    .PARAMETER OutputPath
        The path for the output merged video file.

    .PARAMETER ReEncode
        Forces re-encoding of the videos. Use this if videos have different codecs or properties.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Merge-Video -InputPaths "part1.mp4", "part2.mp4", "part3.mp4" -OutputPath "complete.mp4"
        Merges three video files into one

    .EXAMPLE
        Merge-Video -InputPaths (Get-ChildItem *.mp4 | Select-Object -ExpandProperty FullName) -OutputPath "merged.mp4"
        Merges all MP4 files in the current directory

    .EXAMPLE
        Merge-Video -InputPaths "video1.mp4", "video2.avi" -OutputPath "output.mp4" -ReEncode
        Merges videos with different formats by re-encoding
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            foreach ($path in $_) {
                if (-not (Test-Path $path)) {
                    throw "Input file not found: $path"
                }
            }
            return $true
        })]
        [string[]]$InputPaths,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter()]
        [switch]$ReEncode,

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
            # Validate input
            if ($InputPaths.Count -lt 2) {
                throw "At least two input files are required for merging"
            }

            # Check if output exists
            if ((Test-Path $OutputPath) -and -not $Overwrite -and -not $PSCmdlet.ShouldProcess($OutputPath, "Overwrite existing file")) {
                Write-Warning "Output file already exists: $OutputPath. Use -Overwrite to replace it."
                return
            }

            Write-Verbose "Merging $($InputPaths.Count) video files -> $OutputPath"

            if ($ReEncode) {
                # Use concat filter (re-encodes)
                Write-Verbose "Using concat filter (re-encoding)"

                # Build filter complex input
                $filterParts = @()
                $inputArgs = @()

                for ($i = 0; $i -lt $InputPaths.Count; $i++) {
                    $resolvedPath = Resolve-Path -Path $InputPaths[$i]
                    $inputArgs += @('-i', $resolvedPath)
                    $filterParts += "[$i:v][$i:a]"
                }

                $filterComplex = "$($filterParts -join '')concat=n=$($InputPaths.Count):v=1:a=1[outv][outa]"

                $ffmpegArgs = $inputArgs + @(
                    '-filter_complex', $filterComplex,
                    '-map', '[outv]',
                    '-map', '[outa]'
                )
            }
            else {
                # Use concat demuxer (fast, no re-encoding)
                Write-Verbose "Using concat demuxer (no re-encoding)"

                # Create temporary concat list file
                $tempFile = [System.IO.Path]::GetTempFileName()
                $concatContent = ($InputPaths | ForEach-Object {
                    $resolvedPath = Resolve-Path -Path $_
                    "file '$($resolvedPath.Path.Replace("'", "'\\''"))'"
                }) -join "`n"

                Set-Content -Path $tempFile -Value $concatContent -Encoding UTF8

                Write-Verbose "Concat list file: $tempFile"
                Write-Verbose "Content:`n$concatContent"

                $ffmpegArgs = @(
                    '-f', 'concat',
                    '-safe', '0',
                    '-i', $tempFile,
                    '-c', 'copy'
                )
            }

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Merge videos")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                # Clean up temp file if used
                if (-not $ReEncode -and (Test-Path $tempFile)) {
                    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                }

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg merge failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Video merge completed successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to merge videos: $_"
        }
    }
}
