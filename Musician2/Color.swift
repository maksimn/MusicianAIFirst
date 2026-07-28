//
//  Color.swift
//  Musician2
//
//  Created by Maksim Ivanov on 07.07.2026.
//

import SwiftUI

extension Color {

    init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }

        guard cleanHex.count == 6 else { return nil }

        var rgbValue: UInt64 = 0

        Scanner(string: cleanHex).scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    var isBright: Bool {
        guard let rgba = toRGBA() else { return true }

        let luminance = Double(0.299 * rgba.red + 0.587 * rgba.green + 0.114 * rgba.blue)

        return luminance > 0.7
    }

    /// Extracts RGBA values as Double (range 0.0 to 1.0)
    func toRGBA() -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        #if os(iOS) || os(tvOS) || os(watchOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (Double(red), Double(green), Double(blue), Double(alpha))
        }
        #elseif os(macOS)
        let nsColor = NSColor(self)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            return (
                Double(rgbColor.redComponent),
                Double(rgbColor.greenComponent),
                Double(rgbColor.blueComponent),
                Double(rgbColor.alphaComponent)
            )
        }
        #endif
        return nil
    }
}
