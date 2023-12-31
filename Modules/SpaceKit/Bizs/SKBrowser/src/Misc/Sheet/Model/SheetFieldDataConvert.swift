//
//  SheetFieldDataConvert.swift
//  SKBrowser
//
//  Created by JiayiGuo on 2021/5/14.
//  swiftlint:disable line_length


import SKFoundation
import SKCommon
import HandyJSON
import UniverseDesignTheme
import UniverseDesignColor
import UniverseDesignFont
import Foundation
import UIKit
import SpaceInterface

// 用于局部样式的数据转换，提供segmentArr到attString的转换
public final class SheetFieldDataConvert {
    required init() {}
    
    //中文不能渲染斜体 指定倾斜角度20
    static public func getItalicFont() -> UIFont {
        let matrix = CGAffineTransform(a: 1, b: 0, c: CGFloat(tanf(20 * Float(Double.pi) / 180)), d: 1, tx: 0, ty: 0)
        let desc = UIFontDescriptor(name: "", matrix: matrix)
        return UIFont(descriptor: desc, size: 16)
    }
    
    static public func convertFromStyleToAttributes(from style: SheetStyleJSON, isSpecial: Bool) -> [NSAttributedString.Key: Any] {
        var fieldFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        var descriptor = fieldFont.fontDescriptor

        if style.fontWeight == 700 && style.fontStyle == "normal" {
            descriptor = descriptor.withSymbolicTraits(.traitBold) ?? descriptor
            fieldFont = UIFont(descriptor: descriptor, size: 16)
        } else if style.fontWeight == 400 && style.fontStyle == "italic" {
            fieldFont = fieldFont.italic//getItalicFont()
        } else if style.fontWeight == 700 && style.fontStyle == "italic" {
            fieldFont = fieldFont.boldItalic //getItalicFont().bold()
        }
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: fieldFont
        ]
        
        attributes[SheetInputView.attributedStringStyleKey] = style
        if isSpecial {
            attributes[.foregroundColor] = UIColor.ud.colorfulBlue
        } else {
            attributes[.foregroundColor] = style.showColor
        }
        
        if style.fontStyle == "italic" {
            attributes[SheetInputView.attributedStringFontStyleKey] = "italic"
        }
        
        if style.textDecoration == "underline line-through" || style.textDecoration == "line-through underline" {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            attributes[.strikethroughStyle] = 1
        } else if style.textDecoration == "underline" {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        } else if style.textDecoration == "line-through" {
            attributes[.strikethroughStyle] = 1
        }
        
        return attributes
    }
    static private func getAtInfoFromMention(from mention: SheetMentionSegment) -> AtInfo {
        //根据前端传的mentionSeg得到atinfo 用来后面解析成富文本串
        if let atType = AtType(rawValue: mention.mentionType) {
            if mention.mentionType as Int == 0 {
                return AtInfo(type: atType, href: mention.link, token: mention.token, at: mention.name ?? "")   //类型是user 避免@重复转换
            } else {
                if UserScopeNoChangeFG.HZK.sheetCustomIconPart {
                    return AtInfo(type: atType, href: mention.link, token: mention.token, at: mention.text, iconInfoMeta: mention.iconInfo)
                } else {
                    return AtInfo(type: atType, href: mention.link, token: mention.token, at: mention.text)
                }
                
            }
        } else {
            return AtInfo(type: .unknown, href: mention.link, token: mention.token, at: mention.text)
        }
    }
    
    static private func getAtInfoFromAttach(from attach: SheetAttachmentSegment) -> AtInfo {
        return AtInfo(type: .sheetAttachment, href: "", token: attach.fileToken, at: attach.text)
    }
    
    
    static public func convertFromStyleAndText(style: SheetStyleJSON, text: String, isSpecial: Bool) -> NSMutableAttributedString {
        let attributes = convertFromStyleToAttributes(from: style, isSpecial: isSpecial)
        
        let attString = NSMutableAttributedString(string: text, attributes: attributes)
        attString.addAttribute(SheetInputView.attributedStringFontSizeKey, value: style.fontSize, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(SheetInputView.attributedStringFontFamilyKey, value: style.fontFamily, range: NSRange(location: 0, length: attString.length))
        
        return attString
    }
    
    static private func convertTextSegment(from textSegment: SheetTextSegment, cellStyle: SheetStyleJSON?) -> NSMutableAttributedString {
        let currentStyle = textSegment.style ?? cellStyle ?? SheetStyleJSON()   //样式优先当前seg，如果为空说明单元格中属性都相同，存在cellStyle中
        
        let attString = convertFromStyleAndText(style: currentStyle, text: textSegment.text, isSpecial: false)
        attString.addAttribute(SheetInputView.attributedStringSegmentKey, value: textSegment, range: NSRange(location: 0, length: attString.length))
        
        return attString
    }
    
    static private func convertMentionSegment(from mentionSegment: SheetMentionSegment, cellStyle: SheetStyleJSON?) -> NSMutableAttributedString {
        guard mentionSegment.text.count > 0 else { return NSMutableAttributedString() }
        let currentStyle = mentionSegment.style ?? cellStyle ?? SheetStyleJSON() //样式优先当前seg，如果为空说明单元格中属性都相同，存在cellStyle中
        let attributes = convertFromStyleToAttributes(from: currentStyle, isSpecial: true)
        let atInfo = getAtInfoFromMention(from: mentionSegment)
        let infoStr = atInfo.attributedString(attributes: attributes)
        let attString = NSMutableAttributedString(attributedString: infoStr)
        
        attString.addAttribute(SheetInputView.attributedStringFontSizeKey, value: currentStyle.fontSize, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(SheetInputView.attributedStringFontFamilyKey, value: currentStyle.fontFamily, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(AtInfo.attributedStringAtInfoKey, value: atInfo, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(AtInfo.attributedStringAtInfoKeyStart, value: "start", range: NSRange(location: 0, length: 1)) //添加at属性
        attString.addAttribute(SheetInputView.attributedStringSegmentKey, value: mentionSegment, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(SheetInputView.attributedStringSpecialKey, value: "special", range: NSRange(location: 0, length: attString.length))
        
        return attString
    }
    
    static private func convertHyperLinkSegment(from hyperLinkSegment: SheetHyperLinkSegment, cellStyle: SheetStyleJSON?) -> NSMutableAttributedString {
        let attString = NSMutableAttributedString()
        if let texts = hyperLinkSegment.texts {
            for currentText in texts {
                let currentStyle = currentText.style ?? cellStyle ?? SheetStyleJSON()
                attString.append(convertFromStyleAndText(style: currentStyle, text: currentText.text, isSpecial: true))
            }   //如果texts不为空，每一段属性都不同，单独转换
        } else {
            if let style = hyperLinkSegment.style {
                attString.append(convertFromStyleAndText(style: style, text: hyperLinkSegment.text, isSpecial: true))
            } else if let cellStyle = cellStyle {
                attString.append(convertFromStyleAndText(style: cellStyle, text: hyperLinkSegment.text, isSpecial: true))
            }
            
        }   //如果属性都相同 直接转text
        let url = URL(string: hyperLinkSegment.text) ?? URL(string: "")
        attString.addAttribute(AtInfo.attributedStringURLKey, value: url, range: NSRange(location: 0, length: attString.length)) //url需要支持中间编辑 不加at key
        attString.addAttribute(SheetInputView.attributedStringSegmentKey, value: hyperLinkSegment, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(SheetInputView.attributedStringHyperLinkIdKey, value: UInt64.random(in: .min ... .max), range: NSRange(location: 0, length: attString.length))   //富文本到segment arr的转化用随机uid来区分不同url
        attString.addAttribute(SheetInputView.attributedStringSpecialKey, value: "special", range: NSRange(location: 0, length: attString.length))
        
        return attString
    }
    
    static private func convertPanoSegment(from panoSegment: SheetPanoSegment, cellStyle: SheetStyleJSON?) -> NSMutableAttributedString {
        guard panoSegment.text.count > 0 else { return NSMutableAttributedString() }
        let currentStyle = panoSegment.style ?? cellStyle ?? SheetStyleJSON() //样式优先当前seg，如果为空说明单元格中属性都相同，存在cellStyle中
        let attString = convertFromStyleAndText(style: currentStyle, text: panoSegment.text, isSpecial: true)
        attString.addAttribute(AtInfo.attributedStringAtInfoKey, value: AtInfo.self, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(AtInfo.attributedStringAtInfoKeyStart, value: "start", range: NSRange(location: 0, length: 1))    //为了方便整体插入删除，pano也复用AtInfo逻辑
        attString.addAttribute(AtInfo.attributedStringPanoKey, value: "pano", range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(SheetInputView.attributedStringSegmentKey, value: panoSegment, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(SheetInputView.attributedStringSpecialKey, value: "special", range: NSRange(location: 0, length: attString.length))
        
        return attString
    }
    
    static private func convertAttachSegment(from attachSegment: SheetAttachmentSegment, cellStyle: SheetStyleJSON?, lineBreakMode: NSLineBreakMode?) -> NSMutableAttributedString {
        guard attachSegment.text.count > 0 else { return NSMutableAttributedString() }
        let currentStyle = attachSegment.style ?? cellStyle ?? SheetStyleJSON() //样式优先当前seg，如果为空说明单元格中属性都相同，存在cellStyle中
        let attributes = convertFromStyleToAttributes(from: currentStyle, isSpecial: true)
        let atInfo = getAtInfoFromAttach(from: attachSegment)
        let infoStr = atInfo.attributedString(attributes: attributes, lineBreakMode: lineBreakMode ?? .byWordWrapping)
        let attString = NSMutableAttributedString(attributedString: infoStr)
        
        attString.addAttribute(AtInfo.attributedStringAtInfoKey, value: atInfo, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(AtInfo.attributedStringAtInfoKeyStart, value: "start", range: NSRange(location: 0, length: 1))
        attString.addAttribute(AtInfo.attributedStringAttachmentKey, value: "attach", range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(SheetInputView.attributedStringSegmentKey, value: attachSegment, range: NSRange(location: 0, length: attString.length))
        attString.addAttribute(SheetInputView.attributedStringSpecialKey, value: "special", range: NSRange(location: 0, length: attString.length))
        
        return attString
    }
    
    static public func convertSegmentToAttString(from segmentArray: [SheetSegmentBase]?, cellStyle: SheetCustomCellStyle?) -> NSMutableAttributedString? {
        if let segmentArray = segmentArray {
            let attString = NSMutableAttributedString()
            for currentSegment in segmentArray {
                var segmentStr: NSMutableAttributedString?
                switch currentSegment.type {
                case .text:
                    segmentStr = convertTextSegment(from: currentSegment as? SheetTextSegment ?? SheetTextSegment(), cellStyle: cellStyle?.webCellStyle)
                case .mention:
                    segmentStr = convertMentionSegment(from: currentSegment as? SheetMentionSegment ?? SheetMentionSegment(), cellStyle: cellStyle?.webCellStyle)
                case .url:
                    segmentStr = convertHyperLinkSegment(from: currentSegment as? SheetHyperLinkSegment ?? SheetHyperLinkSegment(), cellStyle: cellStyle?.webCellStyle)
                case .embedImage:
                    ()  //不用做处理 最后当文本为空的时候判断传过来的数组是否为空
                case .pano:
                    segmentStr = convertPanoSegment(from: currentSegment as? SheetPanoSegment ?? SheetPanoSegment(), cellStyle: cellStyle?.webCellStyle)
                case .attachment:
                    var lineBreakMode: NSLineBreakMode?
                    if cellStyle?.needExtraStyle ?? false {
                        lineBreakMode = cellStyle?.attachmentLineBreakMode
                    }
                    segmentStr = convertAttachSegment(from: currentSegment as? SheetAttachmentSegment ?? SheetAttachmentSegment(), cellStyle: cellStyle?.webCellStyle, lineBreakMode: lineBreakMode)
                }
                
                if let segmentStr = segmentStr {
                    if let cellStyle = cellStyle, cellStyle.needExtraStyle {
                        //增加额外样式控制
                        modifySegmentSpacingIfNeed(attrString: segmentStr, spacing: cellStyle.paragraphSpacing)
                        if cellStyle.underlineInLink, currentSegment.type == .url || currentSegment.type == .attachment {
                            segmentStr.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: segmentStr.length))
                        }
                    }
                    attString.append(segmentStr)
                }
            }
            return attString
        } else {
            // 样式数组为空，使用单元格默认样式
            return nil
        }
    }
    
    private static func modifySegmentSpacingIfNeed(attrString: NSMutableAttributedString, spacing: CGFloat) {
        guard attrString.length > 0, spacing > 0 else {
            return
        }
        var attributes = attrString.attributes(at: 0, effectiveRange: nil)
        let paragraphStyle = getMutableParagraphStyle(in: attributes)
        paragraphStyle.paragraphSpacingBefore = spacing
        attributes[.paragraphStyle] = paragraphStyle
        attrString.addAttributes(attributes, range: NSRange(location: 0, length: attrString.length))
    }
    
    private static func getMutableParagraphStyle(in attributes: [NSAttributedString.Key: Any]) -> NSMutableParagraphStyle {
           var paragraphStyle: NSMutableParagraphStyle
           if let oldParagraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
               paragraphStyle = oldParagraphStyle.mutableParagraphStyle
           } else {
               paragraphStyle = NSMutableParagraphStyle()
           }
           return paragraphStyle
       }
}
