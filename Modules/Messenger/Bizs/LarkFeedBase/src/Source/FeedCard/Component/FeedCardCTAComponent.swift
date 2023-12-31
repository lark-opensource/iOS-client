//
//  FeedCardCTAComponent.swift
//  LarkFeedBase
//
//  Created by Ender on 2023/10/13.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkOpenFeed
import LarkModel
import LarkUIKit
import RxSwift
import RustPB
import UniverseDesignButton

// MARK: - Factory
public class FeedCardCTAFactory: FeedCardBaseComponentFactory {
    public let context: FeedCardContext
    // 组件类别
    public var type: FeedCardComponentType {
        return .cta
    }
    public init(context: FeedCardContext) {
        self.context = context
    }

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardCTAComponentVM(feedPreview: feedPreview, context: context)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardCTAComponentView()
    }
}

// MARK: - ViewModel
final class FeedCardCTAComponentVM: FeedCardBaseComponentVM, FeedCardLineHeight {
    var type: FeedCardComponentType {
        return .cta
    }
    var height: CGFloat {
        let height = (Cons.topBottomMargin * 2 + Cons.buttonAreaHeight).auto()
        return buttonData.firstButton == nil ? 0 : height
    }

    let feedId: String
    let feedType: FeedPreviewType
    let buttonData: FeedCardButtonData
    let context: FeedCardContext

    // 埋点专用数据
    // TODO: 最小依赖原则，不应该因为埋点保存整个 FeedPreview
    let feedPreview: FeedPreview

    required init(feedPreview: FeedPreview, context: FeedCardContext) {
        self.context = context
        self.feedType = feedPreview.basicMeta.feedCardType
        self.feedId = feedPreview.id
        self.buttonData = feedPreview.uiMeta.buttonData
        self.feedPreview = feedPreview
    }

    // 供 View 调用
    func firstButtonOnClick() {
        if let firstButton = buttonData.firstButton {
            buttonOnClick(buttonData: firstButton, anotherButtonData: buttonData.secondButton)
        }
    }

    // 供 View 调用
    func secondButtonOnClick() {
        if let secondButton = buttonData.secondButton {
            buttonOnClick(buttonData: secondButton, anotherButtonData: buttonData.firstButton)
        }
    }

    // anotherButton 用于判断是否需要置灰
    private func buttonOnClick(buttonData: FeedCardButton, anotherButtonData: FeedCardButton?) {
        if buttonData.actionType == .urlPage {
            if let url = URL(string: buttonData.url),
               let from = self.context.feedContextService.page {
                let context: [String: Any] = ["from": "feed",
                                              "showTemporary": false,
                                              "feedInfo": ["appID": feedId,
                                                           "type": feedType]] as [String: Any]
                self.context.userResolver.navigator.showDetailOrPush(url,
                                                                     context: context,
                                                                     wrap: LkNavigationController.self,
                                                                     from: from)
            }
        } else if buttonData.actionType == .webhook {
            let ctaInfo = FeedCTAInfo(feedId: feedId, buttonId: buttonData.id)
            var anotherCTAInfo: FeedCTAInfo?
            if let anotherButtonData = anotherButtonData,
               anotherButtonData.actionType == .webhook {
                anotherCTAInfo = FeedCTAInfo(feedId: feedId, buttonId: anotherButtonData.id)
            }
            if let from = self.context.feedContextService.page {
                self.context.ctaConfigService.clickWebhookButton(ctaInfo: ctaInfo, anotherCTAInfo: anotherCTAInfo, from: from)
            }
        }
        trackerButtonClick(feedPreview: feedPreview, ctaElement: buttonData.text)
    }

    enum Cons {
        static let topBottomMargin: CGFloat = 4
        static let buttonAreaHeight: CGFloat = 28
    }
}

// MARK: - View
class FeedCardCTAComponentView: FeedCardBaseComponentView {
    var type: FeedCardComponentType {
        return .cta
    }

    var layoutInfo: FeedCardComponentLayoutInfo? {
        return nil
    }

    weak var vm: FeedCardCTAComponentVM?
    var disposeBag = DisposeBag()

    func creatView() -> UIView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = Cons.buttonSpacing.auto()
        return stackView
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? UIStackView,
              let vm = vm as? FeedCardCTAComponentVM else {
            return
        }
        self.vm = vm

        // 配置第一个按钮
        if let firstButton = vm.buttonData.firstButton {
            let ctaInfo = FeedCTAInfo(feedId: vm.feedId, buttonId: firstButton.id)
            let isLoading = vm.context.ctaConfigService.isLoading(ctaInfo)
            let isDisable = vm.context.ctaConfigService.isDisable(ctaInfo)
            var button: UDButton
            if view.arrangedSubviews.count >= 1 {
                button = view.arrangedSubviews.first as? UDButton ?? UDButton()
            } else {
                button = UDButton()
                view.addArrangedSubview(button)
            }
            setButton(button: button,
                      buttonData: firstButton,
                      isLoading: isLoading,
                      isDisable: isDisable)
            button.addTarget(self, action: #selector(clickFirstButton), for: .touchUpInside)
        } else {
            view.arrangedSubviews.forEach { subview in
                view.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }
            return
        }

        // 配置第二个按钮
        if let secondButton = vm.buttonData.secondButton {
            let ctaInfo = FeedCTAInfo(feedId: vm.feedId, buttonId: secondButton.id)
            let isLoading = vm.context.ctaConfigService.isLoading(ctaInfo)
            let isDisable = vm.context.ctaConfigService.isDisable(ctaInfo)
            var button: UDButton
            if view.arrangedSubviews.count >= 2 {
                button = view.arrangedSubviews[1] as? UDButton ?? UDButton()
            } else {
                button = UDButton()
                view.addArrangedSubview(button)
            }
            setButton(button: button,
                      buttonData: secondButton,
                      isLoading: isLoading,
                      isDisable: isDisable)
            button.addTarget(self, action: #selector(clickSecondButton), for: .touchUpInside)
        } else {
            view.arrangedSubviews.dropFirst().forEach { subview in
                view.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }
        }

        self.disposeBag = DisposeBag()
        vm.context.ctaConfigService.buttonChangeObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] feedId in
                guard let `self` = self, vm.feedId == feedId else { return }
                self.updateView(view: view, vm: vm)
            })
            .disposed(by: disposeBag)
    }

    private func setButton(button: UDButton, buttonData: FeedCardButton, isLoading: Bool, isDisable: Bool) {
        switch buttonData.buttonType {
        case .default:
            button.config = .buttonGray.type(.small)
        case .primary:
            button.config = .buttonBlue.type(.small)
        case .success:
            button.config = .buttonGreen.type(.small)
        case .unknownButtonType:
            button.config = .buttonGray.type(.small)
        @unknown default:
            button.config = .buttonGray.type(.small)
        }

        if isLoading {
            button.showLoading()
            button.setTitle(nil, for: .normal)
        } else {
            button.hideLoading()
            button.setTitle(buttonData.text, for: .normal)
        }
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.isEnabled = !isDisable
    }

    @objc
    private func clickFirstButton() {
        vm?.firstButtonOnClick()
    }

    @objc
    private func clickSecondButton() {
        vm?.secondButtonOnClick()
    }

    enum Cons {
        static let buttonSpacing: CGFloat = 12
    }
}

// TODO: UD 提供的样式 LightMode 下底色有问题，先自定义使用，等 UD 修复后可下掉
extension UDButtonUIConifg {
    public static var buttonGray: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                      backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                      textColor: UIColor.ud.textTitle)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.ud.udtokenBtnSeBgNeutralPressed,
                                                       textColor: UIColor.ud.textTitle)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                       textColor: UIColor.ud.udtokenComponentTextDisabledLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryContentDefault)
        return conifg
    }

    public static var buttonBlue: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.primaryContentDefault,
                                                      backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                      textColor: UIColor.ud.primaryContentDefault)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.primaryContentDefault,
                                                       backgroundColor: UIColor.ud.udtokenBtnSeBgPriPressed,
                                                       textColor: UIColor.ud.primaryContentDefault)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.primaryContentLoading,
                                                       backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                       textColor: UIColor.ud.primaryContentLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryContentDefault)
        return conifg
    }

    public static var buttonGreen: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.functionSuccessContentDefault,
                                                      backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                      textColor: UIColor.ud.functionSuccessContentDefault)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.functionSuccessContentDefault,
                                                       backgroundColor: UIColor.ud.udtokenBtnSelectedBgSuccessHover,
                                                       textColor: UIColor.ud.functionSuccessContentDefault)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.functionSuccessContentLoading,
                                                       backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                                       textColor: UIColor.ud.functionSuccessContentLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.functionSuccessContentDefault)
        return conifg
    }
}

// MARK: 埋点相关
// TODO: 埋点下沉到 LarkFeedBase，收归 is_top、biz_id 等等通用数据
extension FeedCardCTAComponentVM {
    // ctaElement: 卡片上配置的文案，需加密
    private func trackerButtonClick(feedPreview: FeedPreview, ctaElement: String) {
        var params: [AnyHashable: Any] = [:]
        if feedPreview.basicMeta.feedPreviewPBType == .appFeed {
            params["click"] = "leftclick_app_feed_card"
            params["feed_card_type"] = "app_feed"
            params["biz_type"] = appFeedBizType(appFeedCardType: feedPreview.preview.appFeedCardData.type)
            params["app_id"] = String(feedPreview.preview.appFeedCardData.appID)
        } else if feedPreview.basicMeta.feedPreviewPBType == .chat {
            params["click"] = "feed_leftclick_chat"
            params["feed_card_type"] = "chat"
        }
        params["is_top"] = feedPreview.basicMeta.isShortcut ? "true" : "false"
        params["click_sub_type"] = "cta"
        params["biz_id"] = feedPreview.basicMeta.bizId
        params["app_feed_card_id"] = feedPreview.id
        if ctaElement.isEmpty {
            params["cta_element"] = "unknown"
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params))
        } else {
            params["cta_element"] = ctaElement
            Tracker.post(TeaEvent(Homeric.FEED_MAIN_CLICK, params: params, md5AllowList: ["cta_element"]))
        }
    }

    private func appFeedBizType(appFeedCardType: Feed_V1_AppFeedCardType) -> String {
        switch appFeedCardType {
        case .unknownAppFeedCardType:
            return "unknown"
        case .mail:
            return "mail"
        case .calendar:
            return "cal"
        case .open:
            return "open"
        @unknown default:
            return "unknown"
        }
    }
}
