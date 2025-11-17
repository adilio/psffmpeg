function Get-FFmpegVersion {
    <#
    .SYNOPSIS
        Retrieves FFmpeg version information.

    .DESCRIPTION
        Gets detailed version information about the installed FFmpeg, FFprobe, and FFplay utilities,
        including version numbers, build configuration, and available libraries.

    .PARAMETER Component
        Specify which component to query: 'FFmpeg', 'FFprobe', 'FFplay', or 'All'. Default is 'All'.

    .PARAMETER Detailed
        Returns detailed build configuration and library information.

    .OUTPUTS
        PSCustomObject
        Returns an object containing version information for the requested FFmpeg components.

    .EXAMPLE
        Get-FFmpegVersion
        Returns version information for all FFmpeg components

    .EXAMPLE
        Get-FFmpegVersion -Component FFmpeg -Detailed
        Returns detailed version and build information for FFmpeg only

    .EXAMPLE
        Get-FFmpegVersion -Component FFprobe
        Returns version information for FFprobe only

    .NOTES
        Author: PSFFmpeg Contributors
        Name: Get-FFmpegVersion
        Version: 1.0.0
        Requires: FFmpeg

    .LINK
        https://github.com/adilio/psffmpeg

    .LINK
        Test-FFmpegInstalled

    .LINK
        https://ffmpeg.org/
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [ValidateSet('All', 'FFmpeg', 'FFprobe', 'FFplay')]
        [string]$Component = 'All',

        [Parameter()]
        [switch]$Detailed
    )

    begin {
        if (-not (Test-FFmpegInstalled)) {
            throw "FFmpeg is not installed. Please install FFmpeg from https://ffmpeg.org/"
        }
    }

    process {
        try {
            $result = @{}
            $components = if ($Component -eq 'All') { @('FFmpeg', 'FFprobe', 'FFplay') } else { @($Component) }

            foreach ($comp in $components) {
                $exe = $comp.ToLower()

                try {
                    $versionOutput = & $exe -version 2>&1 | Out-String

                    if ($LASTEXITCODE -eq 0) {
                        # Parse version from first line
                        $versionLine = ($versionOutput -split "`n")[0]

                        if ($versionLine -match "$exe version ([\d\.\-\w]+)") {
                            $version = $Matches[1]
                        }
                        else {
                            $version = "Unknown"
                        }

                        $componentInfo = [PSCustomObject]@{
                            Component = $comp
                            Version = $version
                            Available = $true
                        }

                        if ($Detailed) {
                            # Extract build configuration
                            if ($versionOutput -match "configuration: (.+)") {
                                $componentInfo | Add-Member -NotePropertyName Configuration -NotePropertyValue $Matches[1]
                            }

                            # Extract library versions
                            $libraries = @()
                            $libraryMatches = [regex]::Matches($versionOutput, "lib(\w+)\s+([\d\.]+)")
                            foreach ($match in $libraryMatches) {
                                $libraries += [PSCustomObject]@{
                                    Name = $match.Groups[1].Value
                                    Version = $match.Groups[2].Value
                                }
                            }
                            if ($libraries.Count -gt 0) {
                                $componentInfo | Add-Member -NotePropertyName Libraries -NotePropertyValue $libraries
                            }

                            # Add full version output
                            $componentInfo | Add-Member -NotePropertyName FullOutput -NotePropertyValue $versionOutput
                        }

                        $result[$comp] = $componentInfo
                    }
                    else {
                        $result[$comp] = [PSCustomObject]@{
                            Component = $comp
                            Version = "Not Available"
                            Available = $false
                        }
                    }
                }
                catch {
                    Write-Verbose "Could not get version for $comp : $_"
                    $result[$comp] = [PSCustomObject]@{
                        Component = $comp
                        Version = "Not Available"
                        Available = $false
                        Error = $_.Exception.Message
                    }
                }
            }

            # Return results
            if ($Component -eq 'All') {
                return [PSCustomObject]@{
                    FFmpeg = $result['FFmpeg']
                    FFprobe = $result['FFprobe']
                    FFplay = $result['FFplay']
                }
            }
            else {
                return $result[$Component]
            }
        }
        catch {
            Write-Error "Failed to get FFmpeg version information: $_"
        }
    }
}
