//
//  UDColor+Gradient.swift
//  UniverseDesignColor
//
//  Created by dongwei.1615 on 2023年06月09日 14:50:17.
//  ！！本文件由脚本生成，如需改动，请修改 colorGradient.py 脚本！！
//

import FigmaKit
import UniverseDesignTheme

// swiftlint:disable all
fileprivate extension UDColor {
    static func fromGradientWithDirection(_ direction: GradientDirection, size: CGSize, colors: [UIColor], type: GradientType = .linear) -> UIColor? {
        return UIColor.fromGradientWithType(type, direction: direction, frame:  CGRect(origin: .zero, size: size), colors: colors)
    }
}

public extension GradientPattern {

    @available(*, deprecated, message: "不要这么用！GradientPattern 是一个整体，转成 cgColors 会丢失其他信息")
    var cgColors: [CGColor] {
        colors.map { $0.cgColor }
    }
}

extension UDColor {

    public static func gradientBlue(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [B400, B500 & B350])
    }

    public static func gradientCarmine(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [C400 & C500, C500 & C400])
    }

    public static func gradientGreen(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [G300 & G500, G350 & G400])
    }

    public static func gradientIndigo(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [I400, I500 & I350])
    }

    public static func gradientLime(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [L200 & L600, L300 & L500])
    }

    public static func gradientOrange(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [O300 & O600, O350 & O500])
    }

    public static func gradientPurple(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [P400, P500 & P350])
    }

    public static func gradientRed(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [R350 & R500, R400])
    }

    public static func gradientTurquoise(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [T200 & T600, T300 & T500])
    }

    public static func gradientViolet(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [V350 & V500, V400])
    }

    public static func gradientWathet(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [W300 & W500, W350 & W400])
    }

    public static func gradientYellow(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [Y350 & Y500, Y400])
    }

    public static func VnextBgGradient(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.leftToRight, size: size, colors: [N00.withAlphaComponent(0.05) & N50.withAlphaComponent(0.05), N600.withAlphaComponent(0.05) & N00.withAlphaComponent(0.05)])
    }

    public static func AIPrimaryFillDefault(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500 & I400, V350 & V300])
    }

    public static func AIPrimaryFillHover(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I400 & I350, V300 & V200])
    }

    public static func AIPrimaryFillPressed(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I600 & I500, V400 & V350])
    }

    public static func AIPrimaryFillLoading(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500.withAlphaComponent(0.60) & I400.withAlphaComponent(0.60), V350.withAlphaComponent(0.60) & V300.withAlphaComponent(0.60)])
    }

    public static func AIPrimaryContentDefault(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I600 & I500, V400])
    }

    public static func AIPrimaryContentHover(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500 & I400, V350])
    }

    public static func AIPrimaryContentPressed(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I600, V500])
    }

    public static func AIPrimaryContentLoading(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I600.withAlphaComponent(0.60) & I500.withAlphaComponent(0.60), V400.withAlphaComponent(0.60)])
    }

    public static func AIPrimaryFillSolid01(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I50, V50])
    }

    public static func AIPrimaryFillSolid02(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I100, V100])
    }

    public static func AIPrimaryFillSolid03(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I200, V200])
    }

    public static func AIPrimaryFillTransparent01(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500.withAlphaComponent(0.10) & I400.withAlphaComponent(0.15), V350.withAlphaComponent(0.10) & V350.withAlphaComponent(0.15)])
    }

    public static func AIPrimaryFillTransparent02(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500.withAlphaComponent(0.20) & I400.withAlphaComponent(0.25), V350.withAlphaComponent(0.20) & V350.withAlphaComponent(0.25)])
    }

    public static func AIPrimaryFillTransparent03(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500.withAlphaComponent(0.30) & I400.withAlphaComponent(0.35), V350.withAlphaComponent(0.30) & V350.withAlphaComponent(0.35)])
    }

    public static func AILoading(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.leftToRight, size: size, colors: [I600 & I500, V350])
    }

    public static func AISendicon(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.leftToRight, size: size, colors: [I600 & I400, P400])
    }

    public static func AIDynamicLine(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [V400 & V350, I600 & I400, I600 & I400, V400 & V350], type: .angular)
    }

}

extension UDComponentsExtension where BaseType == UIColor {

    public static func gradientBlue(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [B400, B500 & B350])
    }

    public static func gradientCarmine(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [C400 & C500, C500 & C400])
    }

    public static func gradientGreen(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [G300 & G500, G350 & G400])
    }

    public static func gradientIndigo(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [I400, I500 & I350])
    }

    public static func gradientLime(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [L200 & L600, L300 & L500])
    }

    public static func gradientOrange(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [O300 & O600, O350 & O500])
    }

    public static func gradientPurple(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [P400, P500 & P350])
    }

    public static func gradientRed(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [R350 & R500, R400])
    }

    public static func gradientTurquoise(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [T200 & T600, T300 & T500])
    }

    public static func gradientViolet(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [V350 & V500, V400])
    }

    public static func gradientWathet(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [W300 & W500, W350 & W400])
    }

    public static func gradientYellow(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [Y350 & Y500, Y400])
    }

    public static func VnextBgGradient(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.leftToRight, size: size, colors: [N00.withAlphaComponent(0.05) & N50.withAlphaComponent(0.05), N600.withAlphaComponent(0.05) & N00.withAlphaComponent(0.05)])
    }

    public static func AIPrimaryFillDefault(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500 & I400, V350 & V300])
    }

    public static func AIPrimaryFillHover(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I400 & I350, V300 & V200])
    }

    public static func AIPrimaryFillPressed(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I600 & I500, V400 & V350])
    }

    public static func AIPrimaryFillLoading(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500.withAlphaComponent(0.60) & I400.withAlphaComponent(0.60), V350.withAlphaComponent(0.60) & V300.withAlphaComponent(0.60)])
    }

    public static func AIPrimaryContentDefault(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I600 & I500, V400])
    }

    public static func AIPrimaryContentHover(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500 & I400, V350])
    }

    public static func AIPrimaryContentPressed(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I600, V500])
    }

    public static func AIPrimaryContentLoading(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I600.withAlphaComponent(0.60) & I500.withAlphaComponent(0.60), V400.withAlphaComponent(0.60)])
    }

    public static func AIPrimaryFillSolid01(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I50, V50])
    }

    public static func AIPrimaryFillSolid02(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I100, V100])
    }

    public static func AIPrimaryFillSolid03(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I200, V200])
    }

    public static func AIPrimaryFillTransparent01(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500.withAlphaComponent(0.10) & I400.withAlphaComponent(0.15), V350.withAlphaComponent(0.10) & V350.withAlphaComponent(0.15)])
    }

    public static func AIPrimaryFillTransparent02(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500.withAlphaComponent(0.20) & I400.withAlphaComponent(0.25), V350.withAlphaComponent(0.20) & V350.withAlphaComponent(0.25)])
    }

    public static func AIPrimaryFillTransparent03(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal135, size: size, colors: [I500.withAlphaComponent(0.30) & I400.withAlphaComponent(0.35), V350.withAlphaComponent(0.30) & V350.withAlphaComponent(0.35)])
    }

    public static func AILoading(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.leftToRight, size: size, colors: [I600 & I500, V350])
    }

    public static func AISendicon(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.leftToRight, size: size, colors: [I600 & I400, P400])
    }

    public static func AIDynamicLine(ofSize size: CGSize) -> UIColor? {
        return UDColor.fromGradientWithDirection(.diagonal45, size: size, colors: [V400 & V350, I600 & I400, I600 & I400, V400 & V350], type: .angular)
    }

}

extension UDColor {

    public static var gradientBlue: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [B400, B500 & B350])
    }

    public static var gradientCarmine: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [C400 & C500, C500 & C400])
    }

    public static var gradientGreen: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [G300 & G500, G350 & G400])
    }

    public static var gradientIndigo: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [I400, I500 & I350])
    }

    public static var gradientLime: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [L200 & L600, L300 & L500])
    }

    public static var gradientOrange: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [O300 & O600, O350 & O500])
    }

    public static var gradientPurple: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [P400, P500 & P350])
    }

    public static var gradientRed: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [R350 & R500, R400])
    }

    public static var gradientTurquoise: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [T200 & T600, T300 & T500])
    }

    public static var gradientViolet: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [V350 & V500, V400])
    }

    public static var gradientWathet: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [W300 & W500, W350 & W400])
    }

    public static var gradientYellow: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [Y350 & Y500, Y400])
    }

    public static var VnextBgGradient: GradientPattern {
        return GradientPattern(direction: .leftToRight,
                               colors: [N00.withAlphaComponent(0.05) & N50.withAlphaComponent(0.05), N600.withAlphaComponent(0.05) & N00.withAlphaComponent(0.05)])
    }

    public static var AIPrimaryFillDefault: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500 & I400, V350 & V300])
    }

    public static var AIPrimaryFillHover: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I400 & I350, V300 & V200])
    }

    public static var AIPrimaryFillPressed: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I600 & I500, V400 & V350])
    }

    public static var AIPrimaryFillLoading: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500.withAlphaComponent(0.60) & I400.withAlphaComponent(0.60), V350.withAlphaComponent(0.60) & V300.withAlphaComponent(0.60)])
    }

    public static var AIPrimaryContentDefault: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I600 & I500, V400])
    }

    public static var AIPrimaryContentHover: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500 & I400, V350])
    }

    public static var AIPrimaryContentPressed: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I600, V500])
    }

    public static var AIPrimaryContentLoading: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I600.withAlphaComponent(0.60) & I500.withAlphaComponent(0.60), V400.withAlphaComponent(0.60)])
    }

    public static var AIPrimaryFillSolid01: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I50, V50])
    }

    public static var AIPrimaryFillSolid02: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I100, V100])
    }

    public static var AIPrimaryFillSolid03: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I200, V200])
    }

    public static var AIPrimaryFillTransparent01: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500.withAlphaComponent(0.10) & I400.withAlphaComponent(0.15), V350.withAlphaComponent(0.10) & V350.withAlphaComponent(0.15)])
    }

    public static var AIPrimaryFillTransparent02: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500.withAlphaComponent(0.20) & I400.withAlphaComponent(0.25), V350.withAlphaComponent(0.20) & V350.withAlphaComponent(0.25)])
    }

    public static var AIPrimaryFillTransparent03: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500.withAlphaComponent(0.30) & I400.withAlphaComponent(0.35), V350.withAlphaComponent(0.30) & V350.withAlphaComponent(0.35)])
    }

    public static var AILoading: GradientPattern {
        return GradientPattern(direction: .leftToRight,
                               colors: [I600 & I500, V350])
    }

    public static var AISendicon: GradientPattern {
        return GradientPattern(direction: .leftToRight,
                               colors: [I600 & I400, P400])
    }

    public static var AIDynamicLine: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [V400 & V350, I600 & I400, I600 & I400, V400 & V350],
                               type: .angular)
    }

}

extension UDComponentsExtension where BaseType == UIColor {

    public static var gradientBlue: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [B400, B500 & B350])
    }

    public static var gradientCarmine: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [C400 & C500, C500 & C400])
    }

    public static var gradientGreen: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [G300 & G500, G350 & G400])
    }

    public static var gradientIndigo: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [I400, I500 & I350])
    }

    public static var gradientLime: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [L200 & L600, L300 & L500])
    }

    public static var gradientOrange: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [O300 & O600, O350 & O500])
    }

    public static var gradientPurple: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [P400, P500 & P350])
    }

    public static var gradientRed: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [R350 & R500, R400])
    }

    public static var gradientTurquoise: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [T200 & T600, T300 & T500])
    }

    public static var gradientViolet: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [V350 & V500, V400])
    }

    public static var gradientWathet: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [W300 & W500, W350 & W400])
    }

    public static var gradientYellow: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [Y350 & Y500, Y400])
    }

    public static var VnextBgGradient: GradientPattern {
        return GradientPattern(direction: .leftToRight,
                               colors: [N00.withAlphaComponent(0.05) & N50.withAlphaComponent(0.05), N600.withAlphaComponent(0.05) & N00.withAlphaComponent(0.05)])
    }

    public static var AIPrimaryFillDefault: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500 & I400, V350 & V300])
    }

    public static var AIPrimaryFillHover: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I400 & I350, V300 & V200])
    }

    public static var AIPrimaryFillPressed: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I600 & I500, V400 & V350])
    }

    public static var AIPrimaryFillLoading: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500.withAlphaComponent(0.60) & I400.withAlphaComponent(0.60), V350.withAlphaComponent(0.60) & V300.withAlphaComponent(0.60)])
    }

    public static var AIPrimaryContentDefault: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I600 & I500, V400])
    }

    public static var AIPrimaryContentHover: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500 & I400, V350])
    }

    public static var AIPrimaryContentPressed: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I600, V500])
    }

    public static var AIPrimaryContentLoading: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I600.withAlphaComponent(0.60) & I500.withAlphaComponent(0.60), V400.withAlphaComponent(0.60)])
    }

    public static var AIPrimaryFillSolid01: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I50, V50])
    }

    public static var AIPrimaryFillSolid02: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I100, V100])
    }

    public static var AIPrimaryFillSolid03: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I200, V200])
    }

    public static var AIPrimaryFillTransparent01: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500.withAlphaComponent(0.10) & I400.withAlphaComponent(0.15), V350.withAlphaComponent(0.10) & V350.withAlphaComponent(0.15)])
    }

    public static var AIPrimaryFillTransparent02: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500.withAlphaComponent(0.20) & I400.withAlphaComponent(0.25), V350.withAlphaComponent(0.20) & V350.withAlphaComponent(0.25)])
    }

    public static var AIPrimaryFillTransparent03: GradientPattern {
        return GradientPattern(direction: .diagonal135,
                               colors: [I500.withAlphaComponent(0.30) & I400.withAlphaComponent(0.35), V350.withAlphaComponent(0.30) & V350.withAlphaComponent(0.35)])
    }

    public static var AILoading: GradientPattern {
        return GradientPattern(direction: .leftToRight,
                               colors: [I600 & I500, V350])
    }

    public static var AISendicon: GradientPattern {
        return GradientPattern(direction: .leftToRight,
                               colors: [I600 & I400, P400])
    }

    public static var AIDynamicLine: GradientPattern {
        return GradientPattern(direction: .diagonal45,
                               colors: [V400 & V350, I600 & I400, I600 & I400, V400 & V350],
                               type: .angular)
    }

}
// swiftlint:enable all
