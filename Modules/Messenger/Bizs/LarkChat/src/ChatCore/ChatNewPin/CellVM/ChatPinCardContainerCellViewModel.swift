//
//  ChatPinCardContainerCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/25.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkModel
import LKCommonsLogging
import ByteWebImage
import LKRichView
import LarkRichTextCore
import UniverseDesignColor
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LarkSetting
import LarkMessageCore

protocol HasChatPin {
    var pin: ChatPin { get }
}

final class ChatPinCardContainerCellViewModel: ChatPinCardContainerCellAbility, HasChatPin, LKRichViewDelegate {
    private static let logger = Logger.log(ChatPinCardContainerCellViewModel.self, category: "Module.IM.ChatPin")
    private static var cellHeightLimit: CGFloat { 500 }
    private static var cellHeightClippedHeight: CGFloat { 280 }

    var pin: ChatPin {
        return self.metaModel.pin
    }
    private(set) var metaModel: ChatPinCardCellMetaModel
    private let cellViewModel: ChatPinCardCellViewModel
    private let getAvailableMaxWidth: () -> CGFloat
    private let getTargetVC: () -> UIViewController?
    private let refreshHandler: () -> Void
    private let nav: Navigatable
    private let featureGatingService: FeatureGatingService

    private var titleSize: CGSize = .zero
    private var contentSize: CGSize = .zero
    private var pinChatterSize: CGSize = .zero

    private var showCardFooter: Bool {
        if metaModel.pin.isTop, ChatNewPinConfig.supportPinToTop(self.featureGatingService) {
            return true
        }
        return self.renderAbility?.showCardFooter ?? false
    }

    private let renderAbility: (any ChatPinCardRenderAbility)?
    private let cellLifeCycle: ChatPinCardCellLifeCycle?
    private let actionProvider: ChatPinCardActionProvider?
    private var disposeBag = DisposeBag()

    private var richViewCore = LKRichViewCore()
    private var richCoreLock = pthread_rwlock_t()
    private var pinChatterRichElement: LKRichElement?

    private var isExpand: Bool = false
    private var isShowMore: Bool = false

    init(metaModel: ChatPinCardCellMetaModel,
         cellViewModel: ChatPinCardCellViewModel,
         getAvailableMaxWidth: @escaping () -> CGFloat,
         getTargetVC: @escaping () -> UIViewController?,
         refreshHandler: @escaping () -> Void,
         nav: Navigatable,
         featureGatingService: FeatureGatingService) {
        pthread_rwlock_init(&richCoreLock, nil)
        self.metaModel = metaModel
        self.cellViewModel = cellViewModel
        self.renderAbility = cellViewModel as? (any ChatPinCardRenderAbility)
        self.cellLifeCycle = cellViewModel as? ChatPinCardCellLifeCycle
        self.actionProvider = cellViewModel as? ChatPinCardActionProvider
        self.getAvailableMaxWidth = getAvailableMaxWidth
        self.getTargetVC = getTargetVC
        self.refreshHandler = refreshHandler
        self.nav = nav
        self.featureGatingService = featureGatingService
        self.layout()
    }

    private var draggingCellHeight: CGFloat?
    func updateDragState(isDragging: Bool) {
        draggingCellHeight = isDragging ? cellHeight : nil
    }

    private var cellHeight: CGFloat = .zero
    func getCellHeight() -> CGFloat {
        return draggingCellHeight ?? cellHeight
    }

    func render(_ cell: ChatPinListCardContainerCell) {
        cell.moreButton.isHidden = self.getActionItemTypes().isEmpty
        self.renderIcon(cell.iconView)
        self.renderTitle(cell.titleContainer)
        self.renderContent(cell.contentConatiner)
        self.renderPinChatter(cell.pinChatterContainer)

        let result = ChatPinCardContainerCellLayoutManager.calculate(
            iconSize: self.renderAbility?.getIconConfig()?.size ?? .zero,
            titleSize: self.titleSize,
            contentSize: self.contentSize,
            pinChatterSize: self.showCardFooter ? self.pinChatterSize : .zero
        )

        cell.sync(
            layoutResult: result.layoutResult,
            showMore: self.isShowMore,
            showMoreHandler: { [weak self] in
                guard let self = self else { return }
                if self.isShowMore {
                    self.isExpand = true
                    self.refreshHandler()
                }
            }
        )
    }

    func layout() {
        self.titleSize = self.renderAbility?.getTitleSize() ?? .zero
        self.contentSize = self.renderAbility?.getContentSize() ?? .zero
        self.layoutFooter()

        let result = ChatPinCardContainerCellLayoutManager.calculate(
            iconSize: self.renderAbility?.getIconConfig()?.size ?? .zero,
            titleSize: self.titleSize,
            contentSize: self.contentSize,
            pinChatterSize: self.showCardFooter ? self.pinChatterSize : .zero
        )

        if !isExpand, result.cellHeight > Self.cellHeightLimit, self.renderAbility?.supportFold ?? false {
            let heightDifference = result.cellHeight - Self.cellHeightClippedHeight
            let calculatedContentHeight = contentSize.height - heightDifference
            if calculatedContentHeight > 0 {
                contentSize = CGSize(width: contentSize.width, height: calculatedContentHeight)
                cellHeight = Self.cellHeightClippedHeight
                isShowMore = true
            } else {
                cellHeight = result.cellHeight
                isShowMore = false
            }
        } else {
            cellHeight = result.cellHeight
            isShowMore = false
        }
    }

    private func layoutFooter() {
        guard self.showCardFooter else {
            self.pinChatterSize = .zero
            return
        }
        self.pinChatterSize = .zero
        let pin = self.metaModel.pin
        if pin.isTop, ChatNewPinConfig.supportPinToTop(self.featureGatingService) {
            if let topChatter = pin.topChatter {
                self.calculateName(topChatter,
                                   template: BundleI18n.LarkChat.__Lark_IM_SuperApp_NamePrioritized_Text,
                                   replace: { return BundleI18n.LarkChat.Lark_IM_SuperApp_NamePrioritized_Text($0) })
            }
        } else if let pinChatter = pin.pinChatter {
            self.calculateName(pinChatter,
                               template: BundleI18n.LarkChat.__Lark_IM_NewPin_PinnedBy_Text,
                               replace: { return BundleI18n.LarkChat.Lark_IM_NewPin_PinnedBy_Text($0) })
        }
    }

    private func calculateName(_ chatter: Chatter, template: String, replace: (String) -> String) {
        let fromChat = self.metaModel.chat
        let name = chatter.displayName(chatId: fromChat.id,
                                       chatType: fromChat.type,
                                       scene: .reply)
        let key = "{{name}}"
        let blockElement = LKBlockElement(tagName: RichViewAdaptor.Tag.p).style(
            LKRichStyle()
                .font(UIFont.systemFont(ofSize: 14))
                .fontSize(.point(UIFont.systemFont(ofSize: 14).pointSize))
        )
        let atText = LKTextElement(text: name).style(
            LKRichStyle().color( UIColor.ud.primaryPri500)
        )

        let atElement = LKInlineBlockElement(id: chatter.id, tagName: RichViewAdaptor.Tag.at).addChild(atText)
        if !template.contains(key) {
            let text = LKTextElement(text: replace(name)).style(
                LKRichStyle().color(UIColor.ud.textPlaceholder)
            )
            blockElement.children([text])
        } else if template.hasPrefix(key) {
            let text = LKTextElement(text: template.replacingOccurrences(of: key, with: "")).style(
                LKRichStyle().color(UIColor.ud.textPlaceholder)
            )
            blockElement.children([atElement, text])
        } else if template.hasSuffix(key) {
            let text = LKTextElement(text: template.replacingOccurrences(of: key, with: "")).style(
                LKRichStyle().color(UIColor.ud.textPlaceholder)
            )
            blockElement.children([text, atElement])
        } else {
            for (index, value) in template.components(separatedBy: key).enumerated() {
                let text = LKTextElement(text: value).style(
                    LKRichStyle().color(UIColor.ud.textPlaceholder)
                )
                blockElement.addChild(text)
                if index == 0 {
                    blockElement.addChild(atElement)
                }
            }
        }

        self.pinChatterRichElement = blockElement
        let richViewCore = LKRichViewCore()
        let renderer = richViewCore.createRenderer(blockElement)
        richViewCore.load(renderer: renderer)
        self.pinChatterSize = richViewCore.layout(CGSize(width: self.getAvailableMaxWidth() - ChatPinListCardContainerCell.ContentExtraMargin, height: .infinity)) ?? .zero
        pthread_rwlock_wrlock(&self.richCoreLock)
        self.richViewCore = richViewCore
        pthread_rwlock_unlock(&self.richCoreLock)
    }

    private func renderIcon(_ iconView: UIImageView) {
        guard let iconConfig = self.renderAbility?.getIconConfig() else {
            iconView.isHidden = true
            return
        }
        iconView.isHidden = false
        self.disposeBag = DisposeBag()
        URLPreviewPinIconTransformer.renderIcon(iconView, iconResource: iconConfig.iconResource, iconCornerRadius: iconConfig.cornerRadius, disposeBag: self.disposeBag)
    }

    private func renderTitle(_ titleContainer: UIView) {
        /// 找到可更新的视图
        if let targetView = titleContainer.subviews.first {
            targetView.frame = CGRect(origin: .zero, size: self.titleSize)
            self.renderAbility?._updateTitleView(targetView)
            return
        }
        /// 没找到的话先创建一个再更新
        guard let targetView = self.renderAbility?._createTitleView() else {
            return
        }
        targetView.frame = CGRect(origin: .zero, size: self.titleSize)
        titleContainer.addSubview(targetView)
        self.renderAbility?._updateTitleView(targetView)
    }

    private func renderContent(_ contentContainer: UIView) {
        /// 找到可更新的视图
        if let targetView = contentContainer.subviews.first {
            targetView.frame = CGRect(origin: .zero, size: self.contentSize)
            self.renderAbility?._updateContentView(targetView)
            return
        }
        /// 没找到的话先创建一个再更新
        guard let targetView = self.renderAbility?._createContentView() else {
            return
        }
        targetView.frame = CGRect(origin: .zero, size: self.contentSize)
        contentContainer.addSubview(targetView)
        self.renderAbility?._updateContentView(targetView)
    }

    private func renderPinChatter(_ pinChatterContainer: UIView) {

        func updateRichContainerView(_ richContainerView: LKRichContainerView) {
            pthread_rwlock_rdlock(&self.richCoreLock)
            let richViewCore = self.richViewCore
            pthread_rwlock_unlock(&self.richCoreLock)
            richContainerView.richView.setRichViewCore(richViewCore)
            richContainerView.richView.delegate = self
            richContainerView.frame = CGRect(origin: .zero, size: self.pinChatterSize)

        }
        /// 找到可更新的视图
        if let targetView = pinChatterContainer.subviews.first {
            guard let targetView = targetView as? LKRichContainerView else {
                return
            }
            updateRichContainerView(targetView)
            return
        }
        /// 没找到的话先创建一个再更新
        let targetView = LKRichContainerView(frame: CGRect(origin: .zero, size: self.pinChatterSize), options: ConfigOptions([.debug(false)]))
        targetView.richView.bindEvent(selectorLists: [[CSSSelector(value: RichViewAdaptor.Tag.at)]], isPropagation: true)
        updateRichContainerView(targetView)
        pinChatterContainer.addSubview(targetView)
    }

    /// 数据更新 && 计算 size
    func update(_ metaModel: ChatPinCardCellMetaModel) {
        self.metaModel = metaModel
        self.cellViewModel.modelDidChange(model: metaModel)
        self.layout()
    }

    var identifier: String {
        return self.renderAbility?.identifier ?? ""
    }

    func willDisplay() {
        self.cellLifeCycle?.willDisplay()
    }

    func didEndDisplay() {
        self.cellLifeCycle?.didEndDisplay()
    }

    func onResize() {
        self.cellLifeCycle?.onResize()
        self.layout()
    }

    func getActionItemTypes() -> [ChatPinActionItemType] {
        return self.actionProvider?.getActionItems() ?? []
    }

    func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}
    func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}

    func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard element.tagName.typeID == RichViewAdaptor.Tag.at.typeID else {
            return
        }
        let chatterId = element.id
        guard let targetVC = getTargetVC(),
              let pinChatter = self.metaModel.pin.pinChatter,
              pinChatter.id == chatterId else {
            return
        }
        if pinChatter.isAnonymous {
            return
        }
        let body = PersonCardBody(chatterId: chatterId)
        self.nav.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
        event?.stopPropagation()
    }

    func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}
    func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {}
    func getTiledCache(_ view: LKRichView) -> LKTiledCache? { return nil }
    func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {}
}

extension ChatPinCardRenderAbility {
    func _createTitleView() -> UIView {
        return self.createTitleView()
    }

    func _updateTitleView(_ view: UIView) {
        guard let view = view as? TV else {
            return
        }
        self.updateTitletView(view)
    }

    func _createContentView() -> UIView {
        return self.createContentView()
    }

    func _updateContentView(_ view: UIView) {
        guard let view = view as? CV else {
            return
        }
        self.updateContentView(view)
    }

    var identifier: String? {
        return Self.reuseIdentifier
    }
}
