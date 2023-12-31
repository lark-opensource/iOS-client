//
//  DayNonAllDayViewModel+ViewDataTypes.swift
//  Calendar
//
//  Created by 张威 on 2020/8/28.
//

import UIKit
import EventKit
import RichLabel
import Foundation
import LarkExtensions
import LarkTimeFormatUtils
import CalendarFoundation
import UniverseDesignFont

/// DayScene - NonAllDay - ViewModel: ViewDataTypes

// textFonts for Instance View
typealias TextFonts = (title: UIFont, subtitle: UIFont)
typealias TextLayout = (
    padding: (
        left: CGFloat,
        leftWithIndicator: CGFloat,
        leftWithTapIcon: CGFloat,
        top: CGFloat,
        bottom: CGFloat,
        rightForSingleLine: CGFloat,
        rightForMultiLine: CGFloat
    ),
    mixedInSingleLine: (
        spacing: CGFloat,
        minSubtitleLength: CGFloat
    )
)
typealias TextFontsAndLayout = (textFonts: TextFonts, textLayout: TextLayout)

private let textFonts = (
    title: UIFont.cd.mediumFont(ofSize: 14),
    subtitle: UIFont.cd.regularFont(ofSize: 12)
)

private let textLayout = (
    padding: (
        left: CGFloat(6),
        leftWithIndicator: CGFloat(8),
        leftWithTapIcon: CGFloat(4+14+4),
        top: CGFloat(5),
        bottom: CGFloat(4),
        rightForSingleLine: CGFloat(1),
        rightForMultiLine: CGFloat(1)
    ),
    // 单行模式下，title 和 subtitle 可能再同一行
    mixedInSingleLine: (
        // title 和 subtitle 之间的 spacing
        spacing: CGFloat(3),
        // subtitle 最小宽度，如果可用 width 低于这个值，则 subtitle 不显示
        minSubtitleLength: CGFloat(100)
    )
)

let defaultFontsAndLayout: TextFontsAndLayout = (textFonts, textLayout)

// swiftlint:disable cyclomatic_complexity

// MARK: Layout of Instance Texts

extension DayNonAllDayViewModel {

    @inline(__always)
    private static func isSingleLine(from height: CGFloat, textFonts: TextFonts) -> Bool {
        !(height > textFonts.title.lineHeight)
    }

    // 只有 title，没有 subtitle 的 layout
    private static func layoutedTitle(
        from title: NSAttributedString,
        in rect: CGRect,
        with indicator: Bool,
        showTapIcon: Bool,
        textFontsAndLayout: TextFontsAndLayout
    ) -> DayScene.LayoutedText {
        let (textFonts, textLayout) = textFontsAndLayout
        let left: CGFloat
        if indicator {
            left = textLayout.padding.leftWithIndicator
        } else {
            left = textLayout.padding.left
        }
        let singleLineEdgeInsets = UIEdgeInsets(
            top: textLayout.padding.top,
            left: left,
            bottom: textLayout.padding.bottom,
            right: textLayout.padding.rightForSingleLine
        )
        var multiLineEdgeInsets = singleLineEdgeInsets
        multiLineEdgeInsets.right = textLayout.padding.rightForMultiLine
        // 去掉多行的底部间距
        multiLineEdgeInsets.bottom = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = textFonts.title.lineHeight
        let textRect: CGRect
        if isSingleLine(from: rect.height - textLayout.padding.top - textLayout.padding.bottom, textFonts: textFonts) {
            paragraphStyle.lineBreakMode = .byClipping
            textRect = rect.inset(by: singleLineEdgeInsets)
        } else {
            paragraphStyle.lineBreakMode = .byWordWrapping
            textRect = rect.inset(by: multiLineEdgeInsets)
        }

        let attrTitle = NSMutableAttributedString(attributedString: title)
        let caculateAttrTitle = NSMutableAttributedString(attributedString: title)
        attrTitle.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attrTitle.length)
        )
        caculateAttrTitle.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: caculateAttrTitle.length)
        )

        var titleFrame = textRect
        let result = caculateSize(attr: caculateAttrTitle, showTapIcon: showTapIcon, width: textRect.width)
        /// 由于多行场景下是是word截断，且在有tapIconAttachment的场景下计算宽度不准
        /// 导致计算出的result.width可能小于textRect.width，导致显示出现问题，因此下面取最大值
        let width = max(result.width, textRect.width)
        // 计算以lineHeight显示的剩余高度, 需要减去DayNonAllDayInstanceView的下边框高度
        let remainder = textRect.size.height - CGFloat(Int(textRect.size.height / textFonts.title.lineHeight)) * textFonts.title.lineHeight - DayNonAllDayInstanceView.Config.borderWidth
        var height = result.height
        // 判断高度是否大于容器高度，取lineHeight（行高）的余数后是否小于lineHeight* 0.6
        // 是则容器高度减去余数得到新的高度，即会留出部分空白区域
        if result.height > textRect.height, remainder != 0 && remainder < textFonts.title.lineHeight * 0.6 {
            height = textRect.height - remainder
        }
        titleFrame.size = CGSize(width: result.width, height: height)
        return (text: attrTitle, frame: titleFrame)
    }
    
    // 有tapIconAttachment场景，boundingRect计算的宽度不准，这里使用layoutEngine计算
    private static func caculateSize(attr: NSAttributedString, showTapIcon: Bool, width: CGFloat) -> CGSize {
        let result: CGSize
        // 有tapIconAttachment场景，boundingRect计算的宽度不准，这里使用layoutEngine计算
        if showTapIcon {
            let textParser = LKTextParserImpl()
            textParser.originAttrString = attr
            textParser.parse()
            let layoutEngine = LKTextLayoutEngineImpl()
            layoutEngine.attributedText = textParser.renderAttrString
            layoutEngine.preferMaxWidth = width
            layoutEngine.numberOfLines = 0
            let topicSize = layoutEngine.layout(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
            result = topicSize
        } else {
            result = attr.cd.sizeOfString(constrainedToWidth: width)
        }
        return result
    }

    // title 和 subtitle 同时存在的 layout
    private static func layoutedTexts(
        from texts: (title: NSAttributedString, subtitle: NSAttributedString),
        in rect: CGRect,
        with indicator: Bool,
        showTapIcon: Bool,
        textFontsAndLayout: TextFontsAndLayout
    ) -> (title: DayScene.LayoutedText, subtitle: DayScene.LayoutedText?) {
        let (textFonts, textLayout) = textFontsAndLayout
        var layoutedTitle = (
            text: NSMutableAttributedString(attributedString: texts.title),
            frame: CGRect.zero
        )

        var layoutedSubtitle = (
            text: NSMutableAttributedString(attributedString: texts.subtitle),
            frame: CGRect.zero
        )

        let paragraphStyles = (
            title: NSMutableParagraphStyle(),
            subtitle: NSMutableParagraphStyle()
        )
        paragraphStyles.title.maximumLineHeight = textFonts.title.lineHeight
        paragraphStyles.subtitle.maximumLineHeight = textFonts.subtitle.lineHeight

        if isSingleLine(from: rect.height - textLayout.padding.top - textLayout.padding.bottom, textFonts: textFonts) {
            // 单行显示。优先显示 title，subtitle 紧贴其后，如果显示不下，就不显示 subtitle
            let left: CGFloat
            if indicator {
                left = textLayout.padding.leftWithIndicator
            } else {
                left = textLayout.padding.left
            }
            let textRect = rect.inset(by: UIEdgeInsets(
                top: textLayout.padding.top,
                left: left,
                bottom: textLayout.padding.bottom,
                right: textLayout.padding.rightForSingleLine
            ))

            paragraphStyles.title.lineBreakMode = .byClipping
            layoutedTitle.text.addAttribute(
                .paragraphStyle,
                value: paragraphStyles.title,
                range: NSRange(location: 0, length: layoutedTitle.text.length)
            )
            let layoutedTitleSize = caculateSize(attr: layoutedTitle.text, showTapIcon: showTapIcon, width: textRect.width)
            layoutedTitle.frame = CGRect(
                origin: textRect.origin,
                size: layoutedTitleSize
            )

            paragraphStyles.subtitle.lineBreakMode = .byClipping
            layoutedSubtitle.text.addAttribute(
                .paragraphStyle,
                value: paragraphStyles.subtitle,
                range: NSRange(location: 0, length: layoutedSubtitle.text.length)
            )
            layoutedSubtitle.frame = CGRect(
                x: layoutedTitle.frame.right + textLayout.mixedInSingleLine.spacing,
                y: layoutedTitle.frame.top,
                width: textRect.right - layoutedTitle.frame.right - textLayout.mixedInSingleLine.spacing,
                height: layoutedTitle.frame.height
            )
            return (
                title: (text: layoutedTitle.text, frame: layoutedTitle.frame),
                subtitle: (text: layoutedSubtitle.text, frame: layoutedSubtitle.frame)
            )
        } else {
            // 多行显示。优先显示 subtitle
            let left: CGFloat
            if indicator {
                left = textLayout.padding.leftWithIndicator
            } else {
                left = textLayout.padding.left
            }

            let textRect = rect.inset(by: UIEdgeInsets(
                top: textLayout.padding.top,
                left: left,
                // 多行显示时去掉底部间距
                bottom: 0,
                right: textLayout.padding.rightForMultiLine
            ))
            // 有tapIconAttachment场景，boundingRect计算的宽度不准，这里给个空格做补偿
            if showTapIcon {
                layoutedTitle.text.append(NSAttributedString(string: " "))
            }
            let titleDesiredSize = layoutedTitle.text.cd.sizeOfString(constrainedToWidth: textRect.width)
            let subtitleDesiredSize = layoutedSubtitle.text.cd.sizeOfString(constrainedToWidth: textRect.width)
            let subTitleTopPadding: CGFloat = 2
            if titleDesiredSize.height + subTitleTopPadding + subtitleDesiredSize.height <= textRect.height {
                // title 和 subtitle 均能完全显示
                paragraphStyles.title.lineBreakMode = .byWordWrapping
                layoutedTitle.text.addAttribute(
                    .paragraphStyle,
                    value: paragraphStyles.title,
                    range: NSRange(location: 0, length: layoutedTitle.text.length)
                )

                paragraphStyles.subtitle.lineBreakMode = .byWordWrapping
                layoutedSubtitle.text.addAttribute(
                    .paragraphStyle,
                    value: paragraphStyles.subtitle,
                    range: NSRange(location: 0, length: layoutedSubtitle.text.length)
                )
                layoutedTitle.frame = CGRect(origin: textRect.origin, size: titleDesiredSize)
                layoutedSubtitle.frame = CGRect(origin: CGPoint(x: layoutedTitle.frame.left, y: layoutedTitle.frame.bottom + subTitleTopPadding), size: subtitleDesiredSize)
                return (
                    title: (text: layoutedTitle.text, frame: layoutedTitle.frame),
                    subtitle: (text: layoutedSubtitle.text, frame: layoutedSubtitle.frame)
                )
            } else {
                // title 和 subtitle 无法全部完全显示
                //   - 至少显示一行 title
                //   - 尽可能多现实 subtitle

                // layout for title
                let titleLines = max(1, Int((textRect.height - subtitleDesiredSize.height - subTitleTopPadding - DayNonAllDayInstanceView.Config.borderWidth) / textFonts.title.lineHeight))
                let titleWidth: CGFloat
                if titleLines == 1 {
                    titleWidth = rect.right - textRect.origin.x
                    paragraphStyles.title.lineBreakMode = .byClipping
                } else {
                    titleWidth = textRect.right - textRect.origin.x
                    paragraphStyles.title.lineBreakMode = .byWordWrapping
                }
                layoutedTitle.text.addAttribute(
                    .paragraphStyle,
                    value: paragraphStyles.title,
                    range: NSRange(location: 0, length: layoutedTitle.text.length)
                )
                layoutedTitle.frame = CGRect(
                    origin: textRect.origin,
                    size: CGSize(
                        width: titleWidth,
                        height: ceil(textFonts.title.lineHeight * CGFloat(titleLines))
                    )
                )

                // layout for subtitle
                // 计算最大显示的高度，需要减去DayNonAllDayInstanceView的下边框高度
                let maxSubtitleHeight = textRect.bottom - layoutedTitle.frame.bottom - DayNonAllDayInstanceView.Config.borderWidth - subTitleTopPadding
                // 计算subTitle的高度
                let subTitleHeight: CGFloat
                var subtitleLines: Int
                // 有可能剩余刚好能显示下subtitle
                if maxSubtitleHeight >= subtitleDesiredSize.height {
                    subTitleHeight = subtitleDesiredSize.height
                    subtitleLines = Int(subtitleDesiredSize.height / textFonts.subtitle.lineHeight)
                } else {
                    subtitleLines = max(0, Int(maxSubtitleHeight / textFonts.subtitle.lineHeight))
                    // 计算显示subtitleLines后的剩余高度
                    let remainder = maxSubtitleHeight - CGFloat(subtitleLines) * textFonts.subtitle.lineHeight
                    // 如果剩余高度能展示下lineHeight的0.6部分并且小于lineHeight，则行数+1
                    if remainder != 0, remainder > textFonts.subtitle.lineHeight * 0.6 {
                        subtitleLines += 1
                    }
                    subTitleHeight = ceil(textFonts.subtitle.lineHeight * CGFloat(subtitleLines))
                }
                let subtitleWidth: CGFloat
                if subtitleLines <= 1 {
                    subtitleWidth = rect.right - textRect.origin.x
                    paragraphStyles.subtitle.lineBreakMode = .byClipping
                } else {
                    subtitleWidth = textRect.right - textRect.origin.x
                    paragraphStyles.subtitle.lineBreakMode = .byWordWrapping
                }
                layoutedSubtitle.frame = CGRect(
                    x: textRect.left,
                    y: layoutedTitle.frame.bottom + subTitleTopPadding,
                    width: subtitleWidth,
                    height: subTitleHeight
                )
                layoutedSubtitle.text.addAttribute(
                    .paragraphStyle,
                    value: paragraphStyles.subtitle,
                    range: NSRange(location: 0, length: layoutedSubtitle.text.length)
                )

                return (
                    title: (text: layoutedTitle.text, frame: layoutedTitle.frame),
                    subtitle: (text: layoutedSubtitle.text, frame: layoutedSubtitle.frame)
                )
            }
        }
    }

    fileprivate static func instanceLayoutedTexts(
        from texts: (title: NSAttributedString, subtitle: NSAttributedString?),
        in rect: CGRect,
        with hasIndicator: Bool,
        showTapIcon: Bool = false,
        textFontsAndLayout: TextFontsAndLayout
    ) -> (title: DayScene.LayoutedText, subtitle: DayScene.LayoutedText?) {
        let title = texts.title
        if let subtitle = texts.subtitle {
            return layoutedTexts(from: (title, subtitle), in: rect, with: hasIndicator, showTapIcon: showTapIcon, textFontsAndLayout: textFontsAndLayout)
        } else {
            return (
                title: layoutedTitle(from: title, in: rect, with: hasIndicator, showTapIcon: showTapIcon, textFontsAndLayout: textFontsAndLayout),
                subtitle: DayScene.LayoutedText?.none
            )
        }
    }

}

// MARK: - Instance View Data Types

extension DayNonAllDayViewModel {

    /// 针对日程块的 ViewData，抽象了两个类型：
    ///  - SemiInstanceViewData
    ///  - InstanceViewData
    ///
    /// InstanceViewData 是真正的 ViewData Type，SemiInstanceViewData 是一个半成品。
    ///
    /// 二者的构建都可在非主线程进行。其中构建 SemiInstanceViewData 不是一个耗时操作，构建 InstanceViewData
    /// 是一个耗时操作（主要是是 texts 相关处理）。
    ///
    /// 构建 InstanceViewData 的步骤是：
    ///     inputs -> SemiInstanceViewData -> InstanceViewData
    ///
    /// 有这两个步骤的原因是，当需要构建新的 InstanceViewData 时，先构建 SemiInstanceViewData，然后取出之前（如果存在）的
    /// InstanceViewData，判断二者的 hash 是否相等，如果相等，则直接使用之前的 InstanceViewData。如下是伪代码：
    ///
    ///     func makeViewData(from instance: Instance) {
    ///         let semiViewData = SemiInstanceViewData(from: instance)
    ///         if let existViewData = viewDataCache[instance.uniqueId],
    ///             existViewData.hashValues == semiViewData.hashValues {
    ///             return existViewData
    ///         } else {
    ///             return InstanceViewData(from: semiViewData)
    ///         }
    ///     }
    ///

    // MARK: SemiInstanceViewData

    struct SemiInstanceViewData {
        let instance: Instance
        let calendar: CalendarModel?
        var frame: CGRect

        let uniqueId: String
        var title: String
        var subtitle: String?
        var typeIcon: (image: UIImage, tintColor: UIColor)?

        var hasStrikethrough: Bool = false
        var textColor: UIColor = .clear
        var backgroundColor: UIColor = .clear
        var indicatorInfo: (color: UIColor, isStripe: Bool)?
        var dashedBorderColor: UIColor?
        var stripColors: (foreground: UIColor, background: UIColor)?
        var maskOpacity: Float?
        var borderColor: UIColor?

        var hashValues: (coreContent: Int, decoration: Int) = (0, 0)

        var textFontsAndLayout: TextFontsAndLayout

        init(
            instance: Instance,
            calendar: CalendarModel?,
            layout: Rust.InstanceLayout,
            pageDrawRect: CGRect,
            viewSetting: EventViewSetting,
            textFontsAndLayout: TextFontsAndLayout = defaultFontsAndLayout
        ) {
            self.instance = instance
            self.calendar = calendar
            self.textFontsAndLayout = textFontsAndLayout
            self.frame = instanceFrame(from: layout, in: pageDrawRect)
            switch instance {
            case .local(let localInstance):
                uniqueId = String(localInstance.hashValue)
            case .rust(let rustInstance):
                uniqueId = rustInstance.quadrupleStr
            }

            title = ""
            initCoreContent()
            updateDecoration(with: viewSetting)
            updateMaskOpacity(with: viewSetting)
        }

        private mutating func initCoreContent() {
            title = DayScene.title(from: instance, in: calendar)
            subtitle = DayScene.subtitle(from: instance)
            if let typeIconImage = DayScene.typeIconImage(for: instance) {
                typeIcon = (image: typeIconImage, tintColor: .clear)
            } else {
                typeIcon = nil
            }

            var hasher = Hasher()
            hasher.combine(uniqueId)
            hasher.combine("\(frame)")
            hasher.combine(title)
            hasher.combine(subtitle ?? "no subtitle")
            hashValues.coreContent = hasher.finalize()
        }

        fileprivate mutating func updateDecoration(with viewSetting: EventViewSetting) {
            let skinColorHelper = SkinColorHelper(skinType: viewSetting.skinTypeIos, insInfo: .init(from: instance))
            backgroundColor = skinColorHelper.backgroundColor
            stripColors = skinColorHelper.stripeColor
            borderColor = UIColor.ud.calEventViewBg

            hasStrikethrough = instance.selfAttendeeStatus == .decline

            indicatorInfo = skinColorHelper.indicatorInfo
            dashedBorderColor = skinColorHelper.dashedBorderColor

            textColor = hasStrikethrough ? UIColor.ud.textPlaceholder : skinColorHelper.eventTextColor

            // 会议室类型的 instance，colors 要特别设置
            if instance.isCreatedByMeetingRoom.strategy || instance.isCreatedByMeetingRoom.requisition {
                backgroundColor = UIColor.ud.bgBodyOverlay
                stripColors = nil
                indicatorInfo = nil
                textColor = UIColor.ud.textCaption
            }

            // 失效日程，特别设置
            if instance.displayType == .undecryptable {
                textColor = UIColor.ud.textCaption
                backgroundColor = UIColor.ud.N200
                stripColors = nil
                indicatorInfo = nil
            }

            // 更新 typeIcon 的 tintColor
            if let typeIcon = typeIcon {
                self.typeIcon = (image: typeIcon.image, tintColor: skinColorHelper.typeIconTintColor)
            } else {
                self.typeIcon = nil
            }

            var hasher = Hasher()
            hasher.combine(hasStrikethrough)
            hasher.combine(textColor)
            hasher.combine(backgroundColor)

            if let dashedBorderColor = dashedBorderColor {
                hasher.combine(dashedBorderColor)
            } else {
                hasher.combine("no dashedBorderColor")
            }
            if let stripColors = stripColors {
                hasher.combine(stripColors.background)
                hasher.combine(stripColors.foreground)
            } else {
                hasher.combine("no stripColors")
            }
            if let indicatorInfo = indicatorInfo {
                hasher.combine(indicatorInfo.color)
                hasher.combine(indicatorInfo.isStripe)
            } else {
                hasher.combine("no indicatorInfo")
            }
            hasher.combine(textColor)
            if let typeIconTintColor = typeIcon?.tintColor {
                hasher.combine(typeIconTintColor)
            } else {
                hasher.combine("no typeIconTintColor")
            }
            hashValues.decoration = hasher.finalize()
        }

        fileprivate mutating func updateMaskOpacity(with viewSetting: EventViewSetting) {
            guard viewSetting.showCoverPassEvent else {
                maskOpacity = nil
                return
            }
            let endTime: TimeInterval
            switch instance {
            case .local(let localInstance):
                endTime = (localInstance.endDate ?? Date()).timeIntervalSince1970
            case .rust(let rustInstance):
                endTime = TimeInterval(rustInstance.endTime)
            }

            guard endTime < Date().timeIntervalSince1970 else {
                maskOpacity = nil
                return
            }
            maskOpacity = SkinColorHelper(skinType: viewSetting.skinTypeIos, insInfo: .init(from: instance)).maskOpacity
        }
    }
    
    @inline(__always)
    static func instanceFrame(from layout: Rust.InstanceLayout, in rect: CGRect) -> CGRect {
        // layout 里的数据已经做了归一化处理，eg: layout.xOffset = 50 表示 50%
        return CGRect(
            x: (rect.left + rect.width * CGFloat(layout.xOffset / 100)),
            y: (rect.top + rect.height * CGFloat(layout.yOffset / 100)),
            width: (rect.width * CGFloat(layout.width / 100)),
            height: (rect.height * CGFloat(layout.height / 100))
        )
    }
    
    // 时间块模型
    struct TimeBlockViewData: DayNonAllDayItemDataType, DayNonAllDayInstanceViewDataType {
        struct Config {
            static let iconMarigin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
            static let iconSize = CGSize(width: 14, height: 14)
            static let iconColor = UIColor.ud.G700.withAlphaComponent(0.7)
        }
        var frame: CGRect = .zero
        var viewData: DayNonAllDayInstanceViewDataType { self }
        // 日程块唯一标识符
        var uniqueId: String { timeBlockData.id }
        // 日程 title
        var layoutedTitle: DayScene.LayoutedText = (text: .init(string: ""), frame: .zero)
        // 日程 subtitle
        var layoutedSubtitle: DayScene.LayoutedText? = nil
        var isShowIndicator = false
        var typeIcon: (image: UIImage, tintColor: UIColor)? { nil }
        var isSelectedTapIcon: Bool = false
        var backgroundColor: UIColor = .clear
        var iconTapRect: CGRect? = nil
        var indicatorColor: UIColor? { nil }
        var indicatorInfo: (color: UIColor, isStripe: Bool)? { nil }
        var borderColor: UIColor? { UIColor.ud.bgBody }
        var dashedBorderColor: UIColor? { nil }
        var stripColors: (background: UIColor, foreground: UIColor)? { nil }
        var maskOpacity: Float? = nil
        let timeBlockData: TimeBlockModel
        private let layout: Rust.InstanceLayout
        private let pageDrawRect: CGRect
        private let textFontsAndLayout: TextFontsAndLayout
        private var viewSetting: EventViewSetting

        init(timeBlockData: TimeBlockModel,
             viewSetting: EventViewSetting,
             layout: Rust.InstanceLayout,
             pageDrawRect: CGRect,
             is12HourStyle: Bool,
             textFontsAndLayout: TextFontsAndLayout = defaultFontsAndLayout) {
            let frame = instanceFrame(from: layout, in: pageDrawRect)
            self.frame = frame
            self.viewSetting = viewSetting
            self.timeBlockData = timeBlockData
            self.pageDrawRect = pageDrawRect
            self.layout = layout
            self.textFontsAndLayout = textFontsAndLayout
            self.updateUI()
        }
        
        // 生成LKAsyncAttachment的富文本
        static func generateAttmentAttributedStringWith(icon: UIImage,
                                                        font: UIFont,
                                                        size: CGSize,
                                                        margin: UIEdgeInsets = .zero) -> NSAttributedString {
            let attachment = LKAsyncAttachment(
                viewProvider: {
                    let iconView = UIImageView()
                    iconView.image = icon
                    return iconView
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
        mutating func updateWithViewSetting(_ viewSetting: EventViewSetting) {
            updateUI()
        }
        
        mutating func updateUI() {
            let isCompleted = timeBlockData.taskBlockModel?.isCompleted == true
            let skinColorHelper = SkinColorHelper(skinType: viewSetting.skinTypeIos, insInfo: .init(from: timeBlockData))
            updateMaskOpacity(with: viewSetting)
            self.backgroundColor = skinColorHelper.backgroundColor
            // make attributedTitle
            let titleColor = TimeBlockUtils.getTitleColor(helper: skinColorHelper, model: timeBlockData)
            var titleAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: titleColor, .font: textFonts.title]
            if isCompleted {
                titleAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                titleAttrs[.strikethroughColor] = titleColor
            }
            self.isSelectedTapIcon = isCompleted
            let isLightScene = skinColorHelper.skinType == .light
            let iconColor = skinColorHelper.indicatorInfo?.color ?? skinColorHelper.eventTextColor
            let normalColor = isLightScene ? iconColor : TimeBlockUtils.Config.darkSceneBlockIconColor
            let selectedColor = isLightScene ? iconColor : TimeBlockUtils.Config.darkSceneBlockIconColor
            let image = TimeBlockUtils.getIcon(model: timeBlockData, isLight: isLightScene, color: normalColor, selectedColor: selectedColor)
            let tapIconAttributedString = Self.generateAttmentAttributedStringWith(icon: image,
                                                                                   font: textFonts.title,
                                                                                   size: Config.iconSize,
                                                                                   margin: Config.iconMarigin)
            let attributedTitle = NSMutableAttributedString(string: timeBlockData.title, attributes: titleAttrs)
            let result = NSMutableAttributedString(attributedString: tapIconAttributedString)
            result.append(attributedTitle)
            let displayWidth = pageDrawRect.width * CGFloat(layout.fullDisplayWidth / 100)
            let iconTapRect: CGRect? = displayWidth > TimeBlockUtils.Config.tapIconLimitWidth ? .init(CGRect(origin: .init(x: Config.iconMarigin.left, y: Config.iconMarigin.top), size: TimeBlockUtils.Config.tapIconTapSize)) : nil
            self.iconTapRect = iconTapRect
            let layoutedTexts = DayNonAllDayViewModel.instanceLayoutedTexts(
                from: (title: result, subtitle: nil),
                in: CGRect(origin: .zero, size: frame.size),
                with: isShowIndicator,
                showTapIcon: true,
                textFontsAndLayout: textFontsAndLayout
            )
            layoutedTitle = layoutedTexts.title
            layoutedSubtitle = layoutedTexts.subtitle
        }

        mutating func updateMaskOpacity(with viewSetting: EventViewSetting) {
            self.viewSetting = viewSetting
            guard viewSetting.showCoverPassEvent else {
                maskOpacity = nil
                return
            }

            guard TimeInterval(timeBlockData.endTime) < Date().timeIntervalSince1970 else {
                return
            }
            let helper = SkinColorHelper(skinType: viewSetting.skinTypeIos, insInfo: .init(from: timeBlockData))
            maskOpacity = TimeBlockUtils.getMaskOpacity(helper: helper, model: timeBlockData)
        }
    }

    // MARK: InstanceViewData

    struct InstanceViewData: DayNonAllDayItemDataType, DayNonAllDayInstanceViewDataType {
        var instance: Instance { semiViewData.instance }
        var calendar: CalendarModel? { semiViewData.calendar }

        var uniqueId: String { semiViewData.uniqueId }
        var layoutedTitle: DayScene.LayoutedText
        var layoutedSubtitle: DayScene.LayoutedText?
        // 日程无tapIcon
        var iconTapRect: CGRect? { nil }
        var isSelectedTapIcon: Bool { false }
        var typeIcon: (image: UIImage, tintColor: UIColor)? { semiViewData.typeIcon }
        var backgroundColor: UIColor { semiViewData.backgroundColor }
        var indicatorInfo: (color: UIColor, isStripe: Bool)? { semiViewData.indicatorInfo }
        var dashedBorderColor: UIColor? { semiViewData.dashedBorderColor }
        var stripColors: (background: UIColor, foreground: UIColor)? { semiViewData.stripColors }
        var maskOpacity: Float? { semiViewData.maskOpacity }
        var frame: CGRect { semiViewData.frame }
        var borderColor: UIColor? { semiViewData.borderColor }

        var hashValues: (coreContent: Int, decoration: Int) { semiViewData.hashValues }

        var viewData: DayNonAllDayInstanceViewDataType { self }

        var semiViewData: SemiInstanceViewData

        init(
            instance: Instance,
            calendar: CalendarModel?,
            layout: Rust.InstanceLayout,
            pageDrawRect: CGRect,
            viewSetting: EventViewSetting,
            textFontsAndLayout: TextFontsAndLayout = defaultFontsAndLayout
        ) {
            self.init(semiViewData: SemiInstanceViewData(
                instance: instance,
                calendar: calendar,
                layout: layout,
                pageDrawRect: pageDrawRect,
                viewSetting: viewSetting,
                textFontsAndLayout: textFontsAndLayout
            ))
        }

        init(semiViewData: SemiInstanceViewData) {
            let (textFonts, _) = semiViewData.textFontsAndLayout
            // make attributedTitle
            var titleAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: semiViewData.textColor, .font: textFonts.title]
            if semiViewData.hasStrikethrough {
                titleAttrs[.strikethroughStyle] = NSNumber(value: 1)
                titleAttrs[.strikethroughColor] = UIColor.ud.textPlaceholder
            }
            let attributedTitle = NSAttributedString(string: semiViewData.title, attributes: titleAttrs)

            // make attributedSubtitle
            var attributedSubtitle: NSAttributedString?
            if let subtitle = semiViewData.subtitle {
                var subtitleAttrs = titleAttrs
                subtitleAttrs[.font] = textFonts.subtitle
                attributedSubtitle = NSAttributedString(string: subtitle, attributes: subtitleAttrs)
            }

            let layoutedTexts = DayNonAllDayViewModel.instanceLayoutedTexts(
                from: (title: attributedTitle, subtitle: attributedSubtitle),
                in: CGRect(origin: .zero, size: semiViewData.frame.size),
                with: !semiViewData.indicatorInfo.isNil,
                textFontsAndLayout: semiViewData.textFontsAndLayout
            )
            layoutedTitle = layoutedTexts.title
            layoutedSubtitle = layoutedTexts.subtitle

            self.semiViewData = semiViewData
        }
        
        mutating func updateUI() {}

        mutating func updateWithViewSetting(_ viewSetting: EventViewSetting) {
            semiViewData.updateDecoration(with: viewSetting)
            semiViewData.updateMaskOpacity(with: viewSetting)

            // update texts with textColor
            var titleAttrs: [NSAttributedString.Key : Any] = [:]
            if layoutedTitle.text.length != 0 {
                titleAttrs = layoutedTitle.text.attributes(at: 0, effectiveRange: nil)
            }
            titleAttrs[.foregroundColor] = semiViewData.textColor
            layoutedTitle.text = NSAttributedString(string: layoutedTitle.text.string, attributes: titleAttrs)

            if let attrSubtitle = layoutedSubtitle?.text {
                var subtitleAttrs = attrSubtitle.attributes(at: 0, effectiveRange: nil)
                subtitleAttrs[.foregroundColor] = semiViewData.textColor
                layoutedSubtitle?.text = NSAttributedString(string: attrSubtitle.string, attributes: subtitleAttrs)
            }
        }

        mutating func updateMaskOpacity(with viewSetting: EventViewSetting) {
            semiViewData.updateMaskOpacity(with: viewSetting)
        }
    }

}

extension DayNonAllDayViewModel {

    struct PageViewData: DayNonAllDayViewDataType {
        
        let julianDay: JulianDay
        var backgroundColor: UIColor
        var instanceItems: [DayNonAllDayItemDataType] = []
        var items: [DayNonAllDayItemDataType] { instanceItems }

        init(
            julianDay: JulianDay,
            backgroundColor: UIColor = Self.backgroundColors.normal,
            instanceItems: [DayNonAllDayItemDataType] = .init()
        ) {
            self.julianDay = julianDay
            self.backgroundColor = backgroundColor
            self.instanceItems = instanceItems
        }

        private var needsUpdateViewSetting = false
        private var viewSetting: EventViewSetting?

        mutating func setNeedsUpdateViewSetting(_ newViewSetting: EventViewSetting) {
            needsUpdateViewSetting = true
            viewSetting = newViewSetting
        }

        mutating func updateViewSettingIfNeeded() {
            guard needsUpdateViewSetting else { return }
            defer { needsUpdateViewSetting = false }

            guard let viewSetting = viewSetting  else { return }

            for i in 0..<instanceItems.count {
                instanceItems[i].updateWithViewSetting(viewSetting)
            }
        }

        static let backgroundColors = (
            normal: UIColor.ud.calEventViewBg,
            today: UIColor.ud.calEventViewBg // 5.0 需求，去掉今天的背景
        )
    }

}

// swiftlint:enable cyclomatic_complexity
