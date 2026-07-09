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

function New-Color {
	param(
		[int] $R,
		[int] $G,
		[int] $B,
		[int] $A = 255
	)

	return [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function New-SolidBrush {
	param([System.Drawing.Color] $Color)

	return New-Object System.Drawing.SolidBrush $Color
}

function New-Pen {
	param(
		[System.Drawing.Color] $Color,
		[float] $Width = 1
	)

	return New-Object System.Drawing.Pen $Color, $Width
}

function Draw-RoundedRectangle {
	param(
		[System.Drawing.Graphics] $Graphics,
		[System.Drawing.RectangleF] $Rectangle,
		[float] $Radius,
		[System.Drawing.Brush] $Brush = $null,
		[System.Drawing.Pen] $Pen = $null
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

function Draw-SoftShadow {
	param(
		[System.Drawing.Graphics] $Graphics,
		[System.Drawing.RectangleF] $Rectangle,
		[float] $Radius,
		[int] $Alpha = 30
	)

	for ($i = 5; $i -ge 1; $i--) {
		$spread = $i * 5
		$shadow = New-Object System.Drawing.RectangleF ($Rectangle.X - $spread / 2), ($Rectangle.Y + $spread / 2), ($Rectangle.Width + $spread), ($Rectangle.Height + $spread)
		Draw-RoundedRectangle $Graphics $shadow ($Radius + $i) (New-SolidBrush (New-Color 15 23 42 ([Math]::Max(5, [int]($Alpha / $i))))) $null
	}
}

function Draw-Text {
	param(
		[System.Drawing.Graphics] $Graphics,
		[string] $Text,
		[float] $Size,
		[float] $X,
		[float] $Y,
		[System.Drawing.Color] $Color,
		[System.Drawing.FontStyle] $Style = [System.Drawing.FontStyle]::Regular,
		[float] $Width = 0
	)

	$font = New-Font $Size $Style
	$brush = New-SolidBrush $Color
	if ($Width -gt 0) {
		$format = New-Object System.Drawing.StringFormat
		$format.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
		$format.FormatFlags = [System.Drawing.StringFormatFlags]::NoClip
		$Graphics.DrawString($Text, $font, $brush, (New-Object System.Drawing.RectangleF $X, $Y, $Width, 500), $format)
		$format.Dispose()
	} else {
		$Graphics.DrawString($Text, $font, $brush, $X, $Y)
	}
	$brush.Dispose()
	$font.Dispose()
}

function Draw-Icon {
	param(
		[System.Drawing.Graphics] $Graphics,
		[float] $X,
		[float] $Y,
		[float] $Size
	)

	$icon = [System.Drawing.Image]::FromFile($IconPath)
	try {
		$Graphics.DrawImage($icon, $X, $Y, $Size, $Size)
	} finally {
		$icon.Dispose()
	}
}

function Save-Png {
	param(
		[System.Drawing.Bitmap] $Bitmap,
		[string] $Path
	)

	$Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
	$Bitmap.Dispose()
}

function New-Canvas {
	param(
		[int] $Width,
		[int] $Height,
		[System.Drawing.Color] $Background
	)

	$bitmap = New-Bitmap $Width $Height
	$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
	$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
	$graphics.Clear($Background)
	return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Draw-ChromeFrame {
	param(
		[System.Drawing.Graphics] $Graphics,
		[string] $Url
	)

	$top = New-Object System.Drawing.RectangleF 0, 0, 1280, 92
	$Graphics.FillRectangle((New-SolidBrush (New-Color 230 235 241)), $top)
	$Graphics.FillEllipse((New-SolidBrush (New-Color 235 91 83)), 30, 33, 18, 18)
	$Graphics.FillEllipse((New-SolidBrush (New-Color 245 190 79)), 62, 33, 18, 18)
	$Graphics.FillEllipse((New-SolidBrush (New-Color 94 190 92)), 94, 33, 18, 18)
	$address = New-Object System.Drawing.RectangleF 148, 24, 850, 44
	Draw-RoundedRectangle $Graphics $address 6 (New-SolidBrush (New-Color 255 255 255)) (New-Pen (New-Color 210 218 226))
	Draw-Text $Graphics $Url 18 172 35 (New-Color 72 84 96)
}

function Draw-PhotoCard {
	param(
		[System.Drawing.Graphics] $Graphics,
		[float] $X,
		[float] $Y,
		[float] $Width,
		[float] $Height,
		[string] $Label
	)

	$rect = New-Object System.Drawing.RectangleF $X, $Y, $Width, $Height
	Draw-SoftShadow $Graphics $rect 18 22
	$gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, (New-Color 70 118 170), (New-Color 18 32 55), 30
	Draw-RoundedRectangle $Graphics $rect 18 $gradient $null
	$gradient.Dispose()

	$sun = New-SolidBrush (New-Color 255 211 112 220)
	$Graphics.FillEllipse($sun, ($X + $Width - 126), ($Y + 46), 58, 58)
	$sun.Dispose()

	$mountain1 = New-Object System.Drawing.PointF[] 3
	$mountain1[0] = New-Object System.Drawing.PointF ($X + 30), ($Y + $Height - 70)
	$mountain1[1] = New-Object System.Drawing.PointF ($X + 180), ($Y + 150)
	$mountain1[2] = New-Object System.Drawing.PointF ($X + 340), ($Y + $Height - 70)
	$Graphics.FillPolygon((New-SolidBrush (New-Color 228 238 250 235)), $mountain1)

	$mountain2 = New-Object System.Drawing.PointF[] 3
	$mountain2[0] = New-Object System.Drawing.PointF ($X + 220), ($Y + $Height - 70)
	$mountain2[1] = New-Object System.Drawing.PointF ($X + 398), ($Y + 112)
	$mountain2[2] = New-Object System.Drawing.PointF ($X + $Width - 26), ($Y + $Height - 70)
	$Graphics.FillPolygon((New-SolidBrush (New-Color 151 201 191 230)), $mountain2)
	$Graphics.FillRectangle((New-SolidBrush (New-Color 18 52 65 170)), $X, ($Y + $Height - 84), $Width, 84)

	Draw-Text $Graphics $Label 28 ($X + 34) ($Y + $Height - 64) (New-Color 255 255 255) ([System.Drawing.FontStyle]::Bold)
}

function Draw-ContextMenu {
	param(
		[System.Drawing.Graphics] $Graphics,
		[float] $X,
		[float] $Y
	)

	$rect = New-Object System.Drawing.RectangleF $X, $Y, 310, 276
	Draw-SoftShadow $Graphics $rect 10 34
	Draw-RoundedRectangle $Graphics $rect 10 (New-SolidBrush (New-Color 255 255 255)) (New-Pen (New-Color 209 218 228))
	$rows = @(
		@('Open image in new tab', $false),
		@('Save image as...', $false),
		@('Copy image address', $false),
		@('Send with Tailshot', $true),
		@('Inspect', $false)
	)
	$rowY = $Y + 18
	foreach ($row in $rows) {
		if ($row[1]) {
			Draw-RoundedRectangle $Graphics (New-Object System.Drawing.RectangleF ($X + 10), ($rowY - 6), 290, 42) 6 (New-SolidBrush (New-Color 230 247 242)) $null
			Draw-Icon $Graphics ($X + 24) ($rowY + 2) 22
			Draw-Text $Graphics $row[0] 18 ($X + 58) $rowY (New-Color 7 95 70) ([System.Drawing.FontStyle]::Bold)
		} else {
			Draw-Text $Graphics $row[0] 17 ($X + 24) $rowY (New-Color 47 58 70)
		}
		$rowY += 49
	}
}

function Draw-TailshotPanel {
	param(
		[System.Drawing.Graphics] $Graphics,
		[float] $X,
		[float] $Y,
		[float] $Width,
		[float] $Height,
		[string] $State = 'ready'
	)

	$rect = New-Object System.Drawing.RectangleF $X, $Y, $Width, $Height
	Draw-SoftShadow $Graphics $rect 12 44
	Draw-RoundedRectangle $Graphics $rect 12 (New-SolidBrush (New-Color 13 18 26)) (New-Pen (New-Color 75 86 100))
	Draw-Icon $Graphics ($X + 30) ($Y + 28) 38
	Draw-Text $Graphics 'Tailshot' 28 ($X + 82) ($Y + 30) (New-Color 244 248 252) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $Graphics 'Send selected image' 15 ($X + 84) ($Y + 64) (New-Color 142 154 168)
	$Graphics.DrawLine((New-Pen (New-Color 44 54 66)), $X, ($Y + 96), ($X + $Width), ($Y + 96))

	Draw-Text $Graphics 'Selected file' 14 ($X + 30) ($Y + 122) (New-Color 36 222 142) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $Graphics 'photo-from-browser.webp' 19 ($X + 30) ($Y + 148) (New-Color 238 244 250)

	$devices = @(
		@('Workstation', 'Windows - online', (New-Color 39 223 142), $true),
		@('MacBook Pro', 'macOS - online', (New-Color 39 223 142), $false),
		@('Phone', 'Taildrop unavailable', (New-Color 119 129 140), $false)
	)

	$rowStart = $Y + 204
	$rowGap = 12
	$statusReserve = if ($State -eq 'sent') { 58 } else { 0 }
	$availableRowsHeight = ($Y + $Height - 28 - $statusReserve) - $rowStart
	$rowHeight = [Math]::Min(72, [Math]::Max(44, (($availableRowsHeight - (2 * $rowGap)) / 3)))
	$rowY = $rowStart
	foreach ($device in $devices) {
		$row = New-Object System.Drawing.RectangleF ($X + 24), $rowY, ($Width - 48), $rowHeight
		$fill = if ($device[3] -and $State -eq 'ready') { New-Color 28 45 47 } else { New-Color 24 31 40 }
		Draw-RoundedRectangle $Graphics $row 8 (New-SolidBrush $fill) (New-Pen (New-Color 42 52 64))
		$Graphics.FillEllipse((New-SolidBrush $device[2]), ($X + 48), ($rowY + ($rowHeight / 2) - 6), 12, 12)
		Draw-Text $Graphics $device[0] 19 ($X + 76) ($rowY + 12) (New-Color 244 248 252) ([System.Drawing.FontStyle]::Bold)
		Draw-Text $Graphics $device[1] 14 ($X + 76) ($rowY + 38) (New-Color 146 158 170)
		if ($device[3] -and $State -eq 'ready') {
			Draw-RoundedRectangle $Graphics (New-Object System.Drawing.RectangleF ($X + $Width - 122), ($rowY + ($rowHeight / 2) - 15), 76, 30) 6 (New-SolidBrush (New-Color 37 216 137)) $null
			Draw-Text $Graphics 'Send' 15 ($X + $Width - 99) ($rowY + ($rowHeight / 2) - 10) (New-Color 8 25 22) ([System.Drawing.FontStyle]::Bold)
		}
		$rowY += $rowHeight + $rowGap
	}

	if ($State -eq 'sent') {
		Draw-RoundedRectangle $Graphics (New-Object System.Drawing.RectangleF ($X + 24), ($Y + $Height - 74), ($Width - 48), 42) 8 (New-SolidBrush (New-Color 18 70 56)) (New-Pen (New-Color 37 216 137))
		Draw-Text $Graphics 'Sent to Workstation' 17 ($X + 50) ($Y + $Height - 65) (New-Color 221 255 238) ([System.Drawing.FontStyle]::Bold)
	}
}

function Draw-StepPill {
	param(
		[System.Drawing.Graphics] $Graphics,
		[string] $Number,
		[string] $Text,
		[float] $X,
		[float] $Y,
		[float] $Width
	)

	Draw-RoundedRectangle $Graphics (New-Object System.Drawing.RectangleF $X, $Y, $Width, 54) 12 (New-SolidBrush (New-Color 255 255 255 235)) (New-Pen (New-Color 215 224 232))
	Draw-RoundedRectangle $Graphics (New-Object System.Drawing.RectangleF ($X + 14), ($Y + 13), 28, 28) 14 (New-SolidBrush (New-Color 13 118 100)) $null
	Draw-Text $Graphics $Number 15 ($X + 23) ($Y + 17) (New-Color 255 255 255) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $Graphics $Text 17 ($X + 54) ($Y + 16) (New-Color 32 44 56) ([System.Drawing.FontStyle]::Bold)
}

function Draw-UploadFlowScreenshot {
	$canvas = New-Canvas 1280 800 (New-Color 247 249 251)
	$g = $canvas.Graphics
	Draw-ChromeFrame $g 'https://example.com/gallery/photo.webp'
	Draw-Text $g 'Send a browser image in two clicks' 46 78 140 (New-Color 22 31 42) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $g 'Right-click an image, choose Tailshot, then pick a Taildrop-capable device.' 24 82 202 (New-Color 91 103 116)
	Draw-PhotoCard $g 82 292 430 318 'Browser image'
	Draw-ContextMenu $g 392 384
	Draw-Text $g 'Tailshot opens a focused device picker' 22 746 264 (New-Color 22 31 42) ([System.Drawing.FontStyle]::Bold)
	Draw-TailshotPanel $g 742 302 394 372 'ready'
	Draw-StepPill $g '1' 'Right-click image' 84 690 290
	Draw-StepPill $g '2' 'Send with Tailshot' 400 690 308
	Draw-StepPill $g '3' 'Pick destination' 734 690 300
	$g.Dispose()
	Save-Png $canvas.Bitmap (Join-Path $OutputDir 'screenshot-1280x800.png')
}

function Draw-PickerScreenshot {
	$canvas = New-Canvas 1280 800 (New-Color 238 243 247)
	$g = $canvas.Graphics
	$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 0, 0, 1280, 800), (New-Color 239 246 248), (New-Color 218 230 238), 90
	$g.FillRectangle($bg, 0, 0, 1280, 800)
	$bg.Dispose()
	Draw-Text $g 'Choose exactly where the image goes' 46 82 86 (New-Color 21 30 42) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $g 'Tailshot lists your Taildrop-ready devices and keeps unavailable devices out of the way.' 24 86 148 (New-Color 83 96 110)

	Draw-PhotoCard $g 92 244 472 360 'photo-from-browser.webp'
	Draw-TailshotPanel $g 664 178 430 502 'sent'

	Draw-RoundedRectangle $g (New-Object System.Drawing.RectangleF 92, 646, 1002, 72) 14 (New-SolidBrush (New-Color 255 255 255 238)) (New-Pen (New-Color 211 221 230))
	Draw-Text $g 'No cloud relay from Tailshot' 20 126 666 (New-Color 15 118 88) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $g 'The selected image is handed to the local native host, then streamed through the Tailscale CLI.' 20 410 666 (New-Color 72 84 96)
	$g.Dispose()
	Save-Png $canvas.Bitmap (Join-Path $OutputDir 'screenshot-device-picker-1280x800.png')
}

function Draw-LocalTransferScreenshot {
	$canvas = New-Canvas 1280 800 (New-Color 249 250 251)
	$g = $canvas.Graphics
	Draw-Text $g 'Built for local Taildrop transfer' 46 86 84 (New-Color 22 31 42) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $g 'The extension asks for access only when you send the selected image.' 24 90 146 (New-Color 88 100 114)

	$items = @(
		@('Chrome extension', 'Context menu and picker', 112, (New-Color 28 99 152)),
		@('Native host', 'Installed on this PC', 464, (New-Color 13 118 100)),
		@('Tailscale CLI', 'tailscale file cp', 816, (New-Color 97 76 159))
	)

	foreach ($item in $items) {
		$x = [float]$item[2]
		$rect = New-Object System.Drawing.RectangleF $x, 270, 282, 250
		Draw-SoftShadow $g $rect 14 26
		Draw-RoundedRectangle $g $rect 14 (New-SolidBrush (New-Color 255 255 255)) (New-Pen (New-Color 214 223 232))
		Draw-RoundedRectangle $g (New-Object System.Drawing.RectangleF ($x + 28), 304, 58, 58) 14 (New-SolidBrush $item[3]) $null
		if ($item[0] -eq 'Chrome extension') {
			Draw-Icon $g ($x + 39) 315 36
		} else {
			Draw-Text $g '>' 34 ($x + 49) 313 (New-Color 255 255 255) ([System.Drawing.FontStyle]::Bold)
		}
		Draw-Text $g $item[0] 26 ($x + 30) 392 (New-Color 22 31 42) ([System.Drawing.FontStyle]::Bold)
		Draw-Text $g $item[1] 19 ($x + 32) 436 (New-Color 91 103 116)
	}

	foreach ($x in @(408, 760)) {
		$pen = New-Pen (New-Color 37 216 137) 5
		$g.DrawLine($pen, $x, 392, ($x + 66), 392)
		$g.DrawLine($pen, ($x + 66), 392, ($x + 45), 372)
		$g.DrawLine($pen, ($x + 66), 392, ($x + 45), 412)
		$pen.Dispose()
	}

	Draw-RoundedRectangle $g (New-Object System.Drawing.RectangleF 164, 590, 952, 98) 14 (New-SolidBrush (New-Color 20 28 38)) $null
	Draw-Text $g 'Only after you choose "Send with Tailshot"' 23 204 614 (New-Color 244 248 252) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $g 'Image URL and bytes go to your local machine, then to your own Tailscale device.' 19 204 648 (New-Color 174 187 200)
	$g.Dispose()
	Save-Png $canvas.Bitmap (Join-Path $OutputDir 'screenshot-local-transfer-1280x800.png')
}

function Draw-Promo {
	$canvas = New-Canvas 440 280 (New-Color 11 16 24)
	$g = $canvas.Graphics
	$gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 0, 0, 440, 280), (New-Color 18 28 43), (New-Color 5 11 18), 25
	$g.FillRectangle($gradient, 0, 0, 440, 280)
	$gradient.Dispose()
	Draw-RoundedRectangle $g (New-Object System.Drawing.RectangleF 30, 46, 88, 88) 22 (New-SolidBrush (New-Color 255 255 255 10)) (New-Pen (New-Color 101 116 132))
	Draw-Icon $g 48 64 52
	Draw-Text $g 'Tailshot' 42 146 58 (New-Color 250 252 255) ([System.Drawing.FontStyle]::Bold)
	Draw-Text $g 'Send images with Taildrop' 20 149 112 (New-Color 178 190 204)
	$g.DrawLine((New-Pen (New-Color 37 216 137) 4), 149, 158, 392, 158)
	Draw-Text $g 'Right-click. Pick a device. Send.' 21 36 206 (New-Color 37 216 137) ([System.Drawing.FontStyle]::Bold)
	$g.Dispose()
	Save-Png $canvas.Bitmap (Join-Path $OutputDir 'small-promo-440x280.png')
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Draw-Promo
Draw-UploadFlowScreenshot
Draw-PickerScreenshot
Draw-LocalTransferScreenshot

Write-Host "Created store assets in $OutputDir"
