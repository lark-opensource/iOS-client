//
//  File.swift
//  UniverseDesignColor
//
//  Created by 白镜吾 on 2023/5/16.
//

import UIKit
import UniverseDesignTheme

// MARK: - Palette

public protocol UDColorPalette {}

extension UDColorPalette {

    /// Basic red.
    public static var red: UIColor { return UDColor.colorfulRed }

    /// Basic orange.
    public static var orange: UIColor { return UDColor.colorfulOrange }

    /// Basic yellow.
    public static var yellow: UIColor { return UDColor.colorfulYellow }

    /// Basic sunflower.
    public static var sunflower: UIColor { return UDColor.colorfulSunflower }

    /// Basic orange.
    public static var lime: UIColor { return UDColor.colorfulLime }

    /// Basic green.
    public static var green: UIColor { return UDColor.colorfulGreen }

    /// Basic turquoise.
    public static var turquoise: UIColor { return UDColor.colorfulTurquoise }

    /// Basic wathet.
    public static var wathet: UIColor { return UDColor.colorfulWathet }

    /// Basic blue.
    public static var blue: UIColor { return UDColor.colorfulBlue }

    /// Basic indigo.
    public static var indigo: UIColor { return UDColor.colorfulIndigo }

    /// Basic purple.
    public static var purple: UIColor { return UDColor.colorfulPurple }

    /// Basic violet.
    public static var violet: UIColor { return UDColor.colorfulViolet }

    /// Basic carmine.
    public static var carmine: UIColor { return UDColor.colorfulCarmine }
}

extension UDColor: UDColorPalette {}
extension UDComponentsExtension: UDColorPalette where BaseType == UIColor {}
