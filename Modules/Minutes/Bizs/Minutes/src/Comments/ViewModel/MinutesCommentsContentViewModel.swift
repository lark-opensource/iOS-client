//
//  MinutesCommentsContentViewModel.swift
//  Minutes
//
//  Created by yangyao on 2021/1/31.
//

import Foundation
import YYText
import UniverseDesignColor
import LarkContainer
import LarkAccountInterface
import MinutesNetwork

public struct CommentText {
    let text: String
    var textType: Int //0 text, 1 user, 2 owner
    var userId: String?
    var range: NSRange
}

protocol MinutesCommentsContentViewModelDelegate: AnyObject {
    func didSelectUser(userId: String)
    func didSelectUrl(url: String)
}

class MinutesCommentsContentViewModel: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    @ScopedProvider var passportUserService: PassportUserService?
    
    weak var delegate: MinutesCommentsContentViewModelDelegate?

    private lazy var layout: YYTextLayout? = {
        let size = CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
        let layout = YYTextLayout(containerSize: size, text: attributedText)
        return layout
    }()

    private lazy var originalLayout: YYTextLayout? = {
        if originalText.isEmpty {
            return nil
        } else if let originalAttributedText = originalAttributedText {
            let size = CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: originalAttributedText)
            return layout
        } else {
            return nil
        }
    }()

    // disable-lint: magic number
    private lazy var userBorder: YYTextBorder = {
        let border = YYTextBorder(fill: UIColor.ud.primaryContentDefault, cornerRadius: 16)
        border.insets = UIEdgeInsets(top: -3, left: 0, bottom: -3, right: 0)
        border.lineJoin = .round
        return border
    }()
    // enable-lint: magic number

    func creatEmptyAttributeString(width: CGFloat) -> NSMutableAttributedString {
        var spaceText = NSMutableAttributedString.yy_attachmentString(withContent: UIImage(), contentMode: .scaleToFill, attachmentSize: CGSize(width: width, height: 1), alignTo: UIFont.systemFont(ofSize: 0), alignment: .center)
        return spaceText
    }

    private lazy var attributedText: NSMutableAttributedString = {
        return getOutComeText(inText: text, maxWidth: contentWidth, height: MinutesCommentsContentCell.LayoutContext.contentLineHeight, font: MinutesCommentsContentCell.LayoutContext.font, isOriginalText: false)
    }()

    private func getOutComeText(inText: String, maxWidth: CGFloat, height: CGFloat, font: UIFont, isOriginalText: Bool) -> NSMutableAttributedString {

        guard let commentTexts = self.contextParse(contentStr: inText) else {
            return NSMutableAttributedString()
        }

        var outcomeText = NSMutableAttributedString()
        var currentHeight: CGFloat = 0

        for item in commentTexts {
            if item.textType == 0 {
                let color = isOriginalText ?
                    UIColor.ud.textPlaceholder :
                    UIColor.ud.textTitle
                var normalText = MinutesCommentsContentViewModel.parseEmotion(item.text, foregroundColor: color, font: font)
                normalText.yy_font = font
                normalText.yy_minimumLineHeight = height
                outcomeText.append(normalText)
                let size = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
                if let textLayout = YYTextLayout(containerSize: size, text: outcomeText) {
                    currentHeight = textLayout.textBoundingSize.height
                }
            } else {
                var tagText = NSMutableAttributedString()

                if item.textType == 1 {
                    tagText.yy_appendString(item.text)
                    tagText.yy_font = font
                    tagText.yy_minimumLineHeight = height
                    // yyTODO
                    tagText.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentDefault, range: tagText.yy_rangeOfAll())
                } else {
                    tagText.append(creatEmptyAttributeString(width: 4))
                    tagText.yy_appendString(item.text)
                    tagText.append(creatEmptyAttributeString(width: 4))
                    tagText.yy_font = font
                    tagText.yy_minimumLineHeight = height
                    tagText.yy_setTextBackgroundBorder(userBorder, range: tagText.yy_rangeOfAll())
                    // yyTODO
                    tagText.addAttribute(.foregroundColor, value: UIColor.ud.primaryOnPrimaryFill, range: tagText.yy_rangeOfAll())
                }
                outcomeText.append(tagText)

                let tagContainer = YYTextContainer()
                tagContainer.size = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
                var tagLayout = YYTextLayout(container: tagContainer, text: outcomeText)
                if let tagLayout = tagLayout, tagLayout.textBoundingSize.height > currentHeight, currentHeight > 0 {
                    outcomeText.yy_insertString("\n", at: UInt(outcomeText.length - tagText.length))
                    if let newLayout = YYTextLayout(container: tagContainer, text: outcomeText) {
                        currentHeight = newLayout.textBoundingSize.height
                    }
                }
                let range = NSRange(location: outcomeText.length - tagText.length, length: tagText.length)
                outcomeText.yy_setTextHighlight(range, color: nil, backgroundColor: nil) { [weak self] (_, _, tapRange, _) in
                    if let userId = item.userId, NSEqualRanges(range, tapRange) {
                        self?.delegate?.didSelectUser(userId: userId)
                    }
                }
            }
        }
        return outcomeText
    }

    private lazy var originalAttributedText: NSMutableAttributedString? = {
        if originalText.isEmpty {
            return nil
        } else {
            return getOutComeText(inText: originalText, maxWidth: contentWidth, height: MinutesCommentsContentCell.LayoutContext.contentLineHeight, font: MinutesCommentsContentCell.LayoutContext.originalFont, isOriginalText: true)
        }
    }()

    let name: String
    let userID: String
    let avatarUrl: URL?
    let text: String
    let originalText: String
    let time: Int
    var isInTranslationMode: Bool = false
    var imageContents: [ContentForIMItem] = []
    
    let contentForIM: [ContentForIMItem]?
    let originalContentForIM: [ContentForIMItem]?

    lazy var timeStr: String = {
        let date = Date(timeIntervalSince1970: TimeInterval(time / 1000))
        let timeStr = transformDate(createDate: date)
        return timeStr
    }()

    var cellHeight: CGFloat = 0.0
    let commentContent: CommentContent

    var contentWidth: CGFloat

    init(resolver: UserResolver, contentWidth: CGFloat, content: CommentContent, originalContent: CommentContent? = nil, isInTranslationMode: Bool) {
        self.userResolver = resolver
        self.contentWidth = contentWidth
        self.commentContent = content
        self.name = content.userName
        self.userID = content.userID
        self.avatarUrl = URL(string: content.avatarUrl)
        self.text = content.content
        self.originalText = originalContent?.content ?? ""
        self.time = content.createTime
        self.contentForIM = content.contentForIM
        self.originalContentForIM = originalContent?.contentForIM
        self.isInTranslationMode = calcRealTransclateModeBy(isInTranslationMode)
        self.imageContents = getAllImageContents()
        calculateHeight(contentWidth)
    }
    
    func getAllImageContents() -> [ContentForIMItem] {
        guard let content = contentForIM else { return []}
        var imageContent : [ContentForIMItem] = []
        for item in content {
            if item.contentType == "image" || item.contentType == "sticker" {
                imageContent.append(item)
            }
        }
        return imageContent
    }

    func calculateHeight(_ width : CGFloat) {
        let textHeight: CGFloat = layout?.textBoundingSize.height ?? 0
        let originalTextHeight: CGFloat = originalLayout?.textBoundingSize.height ?? 0
        var height: CGFloat = 0.0

        height += MinutesCommentsContentCell.LayoutContext.topMargin
            + MinutesCommentsContentCell.LayoutContext.nameHeight
            + MinutesCommentsContentCell.LayoutContext.verticalOffset
            + textHeight
            + MinutesCommentsContentCell.LayoutContext.verticalOffset2
            + MinutesCommentsContentCell.LayoutContext.timeHeight
            + MinutesCommentsContentCell.LayoutContext.bottomMargin

        if isInTranslationMode {
            height += originalTextHeight + MinutesCommentsContentCell.LayoutContext.verticalOffset2 + 6 * 2
        }
        cellHeight = height
    }

    func calcRealTransclateModeBy(_ isInTranslationMode: Bool) -> Bool {
        if (!isInTranslationMode) {
            return isInTranslationMode
        }

        var isInTranslationModeActually = false
        let originText = getOriginalAttributedText()
        if originText?.length ?? 0 > 0 {
            let text = getAttributedText()
            isInTranslationModeActually = originText?.string != text.string
        }
        return isInTranslationModeActually

    }
    
    func calculateImageHeight(_ width : CGFloat) -> CGFloat {
        if imageContents.isEmpty{
            return 0
        }
        let size = (width - 8) / 3
        let count = imageContents.count
        let rows = count / 3
        let left = count % 3
        let margin = 4
        var height : CGFloat = 0.0
        if left > 0 {
            height = size + CGFloat(margin)
        }
        let margins = rows * margin
        height += CGFloat(rows) * size +  CGFloat(margins)
        return height
    }
    
    func getTextLayout() -> YYTextLayout? {
        return self.layout
    }
    
    func getOriginalTextLayout() -> YYTextLayout? {
        return self.originalLayout
    }
    
    func getAttributedText() -> NSAttributedString {
        return self.attributedText
    }
    
    func getOriginalAttributedText() -> NSMutableAttributedString? {
        return self.originalAttributedText
    }
    
    func imageContentHeight(_ width : CGFloat) -> CGFloat {
        return calculateImageHeight(width)
    }
    
    func imageItemSize(_ width : CGFloat) -> CGFloat {
        return imageContents.isEmpty ? 0.0 : ((width - 8) / 3)        
    }
}

extension MinutesCommentsContentViewModel {
    // disable-lint: magic number
    func transformDate(createDate: Date) -> String {
        var timeTips: String

        let timeDiff = Date().timeIntervalSince(createDate)

        if timeDiff / 60 < 1 {
            timeTips = BundleI18n.Minutes.MMWeb_G_JustNow
            return timeTips
        }

        let mins = Int(timeDiff / 60)
        if mins <= 1 {
            timeTips = BundleI18n.Minutes.MMWeb_G_MinutesAgoSingular(mins)
            return timeTips
        }

        if mins < 60 {
            timeTips = BundleI18n.Minutes.MMWeb_G_MinutesAgo(mins)
            return timeTips
        }

        let hours = Int(timeDiff / 3600)

        if hours <= 1 {
            timeTips = BundleI18n.Minutes.MMWeb_G_HoursAgoSingular(hours)
            return timeTips
        }

        if hours < 4 {
            timeTips = BundleI18n.Minutes.MMWeb_G_HoursAgo(hours)
            return timeTips
        }

        let days = Int(timeDiff / 3600 / 24)

        if days <= 1 {
            timeTips = BundleI18n.Minutes.MMWeb_G_Yesterday
            return timeTips
        }

        let oldF = DateFormatter()
        oldF.dateFormat = "yyyy-MM-dd"

        timeTips = oldF.string(from: createDate)
        return timeTips
    }
    // enable-lint: magic number

    /// ## 评论文字解析
    /// 对于一段字符串：
    /// 输入： 撒打算大撒大<at type=\"User\" id=\"6892951239890370562\">@路人甲</at>阿斯顿撒打算<at type=\"Owner\" id=\"6892951239890370162\">@路人乙</at>dwdw
    /// 输出：一个数据结构 ComplexText，其中包括
    ///      **原串（originalContext）：** 撒打算大撒大@路人甲阿斯顿撒打算@路人乙dwdw
    ///      **类型集（type）：** ["User", "Owner"]
    ///      **@ID及区域（atRangeMap）：** [("6892951239890370562", "NSRange(location: 7, length: 4)"), ("6892951239890370162", "NSRange(location: 17, length: 4)")]
    func contextParse( contentStr: String? ) -> [CommentText]? {
        guard let str = contentStr else {
            return nil
        }

        /// 是否在<at at>规则区域
        var isInruleRange: Bool = false

        var type: Int = 0
        var id: String = ""
        var location: Int = 0
        var length: Int = 0

        var contentTexts: [CommentText] = []
        let compomentList = str.components(separatedBy: ["<", "\"", "=", ">"])

        var currentLocation = 0
        for i in 0..<compomentList.count {
            ///进入规则域
            if compomentList[i].contains("at type") {
                isInruleRange = true
            }

            if isInruleRange {
                if compomentList[i].contains("token") {
                    let curID = compomentList[i + 2]
                    id = idCleanAndCheck(usrID: curID)
                    type = userTypeCheck(userId: id)
                } else if compomentList[i].contains("@") {
                    if contentTexts.last?.textType == 2 {
                        location = currentLocation
                        length = 1
                        let commentText = CommentText(text: " ", textType: 0, userId: nil, range: NSRange(location: location, length: length))
                        currentLocation = currentLocation + length
                        contentTexts.append(commentText)
                    }
                    location = currentLocation
                    length = compomentList[i].count
                    let commentText = CommentText(text: compomentList[i], textType: type, userId: id, range: NSRange(location: location, length: length))
                    currentLocation = currentLocation + length
                    contentTexts.append(commentText)
                } else if compomentList[i].contains("/at") {
                    ///退出规则域，记录当前mention信息
                    isInruleRange = false
                    location = 0
                    length = 0
                    id = ""
                    type = 0
                }
            } else {
                if compomentList[i].count > 0 {
                    location = currentLocation
                    length = compomentList[i].count
                    let commentText = CommentText(text: compomentList[i], textType: 0, userId: nil, range: NSRange(location: location, length: length))
                    currentLocation = currentLocation + length
                    contentTexts.append(commentText)
                }
            }
        }
        return contentTexts
    }

    private func idCleanAndCheck(usrID: String) -> String {
        var id: String = ""
        for i in usrID {
            if i < "0" || i > "9" {
                continue
            }
            id.append(i)
        }
        return id
    }

    private func userTypeCheck(userId: String) -> Int {
        if let myUserId = passportUserService?.user.userID {
            if myUserId == userId {
                return 2
            } else {
                return 1
            }
        }
        return 1
    }
}
