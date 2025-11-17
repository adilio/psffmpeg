function Test-FFmpegInstalled {
    <#
    .SYNOPSIS
        Tests if FFmpeg is installed and accessible.

    .DESCRIPTION
        Checks if FFmpeg and FFprobe are available in the system PATH and validates their versions.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-FFmpegInstalled
        Returns $true if FFmpeg is installed, $false otherwise.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        # Test ffmpeg
        $ffmpegVersion = & ffmpeg -version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "FFmpeg is not installed or not in PATH. Please install FFmpeg from https://ffmpeg.org/"
            return $false
        }

        # Test ffprobe
        $ffprobeVersion = & ffprobe -version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "FFprobe is not installed or not in PATH. Please install FFmpeg (includes FFprobe) from https://ffmpeg.org/"
            return $false
        }

        Write-Verbose "FFmpeg is installed and accessible"
        return $true
    }
    catch {
        Write-Warning "FFmpeg is not installed or not in PATH. Please install FFmpeg from https://ffmpeg.org/"
        Write-Verbose "Error: $_"
        return $false
    }
}
