//
//  IconDrawable.swift
//  IconfontGen
//
//  Created by yangyao on 2019/10/3.
//

import UIKit
import CoreText
import LarkStorage
import LKCommonsLogging

private let renderLayer = ShapeLayer()
private let logger = Logger.log(Iconfont.self, category: "Minutes")

public final class Iconfont: IconRegister {
    public internal(set) static var fontNameCGPathMapper: [String: CGPath] = [:]
    private(set) static var iconImageCache = IconImageCache<NSString, UIImage>()
    public static var isRegistered: Bool = false
    public static var useResourceBundles = true
}

public protocol IconRegister {
    static func setup()
    static var isRegistered: Bool { get set }
    static var useResourceBundles: Bool { get set }
}

extension IconRegister {
    public static func setup() {
        if isRegistered {
            return
        }
        var bundle = BundleConfig.SelfBundle
        if useResourceBundles {
            bundle = BundleConfig.MinutesBundle
        }
        if let url = bundle.url(forResource: "iconfont",
                           withExtension: "ttf") {
            if Icon.register(url) {
                isRegistered = true
            }
        } else {
            logger.warn("Could not find ttf file")
            assertionFailure("Could not find ttf file")
        }
    }
}

public protocol IconDrawable {
    static var familyName: String { get }
    static var count: Int { get }
    var name: String { get }
    var unicode: String { get }
    var path: CGPath? { get }

    init(named iconName: String)

    func shapeImage() -> UIImage?
    func shapeImage(of color: UIColor?) -> UIImage?
    func shapeImage(ofHeight height: CGFloat, color: UIColor?) -> UIImage?
    func shapeImage(ofWidth width: CGFloat, color: UIColor?) -> UIImage?
    func shapeImage(of size: CGSize, color: UIColor?) -> UIImage?
    func shapeImage(of size: CGSize, color: UIColor?, contentsGravity: CALayerContentsGravity) -> UIImage?

    func attributedString(of pointSize: CGFloat, color: UIColor?) -> NSAttributedString?
    func attributedString(of pointSize: CGFloat, color: UIColor?, edgeInsets: UIEdgeInsets) -> NSAttributedString?
    func fontImage(of dimension: CGFloat, color: UIColor?) -> UIImage?
    func fontImage(of dimension: CGFloat, color: UIColor?, edgeInsets: UIEdgeInsets) -> UIImage?
    func fontImage(of size: CGSize, color: UIColor?) -> UIImage?
    func fontImage(of size: CGSize, color: UIColor?, edgeInsets: UIEdgeInsets) -> UIImage?

    static func font(of fontSize: CGFloat) -> UIFont?

    static func register(_ url: URL) -> Bool
    static func unregister(_ url: URL)
}

extension IconDrawable {
    public func shapeImage() -> UIImage? {
        return shapeImage(of: nil)
    }

    public func shapeImage(of color: UIColor?) -> UIImage? {
        guard let path = self.path else { return nil }
        return shapeImage(of: path.boundingBoxOfPath.size, color: color, contentsGravity: .resizeAspect)
    }

    public func shapeImage(ofHeight height: CGFloat, color: UIColor?) -> UIImage? {
        guard let path = self.path else { return nil }
        let pathSize = path.boundingBoxOfPath.size
        return shapeImage(of: CGSize(width: pathSize.width / pathSize.height * height, height: height),
                          color: color,
                          contentsGravity: .resizeAspect)
    }

    public func shapeImage(ofWidth width: CGFloat, color: UIColor?) -> UIImage? {
        guard let path = self.path else { return nil }
        let pathSize = path.boundingBoxOfPath.size
        return shapeImage(of: CGSize(width: width,
                                     height: pathSize.height / pathSize.width * width),
                          color: color,
                          contentsGravity: .resizeAspect)
    }

    public func shapeImage(of size: CGSize, color: UIColor?) -> UIImage? {
        guard self.path != nil else { return nil }
        return shapeImage(of: size, color: color, contentsGravity: .resizeAspect)
    }

    public func shapeImage(of size: CGSize, color: UIColor?, contentsGravity: CALayerContentsGravity) -> UIImage? {
        Iconfont.setup()

        let key = "\(name)_\(size)_\((color ?? .clear).hexComponents)_\(contentsGravity.rawValue)"
        if let image = Iconfont.iconImageCache.image(forKey: key as NSString) {
            return image
        }
        guard self.path != nil else { return nil }

        renderLayer.fillColor = color?.cgColor
        renderLayer.iconDrawable = self
        renderLayer.contentsGravity = contentsGravity
        renderLayer.frame = CGRect(origin: .zero, size: size)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 0.0
        let rect = CGRect(origin: .zero, size: size)
        let render = UIGraphicsImageRenderer(bounds: rect, format: format)
        let image = render.image { renderContext in
            renderContext.cgContext.saveGState()
            renderLayer.layoutIfNeeded()
            renderLayer.render(in: renderContext.cgContext)
            renderContext.cgContext.restoreGState()
        }
        Iconfont.iconImageCache.set(image, forKey: key as NSString)
        return image
    }

    public func attributedString(of pointSize: CGFloat, color: UIColor?) -> NSAttributedString? {
        guard let font = Self.font(of: pointSize) else { return nil }

        var attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        if let color = color {
            attributes[NSAttributedString.Key.foregroundColor] = color
        }
        return NSAttributedString(string: unicode, attributes: attributes)
    }

    public func attributedString(of pointSize: CGFloat,
                                 color: UIColor?,
                                 edgeInsets: UIEdgeInsets) -> NSAttributedString? {
        guard Self.font(of: pointSize) != nil else { return nil }
        guard let aString = attributedString(of: pointSize, color: color) else { return nil }

        let mString = NSMutableAttributedString(attributedString: aString)
        let range = NSRange(location: 0, length: mString.length)

        mString.addAttribute(NSAttributedString.Key.baselineOffset,
                             value: edgeInsets.bottom - edgeInsets.top,
                             range: range)

        let leftSpace = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.kern: edgeInsets.left])
        let rightSpace = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.kern: edgeInsets.right])

        mString.insert(rightSpace, at: mString.length)
        mString.insert(leftSpace, at: 0)

        return mString
    }

    public func fontImage(of dimension: CGFloat, color: UIColor?) -> UIImage? {
        return fontImage(of: CGSize(width: dimension, height: dimension), color: color, edgeInsets: .zero)
    }

    public func fontImage(of dimension: CGFloat, color: UIColor?, edgeInsets: UIEdgeInsets) -> UIImage? {
        return fontImage(of: CGSize(width: dimension, height: dimension), color: color, edgeInsets: edgeInsets)
    }

    public func fontImage(of size: CGSize, color: UIColor?) -> UIImage? {
        return fontImage(of: size, color: color, edgeInsets: .zero)
    }

    public func fontImage(of size: CGSize, color: UIColor?, edgeInsets: UIEdgeInsets) -> UIImage? {
        Iconfont.setup()

        let key = "\(name)_\(size)_\((color ?? .clear).hexComponents)_none"
        if let image = Iconfont.iconImageCache.image(forKey: key as NSString) {
            return image
        }

        let pointSize = min(size.width, size.height)
        guard Self.font(of: pointSize) != nil else { return nil }
        guard let aString = attributedString(of: pointSize, color: color) else { return nil }
        let mString = NSMutableAttributedString(attributedString: aString)

        var rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        rect.origin.y -= edgeInsets.top
        rect.size.width -= edgeInsets.left + edgeInsets.right
        rect.size.height -= edgeInsets.top + edgeInsets.bottom

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let range = NSRange(location: 0, length: mString.length)

        mString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 0.0
        let render = UIGraphicsImageRenderer(bounds: rect, format: format)
        let image = render.image { _ in
            mString.draw(in: rect)
        }

        Iconfont.iconImageCache.set(image, forKey: key as NSString)
        return image
   }

    public static func font(of fontSize: CGFloat) -> UIFont? {
        // 默认大小12
        let size = (fontSize == 0) ? 12.0 : fontSize
        return UIFont(name: familyName, size: size)
    }

    public static func unregister(_ url: URL) {
        var error: Unmanaged<CFError>?
        if CTFontManagerUnregisterFontsForURL(url as CFURL, .none, &error) == false || error != nil {
            logger.warn("Failed unregistering font with name '\(familyName)' at " +
                            "path '\(url)' with error: \(String(describing: error)).")
            assertionFailure("Failed unregistering font with name '\(familyName)' at " +
                "path '\(url)' with error: \(String(describing: error)).")
        }
    }

    public static func register(_ url: URL) -> Bool {
        if (try? NSData.read(from: url.asAbsPath())) == nil {
            return false
        }
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .none, &error) == false || error != nil {
            logger.warn("Failed registering font with the postscript name '\(familyName)' at " +
                            "path '\(url)' with error: \(String(describing: error)).")
            assertionFailure("Failed registering font with the postscript name '\(familyName)' at " +
                "path '\(url)' with error: \(String(describing: error)).")
            return false
        }

        let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor]
        guard let descriptor = descriptors?.first else {
            logger.warn("Descriptor is nil")
            return false
        }
        let ctFont = CTFontCreateWithFontDescriptorAndOptions(descriptor, 0.0, nil, .preventAutoActivation)
        let characterSet: CFCharacterSet = CTFontCopyCharacterSet(ctFont)

        for unicode in 0xE000...0xF8FF {
            guard let unicodeScalar = UnicodeScalar(unicode) else {
                logger.warn("UnicodeScalar is nil")
                break
            }
            let uniChar = UniChar(unicodeScalar.value)
            if CFCharacterSetIsCharacterMember(characterSet, uniChar) {
                var codePoint: [UniChar] = [uniChar]
                var glyphs: [CGGlyph] = [0, 0]
                CTFontGetGlyphsForCharacters(ctFont, &codePoint, &glyphs, glyphs.count)
                if glyphs.isEmpty {
                    continue
                }
                let glyph = glyphs[0]
                if let path = CTFontCreatePathForGlyph(ctFont, glyph, nil), let name = getIconName(unicode: unicode) {
                    let scale = CGAffineTransform(scaleX: 1, y: -1)
                    let translationX = -path.boundingBoxOfPath.origin.x
                    let translationY = path.boundingBoxOfPath.height + path.boundingBoxOfPath.origin.y
                    let translation = CGAffineTransform(translationX: translationX, y: translationY)
                    var transform = scale.concatenating(translation)

                    let transformedPath = path.copy(using: &transform)
                    Iconfont.fontNameCGPathMapper[name] = transformedPath
                }
            }
        }
        return true
    }

    private static func getIconName(unicode: Int) -> String? {
        for icon in Icon.allCases {
            for element in icon.unicode.unicodeScalars {
                if Int(element.value) == unicode {
                    return icon.name
                }
            }
        }
        return nil
    }
}
