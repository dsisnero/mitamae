<#
.SYNOPSIS
    Helper script to run Windows tests for mitamae
.DESCRIPTION
    This script helps run Windows tests for mitamae in different environments:
    - Native Windows (without Docker)
    - Windows Docker container
    - WSL with Docker
.EXAMPLE
    .\test_windows.ps1 -NoDocker
    # Runs tests natively without Docker
.EXAMPLE
    .\test_windows.ps1
    # Runs tests in a Windows Docker container
#>
[CmdletBinding()]
param(
    [switch]$NoDocker
)

$ErrorActionPreference = "Stop"

# Check if running on Windows
$isWindows = $env:OS -like "*Windows*"

if ($NoDocker) {
    Write-Host "Running Windows tests natively (without Docker)..." -ForegroundColor Cyan
    $env:NO_DOCKER = "1"
    
    if ($isWindows) {
        # On Windows, use the native Ruby
        bundle check || bundle install -j4
        bundle exec rspec spec/windows/
    } else {
        Write-Error "Cannot run native Windows tests on non-Windows platform without Docker"
    }
} else {
    Write-Host "Running Windows tests in Docker container..." -ForegroundColor Cyan
    
    # Check Docker is available
    try {
        docker version | Out-Null
    } catch {
        Write-Error "Docker is not available. Please install Docker or use -NoDocker to run tests natively."
    }
    
    # Run the rake task
    rake test:windows
}
