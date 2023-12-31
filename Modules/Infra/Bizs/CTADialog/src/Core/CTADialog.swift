//
//  CTADialog.swift
//  CTADialog
//
//  Created by aslan on 2023/10/11.
//

import Foundation
import LarkContainer
import UniverseDesignDialog
import UniverseDesignToast
import LKCommonsLogging
import LarkNavigator
import RxSwift

typealias I18n = BundleI18n.CTADialog
public typealias CTADialogCallback = (Bool) -> Void

public protocol CTADialogDependency {
    func navigateToProfile(userId: String, from: UIViewController)
}

final public class CTADialog: UserResolverWrapper {

    let logger = Logger.log(CTADialog.self, category: "CTADialog.CTADialog")

    public var userResolver: LarkContainer.UserResolver

    let request: CTARequest
    let disposeBag: DisposeBag = DisposeBag()

    private lazy var contentView: CTAContentView = {
        let view = CTAContentView()
        return view
    }()

    weak var fromVC: UIViewController?
    var featureKey: String = ""
    var scene: String = ""
    var ctaModel: CTAModel? = nil
    weak var dialog: UDDialog?
    var completion: CTADialogCallback?

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.request = CTARequest(userResolver: userResolver)
    }

    /// userResolver: 用户态支持
    /// vc: 从哪个vc present出来
    /// featureKey: 对应boss系统一个付费点位
    /// scene: 付费点位对应不同场景值，由业务和boss系统对接，组件仅是透传
    /// checkpointTenantId: 点位权益租户ID，注意不是当前租户ID
    /// checkpointUserId: 点位权益用户ID，注意不是当前用户ID
    /// callback: 弹窗dismiss后执行，返回弹窗是否成功，成功包含兜底弹窗
    public func show(from vc: UIViewController,
                     featureKey: String,
                     scene: String,
                     checkpointTenantId: String,
                     checkpointUserId: String? = nil,
                     with completion: CTADialogCallback? = nil) {
        self.fromVC = vc
        self.featureKey = featureKey
        self.scene = scene
        UDToast.showLoading(with: "", on: vc.view)
        self.request.sendAsync(featureKey: featureKey,
                          scene: scene,
                          checkpointTenantId: checkpointTenantId,
                          checkpointUserId: checkpointUserId)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (model, error) in
            guard let `self` = self else {
                completion?(false)
                return
            }
            guard let vc = self.fromVC else {
                completion?(false)
                return
            }
            UDToast.removeToast(on: vc.view)
            guard let model = model, error == nil else {
                self.logger.error("request error", error: error)
                self.showPlaceholderDialog(with: completion)
                return
            }
            self.ctaModel = model
            self.showDialog(model: model, with: completion)
        }, onError: { [weak self] error in
            guard let `self` = self else {
                completion?(false)
                return
            }
            guard let vc = self.fromVC else {
                completion?(false)
                return
            }
            UDToast.removeToast(on: vc.view)
            self.logger.error("catch request error", error: error)
            self.showPlaceholderDialog(with: completion)
        })
        .disposed(by: self.disposeBag)
    }

    private func showPlaceholderDialog(with completion: CTADialogCallback? = nil) {
        guard let fromVC = self.fromVC else {
            return
        }
        let dialog = UDDialog(config: UDDialogUIConfig())
        dialog.setTitle(text: I18n.Lark_CtaCommon_UpgradeForMore_Title)
        dialog.setContent(view: self.contentView)
        let content = "\(I18n.Lark_CtaCommon_UpgradeForMore_Desc)\n\(I18n.Lark_CtaCommon_UpgradeForMore_ContactAdmin_Text())"
        self.contentView.setContent(content: content)
        dialog.addSecondaryButton(text: I18n.Lark_CtaCommon_UpgradeForMore_GotIt_Button, dismissCompletion: {
            CTADialogTracker.click(featureKey: self.featureKey, scene: self.scene)
            completion?(true)
        })
        self.userResolver.navigator.present(dialog, from: fromVC)
        CTADialogTracker.popup(featureKey: self.featureKey, scene: self.scene)
    }

    private func showDialog(model: CTAModel, with completion: CTADialogCallback? = nil) {
        guard let fromVC = self.fromVC else {
            return
        }
        let dialog = UDDialog(config: UDDialogUIConfig())
        /// add title
        let title = model.content?.title?.content ?? I18n.Lark_CtaCommon_UpgradeForMore_Title
        dialog.setTitle(text: title)
        /// add content
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textCaption,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        let displayTxt: NSMutableAttributedString = NSMutableAttributedString()
        for ctaText in (model.content?.body?.text ?? []) {
            let fields = ctaText.fields ?? []
            let content = ctaText.content ?? I18n.Lark_CtaCommon_UpgradeForMore_Desc
            let result = CTATool.replace(original: content,
                                         attributes: attributes,
                                         enableClickProfile: self.enableClickProfile(),
                                         with: fields)
            if (!displayTxt.string.isEmpty) {
                displayTxt.append(NSAttributedString(string: "\n"))
            }
            displayTxt.append(result)
        }
        dialog.setContent(view: self.contentView)
        self.contentView.clickDelegate = self
        self.contentView.setContent(content: displayTxt, imgUrl: model.content?.body?.img?.img_url)
        /// ADD BUTTON
        for item in (model.content?.footer ?? []) {
            guard let content = item.content, !content.isEmpty else {
                continue
            }
            if item.style == CTADialogDefine.Cons.primaryButton {
                dialog.addPrimaryButton(text: content, dismissCompletion: { [weak self] in
                    self?.handleButtonClick(item: item)
                })
            } else {
                dialog.addSecondaryButton(text: content, dismissCompletion: { [weak self] in
                    self?.handleButtonClick(item: item)
                })
            }
        }
        if let footer = model.content?.footer, footer.isEmpty {
            /// footer 为空时候兜底
            dialog.addSecondaryButton(text: I18n.Lark_CtaCommon_UpgradeForMore_GotIt_Button, dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                CTADialogTracker.click(featureKey: self.featureKey, scene: self.scene)
                completion?(true)
            })
        }
        self.dialog = dialog
        self.completion = completion
        self.userResolver.navigator.present(dialog, from: fromVC)
        CTADialogTracker.popup(featureKey: self.featureKey, scene: self.scene, model: model)
    }

    func enableClickProfile() -> Bool {
        /// 如果没有 CTADialogDependency 实现，不跳转profile
        /// 比如单品、Demo工程
        if let _ = try? self.userResolver.resolve(type: CTADialogDependency.self) {
            return true
        }
        return false
    }

    func handleButtonClick(item: CTAFooter) {
        CTADialogTracker.click(tag: item.tag, featureKey: self.featureKey, scene: self.scene, model: self.ctaModel)
        if let url = item.action?.url,
            let URL = URL(string: url),
           let fromVC = self.fromVC {
            self.userResolver.navigator.push(URL, from: fromVC)
        }
        self.completion?(true)
    }
}

extension CTADialog: DialogContentClickDelegate {
    func clickLink(url: URL) {
        guard let fromVC = self.fromVC else {
            return
        }
        if url.scheme == CTADialogDefine.Cons.profileScheme {
            if let host = url.host {
                self.dialog?.dismiss(animated: true)
                self.completion?(true)
                let dependency = try? self.userResolver.resolve(type: CTADialogDependency.self)
                dependency?.navigateToProfile(userId: host, from: fromVC)
                CTADialogTracker.click(tag: "contact_admin", featureKey: self.featureKey, scene: self.scene, model: self.ctaModel)
            }
        }
    }
}


#if LARK_NO_DEBUG

import LarkAssembler

public class CTADialogDebugAssembly: LarkAssemblyInterface {

    public init() {}
}

#endif
