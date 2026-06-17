import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let S = 1024
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func col(_ r: Double,_ g: Double,_ b: Double) -> CGColor { CGColor(red: r/255, green: g/255, blue: b/255, alpha: 1) }

// Fond noir profond
ctx.setFillColor(col(14,14,16))
ctx.fill(CGRect(x: 0, y: 0, width: S, height: S))

// Trois barres rouges en bas (clin d'oeil au vrai logo du Romandie)
ctx.setFillColor(col(232,40,46))
let bx = 150.0, bw = 724.0, bh = 34.0
ctx.fill(CGRect(x: bx, y: 150, width: bw, height: bh))
ctx.fill(CGRect(x: bx, y: 95,  width: bw, height: bh))
ctx.fill(CGRect(x: bx, y: 40,  width: bw * 0.72, height: bh))

// Grand "R" rouge centré
let fontNames = ["HelveticaNeue-CondensedBlack", "HelveticaNeue-Bold", "Helvetica-Bold"]
var font: CTFont? = nil
for n in fontNames { let f = CTFontCreateWithName(n as CFString, 760, nil)
    if CTFontCopyPostScriptName(f) as String == n || font == nil { font = f; if (CTFontCopyPostScriptName(f) as String) == n { break } } }
let f = font!
let attrs = [kCTFontAttributeName: f, kCTForegroundColorAttributeName: col(232,40,46)] as CFDictionary
let attrStr = CFAttributedStringCreate(nil, "R" as CFString, attrs)!
let line = CTLineCreateWithAttributedString(attrStr)
let bounds = CTLineGetImageBounds(line, ctx)
let tx = (Double(S) - bounds.width)/2 - bounds.minX
let ty = (Double(S) - bounds.height)/2 - bounds.minY + 40  // remonte un peu au-dessus des barres
ctx.textPosition = CGPoint(x: tx, y: ty)
CTLineDraw(line, ctx)

let img = ctx.makeImage()!
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("ok", CTFontCopyPostScriptName(f) as String)
