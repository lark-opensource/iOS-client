//
//  RichContentServiceImpl.swift
//  Todo
//
//  Created by 张威 on 2021/6/30.
//

import LarkContainer
import RxSwift
import CTFoundation
import LKCommonsLogging
import TangramService
import RichLabel
import ByteWebImage
import LarkExtensions
import LarkModel
import LarkEmotion
import UniverseDesignIcon
import UniverseDesignFont

class RichContentServiceImpl: RichContentService, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy private var anchorService: AnchorService?
    private var isHangEnabled: Bool {
        return FeatureGating(resolver: userResolver).boolValue(for: .urlPreview)
    }
    private static let logger = Logger.log(
        RichContentServiceImpl.self,
        category: "Todo.RichContentServiceImpl"
    )

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    private var counter: Int32 = 0
    func generateId() -> String {
        return String(OSAtomicIncrement32(&counter) & Int32.max)
    }

    // nolint: long function
    func buildLabelContent(
        with richContent: Rust.RichContent,
        config: RichLabelContentBuildConfig
    ) -> RichLabelContent {
        // 当前总共处理了多少个字符，用来判断截断逻辑
        var location: Int = 0
        var anchorMap = [NSRange: RichLabelContent.AnchorItem]()
        var atMap = [NSRange: RichLabelContent.AtItem]()
        var imageMap = [NSRange: RichLabelContent.ImageItem]()
        var richContent = richContent

        let customFont = (config.baseAttrs[.font] as? UIFont) ?? UDFont.systemFont(ofSize: 16)

        // 对 richText 中的元素进行降级
        Utils.RichText.degradeElements(in: &richContent.richText, inclueImage: false)

        // 处理 TEXT 标签
        let textBuilder: AttributedStringOptionType = { option in
            var textContent = option.element.property.text.content
            textContent = textContent.replacingOccurrences(of: "\r\n", with: config.lineSeperator)
            textContent = textContent.replacingOccurrences(of: "\r", with: config.lineSeperator)
            textContent = textContent.replacingOccurrences(of: "\n", with: config.lineSeperator)
            if location == 0 {
                textContent = Self.leadTrimmed(from: textContent)
            }
            let attrText = MutAttrText(string: textContent, attributes: config.baseAttrs)
            location += attrText.length
            return [attrText]
        }

        // 处理 A 标签
        let anchorBuilder: AttributedStringOptionType = { [weak self] option in
            guard let self = self else { return [MutAttrText(string: "")] }
            let anchorItemId = self.generateId()
            let anchor = option.element.property.anchor
            var content = anchor.textContent.isEmpty ? anchor.content : anchor.textContent
            if content.isEmpty {
                content = anchor.href
            }
            var iconAttrText: AttrText?
            var theItem: RichLabelContent.AnchorItem?
            let setupIconAndContent = { [weak self] (ref3: AnchorRef3) in
                guard let self = self else { return }
                // TODO: isHangEnabled 全量后，如下几行代码逻辑去掉
                var ref3 = ref3
                if !self.isHangEnabled {
                    ref3.hangPoint = nil
                    ref3.hangEntity = nil
                }
                iconAttrText = self.makeAnchorIconAttrText(
                    with: ref3,
                    attrs: config.baseAttrs,
                    anchorConfig: config.anchorConfig,
                    isLeading: location == 0,
                    renderCallback: { config.anchorConfig.renderCallback?(anchorItemId, $0) }
                )
                if let title = self.makeAnchorTitle(with: ref3) {
                    content = title
                }
            }
            let hangPoint = richContent.urlPreviewHangPoints[option.elementId]
            if let hangPoint = hangPoint {
                var hangEntity = richContent.urlPreviewEntities.previewEntity[hangPoint.previewID]
                if
                    hangEntity == nil, let anchorService = self.anchorService,
                    case .sync(let entity) = anchorService.getHangEntity(
                        forPoint: hangPoint,
                        sourceId: config.anchorConfig.sourceIdForHangEntity
                    )
                {
                    hangEntity = entity
                }
                setupIconAndContent((hangEntity, hangPoint))
            } else {
                setupIconAndContent((nil, nil))
            }
            let mutAttrText: MutAttrText
            var ranges: (total: NSRange, icon: NSRange?, text: NSRange)
            if let iconAttrText = iconAttrText {
                mutAttrText = MutAttrText(attributedString: iconAttrText)
                let titleAttrStr = AttrText(string: content, attributes: config.baseAttrs)
                mutAttrText.append(titleAttrStr)
                ranges.icon = NSRange(location: location, length: iconAttrText.length)
                ranges.text = NSRange(location: NSMaxRange(ranges.icon!), length: titleAttrStr.length)
            } else {
                mutAttrText = MutAttrText(string: content, attributes: config.baseAttrs)
                ranges.icon = nil
                ranges.text = NSRange(location: location, length: mutAttrText.length)
            }
            if let anchorColor = config.anchorConfig.foregroundColor {
                mutAttrText.addAttribute(
                    .foregroundColor,
                    value: anchorColor,
                    range: NSRange(location: 0, length: mutAttrText.length)
                )
            }
            ranges.total = NSRange(location: location, length: mutAttrText.length)
            theItem = RichLabelContent.AnchorItem(
                id: anchorItemId,
                property: anchor,
                range: ranges.total,
                iconRange: ranges.icon,
                textRange: ranges.text
            )
            anchorMap[ranges.total] = theItem
            location += mutAttrText.length
            return [mutAttrText]
        }

        // 处理 At 标签
        let atColors = (
            normal: config.atConfig.normalForegroundColor ?? (config.baseAttrs[.foregroundColor] as? UIColor),
            outer: config.atConfig.outerForegroundColor ?? (config.baseAttrs[.foregroundColor] as? UIColor)
        )
        let atBuilder: AttributedStringOptionType = { option in
            let attrText = MutAttrText(
                string: Utils.RichText.atText(from: option.element.property.at),
                attributes: config.baseAttrs
            )
            if let atColor = option.element.property.at.isOuter ? atColors.outer : atColors.normal {
                attrText.addAttribute(
                    .foregroundColor,
                    value: atColor,
                    range: NSRange(location: 0, length: attrText.length)
                )
            }
            let range = NSRange(location: location, length: attrText.length)
            atMap[range] = .init(id: self.generateId(), property: option.element.property.at, range: range)
            location += attrText.length
            return [attrText]
        }

        // 处理 Mention 标签
        let mentionBuilder: AttributedStringOptionType = { option in
            let attrText = MutAttrText(
                string: Utils.RichText.mentionText(from: option.element.property.mention),
                attributes: config.baseAttrs
            )
            location += attrText.length
            return [attrText]
        }

        // 处理 Emotion 标签
        let emotionBuilder: AttributedStringOptionType = { option in
            let emotion = option.element
            // 资源统一从EmotionResouce获取
            guard let icon = EmotionResouce.shared.imageBy(key: emotion.property.emotion.key) else {
                let emotionText = EmotionResouce.shared.i18nBy(key: emotion.property.emotion.key) ?? emotion.property.emotion.key
                let attrText = MutAttrText(string: "[\(emotionText)]", attributes: config.baseAttrs)
                location += attrText.length
                return [attrText]
            }
            let attrText = MutAttrText(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKEmojiAttributeName: LKEmoji(icon: icon, font: customFont, spacing: 1)]
            )
            location += 1
            return [attrText]
        }

        // 处理 P 标签
        let paragraphBuilder: AttributedStringOptionType = { option in
            if location == 0 {
                return []
            } else {
                location += config.lineSeperator.count
                return option.results + [MutAttrText(string: config.lineSeperator)]
            }
        }

        // 处理 Link 标签
        let linkBuilder: AttributedStringOptionType = { option in
            return option.results
        }

        // 处理Image 标签
        let imageBuilder: AttributedStringOptionType = { option in
            let property = option.element.property.image
            let width = config.imageConfig.width ?? UIScreen.main.bounds.width
            let size = Self.calculateSize(originSize: CGSize(width: CGFloat(property.originWidth), height: CGFloat(property.originHeight)), maxSize: CGSize(width: width, height: width))
            let imageSet = ImageItemSet.transform(imageProperty: property)
            let key = imageSet.getThumbKey()
            let resource = LarkImageResource.default(key: key)
            let attachment = LKAsyncAttachment(
                viewProvider: {
                    let imageView = UIImageView()
                    imageView.bt.setLarkImage(
                        with: resource,
                        placeholder: imageSet.inlinePreview,
                        completion: { result in
                            if case .failure(let error) = result {
                                Self.logger.error("setLarkImage failed. err: \(error), key: \(key)")
                            }
                        })
                    return imageView
                }, size: size
            )
            let attrText = MutAttrText(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: attachment]
            )
            let range = NSRange(location: location, length: attrText.length)
            imageMap[range] = RichLabelContent.ImageItem(location: location, property: property, range: range)
            location += attrText.length
            return [attrText]
        }

        /// 处理MyAITool 标签
        let buildTool: AttributedStringOptionType = { option in
            let tool = option.element
            let toolName = tool.property.myAiTool.localToolName
            // 使用中
            let usingName = toolName.isEmpty ?
            BundleI18n.Todo.MyAI_IM_UsingExtention_Text :
            BundleI18n.Todo.MyAI_IM_UsingSpecificExtention_Text(toolName)
            // 已使用
            let usedName = toolName.isEmpty ?
            BundleI18n.Todo.MyAI_IM_UsedExtention_Text :
            BundleI18n.Todo.MyAI_IM_UsedSpecificExtention_Text(toolName)
            let content = tool.property.myAiTool.status == .runing ? usingName : usedName
            let attrText = MutAttrText(
                string: content,
                attributes: config.baseAttrs
            )
            location += attrText.length
            return [attrText]
        }

        let mutAttrTexts = richContent.richText.lc.walker(
            options: [
                .text: textBuilder,
                .a: anchorBuilder,
                .p: paragraphBuilder,
                .link: linkBuilder,
                .at: atBuilder,
                .mention: mentionBuilder,
                .emotion: emotionBuilder,
                .img: imageBuilder,
                .myAiTool: buildTool
            ]
        )
        var attrText = mutAttrTexts.reduce(AttrText(string: ""), +)
        let trailRange = (attrText.string as NSString).rangeOfCharacter(
            from: CharacterSet.whitespacesAndNewlines.inverted,
            options: .backwards
        )
        let length: Int
        if trailRange.length > 0, trailRange.length <= attrText.length {
            length = NSMaxRange(trailRange)
        } else {
            length = 0
        }
        if length != attrText.length {
            attrText = attrText.attributedSubstring(from: NSRange(location: 0, length: length))
            let fixRange = { (range: NSRange) -> NSRange? in
                let fixLength = min(attrText.length - range.location, range.length)
                guard fixLength > 0 else { return nil }
                return NSRange(location: range.location, length: fixLength)
            }
            anchorMap = Dictionary(anchorMap.map({ (key, value) in
                if let fixedTotalRange = fixRange(value.range), fixRange(value.textRange) != nil {
                    var newValue = value
                    newValue.range = fixedTotalRange
                    if let iconRange = value.iconRange {
                        newValue.iconRange = fixRange(iconRange)
                    }
                    return (key, newValue)
                }
                return (key, value)
            }), uniquingKeysWith: { $1 })

            atMap = Dictionary(atMap.map({ (key, value) in
                if let fixedRange = fixRange(value.range) {
                    var newValue = value
                    newValue.range = fixedRange
                    return (key, newValue)
                }
                return (key, value)
            }), uniquingKeysWith: { $1 })

            imageMap = Dictionary(imageMap.map({ (key, value) in
                if let fixedRange = fixRange(value.range) {
                    var newValue = value
                    newValue.range = fixedRange
                    return (key, newValue)
                }
                return (key, value)
            }), uniquingKeysWith: { $1 })
        }
        return RichLabelContent(
            id: generateId(),
            attrText: attrText,
            anchorItems: Array(anchorMap.values),
            atItems: Array(atMap.values),
            imageItems: Array(imageMap.values.sorted(by: { $0.location < $1.location }))
        )
    }
    // enable-lint: long function

    func fixLabelContent(
        labelContent: RichLabelContent,
        with hangEntity: Rust.RichText.AnchorHangEntity,
        for anchorItemId: String
    ) -> RichLabelContent {
        let targetText = !hangEntity.serverTitle.isEmpty ? hangEntity.serverTitle : hangEntity.sdkTitle
        guard
            !targetText.isEmpty,
            let anchorItem = labelContent.anchorItems.first(where: { $0.id == anchorItemId }),
            anchorItem.textRange.location >= 0,
            anchorItem.textRange.length > 0,
            NSMaxRange(anchorItem.textRange) <= labelContent.attrText.length
        else {
            return labelContent
        }
        let oldAttrText = labelContent.attrText.attributedSubstring(from: anchorItem.textRange)
        guard oldAttrText.string != targetText else {
            return labelContent
        }
        let replaceText = AttrText(
            string: targetText,
            attributes: oldAttrText.attributes(at: 0, effectiveRange: nil)
        )
        let newAttrText = MutAttrText(attributedString: labelContent.attrText)
        newAttrText.replaceCharacters(in: anchorItem.textRange, with: replaceText)
        var labelContent = labelContent
        let offset = replaceText.length - anchorItem.textRange.length
        let compareLocation = anchorItem.textRange.location
        for i in 0..<labelContent.anchorItems.count {
            if labelContent.anchorItems[i].range.location >= compareLocation {
                labelContent.anchorItems[i].range.location += offset
            }
            if labelContent.anchorItems[i].textRange.location >= compareLocation {
                labelContent.anchorItems[i].textRange.location += offset
            }
            if var iconRange = labelContent.anchorItems[i].iconRange, iconRange.location >= compareLocation {
                iconRange.location += offset
                labelContent.anchorItems[i].iconRange = iconRange
            }
        }
        for i in 0..<labelContent.atItems.count where labelContent.atItems[i].range.location >= compareLocation {
            labelContent.atItems[i].range.location += offset
        }
        labelContent.attrText = newAttrText
        return labelContent
    }

    // 去除 lead 的空白字符或者空白行
    private static func leadTrimmed(from text: String) -> String {
        let nsText = text as NSString
        let range = nsText.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.inverted)
        if range.length > 0, nsText.length - range.location >= 0 {
            let trimRange = NSRange(location: range.location, length: nsText.length - range.location)
            return nsText.substring(with: trimRange)
        } else {
            return ""
        }
    }

    private static func calculateSize(originSize: CGSize, maxSize: CGSize, minSize: CGSize = CGSize(width: 50, height: 50)) -> CGSize {
        struct Cons {
            static var failedImageSize = CGSize(width: 100, height: 100)
            static var stripeImageJudgeWidth: CGFloat = 200
            static var stripeImageJudgeWHRatio: CGFloat = 1 / 3
            static var stripeImageDisplaySize = CGSize(width: 150, height: 240)
            static var imageMaxDisplaySize = CGSize(width: 680, height: 240)
            static var imageMinDisplaySize = CGSize(width: 40, height: 40)
        }
        let showStripeImage = { (originSize: CGSize, maxSize: CGSize) -> Bool in
            return originSize.width >= Cons.stripeImageJudgeWidth &&
            originSize.width / originSize.height < Cons.stripeImageJudgeWHRatio &&
            maxSize.width >= Cons.stripeImageDisplaySize.width &&
            maxSize.height >= Cons.stripeImageDisplaySize.height
        }
        // 大了缩小到 aspectScaleFit，小了不放大
        let calcSize = { (size: CGSize, maxSize: CGSize) -> CGSize in
            if size.width <= maxSize.width && size.height <= maxSize.height {
                return size
            }
            let widthScaleRatio: CGFloat = min(1, maxSize.width / size.width)
            let heightScaleRatio: CGFloat = min(1, maxSize.height / size.height)
            let scaleRatio = min(widthScaleRatio, heightScaleRatio)
            return CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
        }
        if originSize == .zero {
            return Cons.failedImageSize
        }
        // 长图逻辑
        if showStripeImage(originSize, maxSize) == true {
            return Cons.stripeImageDisplaySize
        }
        let minWidth: CGFloat = minSize.width
        let minHeight: CGFloat = minSize.height
        let minWHRatio: CGFloat = minWidth / minHeight
        let imgWHRatio: CGFloat = originSize.width / originSize.height
        // 算出最适合的尺寸
        let fitSize = calcSize(originSize, maxSize)
        return CGSize(width: max(fitSize.width, minSize.width), height: max(fitSize.height, minSize.height))
    }

}

// MARK: Make Anchor Icon

extension RichContentServiceImpl {

    private typealias AnchorRef3 = (
        hangEntity: Rust.RichText.AnchorHangEntity?,
        hangPoint: Rust.RichText.AnchorHangPoint?
    )

    private func makeAnchorIconAttrText(
        with ref3: AnchorRef3,
        attrs: [AttrText.Key: Any],
        anchorConfig: RichLabelContentBuildConfig.AnchorConfig,
        isLeading: Bool,
        renderCallback: @escaping (RichLabelAnchorRenderState) -> Void
    ) -> AttrText? {
        var attachment: LKAttachmentProtocol?
        let font = (attrs[.font] as? UIFont) ?? UDFont.systemFont(ofSize: 16)
        let color = anchorConfig.foregroundColor ?? (attrs[.foregroundColor] as? UIColor) ?? UIColor.ud.textTitle
        if let hangEntity = ref3.hangEntity {
            attachment = makeIconAttachment(for: hangEntity, font: font, color: color)
            renderCallback(.completed(.hangEntity(hangEntity)))
        } else if let hangPoint = ref3.hangPoint {
            attachment = makeIconAttachment(
                for: hangPoint,
                font: font,
                color: color,
                sourceId: anchorConfig.sourceIdForHangEntity,
                renderCallback: renderCallback
            )
        } else {
            return nil
        }
        if let attachment = attachment {
            // isLeading 表示 icon 处于首字符，去掉 margin left
            if isLeading {
                attachment.margin.left = 0
            }
            return AttrText(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: attachment]
            )
        } else {
            return nil
        }
    }

    private func makeAnchorTitle(with ref3: AnchorRef3) -> String? {
        if let hangEntity = ref3.hangEntity {
            if !hangEntity.serverTitle.isEmpty {
                return hangEntity.serverTitle
            }
            if !hangEntity.sdkTitle.isEmpty {
                return hangEntity.sdkTitle
            }
        }
        return nil
    }

    private func attachAnchorIcon(
        to imageView: UIImageView,
        with entity: Rust.RichText.AnchorHangEntity,
        tintColor: UIColor
    ) {
        let refEntity = InlinePreviewEntity.transform(from: entity)
        // 优先级：iconKey > iconUrl > iconImage
        // 参考 TangramService#InlinePreviewService
        let completion = { (imageView: UIImageView?, image: UIImage?, err: Error?) -> Void in
            if Thread.isMainThread {
                imageView?.image = image?.ud.withTintColor(tintColor)
            } else {
                DispatchQueue.main.async {
                    imageView?.image = image?.ud.withTintColor(tintColor)
                }
            }
            if let err = err {
                Self.logger.error("load image failed. previewId: \(entity.previewID), err: \(err)")
            }
        }
        let key = refEntity.iconKey ?? refEntity.iconUrl
        if let key = key, !key.isEmpty {
            imageView.bt.setLarkImage(
                with: .default(key: key),
                placeholder: BundleResources.TangramService.inline_icon_placeholder,
                completion: { [weak imageView] res in
                    switch res {
                    case .success(let imageResult):
                        completion(imageView, imageResult.image, nil)
                    case .failure(let error):
                        completion(imageView, nil, error)
                    }
                })
        } else if let image = refEntity.iconImage {
            completion(imageView, image, nil)
        } else {
            completion(imageView, UDIcon.linkCopyOutlined, nil)
        }
    }

    private func makeIconAttachment(
        for entity: Rust.RichText.AnchorHangEntity,
        font: UIFont,
        color: UIColor
    ) -> LKAsyncAttachment {
        return makeIconAttachment(with: font, color: color) { [weak self] in
            let imageView = UIImageView()
            guard let self = self else { return imageView }
            self.attachAnchorIcon(to: imageView, with: entity, tintColor: color)
            return imageView
        }
    }

    private func makeIconAttachment(
        for point: Rust.RichText.AnchorHangPoint,
        font: UIFont,
        color: UIColor,
        sourceId: String?,
        renderCallback: @escaping (RichLabelAnchorRenderState) -> Void
    ) -> LKAsyncAttachment {
        return makeIconAttachment(with: font, color: color) { [weak self] in
            let imageView = UIImageView()
            imageView.image = UDIcon.linkCopyOutlined.ud.withTintColor(color)
            guard let self = self, let anchorService = self.anchorService else {
                return imageView
            }
            switch anchorService.getHangEntity(forPoint: point, sourceId: sourceId) {
            case .sync(let value):
                self.attachAnchorIcon(to: imageView, with: value, tintColor: color)
                renderCallback(.completed(.hangEntity(value)))
            case .async(let completion):
                renderCallback(.needsFix(point: point))
                completion.onSuccess = { [weak imageView, weak self] entity in
                    guard let self = self, let imageView = imageView else { return }
                    self.attachAnchorIcon(to: imageView, with: entity, tintColor: color)
                    renderCallback(.needsUpdate(entity: entity))
                    Self.logger.info("get hang entity succeed. pid: \(point.previewID), sid: \(sourceId ?? "")")
                }
                completion.onCompleted = {
                    Self.logger.info("get empty hang entity failed. pid: \(point.previewID), sid: \(sourceId ?? "")")
                }
                completion.onError = {
                    Self.logger.error("get hang entity failed. err: \($0), pid: \(point.previewID), sid: \(sourceId ?? "")")
                }
            }
            return imageView
        }
    }

    private func makeIconAttachment(
        with font: UIFont,
        color: UIColor,
        viewProvider: @escaping () -> UIView
    ) -> LKAsyncAttachment {
        let size = CGSize(width: font.pointSize, height: font.pointSize * 0.95)
        let attachment = LKAsyncAttachment(viewProvider: viewProvider, size: size)
        attachment.fontAscent = font.ascender
        attachment.fontDescent = font.descender
        let edgeInsets = font.pointSize * 0.25
        attachment.margin = UIEdgeInsets(top: 0, left: edgeInsets, bottom: 0, right: edgeInsets)
        return attachment
    }

}
