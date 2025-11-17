function Set-VideoMetadata {
    <#
    .SYNOPSIS
        Sets or updates metadata tags in a video file.

    .DESCRIPTION
        Modifies metadata tags in video files including title, artist, album, year, comment, genre,
        and other common tags. Preserves video and audio streams while updating metadata.

    .PARAMETER InputPath
        The path to the input video file.

    .PARAMETER OutputPath
        The path for the output video file with updated metadata.

    .PARAMETER Title
        The title of the video.

    .PARAMETER Artist
        The artist or creator name.

    .PARAMETER Album
        The album name.

    .PARAMETER Year
        The year of creation.

    .PARAMETER Comment
        A comment or description.

    .PARAMETER Genre
        The genre of the content.

    .PARAMETER Copyright
        Copyright information.

    .PARAMETER Description
        Detailed description of the content.

    .PARAMETER Publisher
        Publisher name.

    .PARAMETER Language
        Language code (e.g., 'eng', 'spa', 'fra').

    .PARAMETER CustomMetadata
        Hashtable of custom metadata key-value pairs.

    .PARAMETER ClearExisting
        Clears all existing metadata before setting new values.

    .PARAMETER Overwrite
        Overwrites the output file if it exists without prompting.

    .OUTPUTS
        System.IO.FileInfo

    .EXAMPLE
        Set-VideoMetadata -InputPath "video.mp4" -OutputPath "tagged.mp4" -Title "My Video" -Artist "John Doe" -Year "2025"
        Sets basic metadata tags

    .EXAMPLE
        Set-VideoMetadata -InputPath "movie.mp4" -OutputPath "movie_tagged.mp4" -Title "Amazing Film" -Genre "Documentary" -Description "A film about..."
        Sets title, genre, and description

    .EXAMPLE
        $metadata = @{
            'episode_id' = 'S01E01'
            'network' = 'MyNetwork'
        }
        Set-VideoMetadata -InputPath "show.mp4" -OutputPath "show_tagged.mp4" -CustomMetadata $metadata
        Sets custom metadata fields

    .EXAMPLE
        Set-VideoMetadata -InputPath "old.mp4" -OutputPath "new.mp4" -ClearExisting -Title "Fresh Start"
        Clears all existing metadata and sets only the title

    .NOTES
        Author: PSFFmpeg Contributors
        Name: Set-VideoMetadata
        Version: 1.0.0
        Requires: FFmpeg

    .LINK
        https://github.com/adilio/psffmpeg

    .LINK
        Get-MediaInfo

    .LINK
        Convert-Media

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
        [string]$OutputPath,

        [Parameter()]
        [string]$Title,

        [Parameter()]
        [string]$Artist,

        [Parameter()]
        [string]$Album,

        [Parameter()]
        [ValidateRange(1800, 2200)]
        [int]$Year,

        [Parameter()]
        [string]$Comment,

        [Parameter()]
        [string]$Genre,

        [Parameter()]
        [string]$Copyright,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [string]$Publisher,

        [Parameter()]
        [string]$Language,

        [Parameter()]
        [hashtable]$CustomMetadata,

        [Parameter()]
        [switch]$ClearExisting,

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

            Write-Verbose "Setting metadata for: $ResolvedInput"

            # Build FFmpeg arguments
            $ffmpegArgs = @('-i', $ResolvedInput)

            # Copy streams without re-encoding
            $ffmpegArgs += @('-c', 'copy')

            # Clear existing metadata if requested
            if ($ClearExisting) {
                Write-Verbose "Clearing existing metadata"
                $ffmpegArgs += @('-map_metadata', '-1')
            }
            else {
                $ffmpegArgs += @('-map_metadata', '0')
            }

            # Add standard metadata tags
            $metadataMap = @{
                'Title' = 'title'
                'Artist' = 'artist'
                'Album' = 'album'
                'Year' = 'date'
                'Comment' = 'comment'
                'Genre' = 'genre'
                'Copyright' = 'copyright'
                'Description' = 'description'
                'Publisher' = 'publisher'
                'Language' = 'language'
            }

            foreach ($param in $metadataMap.Keys) {
                $value = Get-Variable -Name $param -ValueOnly -ErrorAction SilentlyContinue
                if ($value) {
                    $tagName = $metadataMap[$param]
                    $ffmpegArgs += @('-metadata', "${tagName}=${value}")
                    Write-Verbose "Setting $tagName = $value"
                }
            }

            # Add custom metadata
            if ($CustomMetadata) {
                foreach ($key in $CustomMetadata.Keys) {
                    $value = $CustomMetadata[$key]
                    $ffmpegArgs += @('-metadata', "${key}=${value}")
                    Write-Verbose "Setting custom metadata: $key = $value"
                }
            }

            if ($Overwrite) {
                $ffmpegArgs += '-y'
            }

            $ffmpegArgs += $OutputPath

            Write-Verbose "FFmpeg arguments: $($ffmpegArgs -join ' ')"

            if ($PSCmdlet.ShouldProcess($OutputPath, "Set video metadata")) {
                # Execute FFmpeg
                $output = & ffmpeg @ffmpegArgs 2>&1

                if ($LASTEXITCODE -ne 0) {
                    throw "FFmpeg metadata update failed with exit code $LASTEXITCODE. Output: $output"
                }

                Write-Verbose "Metadata updated successfully"

                # Return the output file
                Get-Item -Path $OutputPath
            }
        }
        catch {
            Write-Error "Failed to set metadata for video '$InputPath': $_"
        }
    }
}
