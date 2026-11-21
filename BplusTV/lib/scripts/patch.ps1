param(
    [ValidateSet('android')]
    [string]$platform = 'android'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$flutterRoot = $env:FLUTTER_ROOT
if (-not $flutterRoot) {
    $flutterRoot = Split-Path (Split-Path (Get-Command flutter).Source -Parent) -Parent
}

# 可重复执行，保留 SDK 和包缓存内已有的补丁。
function Apply-Patch([string]$targetDir, [string]$relativePatch) {
    $patchPath = Join-Path $projectRoot $relativePatch
    & git -C $targetDir apply --check $patchPath 2>$null
    if ($LASTEXITCODE -eq 0) {
        & git -C $targetDir apply $patchPath
        if ($LASTEXITCODE -ne 0) {
            throw "补丁应用失败：$relativePatch"
        }
        Write-Host "已应用：$relativePatch"
        return
    }
    & git -C $targetDir apply --reverse --check $patchPath 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "补丁与当前源码不兼容：$relativePatch"
    }
    Write-Host "已存在：$relativePatch"
}

$frameworkPatches = @(
    'modal_barrier.patch',
    'text_selection.patch',
    'mouse_cursor.patch',
    'image_anim.patch',
    'layout_builder.patch',
    'navigation_drawer.patch',
    'popup_menu.patch',
    'fab.patch',
    'null_safety_for_selectable_region.patch',
    'selectable_region.patch',
    'editable_text.patch',
    'text_field.patch',
    'scroll_position.patch',
    'scrollable.patch',
    'scrollable_gesture.patch',
    'draggable_scrollable_sheet.patch',
    'scaffold.patch',
    'text.patch',
    'text_painter.patch',
    'sliver.patch',
    'refresh_indicator.patch',
    'bottom_sheet_android.patch',
    'scroll_view.patch',
    'navigator.patch',
    # material_ui 的共享路由 API 也依赖 LocalHistoryEntry 扩展。
    'bottom_sheet_ios_flutter.patch'
)

foreach ($patch in $frameworkPatches) {
    Apply-Patch $flutterRoot "lib/scripts/$patch"
}

$env:PUB_HOSTED_URL = 'https://pub.dev'
Push-Location $projectRoot
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw '依赖安装失败'
    }

    # 从本次解析结果定位固定版本，不删除或重新解压已有缓存。
    $packageConfig = Get-Content '.dart_tool/package_config.json' -Raw | ConvertFrom-Json
    $materialPackage = $packageConfig.packages | Where-Object { $_.name -eq 'material_ui' }
    if (-not $materialPackage) {
        throw '未找到 material_ui'
    }
    $configUri = [Uri]::new((Join-Path $projectRoot '.dart_tool/package_config.json'))
    $materialDir = [Uri]::new($configUri, $materialPackage.rootUri).LocalPath
    $materialPatches = @(
        'modal_barrier_material.patch',
        'navigation_drawer.patch',
        'popup_menu.patch',
        'fab.patch',
        'text_field.patch',
        'scaffold.patch',
        'refresh_indicator.patch',
        'tabs.patch',
        'bottom_sheet_android.patch'
    )
    foreach ($patch in $materialPatches) {
        Apply-Patch $materialDir "lib/scripts/material/$patch"
    }
} finally {
    Pop-Location
}
