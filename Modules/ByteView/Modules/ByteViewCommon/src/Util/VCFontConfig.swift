//
//  NSAttributedExtensions.swift
//  ByteView
//
//  Created by liurundong.henry on 2019/12/25.
//

import Foundation
import UniverseDesignFont

// disable-lint: magic number
/// 字体模板内容
public struct VCFontConfig {
    public enum FontStyle {
        /// systemFont
        case normal
        /// (iOS 13+ only) monospacedSystemFont
        case monospaced
        /// monospacedDigitSystemFont
        case monospacedDigit
    }

    public var fontSize: CGFloat
    public var fontStyle: FontStyle
    public var lineHeight: CGFloat
    public var fontWeight: UIFont.Weight
    public var lineHeightMultiple: CGFloat?

    public var font: UIFont {
        switch fontStyle {
        case .normal:
            return UDFont.systemFont(ofSize: fontSize, weight: fontWeight)
        case .monospaced:
            if #available(iOS 13.0, *) {
                // UDFont 目前还不支持全部等宽，先用系统默认实现
                return UIFont.monospacedSystemFont(ofSize: fontSize, weight: fontWeight)
            } else {
                // fallback
                return UDFont.systemFont(ofSize: fontSize, weight: fontWeight)
            }
        case .monospacedDigit:
            return UDFont.monospacedDigitSystemFont(ofSize: fontSize, weight: fontWeight)
        }
    }

    // https://bytedance.larkoffice.com/docx/CXpvdmON5oHmlAxB94EcMYYHnHf
    var labelBaselineFactor: CGFloat {
        if #available(iOS 16.4, *) {
            return 2.0
        }
        return 4.0
    }

    public init(fontSize: CGFloat, fontStyle: FontStyle = .normal, lineHeight: CGFloat, fontWeight: UIFont.Weight) {
        self.fontSize = fontSize
        self.fontStyle = fontStyle
        self.lineHeight = lineHeight
        self.fontWeight = fontWeight
    }

    public func toAttributes(alignment: NSTextAlignment = .left, lineBreakMode: NSLineBreakMode = .byWordWrapping,
                             textColor: UIColor? = nil) -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = self.lineHeight
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.alignment = alignment
        style.lineBreakMode = lineBreakMode
        if let lineHeightMultiple = self.lineHeightMultiple {
            style.lineHeightMultiple = lineHeightMultiple
        }
        let font = self.font
        let offset = (lineHeight - font.lineHeight) / labelBaselineFactor
        var attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: style, .baselineOffset: offset, .font: font]
        if let textColor = textColor {
            attributes[.foregroundColor] = textColor
        }
        return attributes
    }
}

public extension VCFontConfig {

    /// 特大标题，字号26，行高34，semibold
    static let h0 = VCFontConfig(fontSize: 26, lineHeight: 34, fontWeight: .semibold)

    /// 一级标题，字号24，行高32，semibold
    static let h1 = VCFontConfig(fontSize: 24, lineHeight: 32, fontWeight: .semibold)

    /// 二级标题，字号20，行高28，medium
    static let h2 = VCFontConfig(fontSize: 20, lineHeight: 28, fontWeight: .medium)

    /// 三级标题，字号17，行高24，medium
    static let h3 = VCFontConfig(fontSize: 17, lineHeight: 24, fontWeight: .medium)

    /// 四级标题，字号17，行高24，regular
    static let h4 = VCFontConfig(fontSize: 17, lineHeight: 24, fontWeight: .regular)

    /// 辅助标题，字号16，行高22，medium
    static let hAssist = VCFontConfig(fontSize: 16, lineHeight: 22, fontWeight: .medium)

    /// 正文，字号16，行高22，regular
    static let body = VCFontConfig(fontSize: 16, lineHeight: 22, fontWeight: .regular)

    /// 正文大辅助，字号14，行高20，medium
    static let boldBodyAssist = VCFontConfig(fontSize: 14, lineHeight: 20, fontWeight: .medium)

    /// 正文辅助，字号14，行高20，regular
    static let bodyAssist = VCFontConfig(fontSize: 14, lineHeight: 20, fontWeight: .regular)

    /// 辅助，字号12，行高18，medium
    static let assist = VCFontConfig(fontSize: 12, lineHeight: 18, fontWeight: .medium)

    /// 小辅助，字号12，行高18，regular
    static let tinyAssist = VCFontConfig(fontSize: 12, lineHeight: 18, fontWeight: .regular)

    /// 次小辅助，字号10，行高14，medium
    static let tinierAssist = VCFontConfig(fontSize: 10, lineHeight: 14, fontWeight: .medium)

    /// 最小辅助，字号10，行高13，regular
    static let tiniestAssist = VCFontConfig(fontSize: 10, lineHeight: 13, fontWeight: .regular)
    static let boldTiniestAssist = VCFontConfig(fontSize: 10, lineHeight: 13, fontWeight: .medium)

    /// 字幕，字号13，行高16，regular
    static let subtitle = VCFontConfig(fontSize: 13, lineHeight: 16, fontWeight: .regular)

    /// 字幕，字号16，行高24，regular
    static let subtitlePad = VCFontConfig(fontSize: 16, lineHeight: 24, fontWeight: .regular)

    static let r_12_18 = VCFontConfig(fontSize: 12, lineHeight: 18, fontWeight: .regular)
    static let r_14_22 = VCFontConfig(fontSize: 14, lineHeight: 22, fontWeight: .regular)
    static let r_16_24 = VCFontConfig(fontSize: 16, lineHeight: 24, fontWeight: .regular)

    static let m_14_22 = VCFontConfig(fontSize: 14, lineHeight: 22, fontWeight: .medium)
    static let m_16_24 = VCFontConfig(fontSize: 16, lineHeight: 24, fontWeight: .medium)
    static let m_17_26 = VCFontConfig(fontSize: 17, lineHeight: 26, fontWeight: .medium)
}

public extension NSAttributedString {

    convenience init(string: String,
                     config: VCFontConfig,
                     alignment: NSTextAlignment = .left,
                     lineBreakMode: NSLineBreakMode = .byWordWrapping,
                     textColor: UIColor? = nil) {
        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = config.lineHeight
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.alignment = alignment
        style.lineBreakMode = lineBreakMode
        if let lineHeightMultiple = config.lineHeightMultiple {
            style.lineHeightMultiple = lineHeightMultiple
        }
        let font = config.font
        let offset = (lineHeight - font.lineHeight) / config.labelBaselineFactor
        var attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: style,
                                                         .baselineOffset: offset,
                                                         .font: font]
        if let textColor = textColor {
            attributes[.foregroundColor] = textColor
        }
        self.init(string: string, attributes: attributes)
    }
}
