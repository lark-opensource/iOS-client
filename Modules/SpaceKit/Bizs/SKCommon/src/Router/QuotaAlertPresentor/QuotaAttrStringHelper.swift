//
//  QuotaAttrStringHelper.swift
//  SKCommon
//
//  Created by bupozhuang on 2021/7/19.
//

import Foundation
import SKResource
import UniverseDesignColor
import SpaceInterface
import SKFoundation

public struct TipsOfFileUploadContext {
    public let type: QuotaAlertType
    public let template: String
    public let version: String
    public let maxSize: String
    public let verifiledSize: String?
    
}

class QuotaAttrStringHelper {
    static let adminsPlaceholder = "{{admins}}"
    static let ownerPlaceholder = "{{owner}}"
    static let usagePlcaceholder = "{{usage}}"
    static let limitedPlaceholder = "{{limited}}"
    static let versionPlaceholder = "{{version}}"
    static let maxSizePlaceholder = "{{max_size}}"
    static let adminsV2Placeholder = "{{admin}}"
    static let maxStatementPlaceholder = "{{max_statement}}"
    static let displayNamePlaceholder = "{{APP_DISPLAY_NAME}}"
    static let newLimitedPlaceholder = "{{num1}}"
    static let newUsagePlcaceholder = "{{num2}}"
    static let newAdminsV2Placeholder = "{{name}}"
    static let newLink = "{{link}}"
    //超级管理员和指定成员的文案
    static func tipsWithAdmin(template: String, usage: Int64, limited: Int64, admins: [QuotaContact], limitSize: Int) -> NSAttributedString {
        let usageString = NSAttributedString(string: usage.stringInGB, attributes: defaultAttr)
        let limitedString = NSAttributedString(string: limited.stringInGB, attributes: defaultAttr)
        
        let attrString = NSMutableAttributedString(string: template, attributes: defaultAttr)
        attrString.replace(placeholder: newUsagePlcaceholder, with: usageString)
        attrString.replace(placeholder: newLimitedPlaceholder, with: limitedString)
        let adminsAttrString = NSMutableAttributedString()
        for (index, item) in admins.enumerated() {
            guard index <= limitSize - 1 else {
                //联系人展示有上限，超级管理员最多展示3个，指定成员最多展示10个
                break
            }
            adminsAttrString.append(contactAttributedString(displayName: item.displayName,
                                                            attributeValue: QuotaAttributeInfo.quotaContact(qutoContact: item),
                                                            attributes: defaultAttr))
            if index < admins.count - 1 {
                let colon = NSAttributedString(string: "、", attributes: defaultAttr)
                adminsAttrString.append(colon)
            }
        }
        attrString.replace(placeholder: newAdminsV2Placeholder, with: adminsAttrString)
        return attrString
    }
    //文档链接的文案
    static func tipsWithUrlAdmin(template: String, usage: Int64, limited: Int64, admins: QuotaUrl?) -> NSAttributedString {
        let usageString = NSAttributedString(string: usage.stringInGB, attributes: defaultAttr)
        let limitedString = NSAttributedString(string: limited.stringInGB, attributes: defaultAttr)
        
        let attrString = NSMutableAttributedString(string: template, attributes: defaultAttr)
        attrString.replace(placeholder: newUsagePlcaceholder, with: usageString)
        attrString.replace(placeholder: newLimitedPlaceholder, with: limitedString)
        let adminsAttrString = NSMutableAttributedString()
        adminsAttrString.append(contactNewAttributedString(displayName: admins?.title ?? "", attributes: defaultAttr))
        adminsAttrString.addAttribute(QuotaContact.attributedStringAtInfoKey,
                                      value: QuotaAttributeInfo.link(url: admins?.url ?? ""),
                                          range: NSRange(location: 0, length: adminsAttrString.length))
        attrString.replace(placeholder: newLink, with: adminsAttrString)
        return attrString
    }
    
    static func tipsWithOriginAdmin(template: String, usage: Int64, limited: Int64, admins: [QuotaContact]) -> NSAttributedString {
        let usageString = NSAttributedString(string: usage.stringInGB, attributes: defaultAttr)
        let limitedString = NSAttributedString(string: limited.stringInGB, attributes: defaultAttr)
        
        let attrString = NSMutableAttributedString(string: template, attributes: defaultAttr)
        attrString.replace(placeholder: usagePlcaceholder, with: usageString)
        attrString.replace(placeholder: limitedPlaceholder, with: limitedString)
        let adminsAttrString = NSMutableAttributedString()
        for (index, item) in admins.enumerated() {
            guard index <= 2 else {
                break
            }
            adminsAttrString.append(contactAttributedString(displayName: item.displayName,
                                                            attributeValue: QuotaAttributeInfo.quotaContact(qutoContact: item),
                                                            attributes: defaultAttr))
            if index < admins.count - 1 {
                let colon = NSAttributedString(string: "、", attributes: defaultAttr)
                adminsAttrString.append(colon)
            }
        }
        attrString.replace(placeholder: adminsPlaceholder, with: adminsAttrString)
        return attrString
    }
    
    static func tipsWithOwner(template: String, usage: Int64, limited: Int64, owner: QuotaContact) -> NSAttributedString {
        let usageString = NSAttributedString(string: usage.stringInGB, attributes: defaultAttr)
        let limitedString = NSAttributedString(string: limited.stringInGB, attributes: defaultAttr)
        
        let attrString = NSMutableAttributedString(string: template, attributes: defaultAttr)
        attrString.replace(placeholder: usagePlcaceholder, with: usageString)
        attrString.replace(placeholder: limitedPlaceholder, with: limitedString)
        let ownerString = contactAttributedString(displayName: owner.displayName,
                                                  attributeValue: QuotaAttributeInfo.quotaContact(qutoContact: owner),
                                                  attributes: defaultAttr)
        // 有两个owner参数
        attrString.replace(placeholder: ownerPlaceholder, with: ownerString)
        attrString.replace(placeholder: ownerPlaceholder, with: ownerString)
        return attrString
    }
    
    static func tipsOfFileUploadWithOwner(type: QuotaAlertType, template: String, version: String, maxSize: String, verifiledSize: String?) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string: template, attributes: defaultAttr)
        if let size = verifiledSize {
            return setUnverifiledString(template: BundleI18n.SKResource.__CreationMobile_Drive_Upload_MaxSizeLessThan1GB_Unverified,
                                        verifiledSize: size,
                                        maxSize: maxSize)
        }
        
        let versionString = NSAttributedString(string: version, attributes: defaultAttr)
        let displayString = NSAttributedString(string: BundleI18n.bundleDisplayName, attributes: defaultAttr)
        let maxString = NSAttributedString(string: maxSizeStringOfQuotaType(type: type, maxSize: maxSize), attributes: defaultAttr)
        attrString.replace(placeholder: versionPlaceholder, with: versionString)
        attrString.replace(placeholder: maxStatementPlaceholder, with: maxString)
        attrString.replace(placeholder: displayNamePlaceholder, with: displayString)
        return attrString
    }
    
    static func tipsOfFileUploadWithAdmin(context: TipsOfFileUploadContext, info: QuotaUploadInfo) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string: context.template, attributes: defaultAttr)
        if let size = context.verifiledSize {
            return setUnverifiledString(template: BundleI18n.SKResource.__CreationMobile_Drive_Upload_MaxSizeLessThan1GB_Unverified,
                                        verifiledSize: size,
                                        maxSize: context.maxSize)
        }
        
        let versionString = NSAttributedString(string: context.version, attributes: defaultAttr)
        let displayString = NSAttributedString(string: BundleI18n.bundleDisplayName, attributes: defaultAttr)
        let maxString = NSAttributedString(string: maxSizeStringOfQuotaType(type: context.type, maxSize: context.maxSize), attributes: defaultAttr)
        attrString.replace(placeholder: displayNamePlaceholder, with: displayString)
        attrString.replace(placeholder: versionPlaceholder, with: versionString)
        attrString.replace(placeholder: maxStatementPlaceholder, with: maxString)
        let adminsAttrString = NSMutableAttributedString()
        for (index, item) in info.admins.enumerated() {
            guard index <= 2 else {
                break
            }
            adminsAttrString.append(contactAttributedString(displayName: item.displayName,
                                                            attributeValue: QuotaAttributeInfo.admin(admin: item),
                                                            attributes: defaultAttr))
            if index < info.admins.count - 1 {
                let colon = NSAttributedString(string: "、", attributes: defaultAttr)
                adminsAttrString.append(colon)
            }
        }
        attrString.replace(placeholder: adminsV2Placeholder, with: adminsAttrString)
        return attrString
    }
    
    private static func maxSizeStringOfQuotaType(type: QuotaAlertType, maxSize: String) -> String {
        switch type {
        case .bigFileUpload:
            return BundleI18n.SKResource.CreationMobile_Drive_Lark_Upload_Max_var(maxSize)
        case .bigFileToCopy:
            return BundleI18n.SKResource.CreationMobile_Drive_Lark_Duplicate_Max_var(maxSize)
        case .bigFileSaveToSpace:
            return BundleI18n.SKResource.CreationMobile_Drive_Lark_Save_Max_var(maxSize)
        default:
            assertionFailure("Quota type not bigFile Upload, copy, save")
            return ""
        }
    }
    
    static func tipsOfFileUploadLimitExceeded(template: String, maxSize: String) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string: template, attributes: defaultAttr)
        let maxSizeString = NSAttributedString(string: maxSize, attributes: defaultAttr)
        let displayString = NSAttributedString(string: BundleI18n.bundleDisplayName, attributes: defaultAttr)
        attrString.replace(placeholder: displayNamePlaceholder, with: displayString)
        attrString.replace(placeholder: maxSizePlaceholder, with: maxSizeString)
        return attrString
    }
    
    private static func setUnverifiledString(template: String, verifiledSize: String, maxSize: String) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string: template, attributes: defaultAttr)
        let verifiledSizeString = NSAttributedString(string: verifiledSize, attributes: defaultAttr)
        let maxString = NSAttributedString(string: BundleI18n.SKResource.CreationMobile_Drive_Lark_Upload_Max_var(maxSize), attributes: defaultAttr)
        attrString.replace(placeholder: maxStatementPlaceholder, with: maxString)
        attrString.replace(placeholder: maxSizePlaceholder, with: verifiledSizeString)
        var linkString = regularMatch(targetString: template)
        linkString = "<a>" + linkString + "</a>"
        let linkRange = attrString.mutableString.range(of: linkString)
        do {
            let url = try HelpCenterURLGenerator.generateURL(article: .quotaHelpCenter).absoluteString
            attrString.addAttributes([QuotaContact.attributedStringAtInfoKey: QuotaAttributeInfo.link(url: url),
                                      .foregroundColor: UIColor.ud.B400,
                                      .underlineColor: UIColor.clear],
                                     range: linkRange)
            let tmpStr = NSAttributedString(string: "", attributes: defaultAttr)
            attrString.replace(placeholder: "<a>", with: tmpStr)
            attrString.replace(placeholder: "</a>", with: tmpStr)
        } catch {
            DocsLogger.error("failed to generate helper center URL when setUnverifiledString from quotaHelpCenter", error: error)
        }
        return attrString
    }
    
    private static func regularMatch(targetString: String) -> String {
        let regex = try? NSRegularExpression(pattern: ">(.*?)<", options: [])
        var linkString = ""
        
        regex?.enumerateMatches(in: targetString, options: [], range: NSRange(location: 0, length: targetString.utf16.count)) { result, _, _ in
            if let r = result?.range(at: 1), let range = Range(r, in: targetString) {
                linkString = String(targetString[range])
            }
        }
        return linkString
    }
    
    static func defaultTips(template: String) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string: template, attributes: defaultAttr)
        return attrString
    }
    
    private static var defaultAttr: [NSAttributedString.Key: Any] {
        var attr = [NSAttributedString.Key: Any]()
        attr[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 14)
        attr[NSAttributedString.Key.foregroundColor] = UIColor.ud.N600
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.02
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4
        attr[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        return attr
    }
    
    private static func contactAttributedString(displayName: String,
                                                attributeValue: QuotaAttributeInfo,
                                         attributes: [NSAttributedString.Key: Any],
                                         lineBreakMode: NSLineBreakMode = .byWordWrapping) -> NSMutableAttributedString {
        // build attstr
        let attrString: NSMutableAttributedString
        let finalColor = UDColor.colorfulBlue & UIColor.ud.primaryContentDefault.alwaysDark

        attrString = NSMutableAttributedString(string: "@", attributes: [.foregroundColor: finalColor])
        attrString.append(NSMutableAttributedString(string: displayName, attributes: [.foregroundColor: finalColor]))
        let range = NSRange(location: 0, length: attrString.length)
        if let style = attributes[.paragraphStyle] as? NSMutableParagraphStyle {
            style.lineBreakMode = lineBreakMode
            var attriTemps = attributes
            attriTemps[.paragraphStyle] = style
            attriTemps[.foregroundColor] = finalColor
            attrString.addAttributes(attriTemps, range: range)
        } else {
            // 不使用外面设置的颜色
            var atAttributes = attributes
            atAttributes[NSAttributedString.Key.foregroundColor] = finalColor
            attrString.addAttributes(atAttributes, range: range)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode
            attrString.addAttributes([.paragraphStyle: paragraphStyle], range: range)
        }
        attrString.addAttribute(QuotaContact.attributedStringAtInfoKey, value: attributeValue, range: range)
        return attrString
    }
    
    private static func contactNewAttributedString(displayName: String,
                                         attributes: [NSAttributedString.Key: Any],
                                         lineBreakMode: NSLineBreakMode = .byWordWrapping) -> NSMutableAttributedString {
        // build attstr
        let attrString: NSMutableAttributedString
        let finalColor = UDColor.colorfulBlue & UIColor.ud.primaryContentDefault.alwaysDark

        attrString = NSMutableAttributedString(string: "", attributes: [.foregroundColor: finalColor])
        attrString.append(NSMutableAttributedString(string: displayName, attributes: [.foregroundColor: finalColor]))
        let range = NSRange(location: 0, length: attrString.length)
        if let style = attributes[.paragraphStyle] as? NSMutableParagraphStyle {
            style.lineBreakMode = lineBreakMode
            var attriTemps = attributes
            attriTemps[.paragraphStyle] = style
            attriTemps[.foregroundColor] = finalColor
            attrString.addAttributes(attriTemps, range: range)
        } else {
            // 不使用外面设置的颜色
            var atAttributes = attributes
            atAttributes[NSAttributedString.Key.foregroundColor] = finalColor
            attrString.addAttributes(atAttributes, range: range)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode
            attrString.addAttributes([.paragraphStyle: paragraphStyle], range: range)
        }
        //attrString.addAttribute(Self.attributedStringAtInfoKey, value: self, range: range)
        return attrString
    }
}


extension NSMutableAttributedString {
    // 替换mutableAttributedString中的占位符号
    func replace(placeholder: String, with attrString: NSAttributedString) {
        if self.mutableString.contains(placeholder) {
            let range = self.mutableString.range(of: placeholder)
            self.replaceCharacters(in: range, with: attrString)
        }
    }
}

private extension Int64 {
    var stringInGB: String {
        String(format: "%.2f", Float(self) / 1024.0 / 1024.0 / 1024.0)
    }
}
