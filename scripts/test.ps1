# PowerShell test script for C++ cross-compilation
# This script tests binaries for all architectures

# Configuration
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$BuildScript = Join-Path $ProjectRoot "scripts\build.ps1"
$RunScript = Join-Path $ProjectRoot "scripts\run.ps1"

# Detect if running in GitHub Actions
$InGitHubActions = $false
if ($env:GITHUB_ACTIONS) {
    $InGitHubActions = $true
    Write-Host "Running in GitHub Actions environment"
}

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Cyan"  # PowerShell doesn't have a true "Blue" that's readable, using Cyan instead

# Parse command-line arguments
$Archs = @()

foreach ($arg in $args) {
    switch -Regex ($arg) {
        "^(linux-x86|linux-arm|mac-x86|mac-arm|win-x86|win-arm)$" {
            $Archs += $arg
        }
        "^(-h|--help)$" {
            Write-Host "Usage: $PSCommandPath [options] [architecture]"
            Write-Host "Options:"
            Write-Host "  -h, --help   Show this help message"
            Write-Host "Architecture:"
            Write-Host "  linux-x86    Test Linux x86_64 build"
            Write-Host "  linux-arm    Test Linux ARM64 build"
            Write-Host "  mac-x86      Test macOS x86_64 build"
            Write-Host "  mac-arm      Test macOS ARM64 build"
            Write-Host "  win-x86      Test Windows x86_64 build"
            Write-Host "  win-arm      Test Windows ARM64 build"
            Write-Host "  (none)       Test all architectures"
            exit 0
        }
        default {
            Write-Host "Unknown option: $arg" -ForegroundColor $Red
            Write-Host "Run '$PSCommandPath --help' for more information."
            exit 1
        }
    }
}

# Function to print section headers
function Print-Header {
    param([string]$Text)
    Write-Host "`n==== $Text ====" -ForegroundColor $Yellow
}

# Function to run a test for a specific architecture
function Run-Test {
    param([string]$Arch)
    
    Print-Header "Testing $Arch"
    
    # Run the binary
    Print-Header "Running $Arch binary"
    
    try {
        if ($Arch -eq "win-x86") {
            $BinaryPath = Join-Path $ProjectRoot "build\win-x86\bin\app.exe"
            $Output = & $BinaryPath
        }
        elseif ($Arch -eq "win-arm") {
            Write-Host "Windows ARM64 binaries cannot be directly executed on x64" -ForegroundColor $Yellow
            return $false
        }
        else {
            # For non-Windows binaries, we'd need WSL or similar
            Write-Host "Non-Windows binaries cannot be directly executed on Windows" -ForegroundColor $Yellow
            return $false
        }
    }
    catch {
        Write-Host "Error running binary: $_" -ForegroundColor $Red
        return $false
    }
    
    # Verify output
    Print-Header "Verifying output"
    
    # Check for expected output patterns
    $Success = $true
    
    if ($Output -match "Hello from Modern C\+\+ Cross-Compilation Example!") {
        Write-Host "✓ Found greeting message" -ForegroundColor $Green
    }
    else {
        Write-Host "✗ Missing greeting message" -ForegroundColor $Red
        $Success = $false
    }
    
    if ($Output -match "Original items:") {
        Write-Host "✓ Found items list" -ForegroundColor $Green
    }
    else {
        Write-Host "✗ Missing items list" -ForegroundColor $Red
        $Success = $false
    }
    
    if ($Output -match "After transformation:") {
        Write-Host "✓ Found transformation section" -ForegroundColor $Green
    }
    else {
        Write-Host "✗ Missing transformation section" -ForegroundColor $Red
        $Success = $false
    }
    
    if ($Output -match "fruit: apple") {
        Write-Host "✓ Found transformed items" -ForegroundColor $Green
    }
    else {
        Write-Host "✗ Missing transformed items" -ForegroundColor $Red
        $Success = $false
    }
    
    if ($Output -match "Item at index 10 exists: no") {
        Write-Host "✓ Found index check" -ForegroundColor $Green
    }
    else {
        Write-Host "✗ Missing index check" -ForegroundColor $Red
        $Success = $false
    }
    
    if ($Success) {
        Write-Host "All tests passed for $Arch!" -ForegroundColor $Green
    }
    
    return $Success
}

# Initialize result variables
$LinuxX86Result = ""
$LinuxArmResult = ""
$MacX86Result = ""
$MacArmResult = ""
$WinX86Result = ""
$WinArmResult = ""

# Run tests based on architecture parameters
if ($Archs.Count -gt 0) {
    # Test specific architectures
    foreach ($Arch in $Archs) {
        switch ($Arch) {
            "linux-x86" {
                Print-Header "Testing linux-x86 (verification only)"
                $BinaryPath = Join-Path $ProjectRoot "build\linux-x86\bin\app"
                if (Test-Path $BinaryPath) {
                    Write-Host "✓ Linux x86_64 binary exists" -ForegroundColor $Blue
                    $LinuxX86Result = "SKIP"
                }
                else {
                    Write-Host "✗ Linux x86_64 binary not found" -ForegroundColor $Red
                    $LinuxX86Result = "FAIL"
                }
                Write-Host "Note: Linux binaries cannot be tested on Windows" -ForegroundColor $Yellow
            }
            "linux-arm" {
                Print-Header "Testing linux-arm (verification only)"
                $BinaryPath = Join-Path $ProjectRoot "build\linux-arm\bin\app"
                if (Test-Path $BinaryPath) {
                    Write-Host "✓ Linux ARM64 binary exists" -ForegroundColor $Blue
                    $LinuxArmResult = "SKIP"
                }
                else {
                    Write-Host "✗ Linux ARM64 binary not found" -ForegroundColor $Red
                    $LinuxArmResult = "FAIL"
                }
                Write-Host "Note: Linux binaries cannot be tested on Windows" -ForegroundColor $Yellow
            }
            "mac-x86" {
                Print-Header "Testing mac-x86 (verification only)"
                $BinaryPath = Join-Path $ProjectRoot "build\mac-x86\bin\app"
                if (Test-Path $BinaryPath) {
                    Write-Host "✓ macOS x86_64 binary exists" -ForegroundColor $Blue
                    $MacX86Result = "SKIP"
                }
                else {
                    Write-Host "✗ macOS x86_64 binary not found" -ForegroundColor $Red
                    $MacX86Result = "FAIL"
                }
                Write-Host "Note: macOS binaries cannot be tested on Windows" -ForegroundColor $Yellow
            }
            "mac-arm" {
                Print-Header "Testing mac-arm (verification only)"
                $BinaryPath = Join-Path $ProjectRoot "build\mac-arm\bin\app"
                if (Test-Path $BinaryPath) {
                    Write-Host "✓ macOS ARM64 binary exists" -ForegroundColor $Blue
                    $MacArmResult = "SKIP"
                }
                else {
                    Write-Host "✗ macOS ARM64 binary not found" -ForegroundColor $Red
                    $MacArmResult = "FAIL"
                }
                Write-Host "Note: macOS binaries cannot be tested on Windows" -ForegroundColor $Yellow
            }
            "win-x86" {
                $BinaryPath = Join-Path $ProjectRoot "build\win-x86\bin\app.exe"
                if (Test-Path $BinaryPath) {
                    if ($InGitHubActions) {
                        # In GitHub Actions, we can run the binary directly
                        if (Run-Test "win-x86") {
                            $WinX86Result = "PASS"
                        }
                        else {
                            $WinX86Result = "FAIL"
                        }
                    }
                    else {
                        # Local Windows environment
                        if (Run-Test "win-x86") {
                            $WinX86Result = "PASS"
                        }
                        else {
                            $WinX86Result = "FAIL"
                        }
                    }
                }
                else {
                    Write-Host "✗ Windows x86_64 binary not found" -ForegroundColor $Red
                    $WinX86Result = "FAIL"
                }
            }
            "win-arm" {
                Print-Header "Testing win-arm (verification only)"
                $BinaryPath = Join-Path $ProjectRoot "build\win-arm\bin\app.exe"
                if (Test-Path $BinaryPath) {
                    # Check if it's a placeholder
                    $Content = Get-Content $BinaryPath -Raw -ErrorAction SilentlyContinue
                    if ($Content -match "PLACEHOLDER_BINARY") {
                        Write-Host "✓ Windows ARM64 placeholder binary exists" -ForegroundColor $Blue
                    }
                    else {
                        Write-Host "✓ Windows ARM64 binary exists" -ForegroundColor $Green
                    }
                    $WinArmResult = "SKIP"
                }
                else {
                    Write-Host "✗ Windows ARM64 binary not found" -ForegroundColor $Red
                    $WinArmResult = "FAIL"
                }
                Write-Host "Note: Windows ARM64 binaries cannot be fully tested on x64 Windows" -ForegroundColor $Yellow
            }
        }
    }
}
else {
    # Test all architectures
    # Linux x86_64
    Print-Header "Testing linux-x86 (verification only)"
    $BinaryPath = Join-Path $ProjectRoot "build\linux-x86\bin\app"
    if (Test-Path $BinaryPath) {
        Write-Host "✓ Linux x86_64 binary exists" -ForegroundColor $Blue
        $LinuxX86Result = "SKIP"
    }
    else {
        Write-Host "✗ Linux x86_64 binary not found" -ForegroundColor $Red
        $LinuxX86Result = "FAIL"
    }
    Write-Host "Note: Linux binaries cannot be tested on Windows" -ForegroundColor $Yellow
    
    # Linux ARM64
    Print-Header "Testing linux-arm (verification only)"
    $BinaryPath = Join-Path $ProjectRoot "build\linux-arm\bin\app"
    if (Test-Path $BinaryPath) {
        Write-Host "✓ Linux ARM64 binary exists" -ForegroundColor $Blue
        $LinuxArmResult = "SKIP"
    }
    else {
        Write-Host "✗ Linux ARM64 binary not found" -ForegroundColor $Red
        $LinuxArmResult = "FAIL"
    }
    Write-Host "Note: Linux binaries cannot be tested on Windows" -ForegroundColor $Yellow
    
    # macOS x86_64
    Print-Header "Testing mac-x86 (verification only)"
    $BinaryPath = Join-Path $ProjectRoot "build\mac-x86\bin\app"
    if (Test-Path $BinaryPath) {
        Write-Host "✓ macOS x86_64 binary exists" -ForegroundColor $Blue
        $MacX86Result = "SKIP"
    }
    else {
        Write-Host "✗ macOS x86_64 binary not found" -ForegroundColor $Red
        $MacX86Result = "FAIL"
    }
    Write-Host "Note: macOS binaries cannot be tested on Windows" -ForegroundColor $Yellow
    
    # macOS ARM64
    Print-Header "Testing mac-arm (verification only)"
    $BinaryPath = Join-Path $ProjectRoot "build\mac-arm\bin\app"
    if (Test-Path $BinaryPath) {
        Write-Host "✓ macOS ARM64 binary exists" -ForegroundColor $Blue
        $MacArmResult = "SKIP"
    }
    else {
        Write-Host "✗ macOS ARM64 binary not found" -ForegroundColor $Red
        $MacArmResult = "FAIL"
    }
    Write-Host "Note: macOS binaries cannot be tested on Windows" -ForegroundColor $Yellow
    
    # Windows x86_64
    $BinaryPath = Join-Path $ProjectRoot "build\win-x86\bin\app.exe"
    if (Test-Path $BinaryPath) {
        if (Run-Test "win-x86") {
            $WinX86Result = "PASS"
        }
        else {
            $WinX86Result = "FAIL"
        }
    }
    else {
        Write-Host "✗ Windows x86_64 binary not found" -ForegroundColor $Red
        $WinX86Result = "FAIL"
    }
    
    # Windows ARM64
    Print-Header "Testing win-arm (verification only)"
    $BinaryPath = Join-Path $ProjectRoot "build\win-arm\bin\app.exe"
    if (Test-Path $BinaryPath) {
        # Check if it's a placeholder
        $Content = Get-Content $BinaryPath -Raw -ErrorAction SilentlyContinue
        if ($Content -match "PLACEHOLDER_BINARY") {
            Write-Host "✓ Windows ARM64 placeholder binary exists" -ForegroundColor $Blue
        }
        else {
            Write-Host "✓ Windows ARM64 binary exists" -ForegroundColor $Green
        }
        $WinArmResult = "SKIP"
    }
    else {
        Write-Host "✗ Windows ARM64 binary not found" -ForegroundColor $Red
        $WinArmResult = "FAIL"
    }
    Write-Host "Note: Windows ARM64 binaries cannot be fully tested on x64 Windows" -ForegroundColor $Yellow
}

# Print summary
Print-Header "Test Summary"
if ($LinuxX86Result -eq "PASS") {
    Write-Host "linux-x86: $LinuxX86Result" -ForegroundColor $Green
}
elseif ($LinuxX86Result -eq "SKIP") {
    Write-Host "linux-x86: $LinuxX86Result" -ForegroundColor $Blue
}
else {
    Write-Host "linux-x86: $LinuxX86Result" -ForegroundColor $Red
}

if ($LinuxArmResult -eq "PASS") {
    Write-Host "linux-arm: $LinuxArmResult" -ForegroundColor $Green
}
elseif ($LinuxArmResult -eq "SKIP") {
    Write-Host "linux-arm: $LinuxArmResult" -ForegroundColor $Blue
}
else {
    Write-Host "linux-arm: $LinuxArmResult" -ForegroundColor $Red
}

if ($MacX86Result -eq "PASS") {
    Write-Host "mac-x86: $MacX86Result" -ForegroundColor $Green
}
elseif ($MacX86Result -eq "SKIP") {
    Write-Host "mac-x86: $MacX86Result" -ForegroundColor $Blue
}
else {
    Write-Host "mac-x86: $MacX86Result" -ForegroundColor $Red
}

if ($MacArmResult -eq "PASS") {
    Write-Host "mac-arm: $MacArmResult" -ForegroundColor $Green
}
elseif ($MacArmResult -eq "SKIP") {
    Write-Host "mac-arm: $MacArmResult" -ForegroundColor $Blue
}
else {
    Write-Host "mac-arm: $MacArmResult" -ForegroundColor $Red
}

if ($WinX86Result -eq "PASS") {
    Write-Host "win-x86: $WinX86Result" -ForegroundColor $Green
}
elseif ($WinX86Result -eq "SKIP") {
    Write-Host "win-x86: $WinX86Result" -ForegroundColor $Blue
}
else {
    Write-Host "win-x86: $WinX86Result" -ForegroundColor $Red
}

if ($WinArmResult -eq "PASS") {
    Write-Host "win-arm: $WinArmResult" -ForegroundColor $Green
}
elseif ($WinArmResult -eq "SKIP") {
    Write-Host "win-arm: $WinArmResult" -ForegroundColor $Blue
}
else {
    Write-Host "win-arm: $WinArmResult" -ForegroundColor $Red
}

# Exit with error if any test failed
if ($LinuxX86Result -eq "FAIL" -or $LinuxArmResult -eq "FAIL" -or 
    $MacX86Result -eq "FAIL" -or $MacArmResult -eq "FAIL" -or 
    $WinX86Result -eq "FAIL" -or $WinArmResult -eq "FAIL") {
    exit 1
}

Print-Header "All tests completed successfully!"
