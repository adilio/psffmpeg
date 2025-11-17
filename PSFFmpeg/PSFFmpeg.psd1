@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'PSFFmpeg.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

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
        'Get-MediaInfo',
        'Convert-Media',
        'Resize-Video',
        'Extract-Audio',
        'Edit-Video',
        'Merge-Video',
        'New-VideoThumbnail',
        'Convert-VideoCodec',
        'Add-AudioToVideo'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

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
            ReleaseNotes = 'Initial release of PSFFmpeg module with comprehensive media processing capabilities.'
        }
    }
}
