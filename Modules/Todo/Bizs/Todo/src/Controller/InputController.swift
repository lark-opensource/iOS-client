//
//  InputController.swift
//  Todo
//
//  Created by 张威 on 2021/3/8.
//

import EditTextView
import RustPB
import RxSwift
import RxCocoa
import EENavigator
import TodoInterface
import LarkContainer
import ByteWebImage
import LKCommonsLogging
import TangramService
import UniverseDesignIcon
import LarkUIKit
import UIKit
import LarkModel

/// Input Controller
/// 功能包括：
///   - 基于 User/Doc/RichContent 信息构建基本 AttrText
///   - 基于 AttrText 构建 RichContent
///   - 判断 User 是否是 activeUser

final class InputController: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    enum AnchorExtra {
        case hangEntity(Rust.RichText.AnchorHangEntity)
        case hangPoint(Rust.RichText.AnchorHangPoint)
    }

    /// 活跃的 chatterIds
    let rxActiveChatters = BehaviorRelay<Set<String>>(value: [])

    /// at 元素的字体颜色
    var atColors = (active: UIColor.ud.textLinkNormal, inactive: UIColor.ud.textCaption)
    /// anchor 元素的字体颜色
    var anchorColor = UIColor.ud.textLinkNormal

    private var anchorHangComponents = (
        // url 到 points 的映射
        url2Points: [String: Rust.RichText.AnchorHangPoint](),
        // url 到 entity 的映射
        url2Entities: [String: Rust.RichText.AnchorHangEntity](),
        // 标记为本地生成
        markAsLocal: Set<String>()
    )
    private lazy var transformers = initRichTextTransformers()
    @ScopedInjectedLazy private var anchorService: AnchorService?
    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    private var isHangEnabled: Bool {
        return FeatureGating(resolver: userResolver).boolValue(for: .urlPreview)
    }

    private static let logger = Logger.log(InputController.self, category: "Todo.InputController")

    let sourceId: String?
    init(resolver: UserResolver, sourceId: String?) {
        self.userResolver = resolver
        self.sourceId = sourceId
    }

    /// 基于 User 信息构建 AttrText
    func makeAttrText(from user: User, isOuter: Bool, with attrs: [AttrText.Key: Any]) -> MutAttrText {
        let mutAttrText = AtTransformer.makeAttrText(from: user, isOuter: isOuter, with: attrs)
        let range = NSRange(location: 0, length: mutAttrText.length)
        mutAttrText.addAttribute(.foregroundColor, value: isOuter ? atColors.inactive : atColors.active, range: range)
        return mutAttrText
    }

    /// 基于 AnchorExtra 构建 AttrText
    func makeAnchorIconAttrText(from extra: AnchorExtra, with attrs: [AttrText.Key: Any]) -> MutAttrText {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        let attrValue = AttrText.AnchorIconAttrValue(
            key: "",
            localKey: "",
            imageSize: CGSize(width: 25, height: 17),
            type: .normal
        )

        switch extra {
        case .hangPoint(let hangPoint):
            guard isHangEnabled, let anchorService = anchorService else { return .init() }
            imageView.image = UDIcon.linkCopyOutlined.ud.withTintColor(anchorColor)
            switch anchorService.getHangEntity(forPoint: hangPoint) {
            case .sync(let entity):
                attachAnchorIcon(to: imageView, with: entity)
            case .async(let completion):
                completion.onSuccess = { [weak self, weak imageView] entity in
                    guard let self = self, let imageView = imageView else { return }
                    self.attachAnchorIcon(to: imageView, with: entity)
                }
            }
        case .hangEntity(let hangEntity):
            guard isHangEnabled else { return .init() }
            attachAnchorIcon(to: imageView, with: hangEntity)
        }

        var bounds = CGRect(origin: .zero, size: attrValue.imageSize)
        if let font = attrs[.font] as? UIFont {
            bounds = CGRect(
                x: 0,
                y: -(attrValue.imageSize.height - font.ascender - font.descender) / 2,
                width: bounds.size.width,
                height: bounds.size.height
            )
        }

        let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)
        let attrText = MutAttrText(attributedString: AttrText(attachment: attachment))
        let range = NSRange(location: 0, length: 1)
        attrText.addAttribute(.anchorIcon, value: attrValue, range: range)
        attrText.addAttributes(attrs, range: range)
        return attrText
    }

    /// 基于 RichContent 构建 AttrText
    func makeAttrText(from richContent: Rust.RichContent, with attrs: [AttrText.Key: Any], isAtForceActive: Bool = false) -> MutAttrText {
        var richContent = richContent
        Utils.RichText.degradeElements(in: &richContent.richText, inclueImage: false)
        updateAnchorContext(with: richContent)
        var options: [Rust.RichText.Element.Tag: RichTextElementProcess] = [:]
        transformers.forEach { transformer in
            if let info = transformer.transformFromRichText(attributes: attrs,
                attachmentResult: [:]) {
                info.forEach { (tag, process) in
                    options[tag] = process
                }
            }
        }
        let attrText = try? RichTextParseHelper.convert(richText: richContent.richText, options: options)
        let mutAttrText = MutAttrText(attributedString: attrText ?? .init())
        resetAtInfo(in: mutAttrText, isForceActive: isAtForceActive)
        return mutAttrText
    }

    /// 基于 AttrText 生成 RichContent
    func makeRichContent(from attrText: AttrText) -> Rust.RichContent {
        guard let richText = doMakeRichText(from: attrText) else {
            return .init()
        }
        var richContent = Rust.RichContent()
        richContent.richText = richText
        richContent.docEntity = .init()
        richContent.urlPreviewHangPoints = .init()
        richContent.fakePreviewIds = .init()
        for (key, ele) in richText.elements where ele.tag == .a {
            let href = ele.property.anchor.href
            if let hangPoint = anchorHangComponents.url2Points[href] {
                richContent.urlPreviewHangPoints[key] = hangPoint
                if anchorHangComponents.markAsLocal.contains(hangPoint.previewID) {
                    richContent.fakePreviewIds.append(hangPoint.previewID)
                }
                if let hangEntity = anchorHangComponents.url2Entities[href] {
                    assert(hangEntity.previewID == hangPoint.previewID)
                    if hangEntity.previewID == hangPoint.previewID {
                        richContent.urlPreviewEntities.previewEntity[hangPoint.previewID] = hangEntity
                    }
                }
            }
        }
        return richContent
    }

    /// 根据 activeChatterIds，重置 attrText 里的 at 信息
    func resetAtInfo(in mutAttrText: MutAttrText, isForceActive: Bool = false) {
        let range = NSRange(location: 0, length: mutAttrText.length)
        var atInfos = [(range: NSRange, attrValue: AttrText.AtAttrValue)]()
        mutAttrText.enumerateAttribute(.at, in: range, options: []) { (value, range, _) in
            guard let atAttrValue = value as? AttrText.AtAttrValue else { return }
            atInfos.append((range, atAttrValue))
        }
        let activeChatterIds = rxActiveChatters.value
        for (range, attrValue) in atInfos {
            mutAttrText.removeAttribute(.foregroundColor, range: range)
            mutAttrText.removeAttribute(.at, range: range)
            let newColor: UIColor
            if isForceActive || activeChatterIds.contains(attrValue.at.userID) {
                attrValue.at.isOuter = false
                newColor = atColors.active
            } else {
                attrValue.at.isOuter = true
                newColor = atColors.inactive
            }
            mutAttrText.addAttribute(.foregroundColor, value: newColor, range: range)
            mutAttrText.addAttribute(.at, value: attrValue, range: range)
        }
    }

    /// 插入 at 的 attrText
    /// - Parameters:
    /// - Returns: 插入 @ 人信息后，光标所在的位置
    func insertAtAttrText(
        in attrText: MutAttrText,
        for user: User,
        with attrs: [AttrText.Key: Any],
        in range: NSRange,
        isForceActive: Bool = false
    ) -> Int? {
        guard range.location >= 0 && NSMaxRange(range) <= attrText.length else { return nil }

        // init atAttrText
        let isActive = isForceActive ? true : rxActiveChatters.value.contains(user.chatterId)
        let atAttrText = makeAttrText(from: user, isOuter: !isActive, with: attrs)
        let atRange = NSRange(location: 0, length: atAttrText.length)
        let fgColor = isActive ? atColors.active : atColors.inactive
        atAttrText.addAttribute(.foregroundColor, value: fgColor, range: atRange)
        // 尾随加一个空格
        atAttrText.append(AttrText(string: " ", attributes: attrs))

        attrText.replaceCharacters(in: range, with: atAttrText)
        return range.location + atAttrText.length
    }

    /// 需要添加尾随空格
    func needsEndEmptyChar(in attrText: AttrText) -> Bool {
        guard attrText.length > 0 else { return false }
        let range = NSRange(location: attrText.length - 1, length: 1)
        var hasSpan = false
        attrText.enumerateAttribute(.span, in: range, options: []) { (info, _, stop) in
            guard info != nil else { return }
            hasSpan = true
            stop.pointee = true
        }
        return hasSpan
    }

    /// 尾巴添加空格
    /// attach 主要服务用标题，备注等；如果用字符串会改变标题，形成一个新的历史记录
    func appendEndEmptyChar(in attrText: MutAttrText, with attrs: [AttrText.Key: Any]) {
        let emptyText = MutAttrText(attributedString: makeEmptyImageAttrValue())
        emptyText.addAttributes(attrs, range: NSRange(location: 0, length: emptyText.length))
        attrText.append(emptyText)
    }

    /// 给第一个at的标签后插入空格
    func insertWhiteSpaceAfterFirstAt(in attrText: MutAttrText) {
        let range = NSRange(location: 0, length: attrText.length)
        var firstAtRange: NSRange?
        attrText.enumerateAttribute(.at, in: range, options: []) { (value, range, stop) in
            guard value != nil else { return }
            firstAtRange = range
            stop.pointee = true
        }
        guard let firstRange = firstAtRange else { return }
        guard firstRange.location >= 0 && firstRange.length <= range.length else { return }
        if firstRange.location + firstRange.length + 1 > range.length {
            attrText.append(AttrText(string: " "))
        }
    }

}

// MARK: - Get DocEntity/PreviewEntity

extension InputController {

    func updateAnchorContext(with richContent: Rust.RichContent) {
        anchorService?.cacheHangEntities(in: richContent)
        for (id, point) in richContent.urlPreviewHangPoints {
            guard let ele = richContent.richText.elements[id], ele.tag == .a else {
                continue
            }

            let anchor = ele.property.anchor
            anchorHangComponents.url2Points[anchor.href] = point

            if let hangEntity = richContent.urlPreviewEntities.previewEntity[point.previewID] {
                anchorHangComponents.url2Entities[anchor.href] = hangEntity
                if richContent.fakePreviewIds.contains(point.previewID) {
                    anchorHangComponents.markAsLocal.insert(point.previewID)
                }
            }
        }
    }

}

// MARK: - Privates

extension InputController {

    private class EmptyPreviewableView: UIView, AttachmentPreviewableView {}

    private func makeEmptyImageAttrValue() -> AttrText {
        let attachment = CustomTextAttachment(
            customView: EmptyPreviewableView(),
            bounds: .init(origin: .zero, size: .init(width: 1, height: 1))
        )
        let attachmentStr = MutAttrText(attributedString: AttrText(attachment: attachment))
        let imageInfo = RichTextImageTransformInfo(
            key: "",
            localKey: "local.empty.image.key", // LarkRichTextCore.ImageTransformer.LocalEmptyImageKey,
            imageSize: .zero,
            type: .empty
        )
        attachmentStr.addAttribute(.emptyImage, value: imageInfo, range: NSRange(location: 0, length: 1))
        return attachmentStr
    }

    private func attachAnchorIcon(to imageView: UIImageView, with entity: Rust.RichText.AnchorHangEntity) {
        let refEntity = InlinePreviewEntity.transform(from: entity)
        // 优先级：iconKey > iconUrl > iconImage
        // 参考 TangramService#InlinePreviewService
        let setImage = { [weak imageView] (image: UIImage) in
            if Thread.isMainThread {
                imageView?.image = image
            } else {
                DispatchQueue.main.async {
                    imageView?.image = image
                }
            }
        }

        // 优先级：
        // 当业务配置使用彩色icon时，优先使用彩色icon，彩色icon怎么染色由业务配置；
        // 当没有业务没有配置使用彩色icon，则使用inlineIcon，inlineIcon默认染色蓝色
        var localImage: UIImage?
        var imageKey: String?
        var iconColor: UIColor?
        if refEntity.useColorIcon, let header = refEntity.unifiedHeader, header.hasIcon {
            let colorIcon = header.icon
            // 彩色icon是否染色由业务方配置
            localImage = colorIcon.udIcon.unicodeImage ?? colorIcon.udIcon.udImage
            if !colorIcon.icon.key.isEmpty {
                imageKey = colorIcon.icon.key
            } else if !colorIcon.faviconURL.isEmpty {
                imageKey = colorIcon.faviconURL
            }
        } else if localImage == nil, imageKey == nil {
            localImage = refEntity.udIcon?.unicodeImage ?? refEntity.udIcon?.udImage?.ud.withTintColor(anchorColor)
            imageKey = refEntity.iconKey ?? refEntity.iconUrl
            iconColor = anchorColor
        }

        if let localImage = localImage {
            setImage(localImage)
        } else if let key = imageKey, !key.isEmpty {
            let placeholder = UDIcon.globalLinkOutlined.ud.withTintColor(anchorColor)
            imageView.bt.setLarkImage(.default(key: key), placeholder: placeholder, completion: { result in
                switch result {
                case .success(let imageResult):
                    if var image = imageResult.image {
                        if let iconColor = iconColor {
                            image = image.ud.withTintColor(iconColor)
                        }
                        setImage(image)
                    } else {
                        Self.logger.error("load image failed. key: \(key)")
                    }
                case .failure(let error):
                    Self.logger.error("load image failed. err: \(error), key: \(key)")
                }
            })
        } else {
            setImage((refEntity.iconImage ?? UDIcon.globalLinkOutlined).ud.withTintColor(anchorColor))
        }
    }

    private func initRichTextTransformers() -> [RichTextTransformProtocol] {
        var transformers: [RichTextTransformProtocol] = [
            BlockTransformer(tag: .p),
            RichTextTextTransformer(),
            BlockTransformer(tag: .figure),
            BlockTransformer(tag: .ol),
            BlockTransformer(tag: .ul),
            AtTransformer(),
            MentionTransformer(),
            ImageTransformer(),
            MediaTransformer()
        ]
        let anchorTransformer = AnchorTransformer()
        anchorTransformer.extraGetter = { [weak self] anchor in
            guard let self = self else { return nil }
            if let hangEntity = self.anchorHangComponents.url2Entities[anchor.href] {
                return .hangEntity(hangEntity)
            } else if let hangPoint = self.anchorHangComponents.url2Points[anchor.href] {
                return .hangPoint(hangPoint)
            } else {
                return nil
            }
        }
        anchorTransformer.iconTextGetter = { [weak self] (extra, attrs) in
            return self?.makeAnchorIconAttrText(from: extra, with: attrs) ?? .init()
        }
        transformers.append(anchorTransformer)
        transformers.append(RichTextEmotionTransformer())
        transformers.append(LinkTransformer())
        return transformers
    }

    private func removeAttr<T: Any>(for key: AttrText.Key, with targetType: T.Type, in attrText: MutAttrText) {
        var transform = false
        let fullRange = NSRange(location: 0, length: attrText.length)
        attrText.enumerateAttribute(key, in: fullRange, options: []) { (value, range, stop) in
            guard value is T else { return }
            transform = true
            stop.pointee = true
            attrText.replaceCharacters(in: range, with: "")
        }
        if transform {
            removeAttr(for: key, with: T.self, in: attrText)
        }
    }

    private func doMakeRichText(from attrText: AttrText) -> RichText? {
        guard !attrText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        // remove unexpeced attrs, before transforming
        let mutAttrText = MutAttrText(attributedString: attrText)
        removeAttr(for: .anchorIcon, with: AttrText.AnchorIconAttrValue.self, in: mutAttrText)
        removeAttr(for: .emptyImage, with: AttrText.EmptyImageAttrValue.self, in: mutAttrText)

        // transformer
        let attrText = RichTextTextTransformer.removeWhitespacesAndNewlines(mutAttrText)

        var results: [RichTextFragmentAttr] = []
        transformers.forEach { item in
            results = Self.merge(results, item.transformToRichText(attrText))
        }
        results = Self.sortAndDeleteRepetition(results)

        let richTextTuples = results.map { fragment -> (NSRange, [RichTextParseHelper.RichTextAttrTuple]) in
            return (fragment.range, fragment.attrs.map(\.tuple))
        }

        let content: Rust.RichText?
        do {
            content = try RichTextParseHelper.convert(array: richTextTuples)
        } catch {
            content = nil
        }
        return content
    }

    private enum MergeLastFrom {
        case first, second, unkonwn
    }

    private static func merge(_ first: [RichTextFragmentAttr], _ second: [RichTextFragmentAttr]) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []

        // 排序， range 从小到大
        var first = first.sorted(by: { $0.range.location < $1.range.location })
        var second = second.sorted(by: { $0.range.location < $1.range.location })

//        #if DEBUG
//        self.checkoutRangeValidity(results: first)
//        self.checkoutRangeValidity(results: second)
//        #endif

        var lastFrom: MergeLastFrom = .unkonwn

        while !first.isEmpty || !second.isEmpty {
            if first.isEmpty && lastFrom == .second {
                result.append(contentsOf: second)
                second.removeAll()
                break
            }
            if second.isEmpty && lastFrom == .first {
                result.append(contentsOf: first)
                first.removeAll()
                lastFrom = .first
                break
            }

            var insert: RichTextFragmentAttr?
            var insertFrom: MergeLastFrom = .unkonwn
            var isMerge = false
            if second.isEmpty, let itemFromFirst = first.first {
                insert = itemFromFirst
                insertFrom = .first
            } else if first.isEmpty, let itemFromSecond = second.first {
                insert = itemFromSecond
                insertFrom = .second
            } else if let itemFromFirst = first.first, let itemFromSecond = second.first {
                if itemFromFirst.range.location > itemFromSecond.range.location {
                    insert = itemFromSecond
                    insertFrom = .second
                } else {
                    insert = itemFromFirst
                    insertFrom = .first
                }
            }
            guard let insertItem = insert else { break }

            let deferBlock = {
                lastFrom = isMerge ? .unkonwn : insertFrom
                if insertFrom == .first {
                    first.removeFirst(1)
                } else if insertFrom == .second {
                    second.removeFirst(1)
                }
            }

            guard let lastItem = result.last else {
                // 第一次插入数据
                result.append(insertItem)
                deferBlock()
                continue
            }

            if lastFrom == insertFrom {
                // 如果与上次插入来源相同 则直接插入
                result.append(insertItem)
            } else {
                let mergeItems = merge(lastItem, insertItem)
                result.removeLast(1)
                result.append(contentsOf: mergeItems)
                isMerge = true
            }
            deferBlock()
        }

        return result
    }

    private static func merge(
        _ first: RichTextFragmentAttr,
        _ second: RichTextFragmentAttr
    ) -> [RichTextFragmentAttr] {

        // 判断是否有交集 没有交集直接返回
        if first.range.location >= second.range.location + second.range.length {
            return [second, first]
        } else if second.range.location >= first.range.location + first.range.length {
            return [first, second]
        }

        var results: [RichTextFragmentAttr] = []
        var range1: NSRange?
        var range2: NSRange?
        var range3: NSRange?

        if first.range.location < second.range.location,
            first.range.location + first.range.length > second.range.location,
            first.range.location + first.range.length < second.range.location + second.range.length {
            // first 与 second 有交集，且 first 在前面
            range1 = NSRange(location: first.range.location, length: second.range.location - first.range.location)
            range2 = NSRange(location: second.range.location, length: first.range.location + first.range.length - second.range.location)
            range3 = NSRange(location: first.range.location + first.range.length, length: second.range.location + second.range.length - first.range.location - first.range.length)
        } else if second.range.location < first.range.location,
            second.range.location + second.range.length > first.range.location,
            second.range.location + second.range.length < first.range.location + first.range.length {
            // first 与 second 有交集，且 second 在前面
            range1 = NSRange(location: second.range.location, length: first.range.location - second.range.location)
            range2 = NSRange(location: first.range.location, length: second.range.location + second.range.length - first.range.location)
            range3 = NSRange(location: second.range.location + second.range.length, length: first.range.location + first.range.length - second.range.location - second.range.length)
        } else if first.range.location <= second.range.location && first.range.location + first.range.length >= second.range.location + second.range.length {
            // second 为 first 的子集
            range1 = NSRange(location: first.range.location, length: second.range.location - first.range.location)
            range2 = second.range
            range3 = NSRange(location: second.range.location + second.range.length, length: first.range.location + first.range.length - second.range.location - second.range.length)
        } else if first.range.location >= second.range.location && first.range.location + first.range.length <= second.range.location + second.range.length {
            // first 为 second 的子集
            range1 = NSRange(location: second.range.location, length: first.range.location - second.range.location)
            range2 = first.range
            range3 = NSRange(location: first.range.location + first.range.length, length: second.range.location + second.range.length - first.range.location - first.range.length)
        }

        let handler = { (range: NSRange) in
            let result = first.attrs.compactMap { $0.split(range: range, origin: first.range) } + second.attrs.compactMap { $0.split(range: range, origin: second.range) }
            results.append(RichTextFragmentAttr(range, result))
        }

        if let range = range1, range.length != 0 { handler(range) }
        if let range = range2, range.length != 0 { handler(range) }
        if let range = range3, range.length != 0 { handler(range) }

        return results
    }

    private static func sortAndDeleteRepetition(_ result: [RichTextFragmentAttr]) -> [RichTextFragmentAttr] {
        return result.map { (fragment) -> RichTextFragmentAttr in
            var hasContent = false
            let attrs: [RichTextAttr] = fragment.attrs
                .sorted(by: { $0.priority.rawValue > $1.priority.rawValue }) // 按照优先级排序
                .filter { (attr) -> Bool in // 只保留一个 content 级别的内容
                    if attr.priority.rawValue <= RichTextAttrPriority.content.rawValue {
                        if hasContent { return false }
                        hasContent = true
                    }
                    return true
                }
                .reversed() // 数据需要翻转，嵌套关系为数组前面的元素为后面元素的子元素
            return RichTextFragmentAttr(fragment.range, attrs)
        }
    }

}

// MARK: - Capture Link Action

extension InputController {

    typealias TapItem = AttrText.TapAttrValue.Item

    /// 从 TextView 中捕获可点击信息
    func captureTapItem(with gesture: UIGestureRecognizer, in textView: UITextView) -> TapItem? {
        let layoutManager = textView.layoutManager
        var location = gesture.location(in: textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        let charIndex = layoutManager.characterIndex(
            for: location,
            in: textView.textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        guard charIndex < layoutManager.textStorage?.length ?? 0 else { return nil }
        let attrValue = textView.attributedText.attribute(.tap, at: charIndex, effectiveRange: nil)
        guard let tapItem = (attrValue as? AttrText.TapAttrValue)?.item else {
            Self.logger.error("attrValue is not valid")
            return nil
        }
        return tapItem
    }

    func handleTapAction(_ tapItem: TapItem, from fromVC: UIViewController) {
        switch tapItem {
        case .anchor(let anchorProps):
            guard let url = URL(string: anchorProps.href) else {
                Self.logger.error("href is not valid")
                return
            }
            guard let httpUrl = url.lf.toHttpUrl() else {
                Self.logger.error("url is not valid")
                return
            }
            userResolver.navigator.push(httpUrl, context: ["from": "todo_detail"], from: fromVC)
            Self.logger.info("push to url")
        case .at(let atProp):
            var routeParams = RouteParams(from: fromVC)
            if Display.pad {
                routeParams.openType = .present
                routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
                routeParams.wrap = LkNavigationController.self
            } else {
                routeParams.openType = .push
            }
            routeDependency?.showProfile(with: atProp.userID, params: routeParams)
            Self.logger.info("show profile with userId: \(atProp.userID)")
        case .image(let property):
            routeDependency?.previewImages(.property([property]), sourceIndex: 0, sourceView: nil, from: fromVC)
        }
    }

}

// MARK: - Input Handler

extension InputController {

    func makeSpanInputHandler() -> TextViewInputProtocol {
        let spanInputHandler = SpanInputHandler()
        spanInputHandler.onSpanAttrWillRemove = { (mutAttrText, range) in
            mutAttrText.removeAttribute(.tap, range: range)
            mutAttrText.removeAttribute(.at, range: range)
            mutAttrText.removeAttribute(.anchor, range: range)
            mutAttrText.removeAttribute(.mention, range: range)
            mutAttrText.removeAttribute(.foregroundColor, range: range)

            // 如果包含 icon，则移除 icon（替换为一个不可见的 attachment）
            var removeIconAttrText: MutAttrText?
            mutAttrText.enumerateAttribute(.anchorIcon, in: range, options: []) { (value, r, stop) in
                guard value != nil else { return }
                removeIconAttrText = MutAttrText(attributedString: mutAttrText)
                removeIconAttrText?.replaceCharacters(in: r, with: self.makeEmptyImageAttrValue())
                stop.pointee = true
            }
            return removeIconAttrText ?? mutAttrText
        }
        return spanInputHandler
    }

    func makeAnchorInputHandler() -> TextViewInputProtocol {
        let anchorInputHandler = AnchorInputHandler(resolver: userResolver)
        anchorInputHandler.entityCapturer = { [weak self] (url, entity) in
            // 将 anchorInputHandler 捕获的 entity 给存下来
            assert(Thread.isMainThread)
            assert(!entity.previewID.isEmpty)
            var hangPoint = Rust.RichText.AnchorHangPoint()
            hangPoint.previewID = entity.previewID
            hangPoint.url = url
            self?.anchorHangComponents.url2Points[url] = hangPoint
            self?.anchorHangComponents.url2Entities[url] = entity
            self?.anchorHangComponents.markAsLocal.insert(entity.previewID)
            self?.anchorService?.cacheHangEntity(entity, forPoint: hangPoint)
        }
        anchorInputHandler.iconGetter = { [weak self] (entity, attrs) in
            let extra: AnchorExtra = .hangEntity(entity)
            return self?.makeAnchorIconAttrText(from: extra, with: attrs) ?? .init()
        }
        return anchorInputHandler
    }

    func makeReturnInputHandler(_ returnHandler: (() -> Bool)? = nil) -> TextViewInputProtocol {
        let returnInputHandler = ReturnInputHandler { _ -> Bool in
            if let handler = returnHandler {
                return handler()
            }
            return false
        }
        returnInputHandler.newlineFunc = { textView -> Bool in
            // 搜狗换行会 先输入 \r\r 然后删除一个字符 所以这里需要输入两个 \n
            textView.insertText("\n\n")
            return false
        }
        return returnInputHandler
    }

    func makeLimitInputHandler(_ limit: Int?, handler: (() -> UIView?)? = nil) -> TextViewInputProtocol {
        let limitHandler = LimitInputHandler()
        limitHandler.limit = limit
        limitHandler.handler = {
            guard let handler = handler, let view = handler() else { return }
            Utils.Toast.showWarning(
                with: I18N.Todo_CreateTask_ExceedCharacterLimit_Toast,
                on: view,
                delay: 3.0
            )
        }
        return limitHandler
    }

    func makeEmptyBackspaceInputHandler(handler: (() -> Void)? = nil) -> TextViewInputProtocol {
        let backspaceHandler = EmptyBackspaceInputHandler()
        backspaceHandler.handler = handler
        return backspaceHandler
    }
}

extension LarkEditTextView {
    func updateAttributedText(_ text: NSAttributedString, in range: NSRange?) {
        attributedText = text
        if let range = range, range.location >= 0, range.location <= attributedText.length {
            selectedRange = range
        }
    }
}
