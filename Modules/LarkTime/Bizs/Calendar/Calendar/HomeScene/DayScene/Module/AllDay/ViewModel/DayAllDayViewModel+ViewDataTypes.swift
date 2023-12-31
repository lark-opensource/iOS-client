//
//  DayAllDayViewModel+ViewDataTypes.swift
//  Calendar
//
//  Created by 张威 on 2020/8/31.
//

import UIKit
import EventKit
import CTFoundation
import UniverseDesignIcon

/// DayScene - AllDay - ViewModel: ViewDataTypes

// textFonts for Instance View
private let textFonts = (
    title: UIFont.systemFont(ofSize: 14),
    subtitle: UIFont.systemFont(ofSize: 12)
)

private let textLayout = (
    letfMargin: CGFloat(6),
    leftWithIndicator: CGFloat(8),
    leftWithTapIcon: CGFloat(4+14+4),
    // title 和 subtitle 的 spacing
    vSpacing: CGFloat(6),
    // subtitle 最小宽度，如果可用 width 低于这个值，则 subtitle 不显示
    minSubtitleWidth: CGFloat(100)
)

// swiftlint:disable cyclomatic_complexity

// MARK: - ViewData Types

extension DayAllDayViewModel {

    private static func instanceLayoutedTexts(
        from texts: (title: NSAttributedString, subtitle: NSAttributedString?),
        in drawRect: CGRect,
        with hasIndicator: Bool,
        isShowIcon: Bool = false
    ) -> (title: DayScene.LayoutedText, subtitle: DayScene.LayoutedText?) {
        var inset = UIEdgeInsets.zero
        if isShowIcon {
            inset.left = textLayout.leftWithTapIcon
        } else if hasIndicator {
            inset.left = textLayout.leftWithIndicator
        } else {
            inset.left = textLayout.letfMargin
        }
        let textRect = drawRect.inset(by: inset)
        guard let subtitle = texts.subtitle else {
            return (
                title: (text: texts.title, frame: textRect),
                subtitle: DayScene.LayoutedText?.none
            )
        }
        var titleFrame = textRect
        titleFrame.size.width = ceil(texts.title.cd.sizeOfString(constrainedToWidth: textRect.width).width)
        let layoutedTitle = (text: texts.title, frame: titleFrame)
        var layoutedSubtitle: DayScene.LayoutedText?
        let subtitleAvailableWidth = textRect.right - titleFrame.right - textLayout.vSpacing
        if subtitleAvailableWidth >= textLayout.minSubtitleWidth {
            var subtitleFrame = titleFrame
            subtitleFrame.left = titleFrame.right + textLayout.vSpacing
            subtitleFrame.size.width = subtitleAvailableWidth
            layoutedSubtitle = (text: subtitle, frame: subtitleFrame )
        }
        return (title: layoutedTitle, subtitle: layoutedSubtitle)
    }
    
    struct TimeBlockViewData: DayAllDayInstanceViewDataType {
        // 日程块唯一标识符
        var uniqueId: String { timeBlockData.id }
        // 日程 title
        var layoutedTitle: DayScene.LayoutedText = (text: .init(string: ""), frame: .zero)
        // 日程 subtitle
        var layoutedSubtitle: DayScene.LayoutedText? = nil
        var tapIcon: (isSelected: Bool, image: UIImage, canTap: Bool, expandTapInset: UIEdgeInsets, frame: CGRect)? = nil
        var typeIcon: (image: UIImage, tintColor: UIColor)? { nil }
        var backgroundColor: UIColor = .clear
        var indicatorColor: UIColor? { nil }
        var indicatorInfo: (color: UIColor, isStripe: Bool)? { nil }
        var borderColor: UIColor? { UIColor.ud.bgBody }
        var dashedBorderColor: UIColor? { nil }
        var stripColors: (background: UIColor, foreground: UIColor)? { nil }
        var maskOpacity: Float? = nil
        let timeBlockData: TimeBlockModel
        let layout: DayAllDayPageItemLayout
        let drawRect: CGRect
        static let normalIcon = UDIcon.ellipseOutlined
        static let finishIcon = UDIcon.yesFilled

        init(timeBlockData: TimeBlockModel,
             viewSetting: EventViewSetting,
             layout: DayAllDayPageItemLayout,
             outOfDay: Bool,
             drawRect: CGRect) {
            self.timeBlockData = timeBlockData
            self.layout = layout
            self.drawRect = drawRect
            self.updateWithViewSetting(viewSetting)
            self.updateMaskOpacity(with: viewSetting, outOfDay: outOfDay)
        }

        mutating func updateWithViewSetting(_ viewSetting: EventViewSetting) {
            let isCompletedTask = timeBlockData.taskBlockModel?.isCompleted == true
            
            let skinColorHelper = SkinColorHelper(skinType: viewSetting.skinTypeIos, insInfo: .init(from: timeBlockData))
            let iconColor = skinColorHelper.indicatorInfo?.color ?? skinColorHelper.eventTextColor
            let isLightScene = skinColorHelper.skinType == .light
            let normalColor = isLightScene ? iconColor : TimeBlockUtils.Config.darkSceneBlockIconColor
            let selectedColor = isLightScene ? iconColor : TimeBlockUtils.Config.darkSceneBlockIconColor
            let image = TimeBlockUtils.getIcon(model: timeBlockData, isLight: isLightScene, color: normalColor, selectedColor: selectedColor)
            self.tapIcon = (isSelected: isCompletedTask,
                            image: image,
                            canTap: true,
                            expandTapInset: .init(top: -4, left: -4, bottom: -4, right: -4),
                            frame: .init(x: 4, y: 4, width: 14, height: 14))

            // make attributedTitle
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.maximumLineHeight = textFonts.title.lineHeight
            // swiftlint:disable ban_linebreak_byChar
            titleParagraphStyle.lineBreakMode = .byCharWrapping
            // swiftlint:enable ban_linebreak_byChar
            let titleColor = TimeBlockUtils.getTitleColor(helper: skinColorHelper, model: timeBlockData)
            var titleAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: titleColor,
                                                             .paragraphStyle: titleParagraphStyle,
                                                             .font: textFonts.title]
            if isCompletedTask {
                titleAttrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                titleAttrs[.strikethroughColor] = titleColor
            }
            let attributedTitle = NSAttributedString(string: timeBlockData.title, attributes: titleAttrs)

            let layoutedTexts = DayAllDayViewModel.instanceLayoutedTexts(
                from: (title: attributedTitle, subtitle: nil),
                in: drawRect,
                with: false,
                isShowIcon: true
            )
            self.backgroundColor = skinColorHelper.backgroundColor
            layoutedTitle = layoutedTexts.title
            layoutedSubtitle = layoutedTexts.subtitle
        }

        mutating func updateMaskOpacity(with viewSetting: EventViewSetting, outOfDay: Bool) {
            if viewSetting.showCoverPassEvent && outOfDay {
                let helper = SkinColorHelper(skinType: viewSetting.skinTypeIos, insInfo: .init(from: timeBlockData))
                maskOpacity = TimeBlockUtils.getMaskOpacity(helper: helper, model: timeBlockData)
            } else {
                maskOpacity = nil
            }
        }
    }

    struct InstanceViewData: DayAllDayInstanceViewDataType {
        var instance: Instance { semiViewData.instance }
        var calendar: CalendarModel? { semiViewData.calendar }
        var layout: DayAllDayPageItemLayout { semiViewData.layout }

        var uniqueId: String { semiViewData.uniqueId }
        var layoutedTitle: DayScene.LayoutedText
        var layoutedSubtitle: DayScene.LayoutedText?
        // 全天日程无tapIcon
        var tapIcon: (isSelected: Bool, image: UIImage, canTap: Bool, expandTapInset: UIEdgeInsets, frame: CGRect)? { nil }
        var typeIcon: (image: UIImage, tintColor: UIColor)? { semiViewData.typeIcon }
        var backgroundColor: UIColor { semiViewData.backgroundColor }
        var indicatorInfo: (color: UIColor, isStripe: Bool)? { semiViewData.indicatorInfo }
        var dashedBorderColor: UIColor? { semiViewData.dashedBorderColor }
        var stripColors: (background: UIColor, foreground: UIColor)? { semiViewData.stripColors }
        var maskOpacity: Float? { semiViewData.maskOpacity }

        var hashValues: (coreContent: Int, decoration: Int) { semiViewData.hashValues }

        var semiViewData: SemiInstanceViewData

        init(
            instance: Instance,
            calendar: CalendarModel?,
            layout: DayAllDayPageItemLayout,
            outOfDay: Bool,
            drawRect: CGRect,
            viewSetting: EventViewSetting
        ) {
            self.init(semiViewData: SemiInstanceViewData(
                instance: instance,
                calendar: calendar,
                layout: layout,
                outOfDay: outOfDay,
                drawRect: drawRect,
                viewSetting: viewSetting
            ))
        }

        init(semiViewData: SemiInstanceViewData) {
            // make attributedTitle
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.maximumLineHeight = textFonts.title.lineHeight
            // swiftlint:disable ban_linebreak_byChar
            titleParagraphStyle.lineBreakMode = .byCharWrapping
            // swiftlint:enable ban_linebreak_byChar
            var titleAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: semiViewData.textColor,
                                                             .paragraphStyle: titleParagraphStyle,
                                                             .font: textFonts.title]
            if semiViewData.hasStrikethrough {
                titleAttrs[.strikethroughStyle] = NSNumber(value: 1)
                titleAttrs[.strikethroughColor] = UIColor.ud.textPlaceholder
            }
            let attributedTitle = NSAttributedString(string: semiViewData.title, attributes: titleAttrs)

            // make attributedSubtitle
            var attributedSubtitle: NSAttributedString?
            if let subtitle = semiViewData.subtitle {
                let subtitleParagraphStyle = NSMutableParagraphStyle()
                subtitleParagraphStyle.maximumLineHeight = textFonts.subtitle.lineHeight
                subtitleParagraphStyle.lineBreakMode = .byClipping
                var subtitleAttrs = titleAttrs
                subtitleAttrs[.paragraphStyle] = subtitleParagraphStyle
                subtitleAttrs[.font] = textFonts.subtitle
                attributedSubtitle = NSAttributedString(string: subtitle, attributes: subtitleAttrs)
            }

            let layoutedTexts = DayAllDayViewModel.instanceLayoutedTexts(
                from: (title: attributedTitle, subtitle: attributedSubtitle),
                in: semiViewData.drawRect,
                with: !semiViewData.indicatorInfo.isNil
            )
            layoutedTitle = layoutedTexts.title
            layoutedSubtitle = layoutedTexts.subtitle

            self.semiViewData = semiViewData
        }

        mutating func updateWithViewSetting(_ viewSetting: EventViewSetting) {
            semiViewData.updateDecoration(with: viewSetting)

            // update texts with textColor
            var titleAttrs = layoutedTitle.text.attributes(at: 0, effectiveRange: nil)
            titleAttrs[.foregroundColor] = semiViewData.textColor
            layoutedTitle.text = NSAttributedString(string: layoutedTitle.text.string, attributes: titleAttrs)

            if let attrSubtitle = layoutedSubtitle?.text {
                var subtitleAttrs = attrSubtitle.attributes(at: 0, effectiveRange: nil)
                subtitleAttrs[.foregroundColor] = semiViewData.textColor
                layoutedSubtitle?.text = NSAttributedString(string: attrSubtitle.string, attributes: subtitleAttrs)
            }
        }

        mutating func updateMaskOpacity(with viewSetting: EventViewSetting, outOfDay: Bool) {
            semiViewData.updateMaskOpacity(with: viewSetting, outOfDay: outOfDay)
        }
    }

    /// 全天日程块 ViewData
    struct SemiInstanceViewData {
        var instance: Instance
        var calendar: CalendarModel?
        var layout: DayAllDayPageItemLayout
        let drawRect: CGRect
        var outOfDay: Bool

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

        var hashValues: (coreContent: Int, decoration: Int) = (0, 0)

        init(
            instance: Instance,
            calendar: CalendarModel?,
            layout: DayAllDayPageItemLayout,
            outOfDay: Bool,
            drawRect: CGRect,
            viewSetting: EventViewSetting
        ) {
            self.instance = instance
            self.calendar = calendar
            self.drawRect = drawRect
            self.layout = layout
            self.outOfDay = outOfDay

            switch instance {
            case .local(let localInstance):
                uniqueId = String(localInstance.hashValue)
            case .rust(let rustInstance):
                uniqueId = rustInstance.quadrupleStr
            }

            title = ""
            initCoreContent()
            updateDecoration(with: viewSetting)
            updateMaskOpacity(with: viewSetting, outOfDay: outOfDay)
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
            hasher.combine("\(drawRect)")
            hasher.combine(title)
            hasher.combine(subtitle ?? "no subtitle")
            hashValues.coreContent = hasher.finalize()
        }

        fileprivate mutating func updateDecoration(with viewSetting: EventViewSetting) {
            let skinColorHelper = SkinColorHelper(skinType: viewSetting.skinTypeIos, insInfo: .init(from: instance))

            backgroundColor = instance.isCreatedByMeetingRoom.requisition ? UIColor.ud.N100 : skinColorHelper.backgroundColor

            hasStrikethrough = instance.selfAttendeeStatus == .decline

            indicatorInfo = skinColorHelper.indicatorInfo
            dashedBorderColor = skinColorHelper.dashedBorderColor

            stripColors = skinColorHelper.stripeColor
            let isTextGray = hasStrikethrough || instance.isCreatedByMeetingRoom.requisition
            textColor = isTextGray ? UIColor.ud.textPlaceholder : skinColorHelper.eventTextColor

            // 更新 typeIcon 的 tintColor
            if let typeIcon = typeIcon {
                self.typeIcon = (image: typeIcon.image, tintColor: skinColorHelper.typeIconTintColor)
            } else {
                self.typeIcon = nil
            }

            // 秘钥失效，特别设置
            if instance.displayType == .undecryptable {
                stripColors = nil
                textColor = UIColor.ud.textCaption
                backgroundColor = UIColor.ud.N200
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

        fileprivate mutating func updateMaskOpacity(with viewSetting: EventViewSetting, outOfDay: Bool) {
            if viewSetting.showCoverPassEvent && outOfDay {
                maskOpacity = SkinColorHelper(skinType: viewSetting.skinTypeIos, insInfo: .init(from: instance)).maskOpacity
            } else {
                maskOpacity = nil
            }
        }

    }

    /// 描述被收起（collapsed）的日程块的 tip. eg: 还有42个日程
    struct CollapsedTip {
        var title: String
        var layout: DayAllDayPageItemLayout
    }

    /// 描述 PageView 上展示的 Item
    enum SectionItem {
        // Instance ViewData
        case instanceViewData(DayAllDayInstanceViewDataType)
        // 收起的 tip
        case collapsedTip(CollapsedTip)

        var layout: DayAllDayPageItemLayout {
            switch self {
            case .instanceViewData(let viewData): 
                if let instanceViewData = viewData as? InstanceViewData {
                    return instanceViewData.layout
                } else if let timeBlockViewData = viewData as? TimeBlockViewData {
                    return timeBlockViewData.layout
                }
                return DayAllDayPageItemLayout(pageRange: .init(uncheckedBounds: (0, 1)), row: 0)
            case .collapsedTip(let tip): return tip.layout
            }
        }
    }

    struct SectionViewData {
        var expandedItems: [SectionItem]
        var collapsedItems: [SectionItem]

        private var needsUpdateViewSetting = false
        private var needsUpdateMaskOpacity = false
        private var viewSetting: EventViewSetting?
        private var maskOpacityDependency: (currentDay: JulianDay, timeZone: TimeZone)?
        private var startOfCurrentDay: JulianDayUtil.Timestamp?

        init(expandedItems: [SectionItem], collapsedItems: [SectionItem]) {
            self.expandedItems = expandedItems
            self.collapsedItems = collapsedItems
        }

        mutating func setNeedsUpdateViewSetting(_ newViewSetting: EventViewSetting) {
            needsUpdateViewSetting = true
            viewSetting = newViewSetting
        }

        mutating func setNeedsUpdateMaskOpacity(_ newStartOfCurrentDay: JulianDayUtil.Timestamp) {
            needsUpdateMaskOpacity = true
            startOfCurrentDay = newStartOfCurrentDay
        }

        private mutating func updateIfNeeded() {
            guard needsUpdateViewSetting || needsUpdateMaskOpacity else { return }
            defer {
                needsUpdateViewSetting = false
                needsUpdateMaskOpacity = false
            }
            guard let viewSetting = viewSetting  else { return }

            let transform = { (item: SectionItem) -> SectionItem in
                switch item {
                case .instanceViewData(var viewData):
                    if self.needsUpdateViewSetting {
                        viewData.updateWithViewSetting(viewSetting)
                    }
                    if self.needsUpdateMaskOpacity, let startOfCurrentDay = self.startOfCurrentDay {
                        var endTime: Int64 = 0
                        if let data = viewData as? InstanceViewData {
                            endTime = data.instance.endTime
                        } else if let data = viewData as? TimeBlockViewData {
                            endTime = data.timeBlockData.endTime
                        } else {
                            assertionFailure("unknown type")
                        }
                        let outOfDay = endTime < startOfCurrentDay
                        viewData.updateMaskOpacity(with: viewSetting, outOfDay: outOfDay)
                    }
                    return .instanceViewData(viewData)
                case .collapsedTip:
                    return item
                }
            }
            expandedItems = expandedItems.map(transform)
            collapsedItems = collapsedItems.map(transform)
        }

        mutating func updateViewSettingIfNeeded() {
            updateIfNeeded()
        }

    }

}

// swiftlint:enable cyclomatic_complexity
