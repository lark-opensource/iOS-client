//
//  LanguageIconManager.swift
//  ByteView
//
//  Created by wulv on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignTheme

class LanguageIcon {

    let type: LanguageType
    let image: UIImage
    init(type: LanguageType, image: UIImage) {
        self.type = type
        self.image = image
    }
}

struct LanguageIconIdentifier: Hashable {
    let type: String
    let font: UIFont
    let foregroundColor: UIColor
    let backgroundColor: UIColor
    let size: CGSize

    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(font)
        hasher.combine(foregroundColor)
        hasher.combine(backgroundColor)
        hasher.combine("\(String(describing: size.width))\(String(describing: size.height))")
    }
}

extension LanguageIconManager {

    private static var _shared: LanguageIconManager?

    static var shared: LanguageIconManager {
        if let instance = _shared {
            return instance
        }
        _shared = LanguageIconManager()
        if let instance = _shared {
            return instance
        } else {
            fatalError("LanguageIconManager initialize fail")
        }
    }

    static func destroy() {
        _shared = nil
    }
}

class LanguageIconManager {

    enum DefaultConfig {
        static let size: CGSize = CGSize(width: 20, height: 20)
        static let font: UIFont = .systemFont(ofSize: 11.0)
        static let foregroundColor: UIColor = UIColor.ud.primaryOnPrimaryFill
        static let backgroundColor: UIColor = UIColor.ud.N500
    }

    var icons: [LanguageIconIdentifier: LanguageIcon] = [:]

    private init() {}

    static func get(by type: LanguageType,
                    font: UIFont? = nil,
                    foregroundColor: UIColor? = nil,
                    backgroundColor: UIColor? = nil,
                    size: CGSize? = nil) -> UIImage? {
        let langID = LanguageIconIdentifier(type: type.iconStr,
                                            font: font ?? DefaultConfig.font,
                                            foregroundColor: foregroundColor ?? DefaultConfig.foregroundColor,
                                            backgroundColor: backgroundColor ?? DefaultConfig.backgroundColor,
                                            size: size ?? DefaultConfig.size)
        var icon = shared.icons[langID]
        guard nil == icon else {
            return icon?.image
        }
        let lightImage = createIcon(with: langID.type,
                                    font: langID.font,
                                    foregroundColor: langID.foregroundColor.alwaysLight,
                                    backgroundColor: langID.backgroundColor.alwaysLight,
                                    size: langID.size)
        let darkImage = createIcon(with: langID.type,
                                   font: langID.font,
                                   foregroundColor: langID.foregroundColor.alwaysDark,
                                   backgroundColor: langID.backgroundColor.alwaysDark,
                                   size: langID.size)
        let image = UIImage.dynamic(light: lightImage, dark: darkImage)
        icon = LanguageIcon(type: type, image: image)
        shared.icons[langID] = icon
        return image
    }

    private static func createIcon(with text: String, font: UIFont, foregroundColor: UIColor, backgroundColor: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        let render = UIGraphicsImageRenderer(bounds: rect)
        let image = render.image { context in
            let cgContext = context.cgContext
            // add circular path
            let wRadius = size.width / 2
            let hRadius = size.height / 2
            let path = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: .allCorners,
                                    cornerRadii: CGSize(width: wRadius, height: hRadius))
            cgContext.addPath(path.cgPath)
            cgContext.clip()
            // fill background color
            cgContext.setFillColor(backgroundColor.cgColor)
            cgContext.fill(rect)
            // draw text
            let attributes = [NSAttributedString.Key.foregroundColor: foregroundColor,
                              NSAttributedString.Key.font: font]
            let textSize = text.vc.boundingSize(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), attributes: attributes)
            let textX = (size.width - textSize.width) / 2
            let textY = (size.height - textSize.height) / 2
            text.draw(in: CGRect(x: textX, y: textY, width: ceil(textSize.width), height: ceil(textSize.height)), withAttributes: attributes)
            // fill draw
            cgContext.drawPath(using: .fill)
        }
        return image
    }
}
