//
//  Album+Colors.swift
//  Musician2
//
//  Created by Maksim Ivanov on 23.08.2026.
//

import SwiftUI

extension Album {

    /// The album's median color used as the background of the album views.
    var color: Color {
        Color(hex: albumMedianColor) ?? .clear
    }

    /// The color of the text drawn on top of the album's median color.
    var textColor: Color {
        color.toCharacterColor
    }
}
