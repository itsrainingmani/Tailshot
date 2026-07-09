#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$OutputDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function New-PathRoundedRectangle {
	param(
		[System.Drawing.RectangleF] $Rect,
		[float] $Radius
	)

	$path = [System.Drawing.Drawing2D.GraphicsPath]::new()
	$diameter = $Radius * 2
	$path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
	$path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
	$path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
	$path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
	$path.CloseFigure()
	return $path
}

function New-IconBitmap {
	param([int] $Size)

	$bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
	$bitmap.SetResolution(96, 96)

	$g = [System.Drawing.Graphics]::FromImage($bitmap)
	$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
	$g.Clear([System.Drawing.Color]::Transparent)

	$scale = $Size / 128.0
	$toRect = {
		param($x, $y, $w, $h)
		return [System.Drawing.RectangleF]::new($x * $scale, $y * $scale, $w * $scale, $h * $scale)
	}
	$toPt = {
		param($x, $y)
		return [System.Drawing.PointF]::new($x * $scale, $y * $scale)
	}

	$bgPath = New-PathRoundedRectangle (& $toRect 3 3 122 122) (28 * $scale)
	$bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
		(& $toRect 0 0 128 128),
		[System.Drawing.Color]::FromArgb(255, 17, 27, 43),
		[System.Drawing.Color]::FromArgb(255, 5, 11, 19),
		45
	)
	$g.FillPath($bgBrush, $bgPath)
	$g.DrawPath([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(70, 255, 255, 255), [Math]::Max(1, 1.5 * $scale)), $bgPath)

	$backCardPath = New-PathRoundedRectangle (& $toRect 35 28 53 43) (10 * $scale)
	$backBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 46, 73, 97))
	$g.FillPath($backBrush, $backCardPath)

	$cardPath = New-PathRoundedRectangle (& $toRect 24 39 61 50) (12 * $scale)
	$cardFill = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 238, 247, 250))
	$g.FillPath($cardFill, $cardPath)

	$imagePath = New-PathRoundedRectangle (& $toRect 32 47 45 34) (6 * $scale)
	$imageBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
		(& $toRect 32 47 45 34),
		[System.Drawing.Color]::FromArgb(255, 48, 163, 230),
		[System.Drawing.Color]::FromArgb(255, 18, 193, 156),
		35
	)
	$g.FillPath($imageBrush, $imagePath)

	$glintBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 255, 255, 255))
	$g.FillEllipse($glintBrush, 38 * $scale, 53 * $scale, 8 * $scale, 8 * $scale)

	$mountainPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
	$mountainPath.AddPolygon([System.Drawing.PointF[]]@(
		(& $toPt 35 79),
		(& $toPt 48 64),
		(& $toPt 58 76),
		(& $toPt 65 68),
		(& $toPt 77 81)
	))
	$g.FillPath([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 7, 35, 43)), $mountainPath)

	$planePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
	$planePath.AddPolygon([System.Drawing.PointF[]]@(
		(& $toPt 67 74),
		(& $toPt 112 55),
		(& $toPt 94 108),
		(& $toPt 84 87)
	))
	$planeBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
		(& $toRect 66 54 48 55),
		[System.Drawing.Color]::FromArgb(255, 21, 242, 187),
		[System.Drawing.Color]::FromArgb(255, 0, 187, 135),
		20
	)
	$g.FillPath($planeBrush, $planePath)

	$foldPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
	$foldPath.AddPolygon([System.Drawing.PointF[]]@(
		(& $toPt 84 87),
		(& $toPt 112 55),
		(& $toPt 91 94)
	))
	$g.FillPath([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(80, 0, 71, 63)), $foldPath)

	$g.DrawLine(
		[System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120, 255, 255, 255), [Math]::Max(1, 2 * $scale)),
		(& $toPt 72 75),
		(& $toPt 105 60)
	)

	foreach ($resource in @(
			$bgPath, $bgBrush, $backCardPath, $backBrush, $cardPath, $cardFill,
			$imagePath, $imageBrush, $glintBrush, $mountainPath, $planePath,
			$planeBrush, $foldPath, $g
		)) {
		$resource.Dispose()
	}

	return $bitmap
}

foreach ($size in @(16, 32, 48, 128)) {
	$bitmap = New-IconBitmap -Size $size
	$outputPath = Join-Path $OutputDir "icon$size.png"
	$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
	$bitmap.Dispose()
	Write-Host "Created $outputPath"
}
