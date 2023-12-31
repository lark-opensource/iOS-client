//
//  BTUtil.swift
//  DocsSDK
//
//  Created by maxiao on 2019/12/11.
// swiftlint:disable file_length

import Foundation
import UIKit
import RxSwift
import SKCommon
import SKUIKit
import SKBrowser
import SKFoundation
import SKResource
import LarkUIKit
import EENavigator
import UniverseDesignToast
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor
import SpaceInterface

// swiftlint:disable type_body_length
final class BTUtil {
    
    // 卡片关闭时无需处理的前端action
    static let notNeedHandleActionWhenCardClose: [BTActionFromJS] = [.updateField, .updateRecord]
    
    // 颜色系推荐色ID
    // nolint: magic_number
    static let recommendColorList: [Int] = [40, 28, 27, 37, 25, 24, 23, 33, 41, 42, 43]

    //色板颜色排列顺序
    static let colorGroupList: [[Int]] = [
        [0, 18, 29, 40, 51],
        [2, 17, 28, 39, 50],
        [4, 16, 27, 38, 49],
        [7, 15, 26, 37, 48],
        [9, 14, 25, 36, 47],
        [3, 13, 24, 35, 46],
        [1, 12, 23, 34, 45],
        [5, 11, 22, 33, 44],
        [8, 19, 30, 41, 52],
        [6, 20, 31, 42, 53],
        [10, 21, 32, 43, 54]
    ]
    
    class func getColorGroupItems(colors: [BTColorModel], selectColorId: Int?) -> ([ColorItemNew], IndexPath) {
        var colorItems: [ColorItemNew] = []
        var selectedIndexPath: IndexPath = IndexPath(item: -1, section: -1)

        for (i, colorGroup) in BTUtil.colorGroupList.enumerated() {
            let colorItem = ColorItemNew()
            let topicColorId = BTUtil.recommendColorList[i]
            guard let topicColor = colors.first(where: { $0.id == topicColorId }) else {
                      break
                  }

            var colorList: [String] = []
            colorItem.topicColor = topicColor.color
            colorItem.defaultColor = topicColor.color
            for (j, colorId) in colorGroup.enumerated() {
                if colorId == selectColorId {
                    selectedIndexPath = IndexPath(item: j, section: i)
                }

                guard let color = colors.first(where: { $0.id == colorId }) else { break }
                colorList.append(color.color)
            }
            colorItem.colorList = colorList
            colorItems.append(colorItem)
        }
        
        return (colorItems, selectedIndexPath)
    }

    /// 获取卡片标题的样式
    class func getTitleAttrString(title: String) -> NSAttributedString {
        let fullAttString = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: UDColor.textTitle])
        let font = BTFieldLayout.Const.recordHeaderTitleFont
        let shouldReplaceNewlineWithSpace = true
        let lineBreakMode: NSLineBreakMode = .byTruncatingTail
        let fullRange = NSRange(location: 0, length: fullAttString.length)
        if shouldReplaceNewlineWithSpace {
            fullAttString.mutableString.replaceOccurrences(of: "\n", with: " ", options: [], range: fullRange)
        }
        let attrs = getFigmaHeightAttributes(font: font, alignment: .left, lineBreakMode: lineBreakMode)
        fullAttString.addAttributes(attrs, range: fullRange)
        return fullAttString
    }

    /// 数据
    class func convert(_ segments: [BTRichTextSegmentModel],
                       font: UIFont = .systemFont(ofSize: 14),
                       plainTextColor: UIColor = UDColor.textTitle,
                       shouldReplaceNewlineWithSpace: Bool = false,
                       shouldUseTextAsLinkForURLSegment: Bool = true,
                       lineBreakMode: NSLineBreakMode = .byWordWrapping,
                       forTextView textView: UITextView? = nil) -> NSAttributedString {
        let fullAttString = NSMutableAttributedString(string: "")
        for sgm in segments {
            switch sgm.type {
            case .text: // 纯文本
                let textSgm = sgm as BTTextSegment
                let attString = NSAttributedString(string: textSgm.text, attributes: [NSAttributedString.Key.foregroundColor: plainTextColor])
                fullAttString.append(attString)

            case .embeddedImage: // 描述里面的图片，交互类似于 drive 附件的 mention，编辑时不可分割
                let imageModel = sgm.btEmbeddedImageModel
                let imageAttrString = NSMutableAttributedString()
                let attachment = NSTextAttachment()
                attachment.image = UDIcon.getIconByKey(.imageOutlined, size: CGSize(width: font.pointSize, height: font.pointSize)).ud.withTintColor(UDColor.textLinkNormal)
                attachment.bounds = CGRect(x: 0, y: (font.capHeight - font.pointSize).rounded() / 2, width: font.pointSize, height: font.pointSize)
                imageAttrString.append(NSMutableAttributedString(attachment: attachment))
                
                let showingText = sgm.name.count > 35 ? "\(sgm.name.mySubString(to: 35))…" : sgm.name
                if !showingText.hasPrefix(" ") {
                    // 在移动端编辑时，如果粘贴了一个云文档链接，在 AtInfo 那里会自动在 attachment 后面补充一个空格，
                    // 而 bitable 这边的历史代码没有做这个逻辑，所以造成了不统一。
                    // 5.5 版本补充一下这个逻辑，只在 showingText 前面没有空格时再补充空格。不然，多个空格又会太宽。
                    imageAttrString.append(NSMutableAttributedString(string: " "))
                }
                let nameString = NSMutableAttributedString(string: showingText)
                let nameRange = NSRange(showingText.startIndex..., in: showingText)
                nameString.addAttribute(.foregroundColor, value: UDColor.textLinkNormal, range: nameRange)
                imageAttrString.append(nameString)
                let fullRange = NSRange(location: 0, length: imageAttrString.length)
                imageAttrString.addAttribute(BTRichTextSegmentModel.attrStringBTEmbeddedImageKey, value: imageModel, range: fullRange)
                fullAttString.append(imageAttrString)
           
            case .mention: // 人、文档、表格等，编辑时不可分割
                let btAtInfo = sgm.btAtInfo
                let attachment = BTTextAttachment()
                let mentionSgm = sgm as BTMentionSegment
                let mentionAttrString = NSMutableAttributedString()
                if mentionSgm.mentionType != .user {
                    attachment.hostTextView = textView
                    attachment.image = resolveAttachmentIcon(type: mentionSgm.mentionType).ud.withTintColor(UDColor.textLinkNormal)
                    attachment.bounds = CGRect(x: 0, y: (font.capHeight - font.pointSize).rounded() / 2, width: font.pointSize, height: font.pointSize)
                    let iconInfo = RecommendData.IconInfo(type: mentionSgm.icon.type, key: mentionSgm.icon.key, fsunit: mentionSgm.icon.fs_unit)
                    attachment.icon = iconInfo
                    let attachmentString = NSMutableAttributedString(attachment: attachment)
                    mentionAttrString.append(attachmentString)
                }
                let showingText = sgm.text
                if !showingText.hasPrefix(" ") {
                    // 在移动端编辑时，如果粘贴了一个云文档链接，在 AtInfo 那里会自动在 attachment 后面补充一个空格，
                    // 而 bitable 这边的历史代码没有做这个逻辑，所以造成了不统一。
                    // 5.5 版本补充一下这个逻辑，只在 showingText 前面没有空格时再补充空格。不然，多个空格又会太宽。
                    mentionAttrString.append(NSMutableAttributedString(string: " "))
                }
                let attString = NSMutableAttributedString(string: showingText)
                let textRange = NSRange(showingText.startIndex..., in: showingText)
                attString.addAttribute(.foregroundColor, value: UDColor.textLinkNormal, range: textRange)
                mentionAttrString.append(attString)
                let fullRange = NSRange(location: 0, length: mentionAttrString.length)
                mentionAttrString.addAttribute(BTRichTextSegmentModel.attrStringBTAtInfoKey, value: btAtInfo, range: fullRange)
                fullAttString.append(mentionAttrString)

            case .url: // 其他链接，例如 https://www.baidu.com, google.com 等等，支持编辑，编辑时可以分割，与 sheet 富文本编辑体验相同，所以复用了 AtInfo.attributedStringURLKey
                let urlSgm = sgm as BTURLSegment
                let showingText = urlSgm.text
                let attString = NSMutableAttributedString(string: showingText)
                let range = NSRange(showingText.startIndex..., in: showingText)
                attString.addAttribute(.foregroundColor, value: plainTextColor, range: range)
                if shouldUseTextAsLinkForURLSegment, let url = URL(string: urlSgm.link.isEmpty ? urlSgm.text : urlSgm.link) {
                    attString.addAttribute(AtInfo.attributedStringURLKey, value: url, range: range)
                    attString.addAttribute(.foregroundColor, value: UDColor.textLinkNormal, range: range)
                } else {
                    DocsLogger.btError("[DATA] illegal url segment")
                }
                fullAttString.append(attString)
            }
        }
        let fullRange = NSRange(location: 0, length: fullAttString.length)
        if shouldReplaceNewlineWithSpace {
            fullAttString.mutableString.replaceOccurrences(of: "\n", with: " ", options: [], range: fullRange)
        }
        let attrs = getFigmaHeightAttributes(font: font, alignment: .left, lineBreakMode: lineBreakMode)
        fullAttString.addAttributes(attrs, range: fullRange)
		return fullAttString
	}
    
    
    /// 时间戳格式化
    /// - Parameters:
    ///   - timestamp: 时间戳
    ///   - dateFormat: 日期格式
    ///   - timeFormat: 时间格式
    ///   - timeZoneId: 时区id
    ///   - displayTimeZone: 是否展示 GMT
    /// - Returns: 格式化后的字符串
    class func dateFormate(_ timestamp: TimeInterval, dateFormat: String,
                          timeFormat: String,
                          timeZoneId: String? = nil,
                          displayTimeZone: Bool = false) -> String {
        if !UserScopeNoChangeFG.YY.bitableDateFormatFixDisable {
            // 不然在 Xcode 15 编译的包安装到 iOS 14.2 系统上后会出现 format 格式异常
            // https://forums.swift.org/t/date-formatted-is-returning-a-different-string-in-xcode-15/67511/4
            // https://meego.feishu.cn/larksuite/issue/detail/14969258
            let date = Date(timeIntervalSince1970: timestamp)
            
            var dateFormatter: DateFormatter?
            var timeFormatter: DateFormatter?
            if !dateFormat.isEmpty {
                dateFormatter = DateFormatter().construct { it in
                    it.dateFormat = dateFormat
                }
            }
            if !timeFormat.isEmpty {
                timeFormatter = DateFormatter().construct { it in
                    it.dateFormat = timeFormat
                }
            }
            var timeZoneAbbr = ""
            if let id = timeZoneId, let timeZone = TimeZone(identifier: id) {
                dateFormatter?.timeZone = timeZone
                timeFormatter?.timeZone = timeZone
                let tzAbbr = timeZone.docs.gmtAbbreviation()
                timeZoneAbbr = displayTimeZone ? (" (" + tzAbbr + ")") : ""
            }
            
            var dateStr = dateFormatter?.string(from: date) ?? ""
            var timeStr = timeFormatter?.string(from: date) ?? ""
            return dateStr + " " + timeStr + timeZoneAbbr
        }
        let timeFormat = "\(dateFormat) \(timeFormat)"
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormat = DateFormatter().construct { it in
            it.dateFormat = timeFormat
        }
        var timeZoneAbbr = ""
        if let id = timeZoneId, let timeZone = TimeZone(identifier: id) {
            dateFormat.timeZone = timeZone
            let tzAbbr = timeZone.docs.gmtAbbreviation()
            timeZoneAbbr = displayTimeZone ? (" (" + tzAbbr + ")") : ""
        }
        let dateString = dateFormat.string(from: date) + timeZoneAbbr
        return dateString
    }
    
    class func getFigmaHeightAttributes(font: UIFont,
                                        alignment: NSTextAlignment,
                                        lineBreakMode: NSLineBreakMode = .byWordWrapping) -> [NSAttributedString.Key: Any] {
        let lineHeight = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0

        // Paragraph style.
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight
        mutableParagraphStyle.alignment = alignment
        mutableParagraphStyle.lineBreakMode = lineBreakMode
        return [
            .font: font,
            .baselineOffset: baselineOffset,
            .paragraphStyle: mutableParagraphStyle
        ]
    }

    // MARK: - get
    class func getSelectedOptions(withIDs selectedOptionIDs: [String],
                                  colors: [BTColorModel],
                                  allOptionInfos: [BTOptionModel]) -> [BTCapsuleModel] {
        guard !selectedOptionIDs.isEmpty else { return [] }
        return selectedOptionIDs.compactMap { (opID) -> BTCapsuleModel? in
            guard let op = allOptionInfos.first(where: { (op) -> Bool in
                return op.id == opID
            }) else {
                return nil
            }
            
            let index = colors.count == 0 ? 0 : op.color % colors.count
            
            return BTCapsuleModel(
                id: op.id,
                text: op.name,
                color: colors.count != 0 ? colors[index] : BTColorModel(color: "#FFFFFF", id: 0, textColor: "#FFFFFF"),
                isSelected: true,
                font: UIFont.systemFont(ofSize: 14, weight: .medium)
            )
        }
    }

    class func getAllOptions(with selectedOptionIDs: [String],
                             colors: [BTColorModel],
                             allOptionInfos: [BTOptionModel]) -> [BTCapsuleModel] {
        return allOptionInfos.map { (op) -> BTCapsuleModel in
            let index = colors.count == 0 ? 0 : op.color % colors.count
            let selected = selectedOptionIDs.contains(op.id)
            return BTCapsuleModel(
                id: op.id,
                text: op.name,
                color: colors[index],
                isSelected: selected,
                font: UIFont.systemFont(ofSize: 14, weight: .medium)
            )
        }
    }

    class func getAttributes(in textView: BTAttributedTextView, at testPoint: CGPoint) -> [NSAttributedString.Key: Any] {
        guard let attributedString = textView.attrString, attributedString.length != 0 else {
            return [:]
        }
        let (manager, container) = textView.layout
        let nearestGlyphIndex = manager.glyphIndex(for: testPoint, in: container, fractionOfDistanceThroughGlyph: nil)
        guard nearestGlyphIndex < manager.numberOfGlyphs else {
            DocsLogger.btError("[BTUtil] getAttributes nearestGlyphIndex out of bounds nearestGlyphIndex:\(nearestGlyphIndex) numberOfGlyphs:\(manager.numberOfGlyphs)")
            return [:]
        }
        
        let nearestLineFragmentVisibleRect = manager.lineFragmentUsedRect(forGlyphAt: nearestGlyphIndex, effectiveRange: nil)
        // 如果点击空白地方，会返回行尾字符的 index，如果行尾是个链接那就会被误判，因为点击空白地方不应该跳转
        guard nearestLineFragmentVisibleRect.contains(testPoint),
              nearestGlyphIndex >= 0,
              nearestGlyphIndex < attributedString.length else {
            return [:]
        }
        var attributes = attributedString.attributes(at: nearestGlyphIndex, effectiveRange: nil)
        let allEmbeddedImages = BTUtil.getAllEmbeddedImages(from: attributedString)
        if !allEmbeddedImages.isEmpty {
            attributes[BTRichTextSegmentModel.attrStringBTAllEmbeddedImagesKey] = allEmbeddedImages
        }
        return attributes.filter { (key, _) in
            BTRichTextSegmentModel.linkAttributes.contains(key)
        }
    }

    class func getAttributes(in view: BTAttributedTextView, sender: UIGestureRecognizer) -> [NSAttributedString.Key: Any] {
        let testPoint = sender.location(in: view.view)
        let textInset = view.textContainerInset
        // glyphIndex(for:in:fractionOfDistanceThroughGlyph:) 是依据 text container 实际尺寸的，所以 testPoint 要确保扣掉了 textContainerInset
        let realPoint = CGPoint(x: testPoint.x - textInset.left, y: testPoint.y - textInset.top)
        return BTUtil.getAttributes(in: view, at: realPoint)
    }
    
    
    /// 判断是不是点击了最后一行的空白
    class func isTapOnTrailBlank(in view: BTAttributedTextView, at pointOfView: CGPoint) -> Bool {
        let testPoint = pointOfView
        let textInset = view.textContainerInset
        let realPoint = CGPoint(x: testPoint.x - textInset.left, y: testPoint.y - textInset.top)
        guard let attributedString = view.attrString, attributedString.length != 0 else {
            return true
        }
        let (manager, container) = view.layout
        let lastGlyphIndex = manager.glyphIndexForCharacter(at: manager.numberOfGlyphs - 1)
        let lastUsedRect = manager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)
        
        debugPrint("BTURLField isTapOnNotTrailBlank lastUsedRect: \(lastUsedRect), testPoint \(realPoint)")
        
        let isTapOnRightOfLastRect = (lastUsedRect.minX + lastUsedRect.size.width) < realPoint.x
        let isTapOnLastLine = lastUsedRect.origin.y < realPoint.y
        let isOnlyOneLine = lastUsedRect.minY == 0
        guard isTapOnRightOfLastRect else {
            return false
        }
        // 这里要判断一行的情况，是为了兼容 realPointX 为负数的情况。
        return isOnlyOneLine || isTapOnLastLine
    }

    class func getAllEmbeddedImages(from attributedString: NSAttributedString) -> [BTEmbeddedImageModel] {
        var embeddedImages: [BTEmbeddedImageModel] = []
        attributedString.enumerateAttribute(BTRichTextSegmentModel.attrStringBTEmbeddedImageKey,
                                            in: NSRange(location: 0, length: attributedString.length),
                                            options: []) { attr, _, _ in
            if let attr = attr as? BTEmbeddedImageModel {
                embeddedImages.append(attr)
            }
        }
        return embeddedImages
    }
    

    private class func resolveAttachmentIcon(type: BTMentionSegmentType) -> UIImage {
        switch type {
        case .docs, .wiki: // FIXME: 后期优化为按照 wiki 实际类型显示图标
            return UDIcon.getIconByKey(.fileLinkWordOutlined, size: CGSize(width: 14, height: 14))
        case .docx:
            return UDIcon.getIconByKey(.fileLinkDocxOutlined, size: CGSize(width: 14, height: 14))
        case .sheets:
            return UDIcon.getIconByKey(.fileLinkSheetOutlined, size: CGSize(width: 14, height: 14))
        case .bitable:
            return UDIcon.getIconByKey(.fileLinkBitableOutlined, size: CGSize(width: 14, height: 14))
        case .mindnote:
            return UDIcon.getIconByKey(.fileLinkMindnoteOutlined, size: CGSize(width: 14, height: 14))
        case .box:
            return UDIcon.getIconByKey(.fileLinkOtherfileOutlined, size: CGSize(width: 14, height: 14))
        case .slides:
            return UDIcon.getIconByKey(.fileLinkSlidesOutlined, size: CGSize(width: 14, height: 14))
        case .whiteboard:
            return UDIcon.getIconByKey(.vcWhiteboardOutlined, size: CGSize(width: 14, height: 14))
        default:
            return UDIcon.getIconByKey(.fileLinkOtherfileOutlined, size: CGSize(width: 14, height: 14))
        }
    }


    /// 数据源搜索匹配
    /// - Parameters:
    ///   - matchString: 需要用来匹配的字符
    ///   - textPinyinMap: 匹配数据源字符的中文拼音字典，可不传
    ///   - models: 用来匹配的数据源
    /// - Returns: 匹配结果
    class func getSimilarityItems(matchString: String,
                                  textPinyinMap: [String: String] = [:],
                                  models: [BTCapsuleModel]) -> [BTCapsuleModel] {
        var matchModels: [BTCapsuleModel]
        matchModels = models.filter { model in
            let transformedString = textPinyinMap[model.id]?.lowercased() ?? ""
            var isMatch = false
            if matchString.containsChineseCharacters {
                isMatch = model.text.lowercased().contains(matchString)
            } else {
                isMatch = transformedString.contains(matchString)
            }
            return isMatch
        }
        return matchModels
    }


    /// 将中文字符转换成拼音
    /// - Parameter string: 需要转换为拼音的字符
    /// - Returns: 转换后的结果
    class func transformChineseToPinyin(string: String) -> String {
        guard !string.isEmpty, string.containsChineseCharacters else {
            return string
        }
        let stringRef = NSMutableString(string: string) as CFMutableString
        //转换为带音标的拼音
        CFStringTransform(stringRef, nil, kCFStringTransformToLatin, false)
        //去掉音标
        CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false)

        var pinyin = stringRef as String
        //中文转换为拼音后会在中间加上空格，需要去掉
        pinyin = pinyin.replacingOccurrences(of: " ", with: "")
        return pinyin
    }
    
    /// 判断是否需要添加 http:// 前缀，确保链接有效。
    class func addHttpScheme(to originalUrl: String) -> String {
        if originalUrl.isEmpty {
            return ""
        }
        // 先转为都是小写，更准确的处理。
        let originalUrlLowcase = originalUrl.lowercased()
        return (originalUrlLowcase.hasPrefix("http://") || originalUrlLowcase.hasPrefix("https://")) ? originalUrl : "http://" + originalUrl
    }
    
    
    /// 当禁止复制时弹出 toast 提示用户
    /// - Parameters:
    ///   - copyPermisson: 复制权限
    ///   - targetView: 展示的视图
    class func showToastWhenCopyProhibited(copyPermisson: BTCopyPermission?, isSameTenant: Bool, on hostView: UIView, token: String? = nil) {
        let targetView = hostView.window ?? hostView
        let _copyPermission: BTCopyPermission = copyPermisson ?? .refuseByUser
        switch _copyPermission {
        case .allow, .allowBySingleDocumentProtect: break
        case .refuseByUser:
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Copy_FeatureDisabledByOwner, on: targetView)
        case .refuseByAdmin:
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Copy_FeatureDisabledByAdmin, on: targetView)
        case let .refuseByDlp(status):
            UDToast.showFailure(with: status.text(action: .COPY, isSameTenant: isSameTenant), on: targetView)
        case .refuseByFileStrategy:
            CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: .bitable, token: token)
        case .refuseBySecurityAudit:
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: targetView)
        case let .fromPermissionSDK(response):
            guard let controller = hostView.affiliatedViewController else {
                if !response.allow {
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Copy_FeatureDisabledByOwner, on: targetView)
                }
                return
            }
            response.didTriggerOperation(controller: controller, BundleI18n.SKResource.Bitable_Copy_FeatureDisabledByOwner)
        }
    }

    class func showToastWhenCopyProhibited(permissionService: UserPermissionService, isSameTenant: Bool, on controller: UIViewController, token: String? = nil) {
        let response = permissionService.validate(operation: .copyContent)
        response.didTriggerOperation(controller: controller,
                                     BundleI18n.SKResource.Bitable_Copy_FeatureDisabledByOwner)
    }

    /// 将链接交给外部进行处理。因为有些视图层级太多了，所以需要把转屏抛到外部。
    typealias OpenURLByVCFollowIfNeedHandler = (_ url: URL, _ isNeedTransOrientation: Bool) -> Bool

    /// 处理bitable文本字段中链接的点击跳转
    /// - Parameters:
    ///   - hostVC: 宿主VC，BrowserVC 或 BTController
    ///   - objToken: 文档token，用来判断点击的链接是否是当前文档
    ///   - objType: 文档类型，用来拼接URL
    ///   - needFullScreen: 是否需要全屏展示跳转的页面，默认true
    ///   - isJira: 是否是jira类型，用来做埋点上报
    ///   - attributes: 富文本属性
    ///   - openURLByVCFollowIfNeed: VC 中打开。
    ///   - trackingEventBlock: 用于埋点上报
    class func didTapView(hostVC: UIViewController,
                          hostDocsInfo: DocsInfo,
                          needFullScreen: Bool = true,
                          isJira: Bool = false,
                          withAttributes attributes: [NSAttributedString.Key: Any],
                          openURLByVCFollowIfNeed: OpenURLByVCFollowIfNeedHandler?,
                          trackingEventBlock: (() -> Void)? = nil,
                          completion: EENavigator.Handler? = nil) {
        let topVC = UIViewController.docs.topMost(of: hostVC) ?? hostVC
        var realFromVC = topVC
        let topIsPopover = hostVC.presentedViewController?.modalPresentationStyle == .popover
        let objToken = hostDocsInfo.objToken
        let objType = hostDocsInfo.type
        
        // 临时方法，后面做了 desc 的多图预览后可以干掉
        func dismissBeforePush() {
            guard topIsPopover else { return }
            hostVC.presentedViewController?.dismiss(animated: true)
            realFromVC = hostVC
        }

        func appendingFromParameter(_ url: URL) -> URL {
            let parameters = url.queryParameters
            guard parameters["from"] == nil else {
                return url
            }
            let type = objType
            let module = type == .doc ? "from_parent_docs" : "from_parent_sheet" // FIXME: 与数据同学补充 from_parent_docx 和 from_parent_bitable
            
            return url.docs.addQuery(parameters: ["from": module])
        }

        if let atInfo = attributes[BTRichTextSegmentModel.attrStringBTAtInfoKey] as? BTAtModel {
            switch atInfo.type {
            case .user:
                jumpToUserProfile(userId: atInfo.userID, fromVC: realFromVC)
            default:
                let routerCanOpen = BTRouter.canOpen(atInfo, from: hostDocsInfo)
                if !routerCanOpen.canOpen {
                    if let tips = routerCanOpen.tips {
                        UDToast.showFailure(with: tips, on: hostVC.view.window ?? UIView())
                    }
                    return
                }
                guard let url = URL(string: atInfo.link.urlDecoded()) else { return }
                let fixURL = appendingFromParameter(url)
                dismissBeforePush()
                trackingEventBlock?()
                handleClickInternalLink(fixURL,
                                        fromVC: realFromVC,
                                        needFullScreen: needFullScreen,
                                        needTransOrientation: !atInfo.type.landscapeEnabled ,
                                        openURLByVCFollowIfNeed: openURLByVCFollowIfNeed)
                //Navigator.shared.push(fixURL, from: realFromVC) //内部文档
            }
        } else if let urlInfo = attributes[AtInfo.attributedStringURLKey] as? URL,
                  let modifiedURL = urlInfo.docs.avoidNoDefaultScheme {
            hostVC.navigationController?.navigationBar.isTranslucent = false
            dismissBeforePush()
            trackingEventBlock?()
            //外部链接
            handleClickExternalLink(modifiedURL,
                                    fromVC: realFromVC,
                                    isJira: isJira,
                                    needFullScreen: needFullScreen,
                                    openURLByVCFollowIfNeed: openURLByVCFollowIfNeed,
                                    completion: completion)
        } else if let atInfo = attributes[AtInfo.attributedStringAtInfoKey] as? AtInfo {
            if atInfo.type == .user { // 用户跳转到 Lark Profile
                jumpToUserProfile(userId: atInfo.token, fromVC: realFromVC)
                return
            }
            guard let url = URL(string: atInfo.href) else { return }
            let fixURL = appendingFromParameter(url)
            dismissBeforePush()
            trackingEventBlock?()
            handleClickInternalLink(fixURL,
                                    fromVC: realFromVC,
                                    needFullScreen: needFullScreen,
                                    needTransOrientation: !atInfo.type.makeDocsType.alwaysOrientationsEnable,
                                    openURLByVCFollowIfNeed: openURLByVCFollowIfNeed)
            //Navigator.shared.push(fixURL, from: realFromVC) //粘贴的内部文档
        } else if nil != attributes[BTRichTextSegmentModel.attrStringBTEmbeddedImageKey] as? BTEmbeddedImageModel {
            // 5.5 版本先弹 toast，后续再上多图预览功能
            if let window = hostVC.view.window {
                UDToast.showTips(with: BundleI18n.SKResource.Bitable_Field_PleaseUpdateToViewPic, on: window)
            }
            // 如果要跳转 drive 预览多图的话，从 attribtues 里拿到所有图片：BTRichTextSegmentModel.attrStringBTAllEmbeddedImagesKey
        }
    }

    @discardableResult
    class func forceInterfaceOrientationIfNeed(to orientation: UIInterfaceOrientation?) -> Bool {
        guard !SKDisplay.pad else { return false }
        guard let orientation = orientation, UIApplication.shared.statusBarOrientation != orientation else { return false }
        LKDeviceOrientation.setOritation(LKDeviceOrientation.convertMaskOrientationToDevice(orientation))
        return true
    }
    
    /// 转屏，并且适配 iOS 16
    /// - Parameters:
    ///   - orientation: 转屏
    ///   - completion: 回调：这个不是真正的转屏完成，只是为了适配 iOS 16
    class func forceInterfaceOrientationIfNeed(to orientation: UIInterfaceOrientation?, completion: (() -> Void)?) {
        guard self.forceInterfaceOrientationIfNeed(to: orientation) else {
            completion?()
            return
        }
        if #available(iOS 16.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    // 跳转到用户界面
    private class func jumpToUserProfile(userId: String, fromVC: UIViewController) {
        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
        HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fromVC: fromVC))
    }
    
    //点击内部链接
    private class func handleClickInternalLink(_ url: URL,
                                               fromVC: UIViewController,
                                               needFullScreen: Bool,
                                               needTransOrientation: Bool,
                                               openURLByVCFollowIfNeed: OpenURLByVCFollowIfNeedHandler?) {
        if openURLByVCFollowIfNeed?(url, needTransOrientation) ?? false {
            return
        }
        if needTransOrientation {
            forceInterfaceOrientationIfNeed(to: .portrait)
        }
        handlePush(url, from: fromVC, needFullScreen: needFullScreen)
    }
    
    //点击外部链接
    private class func handleClickExternalLink(_ url: URL,
                                               fromVC: UIViewController,
                                               isJira: Bool,
                                               needFullScreen: Bool,
                                               openURLByVCFollowIfNeed: OpenURLByVCFollowIfNeedHandler?,
                                               completion: EENavigator.Handler? = nil) {
        if openURLByVCFollowIfNeed?(url, true) ?? false {
            return
        }
        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
        // 跳转处理
        if JiraPatternUtil.checkIsCommonJiraDomain(url: url.absoluteString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                handlePush(url, from: fromVC, needFullScreen: needFullScreen)
                DocsLogger.btError("[ACTION] atlassian.net, jira app not found on device!")
            }
        } else {
            handlePush(url, from: fromVC, needFullScreen: needFullScreen, completion: completion)
        }

        // 目前只有 jira 的 BitableBlock 才需要上报处理
        if isJira {
            if JiraPatternUtil.checkIsJiraDomain(url: url.absoluteString) {
                DocsTracker.log(enumEvent: .bitableClickOpenOriginLink,
                                parameters: ["link_type": "jira",
                                             "source": "recordinfilter",
                                             "view_status": "card"])
            }
        }
    }
    
    private class func handlePush(_ url: URL, from: UIViewController, needFullScreen: Bool, completion: EENavigator.Handler? = nil) {
        if needFullScreen {
            Navigator.shared.push(url, from: from, completion: completion)
        } else {
            Navigator.shared.docs.showDetailOrPush(url, wrap: LkNavigationController.self, from: from, completion: completion)
        }
    }
    
    // 目前使用统一的动画样式，如果设计提出了不一样的转圈动画效果，建议优先沟通使用bitable统一的样式
    class func startRotationAnimation(view: UIView) {
        stopRotationAnimation(view: view)
        view.layer.speed = 1
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [rotationAnimation]
        groupAnimation.duration = 1.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards
        view.layer.add(groupAnimation, forKey: "animation")
    }
    class func stopRotationAnimation(view: UIView) {
        view.layer.removeAllAnimations()
    }
    
    // 根据icon model返回image
    class func getImage(icon: BTIcon, style: BTIconAndTextStyle? = nil) -> UIImage? {
        var image: UIImage?
        if let udIconKey = bitableRealUDKey(icon.udKey), let key = UDIcon.getIconTypeByName(udIconKey) {
            image = UDIcon.getIconByKey(key)
        } else {
            switch icon.id {
            case "select": image = BundleResources.SKResource.Bitable.icon_bitable_selected
            case "unselect": image = BundleResources.SKResource.Bitable.icon_bitable_unselected
            case "grid": image = UDIcon.bitablegridOutlined
            case "kanban": image = UDIcon.bitablekanbanOutlined
            case "gallery": image = UDIcon.bitablegalleryOutlined
            case "gantt": image = UDIcon.bitableganttOutlined
            case "create": image = UDIcon.addOutlined
            case "copy": image = UDIcon.copyOutlined
            case "delete": image = UDIcon.deleteTrashOutlined
            case "rename": image = UDIcon.renameOutlined
            case "form": image = UDIcon.bitableformOutlined
            case "sync": image = UDIcon.buzzOutlined
            case "task": image = UDIcon.bitableTaskviewOutlined
            case "calendar": image = UDIcon.calendarLineOutlined
            default:
                // 不应该走到这里
                let msg = "use leftIconId error"
                DocsLogger.error(msg)
                assertionFailure(msg)
            }
        }
        
        let style = icon.style ?? style
        if let tintColor: UIColor = style?.getColor().iconColor {
            return image?.ud.withTintColor(tintColor)
        }
        
        return image
    }
}

protocol BTAttributedTextView {
    var view: UIView { get }
    var bounds: CGRect { get }
    var attrString: NSAttributedString? { get }
    var layout: (manager: NSLayoutManager, container: NSTextContainer) { get }
    var textContainerInset: UIEdgeInsets { get }
}

extension UILabel: BTAttributedTextView {
    var view: UIView {
        return self
    }

    var attrString: NSAttributedString? {
        return attributedText
    }

    var layout: (manager: NSLayoutManager, container: NSTextContainer) {
        let storage = NSTextStorage(attributedString: attributedText ?? NSAttributedString(string: text ?? ""))
        let manager = NSLayoutManager()
        storage.addLayoutManager(manager)
        let container = NSTextContainer(size: bounds.size)
        container.lineFragmentPadding = 0
        container.lineBreakMode = lineBreakMode
        container.maximumNumberOfLines = numberOfLines
        manager.addTextContainer(container)
        return (manager, container)
    }

    var textContainerInset: UIEdgeInsets {
        return .zero
    }
}

extension UITextView: BTAttributedTextView {

    var view: UIView {
        return self
    }

    var attrString: NSAttributedString? {
        return attributedText
    }

    var layout: (manager: NSLayoutManager, container: NSTextContainer) {
        return (layoutManager, textContainer)
    }
}

extension DocsLogger {
    class func btInfo(_ log: String,
                      params: [String: Any] = [:],
                      fileName: String = #fileID,
                      funcName: String = #function,
                      funcLine: Int = #line) {
        #if DEBUG
        debugPrint("[INFO] ==bitable== \(log)")
        #else
        DocsLogger.info("\(log)",
                        extraInfo: params,
                        component: LogComponents.bitable,
                        fileName: fileName,
                        funcName: funcName,
                        funcLine: funcLine)
        #endif
    }
    
    class func btDebug(_ log: String,
                      params: [String: Any] = [:],
                      fileName: String = #fileID,
                      funcName: String = #function,
                      funcLine: Int = #line) {
        #if DEBUG
        debugPrint("[INFO] ==bitable== \(log)")
        #else
        DocsLogger.debug("\(log)",
                        extraInfo: params,
                        component: LogComponents.bitable,
                        fileName: fileName,
                        funcName: funcName,
                        funcLine: funcLine)
        #endif
    }
    
    class func btWarn(_ log: String,
                      params: [String: Any] = [:],
                      fileName: String = #fileID,
                      funcName: String = #function,
                      funcLine: Int = #line) {
        #if DEBUG
        debugPrint("[INFO] ==bitable== \(log)")
        #else
        DocsLogger.warning("\(log)",
                        extraInfo: params,
                        component: LogComponents.bitable,
                        fileName: fileName,
                        funcName: funcName,
                        funcLine: funcLine)
        #endif
    }

    class func btError(_ log: String,
                       fileName: String = #fileID,
                       funcName: String = #function,
                       funcLine: Int = #line) {
        #if DEBUG
        debugPrint("[ERROR] ==bitable== \(log)")
        #else
        DocsLogger.error("\(log)", component: LogComponents.bitable,
                         fileName: fileName,
                         funcName: funcName,
                         funcLine: funcLine)
        #endif
    }
}

final class BTTextAttachment: NSTextAttachment {
    private let disposeBag = DisposeBag()
    weak var hostTextView: UITextView?
    var icon: RecommendData.IconInfo? {
        didSet { loadIcon() }
    }
    private func loadIcon() {
        guard let enable = icon?.type.isCurSupported, enable else { return }
        icon?.image.bind { [weak self] (image) in
            self?.image = image
        }.disposed(by: disposeBag)

        icon?.image.subscribe(onNext: { [weak self] (_) in
            guard let self = self, let view = self.hostTextView else { return }
            let range = NSRange(location: 0, length: view.attributedText.length)
            view.layoutManager.invalidateDisplay(forCharacterRange: range)
        }).disposed(by: disposeBag)
    }
}

extension UIDeviceOrientation {
    var toInterfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .unknown:
            return .unknown
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .faceUp:
            return .portrait
        case .faceDown:
            return .portraitUpsideDown
        default:
            return .unknown
        }
    }
}

extension NSTextAttachment {
    convenience init(_ image: UIImage, imageSize: CGSize, font: UIFont, fontBaseLineOffset: CGFloat, padding: CGFloat) {
        self.init()
        let image = image.ud.resized(to: imageSize).withInsets(UIEdgeInsets(edges: padding))
        self.image = image
        self.bounds = CGRect(
            x: 0,
            y: (font.capHeight - image.size.height) / 2 + fontBaseLineOffset,
            width: image.size.width,
            height: image.size.height
        )
    }
}

extension UIImage {
    func withInsets(_ insets: UIEdgeInsets) -> UIImage {
        let targetWidth = size.width + insets.left + insets.right
        let targetHeight = size.height + insets.top + insets.bottom
        let targetSize = CGSize(width: targetWidth, height: targetHeight)
        let targetOrigin = CGPoint(x: insets.left, y: insets.top)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: targetOrigin, size: size))
        }.withRenderingMode(renderingMode)
    }
}

typealias DiffableCollectionViewCellProvider = (UICollectionView, IndexPath, String) -> UICollectionViewCell?
