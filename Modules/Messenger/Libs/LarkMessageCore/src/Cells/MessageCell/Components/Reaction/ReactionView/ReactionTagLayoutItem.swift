//
//  ReactionTagLayoutItem.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/9/8.
//

import UIKit
import Foundation
import LarkModel
import CoreText
import RichLabel
import LKCommonsLogging
import LarkEmotion

private let LKMessageReactionCommaAttributeName = NSAttributedString.Key(rawValue: "LKMessageReactionCommaAttributeName")

protocol LayoutEngineItem {
    var margin: UIEdgeInsets { get }
    var origin: CGPoint { get set }
    var contentSize: CGSize { get }
    func featWidth(_ width: CGFloat)
}

/// 实现LayoutEngineItem协议，可放入TagLayoutEngine中布局
extension ReactionTagLayoutItem: LayoutEngineItem { }
/// 内容划分：[internal - icon - internal - 分割线 - internal - 名字区域 - internal]，没有算margin，内容的高度目前固定为24
final class ReactionTagLayoutItem {

    enum Cons {
        /// 内容上下边距
        static var vMargin: CGFloat { 4 }
        /// 内容左右边距
        static var hMargin: CGFloat { 8 }
        /// 分割线的左右编剧
        static var hPadding: CGFloat { 5 }
        /// 字体高度
        static var labelFont: UIFont { UIFont.ud.caption1 }
        /// 内容高度（等于字体行高）
        static var contentHeight: CGFloat { labelFont.pointSize * 1.5 }
        /// 总体高度
        static var totalHeight: CGFloat { contentHeight + vMargin * 2 }
    }

    private static let logger = Logger.log(ReactionTagLayoutItem.self, category: "Reaction")

    /// 最多显示几个人名 默认5个
    private var canShowUserNameCount: Int = 5
    /// 记录显示前i个人的长度
    private var userNameWidths: [CGFloat] = []
    /// icon、分割线、名字区域 rect
    private lazy var iconRect: CGRect = {
        // 尺寸不固定, 需要从资源列表获取
        let width: CGFloat
        if let size = EmotionResouce.shared.sizeBy(key: reaction.type) {
            width = size.width * Cons.contentHeight / size.height
        } else {
            width = Cons.contentHeight
        }
        return CGRect(
            x: Cons.hMargin,
            y: Cons.vMargin,
            width: width,
            height: Cons.contentHeight
        )
    }()
    /// 分割线位置
    private lazy var separatorRect: CGRect = {
        let height = Cons.labelFont.pointSize * 1.2
        let y = (Cons.contentHeight - height) / 2 + Cons.vMargin
        if justShowCount {
            let x = iconRect.width + iconRect.minX + 1
            return CGRect(x: x, y: y, width: 0, height: height)
        }
        let x = Cons.hMargin + iconRect.width + Cons.hPadding
        return CGRect(x: x, y: y, width: 1, height: height)
    }()
    private lazy var nameRect = CGRect(
        x: separatorRect.maxX + Cons.hPadding,
        y: Cons.vMargin,
        width: 0,   // not determined
        height: Cons.contentHeight
    )
    /// name最终显示的内容
    private var userNamesText: String = ""
    /// 内容区域最长长度
    private var preferMaxLayoutWidth: CGFloat = 0
    /// reaction所有点击者的名字
    private let userNames: [String]
    /// reaction所有点击者的id
    private let userIDs: [String]
    private let reaction: Reaction
    private weak var delegate: ReactionViewDelegate?
    private let displayName: ((Chatter) -> String)?
    /// 省略号截断
    private let ellipsisString = "…"
    private lazy var ellipsisWidth: CGFloat = self.width(for: ellipsisString, availableWidth: .greatestFiniteMagnitude)
    /// 字符计算信息
    private struct CoreTextInformation {
        let lktextLine: LKTextLine
        // comma glyph 在 glyph 数组里的位置
        let commaLocationSet: Set<Int>
        // comma run 里面的 glyph 数量
        let commaGlyphCount: Int
        // 文本从开头到该 glyph 的宽度
        let glyphWidthArr: [CGFloat]
        // 下标为第几个 glyph，值为该 glyph 所对应的 string location
        let glyphIndicesArr: [CFIndex]
    }

    var textColor: UIColor = .black
    var tagBgColor: UIColor = UIColor.ud.N900.withAlphaComponent(0.06)
    var separatorColor: UIColor = UIColor.ud.N400
    /// --- TagLayoutItem begin ---
    var margin: UIEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
    var origin: CGPoint = .zero

    private var justShowCount: Bool = false

    /// 不计算self.margin，由上层去计算
    var contentSize: CGSize {
        return CGSize(width: self.nameRect.maxX + Cons.hMargin, height: Cons.totalHeight)
    }
    func featWidth(_ width: CGFloat) {
        self.preferMaxLayoutWidth = width
        self.setUserNames()
    }
    /// --- TagLayoutItem end ---

    init?(reaction: Reaction,
          displayName: ((Chatter) -> String)?,
          delegate: ReactionViewDelegate? = nil) {
        /// copy reaction
        self.delegate = delegate
        var chatterIds: [String] = []
        for str in reaction.chatterIds where !str.isEmpty {
            chatterIds.append(String(str))
        }
        let copyReaction = Reaction(type: reaction.type, chatterIds: chatterIds, chatterCount: reaction.chatterCount)
        copyReaction.chatters = reaction.chatters
        self.reaction = copyReaction
        self.displayName = displayName
        self.justShowCount = self.delegate?.justShowCountFor(reaction: reaction) ?? false
        self.canShowUserNameCount = self.delegate?.maxReactionDisplayCount(reaction) ?? 5
        var userNameAndIds: [(String, String)] = []
        let reactionChatters = copyReaction.chatters ?? []
        reactionChatters.forEach { (chatter) in
            let chatterId = chatter.id
            var userName = displayName?(chatter) ?? ""
            if userName.isEmpty {
                userName = chatter.localizedName
            }
            if !userName.isEmpty, !chatterId.isEmpty {
                userNameAndIds.append((userName, chatterId))
            }
        }
        if !justShowCount, userNameAndIds.isEmpty { return nil }
        self.userNames = userNameAndIds.map { $0.0 }
        self.userIDs = userNameAndIds.map { $0.1 }
    }

    private func width(for string: String, availableWidth: CGFloat) -> CGFloat {
        return NSString(string: string).boundingRect(
            with: CGSize(width: availableWidth, height: Cons.contentHeight),
            options: .usesLineFragmentOrigin,
            attributes: [.font: Cons.labelFont],
            context: nil).size.width
    }

    // "+x人"
    private func processReactionAppendTextAndWidth(nameCount: Int) -> (String, CGFloat) {
        var totalCount = nameCount
        if let absenceCount = self.delegate?.reactionAbsenceCount(self.reaction) {
            totalCount = absenceCount + nameCount
        }
        let text = BundleI18n.LarkMessageCore.Lark_Legacy_PostReactionAppend(totalCount)
        let width = self.width(for: text, availableWidth: .greatestFiniteMagnitude)
        return (text, width)
    }

    private func setUserNamesAndWidth(with userNamesString: String, width: CGFloat) {
        self.userNamesText = userNamesString
        self.nameRect.size.width = ceil(width)
    }

    private func setUserNames() {
        if justShowCount {
            Self.logger.info("ReactionTag justShowCount \(self.userNames.count)")
            var count = self.userNames.count
            if let absenceCount = self.delegate?.reactionAbsenceCount(self.reaction) {
                Self.logger.info("ReactionTag absenceCount \(absenceCount)")
                count += absenceCount
            }
            let width = self.width(for: "\(count)", availableWidth: .greatestFiniteMagnitude)
            self.setUserNamesAndWidth(with: "\(count)", width: width)
            return
        }
        guard !self.userNames.isEmpty else { return }
        /// 名字部分宽度的限制
        /// 因为Count会根据显示的人数变化，且文本拼接前后宽度会存在一定误差，这里加上一定的偏移量，确保计算出来的宽度小于最大宽度
        /// 计算备注 https://bytedance.feishu.cn/docs/doccnhAynTuaV8bRhfsiH13kEvf#
        let toleranceValue = Cons.labelFont.pointSize / 2 + 1
        let maxAvailableWidth = self.preferMaxLayoutWidth - self.nameRect.minX - Cons.hMargin - toleranceValue
        self.userNameWidths = []
        let attrStr = self.buildAttributedString()
        let ctInfo = self.buildCoreTextInformation(attrStr: attrStr)

        if let result = self.checkNeedAppendMore(limitedWidth: maxAvailableWidth, ctInfo: ctInfo) {
            Self.logger.info("ReactionTag setUserNames checkNeedAppendMoreResult \(maxAvailableWidth) \(self.userNames.count) \(result.needEllipsis)")
            var finalText = self.generateTextWithIndex(result.findedIndex, ctInfo: ctInfo)
            if result.needEllipsis {
                finalText += "…"
            }
            let restNameCount = self.userNames.count - self.locateName(index: result.findedIndex, ctInfo: ctInfo) - 1
            if restNameCount < 0 {
                ReactionTagLayoutItem.logger.error("restNameCount \(restNameCount) is negative")
                return
            }

            if (self.delegate?.forceShowMoreAbsenceCount(reaction: reaction) ?? false) == false {
                if restNameCount == 0 {
                    ReactionTagLayoutItem.logger.error("restNameCount \(restNameCount) is negative")
                    return
                }
            }

            finalText += self.processReactionAppendTextAndWidth(nameCount: restNameCount).0

            // 需要使用最够展示下的最大宽度计算
            let finalWidth = self.width(for: finalText, availableWidth: maxAvailableWidth)
            self.setUserNamesAndWidth(with: finalText, width: finalWidth)
            self.fixNameWidths(index: result.findedIndex, needEllipsis: result.needEllipsis, ctInfo: ctInfo)
            return
        }
        if let result = self.checkWithoutAppendMore(limitedWidth: maxAvailableWidth, ctInfo: ctInfo) {
            var finalText = self.generateTextWithIndex(result.findedIndex, ctInfo: ctInfo)
            if result.needEllipsis {
                finalText += "…"
            }

            // 需要使用最够展示下的最大宽度计算
            let finalWidth = self.width(for: finalText, availableWidth: maxAvailableWidth)
            self.setUserNamesAndWidth(with: finalText, width: finalWidth)
            self.fixNameWidths(index: result.findedIndex, needEllipsis: result.needEllipsis, ctInfo: ctInfo)
            return
        }
    }
}

// MARK: - 文本按字符截断
extension ReactionTagLayoutItem {
    // 判断是否需要"+x人"文案
    private func checkNeedAppendMore(limitedWidth: CGFloat, ctInfo: CoreTextInformation) -> (findedIndex: Int, needEllipsis: Bool)? {

        // 已知带有国际化的情况下截断文本
        func truncateNamesWithi18n(limitedWidth: CGFloat) -> (findedIndex: Int, needEllipsis: Bool) {
            Self.logger.info("ReactionTag appendMore truncateNamesWithi18n \(self.userNames.count)")
            var findedIndex = self.findMaxIndex(limitedWidth: limitedWidth, ctInfo: ctInfo)
            if !self.checkIsMiddleTruncate(index: findedIndex, ctInfo: ctInfo) {
                return (findedIndex: findedIndex, needEllipsis: false)
            }

            findedIndex = self.findMaxIndex(limitedWidth: limitedWidth - self.ellipsisWidth, ctInfo: ctInfo)
            if !self.checkIsMiddleTruncate(index: findedIndex, ctInfo: ctInfo) {
                return (findedIndex: findedIndex, needEllipsis: false)
            }
            return (findedIndex: findedIndex, needEllipsis: true)
        }

        if self.userNames.count > self.canShowUserNameCount || self.delegate?.forceShowMoreAbsenceCount(reaction: reaction) ?? false {
            Self.logger.info("ReactionTag appendMore UserNamesCountSurpassFive \(self.userNames.count)")
            let i18nWith = self.processReactionAppendTextAndWidth(nameCount: self.userNames.count).1
            if ctInfo.lktextLine.width > limitedWidth - i18nWith - self.ellipsisWidth {
                // 需要省略号，所以计算limitedWidth的时候要减去省略号的宽度
                return (findedIndex: truncateNamesWithi18n(limitedWidth: limitedWidth - i18nWith - self.ellipsisWidth).0, needEllipsis: true)
            }
            // 文本可以完全显示
            return (findedIndex: ctInfo.glyphWidthArr.count - 1, needEllipsis: true)
        }

        if ctInfo.lktextLine.width > limitedWidth {
            Self.logger.info("ReactionTag appendMore TextLineWidthGreaterThanLimitedWidth \(self.userNames.count)")
            let findedIndex = self.findMaxIndex(limitedWidth: limitedWidth - self.ellipsisWidth, ctInfo: ctInfo)
            let nameLocation = self.locateName(index: findedIndex, ctInfo: ctInfo)
            if nameLocation + 1 == self.userNames.count {
                return nil
            }
            let i18nWith = self.processReactionAppendTextAndWidth(nameCount: self.userNames.count).1
            return truncateNamesWithi18n(limitedWidth: limitedWidth - i18nWith)
        }

        return nil
    }

    // 已知不需要"+x人"文案，仅判断是否需要截断
    private func checkWithoutAppendMore(limitedWidth: CGFloat, ctInfo: CoreTextInformation) -> (findedIndex: Int, needEllipsis: Bool)? {
        guard self.userNames.count <= self.canShowUserNameCount else { return nil }

        if ctInfo.lktextLine.width > limitedWidth {
            let findedIndex = self.findMaxIndex(limitedWidth: limitedWidth - self.ellipsisWidth, ctInfo: ctInfo)
            let nameLocation = self.locateName(index: findedIndex, ctInfo: ctInfo)
            if nameLocation + 1 == self.userNames.count {
                return (findedIndex: findedIndex, needEllipsis: true)
            }
            return nil
        }
        return (findedIndex: ctInfo.glyphWidthArr.count - 1, needEllipsis: false)
    }

    private func buildAttributedString() -> NSAttributedString {
        let attrStr = NSMutableAttributedString(string: "",
                                                attributes: [.font: Cons.labelFont])
        if let firstName = self.userNames.first {
            attrStr.append(NSAttributedString(string: firstName,
                                              attributes: [.font: Cons.labelFont]))
        }
        if self.userNames.count > 1 {
            let needCount = min(self.userNames.count, self.canShowUserNameCount)
            for i in 1..<needCount {
                attrStr.append(NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_Comma,
                                                  attributes: [.font: Cons.labelFont,
                                                               LKMessageReactionCommaAttributeName: LKMessageReactionCommaAttributeName.rawValue]))
                attrStr.append(NSAttributedString(string: self.userNames[i],
                                                  attributes: [.font: Cons.labelFont]))
            }
        }
        return attrStr
    }

    // 生成 Core Text 相关信息
    private func buildCoreTextInformation(attrStr: NSAttributedString) -> CoreTextInformation {
        let lktextLine = LKTextLine(line: CTLineCreateWithAttributedString(attrStr))
        // comma glyph 在 glyph 数组里的位置
        var commaLocationSet: Set<Int> = []
        // comma run 里面的 glyph 数量
        var commaGlyphCount: Int = 0
        // 文本从开头到该 glyph 的宽度
        var glyphWidthArr: [CGFloat] = []
        // 下标为第几个 glyph，值为该 glyph 所对应的 NSString Location
        var glyphIndicesArr: [CFIndex] = []

        // 每个 glyph 逐个遍历
        for runIdx in 0..<lktextLine.runs.count {

            let lkrun = lktextLine.runs[runIdx]
            let glyphCounts = lkrun.glyphPoints.count

            for glyphIdx in 0..<glyphCounts {
                glyphWidthArr.append(lkrun.glyphPoints[glyphIdx].x)
                glyphIndicesArr.append(lkrun.indices[glyphIdx])
            }

            let runAttrDic: NSDictionary = CTRunGetAttributes(lkrun.run)
            // comma run
            if runAttrDic.value(forKey: LKMessageReactionCommaAttributeName.rawValue) != nil {
                commaGlyphCount = glyphCounts
                // 获取目前 glyph 总数量，倒序计算 comma 的位置
                let currentGlyphCount = glyphWidthArr.count
                for i in 1...glyphCounts {
                    commaLocationSet.insert(currentGlyphCount - i)
                }
            }
        }

        if !glyphWidthArr.isEmpty {
            for i in 1..<glyphWidthArr.count {
                glyphWidthArr[i - 1] = glyphWidthArr[i]
            }
            glyphWidthArr[glyphWidthArr.count - 1] = lktextLine.width
        }

        let ctInfo = CoreTextInformation(
            lktextLine: lktextLine,
            commaLocationSet: commaLocationSet,
            commaGlyphCount: commaGlyphCount,
            glyphWidthArr: glyphWidthArr,
            glyphIndicesArr: glyphIndicesArr
        )
        return ctInfo
    }

    // 判断一个 glyph 是否在一个 name 的内部而不是 last glyph
    private func checkIsMiddleTruncate(index: Int, ctInfo: CoreTextInformation) -> Bool {
        // 如果位于 comma 区域，寻找前面最近的一个 name 的 last glyph
        if ctInfo.commaLocationSet.contains(index) {
            ReactionTagLayoutItem.logger.error("index \(index) should not in comma range")
            return false
        }

        if index == ctInfo.glyphWidthArr.count - 1 {
            return false
        }
        return !ctInfo.commaLocationSet.contains(index + 1)
    }

    // 找到符合宽度限制的最大 glyph index
    private func findMaxIndex(limitedWidth: CGFloat, ctInfo: CoreTextInformation) -> Int {
        if let availableIndex = ctInfo.glyphWidthArr.firstIndex(where: { $0 > limitedWidth }) {
            var index = availableIndex - 1
            while ctInfo.commaLocationSet.contains(index) {
                index -= 1
            }
            if index < 0 {
                ReactionTagLayoutItem.logger.error("index \(index) should not negative")
                return 0
            }
            return index
        }
        // 整行文本满足宽度限制
        return ctInfo.glyphWidthArr.count - 1
    }

    // 根据 glyph 位置定位到第几个 name
    private func locateName(index: Int, ctInfo: CoreTextInformation) -> Int {
        if index < 0 || ctInfo.commaLocationSet.contains(index) {
            ReactionTagLayoutItem.logger.error("index \(index) should not in comma range or is negative")
            return 0
        }
        var record = 0
        for i in 0...index {
            if ctInfo.commaLocationSet.contains(i) {
                record += 1
            }
        }
        if record == 0 || ctInfo.commaGlyphCount == 0 {
            return 0
        }
        return record / ctInfo.commaGlyphCount
    }

    // 根据 index 生成文本
    private func generateTextWithIndex(_ index: Int, ctInfo: CoreTextInformation) -> String {
        ReactionTagLayoutItem.logger.info("generateText \(self.userNames.count),\(self.userNames.description.count),\(index)")
        let prefixString: String = self.userNames.prefix(self.canShowUserNameCount).joined(separator: BundleI18n.LarkMessageCore.Lark_Legacy_Comma)
        if index == ctInfo.glyphWidthArr.count - 1 {
            ReactionTagLayoutItem.logger.info("generateTextLast \(prefixString.count),\(index)")
            return prefixString
        }
        ReactionTagLayoutItem.logger.info("generateTextMiddle \(prefixString.count),\(ctInfo.glyphIndicesArr.count),\(index)")
        return NSString(string: prefixString).substring(to: ctInfo.glyphIndicesArr[index + 1])
    }

    // 处理每个 name 距开头距离，点击使用
    private func fixNameWidths(index: Int, needEllipsis: Bool, ctInfo: CoreTextInformation) {
        guard index >= 0 else { return }
        self.userNameWidths = []

        for i in 0...index {
            if ctInfo.commaLocationSet.contains(i) { continue }
            if i == index || !self.checkIsMiddleTruncate(index: i, ctInfo: ctInfo) {
                self.userNameWidths.append(ctInfo.glyphWidthArr[i])
            }
        }
        if needEllipsis, !self.userNameWidths.isEmpty {
            let lastWidth = self.userNameWidths.removeLast()
            self.userNameWidths.append(lastWidth + self.ellipsisWidth)
        }
    }
}

// MARK: - 针对ReactionTagView定制，得到ReactionTag展示需要的所有属性
extension ReactionTagLayoutItem {
    func reactionTagLayout() -> ReactionTagLayout {
        var layout = ReactionTagLayout()
        layout.origin = self.origin
        layout.contentSize = self.contentSize
        layout.iconRect = self.iconRect
        layout.separatorRect = self.separatorRect
        layout.nameRect = self.nameRect
        return layout
    }

    func reactionTagModel() -> ReactionTagModel {
        var model = ReactionTagModel()
        model.delegate = self.delegate
        /// copy reaction
        let reaction = Reaction(type: self.reaction.type, chatterIds: self.reaction.chatterIds, chatterCount: self.reaction.chatterCount)
        reaction.chatters = self.reaction.chatters
        model.reaction = reaction
        model.userIDs = self.userIDs
        model.userNameWidths = self.userNameWidths
        model.font = Cons.labelFont
        model.userNamesText = self.userNamesText
        model.tagBgColor = self.tagBgColor
        model.separatorColor = self.separatorColor
        model.textColor = self.textColor
        return model
    }
}
