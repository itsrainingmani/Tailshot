#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$OutputDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $OutputDir '..\..')).Path
$IconPath = Join-Path $RepoRoot 'icons\icon128.png'

function New-Bitmap {
	param(
		[int] $Width,
		[int] $Height
	)

	$bitmap = New-Object System.Drawing.Bitmap $Width, $Height
	$bitmap.SetResolution(96, 96)
	return $bitmap
}

function New-Font {
	param(
		[float] $Size,
		[System.Drawing.FontStyle] $Style = [System.Drawing.FontStyle]::Regular
	)

	return [System.Drawing.Font]::new('Segoe UI', $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-RoundedRectangle {
	param(
		[System.Drawing.Graphics] $Graphics,
		[System.Drawing.Pen] $Pen,
		[System.Drawing.Brush] $Brush,
		[System.Drawing.RectangleF] $Rectangle,
		[float] $Radius
	)

	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$diameter = $Radius * 2
	$path.AddArc($Rectangle.X, $Rectangle.Y, $diameter, $diameter, 180, 90)
	$path.AddArc($Rectangle.Right - $diameter, $Rectangle.Y, $diameter, $diameter, 270, 90)
	$path.AddArc($Rectangle.Right - $diameter, $Rectangle.Bottom - $diameter, $diameter, $diameter, 0, 90)
	$path.AddArc($Rectangle.X, $Rectangle.Bottom - $diameter, $diameter, $diameter, 90, 90)
	$path.CloseFigure()

	if ($Brush) {
		$Graphics.FillPath($Brush, $path)
	}

	if ($Pen) {
		$Graphics.DrawPath($Pen, $path)
	}

	$path.Dispose()
}

function Save-Png {
	param(
		[System.Drawing.Bitmap] $Bitmap,
		[string] $Path
	)

	$Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
	$Bitmap.Dispose()
}

function Draw-TailshotWindow {
	param(
		[System.Drawing.Graphics] $Graphics,
		[float] $X,
		[float] $Y,
		[float] $Width,
		[float] $Scale
	)

	$black = [System.Drawing.Color]::FromArgb(255, 9, 9, 9)
	$panel = [System.Drawing.Color]::FromArgb(255, 26, 26, 26)
	$border = [System.Drawing.Color]::FromArgb(255, 55, 55, 55)
	$green = [System.Drawing.Color]::FromArgb(255, 0, 255, 120)
	$text = [System.Drawing.Color]::FromArgb(255, 230, 230, 230)
	$muted = [System.Drawing.Color]::FromArgb(255, 120, 120, 120)

	$height = 420 * $Scale
	$outer = New-Object System.Drawing.RectangleF $X, $Y, $Width, $height
	Draw-RoundedRectangle $Graphics (New-Object System.Drawing.Pen $border, (2 * $Scale)) (New-Object System.Drawing.SolidBrush $black) $outer (8 * $Scale)

	$titleFont = New-Font (22 * $Scale) ([System.Drawing.FontStyle]::Bold)
	$labelFont = New-Font (15 * $Scale) ([System.Drawing.FontStyle]::Bold)
	$bodyFont = New-Font (17 * $Scale)

	$icon = [System.Drawing.Image]::FromFile($IconPath)
	$Graphics.DrawImage($icon, ($X + 34 * $Scale), ($Y + 26 * $Scale), (28 * $Scale), (28 * $Scale))
	$icon.Dispose()

	$Graphics.DrawString('TAILSHOT', $titleFont, (New-Object System.Drawing.SolidBrush $green), ($X + 76 * $Scale), ($Y + 28 * $Scale))
	$Graphics.DrawLine((New-Object System.Drawing.Pen $border, (1 * $Scale)), $X, ($Y + 78 * $Scale), ($X + $Width), ($Y + 78 * $Scale))

	$Graphics.DrawString('FILE:', $labelFont, (New-Object System.Drawing.SolidBrush $green), ($X + 34 * $Scale), ($Y + 104 * $Scale))
	$Graphics.DrawString('photo-from-browser.webp', $bodyFont, (New-Object System.Drawing.SolidBrush $text), ($X + 96 * $Scale), ($Y + 102 * $Scale))
	$Graphics.DrawLine((New-Object System.Drawing.Pen $border, (1 * $Scale)), $X, ($Y + 146 * $Scale), ($X + $Width), ($Y + 146 * $Scale))

	$devices = @(
		@('DESKTOP', 'Windows', $green),
		@('MACBOOK', 'macOS', $green),
		@('PHONE', 'Offline', $muted)
	)

	$rowY = $Y + 164 * $Scale
	foreach ($device in $devices) {
		$row = New-Object System.Drawing.RectangleF ($X + 20 * $Scale), $rowY, ($Width - 40 * $Scale), (66 * $Scale)
		Draw-RoundedRectangle $Graphics $null (New-Object System.Drawing.SolidBrush $panel) $row (6 * $Scale)
		$Graphics.FillEllipse((New-Object System.Drawing.SolidBrush $device[2]), ($X + 42 * $Scale), ($rowY + 28 * $Scale), (10 * $Scale), (10 * $Scale))
		$Graphics.DrawString($device[0], $bodyFont, (New-Object System.Drawing.SolidBrush $text), ($X + 72 * $Scale), ($rowY + 22 * $Scale))
		$Graphics.DrawString($device[1], (New-Font (14 * $Scale)), (New-Object System.Drawing.SolidBrush $muted), ($X + $Width - 122 * $Scale), ($rowY + 24 * $Scale))
		$rowY += 76 * $Scale
	}

	$titleFont.Dispose()
	$labelFont.Dispose()
	$bodyFont.Dispose()
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$promo = New-Bitmap 440 280
$g = [System.Drawing.Graphics]::FromImage($promo)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 15, 19, 24))
$green = [System.Drawing.Color]::FromArgb(255, 0, 255, 120)
$white = [System.Drawing.Color]::FromArgb(255, 242, 242, 242)
$muted = [System.Drawing.Color]::FromArgb(255, 170, 180, 190)

$icon = [System.Drawing.Image]::FromFile($IconPath)
$g.DrawImage($icon, 34, 50, 86, 86)
$icon.Dispose()
$g.DrawString('Tailshot', (New-Font 42 ([System.Drawing.FontStyle]::Bold)), (New-Object System.Drawing.SolidBrush $white), 145, 58)
$g.DrawString('Images to your devices', (New-Font 20), (New-Object System.Drawing.SolidBrush $muted), 146, 112)
$g.DrawLine((New-Object System.Drawing.Pen $green, 3), 146, 154, 392, 154)
$g.DrawString('Right-click. Pick a device. Send.', (New-Font 22 ([System.Drawing.FontStyle]::Bold)), (New-Object System.Drawing.SolidBrush $green), 34, 198)
$g.Dispose()
Save-Png $promo (Join-Path $OutputDir 'small-promo-440x280.png')

$screenshot = New-Bitmap 1280 800
$g = [System.Drawing.Graphics]::FromImage($screenshot)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 246, 247, 249))
$g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 228, 233, 238))), 0, 0, 1280, 82)
$g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 236, 94, 86))), 28, 26, 18, 18)
$g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 246, 190, 79))), 58, 26, 18, 18)
$g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 98, 197, 84))), 88, 26, 18, 18)
$g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), 140, 22, 840, 36)
$g.DrawString('https://example.com/images/photo.webp', (New-Font 18), (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 95, 105, 115))), 160, 29)

$g.DrawString('Right-click an image', (New-Font 48 ([System.Drawing.FontStyle]::Bold)), (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 30, 35, 40))), 92, 170)
$g.DrawString('Tailshot opens a compact picker for your devices.', (New-Font 26), (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 85, 95, 105))), 96, 238)

$photoBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 96, 320, 500, 330), ([System.Drawing.Color]::FromArgb(255, 80, 130, 190)), ([System.Drawing.Color]::FromArgb(255, 30, 45, 70)), 35
Draw-RoundedRectangle $g $null $photoBrush (New-Object System.Drawing.RectangleF 96, 320, 500, 330) 16
$g.DrawString('Image on page', (New-Font 38 ([System.Drawing.FontStyle]::Bold)), (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)), 150, 448)
$g.DrawString('Send with Tailscale', (New-Font 26 ([System.Drawing.FontStyle]::Bold)), (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 0, 255, 120))), 648, 360)
$g.DrawLine((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 0, 255, 120), 4)), 594, 468, 684, 468)
$g.DrawLine((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 0, 255, 120), 4)), 684, 468, 662, 446)
$g.DrawLine((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 0, 255, 120), 4)), 684, 468, 662, 490)
Draw-TailshotWindow $g 720 220 390 1.18
$g.Dispose()
Save-Png $screenshot (Join-Path $OutputDir 'screenshot-1280x800.png')

Write-Host "Created store assets in $OutputDir"
