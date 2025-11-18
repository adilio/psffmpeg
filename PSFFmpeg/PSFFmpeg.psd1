@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'PSFFmpeg.psm1'

    # Version number of this module.
    ModuleVersion = '1.1.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-4a5b-9c8d-7e6f5a4b3c2d'

    # Author of this module
    Author = 'PSFFmpeg Contributors'

    # Company or vendor of this module
    CompanyName = 'Community'

    # Copyright statement for this module
    Copyright = '(c) 2025 PSFFmpeg Contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A PowerShell wrapper for FFmpeg providing easy-to-use cmdlets for media conversion, editing, and processing tasks.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'Add-AudioToVideo',
        'Add-Subtitle',
        'Convert-Media',
        'Convert-VideoCodec',
        'Edit-Video',
        'Extract-Audio',
        'Get-FFmpegVersion',
        'Get-MediaInfo',
        'Merge-Video',
        'New-VideoFromImages',
        'New-VideoGif',
        'New-VideoThumbnail',
        'Optimize-Video',
        'Resize-Video',
        'Set-VideoMetadata',
        'Split-Video',
        'Test-FFmpegCapability'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # URI for updatable help
    HelpInfoURI = 'https://raw.githubusercontent.com/adilio/psffmpeg/main/'

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module to aid in module discovery
            Tags = @('FFmpeg', 'Video', 'Audio', 'Media', 'Conversion', 'Encoding', 'Multimedia')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/adilio/psffmpeg/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/adilio/psffmpeg'

            # ReleaseNotes of this module
            ReleaseNotes = @'
v1.1.0:
- Enhanced all functions with comprehensive .NOTES and .LINK documentation sections
- Added ValidateNotNullOrEmpty and ConfirmImpact for better parameter validation
- New cmdlets for improved UI/UX:
  * Get-FFmpegVersion - Get FFmpeg version and build information
  * Test-FFmpegCapability - Test for codec, format, and feature support
  * New-VideoFromImages - Create videos from image sequences
  * Split-Video - Split videos into multiple segments
  * Add-Subtitle - Add or burn-in subtitles to videos
  * New-VideoGif - Create optimized animated GIFs from videos
  * Optimize-Video - Smart video optimization for size, quality, or streaming
  * Set-VideoMetadata - Edit video metadata tags
- Follows PowerShell best practices from PoshCode style guide
- Improved error handling and user feedback
- All cmdlets now include detailed help documentation

v1.0.0:
- Initial release with core media processing capabilities
'@
        }
    }
}
