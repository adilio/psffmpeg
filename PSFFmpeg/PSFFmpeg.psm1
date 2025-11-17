#Requires -Version 5.1

# Get the module root path
$ModuleRoot = $PSScriptRoot

# Import private functions
$PrivateFunctions = @(Get-ChildItem -Path "$ModuleRoot/Private/*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Imported private function: $($Function.BaseName)"
    }
    catch {
        Write-Error "Failed to import private function $($Function.FullName): $_"
    }
}

# Import public functions
$PublicFunctions = @(Get-ChildItem -Path "$ModuleRoot/Public/*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Imported public function: $($Function.BaseName)"
    }
    catch {
        Write-Error "Failed to import public function $($Function.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName

# Module initialization
Write-Verbose "PSFFmpeg module loaded successfully"
