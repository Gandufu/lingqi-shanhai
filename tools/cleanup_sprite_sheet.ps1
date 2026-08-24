param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [string]$OutputPath = "",

    [int]$HFrames = 4,
    [int]$VFrames = 4,
    [ValidateRange(0, 255)]
    [int]$AlphaCutoff = 32,
    [ValidateRange(1, 1000000)]
    [int]$MinComponentPixels = 24,
    [ValidateRange(0.0, 1.0)]
    [double]$MinComponentRatio = 0.005,
    [switch]$OpaqueCheckerboard,
    [switch]$OpaqueBlack,
    [switch]$DryRun
)

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
if (-not $DryRun -and [string]::IsNullOrWhiteSpace($OutputPath)) {
    throw "OutputPath is required unless DryRun is set."
}

Add-Type -AssemblyName System.Drawing
$drawingCommon = [System.Drawing.Bitmap].Assembly.Location
$drawingPrimitives = [System.Drawing.Rectangle].Assembly.Location
$platformAssemblies = [string]([AppContext]::GetData("TRUSTED_PLATFORM_ASSEMBLIES")) -split [IO.Path]::PathSeparator
$drawingDirectory = [IO.Path]::GetDirectoryName($drawingCommon)
$windowsDrawingAssemblies = @(
    (Join-Path $drawingDirectory "System.Private.Windows.Core.dll"),
    (Join-Path $drawingDirectory "System.Private.Windows.GdiPlus.dll")
) | Where-Object { Test-Path -LiteralPath $_ }
$compilerReferences = @($platformAssemblies) + @($drawingCommon, $drawingPrimitives) + @($windowsDrawingAssemblies)
Add-Type -ReferencedAssemblies $compilerReferences -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public static class SpriteSheetCleaner
{
    public static string Clean(
        string inputPath,
        string outputPath,
        int hFrames,
        int vFrames,
        int alphaCutoff,
        int minComponentPixels,
        double minComponentRatio,
        bool opaqueCheckerboard,
        bool opaqueBlack,
        bool dryRun)
    {
        using (var source = new Bitmap(inputPath))
        using (var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            var rectangle = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
            var data = bitmap.LockBits(rectangle, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            var byteCount = Math.Abs(data.Stride) * data.Height;
            var pixels = new byte[byteCount];
            Marshal.Copy(data.Scan0, pixels, 0, byteCount);

            var backgroundPixelsRemoved = opaqueCheckerboard || opaqueBlack
                ? RemoveConnectedBackground(pixels, data.Stride, bitmap.Width, bitmap.Height, opaqueBlack)
                : 0;

            var report = new StringBuilder();
            report.AppendLine($"{Path.GetFileName(inputPath)}: {bitmap.Width}x{bitmap.Height}, cutoff={alphaCutoff}, ratio={minComponentRatio:0.####}");
            if (opaqueCheckerboard || opaqueBlack)
                report.AppendLine($"  opaque background pixels removed={backgroundPixelsRemoved}");

            for (var frameY = 0; frameY < vFrames; frameY++)
            {
                var top = frameY * bitmap.Height / vFrames;
                var bottom = (frameY + 1) * bitmap.Height / vFrames;
                for (var frameX = 0; frameX < hFrames; frameX++)
                {
                    var left = frameX * bitmap.Width / hFrames;
                    var right = (frameX + 1) * bitmap.Width / hFrames;
                    var frameWidth = right - left;
                    var frameHeight = bottom - top;
                    var pixelTotal = frameWidth * frameHeight;
                    var componentIds = new int[pixelTotal];
                    for (var index = 0; index < pixelTotal; index++)
                        componentIds[index] = -1;
                    var queue = new int[pixelTotal];
                    var componentSizes = new int[pixelTotal];
                    var componentCount = 0;

                    for (var localY = 0; localY < frameHeight; localY++)
                    {
                        for (var localX = 0; localX < frameWidth; localX++)
                        {
                            var localIndex = localY * frameWidth + localX;
                            if (componentIds[localIndex] != -1 || AlphaAt(pixels, data.Stride, left + localX, top + localY) < alphaCutoff)
                                continue;

                            var componentId = componentCount;
                            var head = 0;
                            var tail = 0;
                            queue[tail++] = localIndex;
                            componentIds[localIndex] = componentId;

                            while (head < tail)
                            {
                                var current = queue[head++];
                                var currentX = current % frameWidth;
                                var currentY = current / frameWidth;
                                for (var offsetY = -1; offsetY <= 1; offsetY++)
                                {
                                    for (var offsetX = -1; offsetX <= 1; offsetX++)
                                    {
                                        if (offsetX == 0 && offsetY == 0)
                                            continue;
                                        var nextX = currentX + offsetX;
                                        var nextY = currentY + offsetY;
                                        if (nextX < 0 || nextX >= frameWidth || nextY < 0 || nextY >= frameHeight)
                                            continue;
                                        var next = nextY * frameWidth + nextX;
                                        if (componentIds[next] != -1 || AlphaAt(pixels, data.Stride, left + nextX, top + nextY) < alphaCutoff)
                                            continue;
                                        componentIds[next] = componentId;
                                        queue[tail++] = next;
                                    }
                                }
                            }
                            componentSizes[componentCount++] = tail;
                        }
                    }

                    var largest = 0;
                    for (var componentIndex = 0; componentIndex < componentCount; componentIndex++)
                        largest = Math.Max(largest, componentSizes[componentIndex]);
                    var minimumSize = Math.Max(minComponentPixels, (int)Math.Ceiling(largest * minComponentRatio));
                    var removed = 0;

                    for (var localY = 0; localY < frameHeight; localY++)
                    {
                        for (var localX = 0; localX < frameWidth; localX++)
                        {
                            var localIndex = localY * frameWidth + localX;
                            var alpha = AlphaAt(pixels, data.Stride, left + localX, top + localY);
                            var componentId = componentIds[localIndex];
                            if (alpha < alphaCutoff || (componentId >= 0 && componentSizes[componentId] < minimumSize))
                            {
                                if (alpha > 0)
                                    removed++;
                                SetTransparent(pixels, data.Stride, left + localX, top + localY);
                            }
                        }
                    }

                    var sortedSizes = new int[componentCount];
                    Array.Copy(componentSizes, sortedSizes, componentCount);
                    Array.Sort(sortedSizes);
                    Array.Reverse(sortedSizes);
                    var topCount = Math.Min(6, sortedSizes.Length);
                    var topSizes = new string[topCount];
                    for (var topIndex = 0; topIndex < topCount; topIndex++)
                        topSizes[topIndex] = sortedSizes[topIndex].ToString();
                    report.AppendLine($"  frame {frameY},{frameX}: components={componentCount}, top=[{string.Join(",", topSizes)}], keep>={minimumSize}, removed={removed}");
                }
            }

            if (!dryRun)
                Marshal.Copy(pixels, 0, data.Scan0, byteCount);
            bitmap.UnlockBits(data);

            if (!dryRun)
            {
                var directory = Path.GetDirectoryName(Path.GetFullPath(outputPath));
                if (!string.IsNullOrEmpty(directory))
                    Directory.CreateDirectory(directory);
                bitmap.Save(outputPath, ImageFormat.Png);
                report.AppendLine($"Saved: {Path.GetFullPath(outputPath)}");
            }

            return report.ToString();
        }
    }

    private static byte AlphaAt(byte[] pixels, int stride, int x, int y)
    {
        return pixels[y * stride + x * 4 + 3];
    }

    private static int RemoveConnectedBackground(byte[] pixels, int stride, int width, int height, bool darkBackground)
    {
        var pixelTotal = width * height;
        var background = new bool[pixelTotal];
        var queue = new int[pixelTotal];
        var head = 0;
        var tail = 0;

        for (var x = 0; x < width; x++)
        {
            TryQueueBackground(pixels, stride, width, height, x, 0, darkBackground, background, queue, ref tail);
            TryQueueBackground(pixels, stride, width, height, x, height - 1, darkBackground, background, queue, ref tail);
        }
        for (var y = 0; y < height; y++)
        {
            TryQueueBackground(pixels, stride, width, height, 0, y, darkBackground, background, queue, ref tail);
            TryQueueBackground(pixels, stride, width, height, width - 1, y, darkBackground, background, queue, ref tail);
        }

        while (head < tail)
        {
            var current = queue[head++];
            var currentX = current % width;
            var currentY = current / width;
            for (var offsetY = -1; offsetY <= 1; offsetY++)
            {
                for (var offsetX = -1; offsetX <= 1; offsetX++)
                {
                    if (offsetX == 0 && offsetY == 0)
                        continue;
                    TryQueueBackground(pixels, stride, width, height, currentX + offsetX, currentY + offsetY, darkBackground, background, queue, ref tail);
                }
            }
        }

        for (var expansion = 0; expansion < 2; expansion++)
        {
            var additions = new bool[pixelTotal];
            for (var y = 1; y < height - 1; y++)
            {
                for (var x = 1; x < width - 1; x++)
                {
                    var index = y * width + x;
                    if (background[index] || !IsNearNeutralEdge(pixels, stride, x, y, darkBackground))
                        continue;
                    var touchesBackground = false;
                    for (var offsetY = -1; offsetY <= 1 && !touchesBackground; offsetY++)
                        for (var offsetX = -1; offsetX <= 1; offsetX++)
                            if (background[(y + offsetY) * width + x + offsetX])
                            {
                                touchesBackground = true;
                                break;
                            }
                    if (touchesBackground)
                        additions[index] = true;
                }
            }
            for (var index = 0; index < pixelTotal; index++)
                if (additions[index])
                    background[index] = true;
        }

        var removed = 0;
        for (var index = 0; index < pixelTotal; index++)
        {
            if (!background[index])
                continue;
            var x = index % width;
            var y = index / width;
            SetTransparent(pixels, stride, x, y);
            removed++;
        }
        return removed;
    }

    private static void TryQueueBackground(
        byte[] pixels,
        int stride,
        int width,
        int height,
        int x,
        int y,
        bool darkBackground,
        bool[] background,
        int[] queue,
        ref int tail)
    {
        if (x < 0 || x >= width || y < 0 || y >= height)
            return;
        var index = y * width + x;
        if (background[index] || !IsBackgroundPixel(pixels, stride, x, y, darkBackground))
            return;
        background[index] = true;
        queue[tail++] = index;
    }

    private static bool IsBackgroundPixel(byte[] pixels, int stride, int x, int y, bool darkBackground)
    {
        var offset = y * stride + x * 4;
        var blue = pixels[offset];
        var green = pixels[offset + 1];
        var red = pixels[offset + 2];
        var minimum = Math.Min(red, Math.Min(green, blue));
        var maximum = Math.Max(red, Math.Max(green, blue));
        if (darkBackground)
            return maximum <= 8;
        return minimum >= 225 && maximum - minimum <= 10;
    }

    private static bool IsNearNeutralEdge(byte[] pixels, int stride, int x, int y, bool darkBackground)
    {
        var offset = y * stride + x * 4;
        var blue = pixels[offset];
        var green = pixels[offset + 1];
        var red = pixels[offset + 2];
        var minimum = Math.Min(red, Math.Min(green, blue));
        var maximum = Math.Max(red, Math.Max(green, blue));
        if (darkBackground)
            return maximum <= 16 && maximum - minimum <= 10;
        return minimum >= 190 && maximum - minimum <= 28;
    }

    private static void SetTransparent(byte[] pixels, int stride, int x, int y)
    {
        var offset = y * stride + x * 4;
        pixels[offset] = 0;
        pixels[offset + 1] = 0;
        pixels[offset + 2] = 0;
        pixels[offset + 3] = 0;
    }
}
'@

$resolvedOutput = if ([string]::IsNullOrWhiteSpace($OutputPath)) { "" } else { [IO.Path]::GetFullPath($OutputPath) }
[SpriteSheetCleaner]::Clean(
    $resolvedInput,
    $resolvedOutput,
    $HFrames,
    $VFrames,
    $AlphaCutoff,
    $MinComponentPixels,
    $MinComponentRatio,
    $OpaqueCheckerboard.IsPresent,
    $OpaqueBlack.IsPresent,
    $DryRun.IsPresent
)
