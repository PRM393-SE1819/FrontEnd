# run_dev.ps1 - Dùng script này để chạy app thay vì "flutter run" trực tiếp
# Script tự load .env và inject key qua --dart-define

# Load .env file
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
            Write-Host "Loaded: $key" -ForegroundColor Green
        }
    }
} else {
    Write-Host "WARNING: .env file not found! Copy .env.example to .env and fill in your keys." -ForegroundColor Yellow
}

$apiKey = [System.Environment]::GetEnvironmentVariable("OPENROUTER_API_KEY", "Process")

# Run Flutter with injected keys
flutter run -d edge --dart-define=OPENROUTER_API_KEY=$apiKey $args
