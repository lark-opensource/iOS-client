//
//  UDButton+Theme.swift
//  UniverseDesignButton
//
//  Created by 姚启灏 on 2020/9/9.
//

import Foundation
import UniverseDesignColor

// swiftlint:disable all

public extension UDButton {
    /// Mainly refers to the blue flat button
    static var primaryBlue: UDButton {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        return button
    }

    /// Mainly refers to the red flat button
    static var primaryRed: UDButton {
        let button = UDButton(UDButtonUIConifg.primaryRed)
        return button
    }

    /// Gray stroke buttons (including rectangular buttons and full-width buttons)
    static var secondaryGray: UDButton {
        let button = UDButton(UDButtonUIConifg.secondaryGray)
        return button
    }

    /// Blue stroke buttons (including rectangular buttons and full-width buttons)
    static var secondaryBlue: UDButton {
        let button = UDButton(UDButtonUIConifg.secondaryBlue)
        return button
    }

    /// Red stroke buttons (including rectangular buttons and full-width buttons)
    static var secondaryRed: UDButton {
        let button = UDButton(.secondaryRed)
        return button
    }

    /// Gray text type button
    static var textGray: UDButton {
        let button = UDButton(UDButtonUIConifg.textGray)
        return button
    }

    /// Blue text type button
    static var textBlue: UDButton {
        let button = UDButton(UDButtonUIConifg.textBlue)
        return button
    }

    /// Red text type button
    static var textRed: UDButton {
        let button = UDButton(UDButtonUIConifg.textRed)
        return button
    }
}
// swiftlint:enable all
