try {
    $versionName = $null

    $versionCode = [int](git rev-list --count HEAD).Trim()

    $commitHash = (git rev-parse HEAD).Trim()

    $updatedContent = foreach ($line in (Get-Content -Path 'pubspec.yaml' -Encoding UTF8)) {
        if ($line -match '^\s*version:\s*([\d\.]+)') {
            # 版本名保持干净（1.0.0），commit 信息经 pili.hash 在关于页展示。
            $versionName = $matches[1]
            "version: $versionName+$versionCode"
        }
        else {
            $line
        }
    }

    if ($null -eq $versionName) {
        throw 'version not found'
    }

    $updatedContent | Set-Content -Path 'pubspec.yaml' -Encoding UTF8

    $buildTime = [int]([DateTimeOffset]::Now.ToUnixTimeSeconds())

    $data = @{
        'pili.name' = $versionName
        'pili.code' = $versionCode
        'pili.hash' = $commitHash
        'pili.time' = $buildTime
        'pili.repository' = $env:GITHUB_REPOSITORY ?? ''
    }

    $data | ConvertTo-Json -Compress | Out-File 'pili_release.json' -Encoding UTF8

    Add-Content -Path $env:GITHUB_ENV -Value "version=$versionName"
    $buildDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId(
        [DateTimeOffset]::Now, 'China Standard Time').ToString('yyyy-MM-dd HH:mm')
    Add-Content -Path $env:GITHUB_ENV -Value "build_date=$buildDate"
}
catch {
    Write-Error "Prebuild Error: $($_.Exception.Message)"
    exit 1
}
