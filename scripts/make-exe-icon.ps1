#Requires -Version 5.1
<#
    Builds gui/Genesis.ico (multi-resolution: 16/32/48/256) from
    genesis-icon-app-512x512.png, using .NET only (no ImageMagick needed).
    Modern .ico files can embed PNG-encoded frames directly, which is all
    this does - resize the source into each size and staple them together
    with a hand-written ICONDIR header.
#>

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $PSScriptRoot
$sourcePng = Join-Path $Root 'genesis-icon-app-512x512.png'
$outIco = Join-Path $Root 'gui\Genesis.ico'

if (-not (Test-Path $sourcePng)) {
    throw "Nao encontrei $sourcePng"
}

$sizes = 16, 32, 48, 256
$src = [System.Drawing.Image]::FromFile($sourcePng)

$pngBlobs = @()
foreach ($size in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.DrawImage($src, 0, 0, $size, $size)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBlobs += , $ms.ToArray()
    $ms.Dispose()
    $bmp.Dispose()
}
$src.Dispose()

# ICONDIR (6 bytes) + one ICONDIRENTRY (16 bytes) per image, then the PNG
# blobs back to back in the same order.
$headerSize = 6
$entrySize = 16
$offset = $headerSize + ($entrySize * $sizes.Count)

$stream = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter($stream)

$writer.Write([uint16]0)      # reserved
$writer.Write([uint16]1)      # type: 1 = icon
$writer.Write([uint16]$sizes.Count)

for ($i = 0; $i -lt $sizes.Count; $i++) {
    $size = $sizes[$i]
    $blob = $pngBlobs[$i]
    $byteSize = if ($size -eq 256) { 0 } else { $size }  # 256 encodes as 0 per the ICO spec
    $writer.Write([byte]$byteSize)   # width
    $writer.Write([byte]$byteSize)   # height
    $writer.Write([byte]0)           # color palette
    $writer.Write([byte]0)           # reserved
    $writer.Write([uint16]1)         # color planes
    $writer.Write([uint16]32)        # bits per pixel
    $writer.Write([uint32]$blob.Length)
    $writer.Write([uint32]$offset)
    $offset += $blob.Length
}
foreach ($blob in $pngBlobs) { $writer.Write($blob) }

$writer.Flush()
[System.IO.File]::WriteAllBytes($outIco, $stream.ToArray())
$writer.Dispose()
$stream.Dispose()

Write-Host "Gerado: $outIco ($($sizes -join '/')px)" -ForegroundColor Green
