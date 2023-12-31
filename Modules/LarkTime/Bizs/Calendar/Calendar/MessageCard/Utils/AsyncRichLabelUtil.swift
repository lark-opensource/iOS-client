//
//  AsyncRichLabelUtil.swift
//  Calendar
//
//  Created by pluto on 2023/2/15.
//

import UIKit
import Foundation
import RichLabel

struct AsyncRichLabelUtil {
    
    //    用于在子线程构造富文本 插入自定义TagView
    //    老版rsvp使用，待移除
    static func transTagViewToNSMutableString(tagString: String, tagType: RSVPCardTagType, size: CGSize, margin: UIEdgeInsets, font: UIFont) -> NSAttributedString {
        let attachment = LKAsyncAttachment(
            viewProvider: {
                let tagView = RSVPCardTagView(tagString: tagString, tagType: tagType)
                return tagView
            },
            size: size
        )
        attachment.fontAscent = font.ascender
        attachment.fontDescent = font.descender
        attachment.size = size
        attachment.margin = margin
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName: attachment])
    }
    //    用于在子线程构造富文本 插入自定义TagView
    static func transTagViewToNSMutableString(tagData: CalendarEventCardTag, margin: UIEdgeInsets) -> NSAttributedString {
        let attachment = LKAsyncAttachment(
            viewProvider: {
                let tagView = RSVPCardTagView(tagString: tagData.title, tagType: tagData.type)
                return tagView
            },
            size: tagData.size
        )
        attachment.fontAscent = tagData.font.ascender
        attachment.fontDescent = tagData.font.descender
        attachment.size = tagData.size
        attachment.margin = margin
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName: attachment])
    }
    
    /// limitWidth：限宽 （可能是对多行文字的限宽）
    /// maxWidth： 屏幕宽度
    static func getTrimStrWithEllipsis(str: String, limitWidth: CGFloat, font: UIFont, maxWidth: CGFloat) -> String {
        if limitWidth < 0 { return str }
        let tailText = "..."
        let tailWidth = tailText.getWidth(font: font)
        var res: String = ""
        var currentWidth: CGFloat = 0
        
        var tmpStr: String = ""
        /// 换行补偿
        var offset: CGFloat = 0
        if str.getWidth(font: font) > limitWidth {
            for i in str {
                if currentWidth + "\(i)".getWidth(font: font) + offset > limitWidth - tailWidth - 4 {
                    break
                }
                
                /// 误差修正，字符串计算换行时会忽略一部分的offset，在这里计算补偿
                if tmpStr.getWidth(font: font) < maxWidth && (tmpStr + "\(i)").getWidth(font: font) > maxWidth {
                    offset += maxWidth - tmpStr.getWidth(font: font)
                    tmpStr = ""
                }
            
                res.append(i)
                currentWidth = res.getWidth(font: font)
                tmpStr.append(i)
            }
        } else {
            return str
        }
        return res + tailText
    }
    
    /*
     
     参数：标题文字、标题字体、标题富文本属性、tag数据、最大宽度、首tag边距（Tag和文字边距）、行数
     
     功能：用于卡片，生成富文本文字尾随标签
     支持多个标签、自定义首个标签左边距
     多个tag存在，tag间间距默认4
     
     内部逻辑： 裁剪字符串 构造tag，计算tagLeftMargin，拼接
     
     */
    static func getRichTextWithTrailingTags(titleStr: String, titleFont: UIFont, titleAttributes: [NSAttributedString.Key: Any], tagDataSource: [CalendarEventCardTag], maxWidth: CGFloat, fistTagLeftMargin: CGFloat, numberOfLines: Int, topMargin: CGFloat = 0) -> NSAttributedString {
        var preTrimStr: String = titleStr

        let blankNSAttributeStr: NSAttributedString = NSAttributedString(string: " ")
        let tagBetweenMargin: CGFloat = 4
        /// Tag宽度
        let tagWidth: CGFloat = tagDataSource.map{ $0.size.width }.reduce(0) { $0 + $1 }
        /// 算上TagMargin
        let tagRangeWidth: CGFloat = tagWidth + fistTagLeftMargin + tagBetweenMargin * CGFloat((tagDataSource.count - 1))
        /// 检查是否需要裁剪
        let needTrim: Bool = CGFloat(numberOfLines) * maxWidth < titleStr.getWidth(font: titleFont) + tagRangeWidth
        if needTrim {
            preTrimStr = getTrimStrWithEllipsis(str: preTrimStr, limitWidth: CGFloat(numberOfLines) * maxWidth - tagRangeWidth, font: titleFont, maxWidth: maxWidth)
        }
        
        /// 没有 Tag 直接返回文字
        if tagDataSource.count < 1 {
            return NSMutableAttributedString(string: preTrimStr, attributes: titleAttributes)
        }
        
        let fullTimeAttributeString: NSMutableAttributedString = NSMutableAttributedString(string: preTrimStr, attributes: titleAttributes)
        var isFistTag: Bool = true
        var currentWidth: CGFloat = floor(preTrimStr.getWidth(font: titleFont)).truncatingRemainder(dividingBy: floor(maxWidth))
        ///遍历Tag，逐个添加
        for item in tagDataSource {
            var tagAttributeStr: NSAttributedString
            currentWidth = floor(currentWidth).truncatingRemainder(dividingBy: floor(maxWidth))
            ///先计算tag的左margin
            if currentWidth == 0 {
                tagAttributeStr = AsyncRichLabelUtil.transTagViewToNSMutableString(tagData: item, margin: UIEdgeInsets(top: topMargin, left: 0, bottom: 0, right: 0))
                currentWidth = item.size.width
            } else {
                let leftMargin = isFistTag ? fistTagLeftMargin : tagBetweenMargin
                /// 计算是否需要重新起一行
                let needStartInNewLine: Bool = currentWidth + item.size.width + leftMargin > maxWidth
                /// 处理：不换行需要leftMargin，换行leftMargin为0，当tag刚好不用margin就能放下时的case，手动补个空格
                let isInBorderCase =  needStartInNewLine && currentWidth + item.size.width <= maxWidth
                
                tagAttributeStr = AsyncRichLabelUtil.transTagViewToNSMutableString(tagData: item, margin: UIEdgeInsets(top: topMargin, left:  needStartInNewLine ? 0 : leftMargin, bottom: 0, right: 0))
                
                if needStartInNewLine {
                    currentWidth = item.size.width
                    if isInBorderCase { fullTimeAttributeString.append(blankNSAttributeStr) }
                } else {
                    currentWidth += item.size.width + leftMargin
                }
            }
            fullTimeAttributeString.append(tagAttributeStr)
            isFistTag = false
        }
        
        return fullTimeAttributeString
    }
    
    /*
     
     参数：尾随字符串、发送人姓名、富文本属性、字体格式、卡片宽度、首tag边距（Tag和文字边距）、行数
     
     功能：用于卡片，生成富文本文字尾随字符串
     尾随字符串可以跟着发送人姓名一起换行
     
     内部逻辑： 裁剪字符串 拼接
     
     */
    
    static func getSubtitleTrimText(senderUserActionTag: String, senderUserName: String, attributes: [NSAttributedString.Key: Any], font: UIFont, contentWidth: CGFloat, fistTagLeftMargin: CGFloat, numberOfLines: Int) -> NSAttributedString? {
        var preTrimStr: String = senderUserName

        /// Tag宽度
        let tagWidth: CGFloat = senderUserActionTag.getWidth(font: font)
        /// 算上TagMargin
        let tagRangeWidth: CGFloat = tagWidth + fistTagLeftMargin
        /// 检查是否需要裁剪
        let needTrim: Bool = CGFloat(numberOfLines) * contentWidth < preTrimStr.getWidth(font: font) + tagRangeWidth
        if needTrim {
            preTrimStr = getTrimStrWithEllipsis(str: preTrimStr, limitWidth: CGFloat(numberOfLines) * contentWidth - tagRangeWidth, font: font, maxWidth: contentWidth)
        }
        
        return NSMutableAttributedString(string: preTrimStr + senderUserActionTag, attributes: attributes)
    }
}
