function Test-FFmpegCapability {
    <#
    .SYNOPSIS
        Tests for specific FFmpeg capabilities and features.

    .DESCRIPTION
        Checks if FFmpeg supports specific codecs, formats, filters, or other features.
        Useful for determining if your FFmpeg build has the necessary capabilities before
        attempting operations that require specific codecs or features.

    .PARAMETER Type
        The type of capability to test: 'Codec', 'Format', 'Filter', 'Encoder', 'Decoder', or 'HardwareAccel'.

    .PARAMETER Name
        The name of the codec, format, filter, or feature to test for.

    .PARAMETER ListAll
        Lists all available items of the specified type instead of testing for a specific one.

    .OUTPUTS
        System.Boolean or PSCustomObject
        Returns $true/$false when testing a specific capability, or a list of available items when using -ListAll.

    .EXAMPLE
        Test-FFmpegCapability -Type Codec -Name h264
        Tests if H.264 codec is available

    .EXAMPLE
        Test-FFmpegCapability -Type Encoder -Name hevc_nvenc
        Tests if NVIDIA HEVC hardware encoder is available

    .EXAMPLE
        Test-FFmpegCapability -Type Format -Name mp4
        Tests if MP4 format is supported

    .EXAMPLE
        Test-FFmpegCapability -Type Codec -ListAll
        Lists all available codecs

    .EXAMPLE
        Test-FFmpegCapability -Type HardwareAccel -ListAll
        Lists all available hardware acceleration methods

    .NOTES
        Author: PSFFmpeg Contributors
        Name: Test-FFmpegCapability
        Version: 1.0.0
        Requires: FFmpeg

    .LINK
        https://github.com/adilio/psffmpeg

    .LINK
        Get-FFmpegVersion

    .LINK
        https://ffmpeg.org/
    #>
    [CmdletBinding(DefaultParameterSetName = 'Test')]
    [OutputType([bool], [PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Codec', 'Format', 'Filter', 'Encoder', 'Decoder', 'HardwareAccel')]
        [string]$Type,

        [Parameter(Mandatory = $true, ParameterSetName = 'Test')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'List')]
        [switch]$ListAll
    )

    begin {
        if (-not (Test-FFmpegInstalled)) {
            throw "FFmpeg is not installed. Please install FFmpeg from https://ffmpeg.org/"
        }
    }

    process {
        try {
            $ffmpegArgs = switch ($Type) {
                'Codec' { '-codecs' }
                'Format' { '-formats' }
                'Filter' { '-filters' }
                'Encoder' { '-encoders' }
                'Decoder' { '-decoders' }
                'HardwareAccel' { '-hwaccels' }
            }

            Write-Verbose "Querying FFmpeg for $Type information"
            $output = & ffmpeg $ffmpegArgs 2>&1 | Out-String

            if ($LASTEXITCODE -ne 0) {
                throw "FFmpeg failed to retrieve $Type information"
            }

            if ($ListAll) {
                # Parse and return all items
                $items = @()
                $lines = $output -split "`n"

                foreach ($line in $lines) {
                    # Skip header lines
                    if ($line -match '^\s*-+' -or $line -match '^\s*$' -or $line -match '^FFmpeg version' -or $line -match '^configuration:') {
                        continue
                    }

                    # Parse based on type
                    switch ($Type) {
                        'Codec' {
                            # Format: D..... = Decoder, E..... = Encoder, etc.
                            if ($line -match '^\s*([D\.][E\.][AVSL\.][I\.][L\.][S\.])\s+(\S+)\s+(.+)$') {
                                $items += [PSCustomObject]@{
                                    Flags = $Matches[1].Trim()
                                    Name = $Matches[2].Trim()
                                    Description = $Matches[3].Trim()
                                    CanDecode = $Matches[1][0] -eq 'D'
                                    CanEncode = $Matches[1][1] -eq 'E'
                                }
                            }
                        }
                        'Format' {
                            # Format: D = Demuxing, E = Muxing
                            if ($line -match '^\s*([D\.][E\.])\s+(\S+)\s+(.+)$') {
                                $items += [PSCustomObject]@{
                                    Flags = $Matches[1].Trim()
                                    Name = $Matches[2].Trim()
                                    Description = $Matches[3].Trim()
                                    CanDemux = $Matches[1][0] -eq 'D'
                                    CanMux = $Matches[1][1] -eq 'E'
                                }
                            }
                        }
                        'Filter' {
                            if ($line -match '^\s*([T\.][S\.][C\.])\s+(\S+)\s+(.+)$') {
                                $items += [PSCustomObject]@{
                                    Flags = $Matches[1].Trim()
                                    Name = $Matches[2].Trim()
                                    Description = $Matches[3].Trim()
                                }
                            }
                        }
                        { $_ -in @('Encoder', 'Decoder') } {
                            if ($line -match '^\s*([AVSL\.]+)\s+(\S+)\s+(.+)$') {
                                $items += [PSCustomObject]@{
                                    Type = $Matches[1].Trim()
                                    Name = $Matches[2].Trim()
                                    Description = $Matches[3].Trim()
                                }
                            }
                        }
                        'HardwareAccel' {
                            $trimmed = $line.Trim()
                            if ($trimmed -and $trimmed -notmatch '^Hardware' -and $trimmed -notmatch '^-+') {
                                $items += [PSCustomObject]@{
                                    Name = $trimmed
                                }
                            }
                        }
                    }
                }

                return $items
            }
            else {
                # Test for specific item
                $nameLower = $Name.ToLower()

                # Simple search in output
                $found = $output -split "`n" | Where-Object {
                    $_ -match "\s+$nameLower\s+" -or $_ -match "^\s+$nameLower$"
                }

                if ($found) {
                    Write-Verbose "$Type '$Name' is available"
                    return $true
                }
                else {
                    Write-Verbose "$Type '$Name' is NOT available"
                    return $false
                }
            }
        }
        catch {
            Write-Error "Failed to test FFmpeg capability: $_"
            return $false
        }
    }
}
