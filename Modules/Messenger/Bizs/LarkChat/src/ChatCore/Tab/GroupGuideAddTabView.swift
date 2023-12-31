//
//  GroupGuideAddTabView.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/12/16.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkContainer
import LarkSDKInterface
import RxSwift
import LKCommonsLogging
import LarkUIKit
import EENavigator
import UniverseDesignToast
import LarkSetting
import RustPB
import LarkMessageCore

public final class GroupGuideAddTabProviderImp: GroupGuideAddTabProvider {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    public func createView(docToken: String, docType: String, templateId: String, chatId: String, fromVC: UIViewController?) -> UIView {
        return (try? GroupGuideAddTabView(userResolver: userResolver, docToken: docToken, docType: docType, templateId: templateId, chatId: chatId, fromVC: fromVC))
            ?? .init()
    }
}

class GroupGuideAddTabView: UIView, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(GroupGuideAddTabView.self, category: "Module.GroupGuideAddTabView")

    private lazy var button: UIButton = {
        let btn = UIButton()
        if featureGatingService.staticFeatureGatingValue(with: ChatNewPinConfig.pinnedUrlKey) {
            btn.setTitle(BundleI18n.LarkChat.Lark_IM_NewPin_AddPinnedItem_Button, for: .normal)
        } else {
            btn.setTitle(BundleI18n.LarkChat.Lark_IM_AddTab_CardTitle, for: .normal)
        }
        btn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        btn.addTarget(self, action: #selector(click(_:)), for: .touchUpInside)
        btn.backgroundColor = UIColor.ud.primaryContentDefault
        btn.layer.cornerRadius = 6
        return btn
    }()

    private let docToken: String
    private let docType: String
    private let chatId: String
    private let templateId: String

    private let chatAPI: ChatAPI
    private let featureGatingService: FeatureGatingService
    private let chatDocDependency: ChatDocDependency
    private let disposeBag = DisposeBag()
    private weak var fromVC: UIViewController?

    init(userResolver: UserResolver, docToken: String, docType: String, templateId: String, chatId: String, fromVC: UIViewController?) throws {
        self.userResolver = userResolver
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.chatDocDependency = try userResolver.resolve(assert: ChatDocDependency.self)
        self.featureGatingService = try userResolver.resolve(assert: FeatureGatingService.self)

        self.docToken = docToken
        self.docType = docType
        self.chatId = chatId
        self.fromVC = fromVC
        self.templateId = templateId
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.ud.setShadow(type: .s1Up)
        self.addSubview(self.button)
        self.button.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(16)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.height.equalTo(48)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func click(_ button: UIButton) {
        let jumpDoc: (String) -> Void = { [weak fromVC] urlStr in
            guard let navigationController = fromVC?.navigationController,
                  let url = URL(string: urlStr) else { return }
            let navigator = self.navigator
            if Display.pad {
                navigationController.presentedViewController?.dismiss(animated: true) {
                    navigator.push(url, from: navigationController)
                }
            } else {
                let deleteViewController = navigationController.topViewController
                navigator.push(url, from: navigationController)
                navigationController.viewControllers.removeAll(where: { $0 == deleteViewController })
            }
        }

        guard let window = self.fromVC?.currentWindow() else { return }
        let hud = UDToast.showLoading(on: window)
        self.chatDocDependency.createDocsByTemplate(
            docToken: self.docToken,
            docType: Int(self.docType) ?? 0,
            templateId: self.templateId
        ) { [weak self] (result: (url: String?, title: String?), error) in
            guard let url = result.url, !url.isEmpty,
                  let name = result.title, !name.isEmpty else {
                Self.logger.error("createDocsByTemplate failed \(error)")
                hud.remove()
                return
            }
            guard let self = self, let chatId = Int64(self.chatId) else {
                hud.remove()
                return
            }

            // 走添加 New Pin 流程
            if self.featureGatingService.staticFeatureGatingValue(with: ChatNewPinConfig.pinnedUrlKey) {
                self.chatAPI.notifyCreateUrlChatPinPreview(chatId: chatId, url: url, deleteToken: "")
                    .flatMap { [weak self] (res) -> Observable<RustPB.Im_V1_CreateUrlChatPinResponse> in
                        Self.logger.info("chatPinCardTrace createURLPreview success chatId: \(chatId) previewInfos count: \(res.previewInfos.count)")
                        guard let self = self else {
                            return .empty()
                        }
                        let params = res.previewInfos.map { previewInfo in
                            var previewInfo = previewInfo
                            previewInfo.icon.type = URLPreviewPinIconTransformer.transformToPinIconType(RustPB.Basic_V1_Doc.TypeEnum(rawValue: Int(self.docType) ?? 0) ?? .unknown)
                            previewInfo.title = name
                            return (previewInfo, false)
                        }
                        return self.chatAPI.createUrlChatPin(chatId: chatId,
                                                             params: params,
                                                             deleteToken: res.nextDeleteToken)
                    }.observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        guard let window = self?.fromVC?.currentWindow() else { return }
                        hud.showSuccess(with: BundleI18n.LarkChat.Lark_IM_NewPin_AddedToPinned_Toast, on: window)
                        jumpDoc(url)
                    }, onError: { [weak self] error in
                        guard let window = self?.fromVC?.currentWindow() else { return }
                        Self.logger.error("chatPinCardTrace createUrlChatPin fail chatId: \(chatId)", error: error)
                        hud.showFailure(with: BundleI18n.LarkChat.Lark_IM_NewPin_ActionFailedRetry_Toast, on: window, error: error)
                    }).disposed(by: self.disposeBag)
                return
            }

            // 添加群 tab 逻辑
            let jsonDic: [String: String] = ["name": name,
                                             "url": url,
                                             "docType": self.docType]
            var jsonPayload: String?
            if let data = try? JSONEncoder().encode(jsonDic) {
                jsonPayload = String(data: data, encoding: .utf8)
            }
            self.chatAPI.addChatTab(chatId: chatId, name: name, type: .doc, jsonPayload: jsonPayload)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    hud.remove()
                    jumpDoc(url)
                }, onError: { [weak self] error in
                    guard let window = self?.fromVC?.currentWindow() else { return }
                    Self.logger.error("add tab failed \(error)")
                    hud.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                }).disposed(by: self.disposeBag)
        }
    }

}
