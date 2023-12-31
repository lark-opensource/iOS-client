//
//  MoreAppListViewController+UITextViewDelegate.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/13.
//

import LKCommonsLogging
import LarkUIKit
import EENavigator
import Foundation
import Swinject
import RxSwift
import LarkAccountInterface
import LarkAlertController
import LarkOPInterface
import LarkMessengerInterface
import LarkAppLinkSDK
import RustPB
import LarkRustClient
import LarkModel
import EEMicroAppSDK

// MARK: 交互事件 - UITextViewDelegate
extension MoreAppListViewController {
    /// 跳转「获取企业自建应用」
    func _textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        guard let targetUrl = jumpUrl()?.possibleURL() else {
            GuideIndexPageVCLogger.warn("footer link is wrong \(jumpUrl() ?? "")")
            return false
        }
        GuideIndexPageVCLogger.info("guardIndex redirect to Enterprise self-built applications \(targetUrl)")
        self.resolver.navigator.push(targetUrl, context: ["from": fromScene.rawValue], from: self, animated: true, completion: nil)
        return false
    }

    /// FIXME:和数据拉取并行，会存在时序问题（两个请求速度不一样，但是主请求后面的业务以来这个请求的数据），如果主数据先回来，会展示出无链接的header，然后等setting数据回来刷新页面，header刷新成有链接的。和lilun.ios确认，符合预期
    /// 更新配置相关的Url
    func fetchInstruction() {
        let key = "messageaction_plusmenu_config"
        GuideIndexPageVCLogger.info("fetchInstruction start")
        fetchSettingsRequest(fields: [key])?.subscribeForUI(onNext: { [weak self] (config) in
            GuideIndexPageVCLogger.info("fetchInstruction fetch keys finish: \(key) result = \(config)")
            if let configString = config[key],
               let configData = configString.data(using: String.Encoding.utf8),
               let config = try? JSONDecoder().decode(GuideIndexInstructionUrl.self, from: configData) {
                self?.handleInstruction(url: config)
            }
        }, onError: { (error) in
            GuideIndexPageVCLogger.error("fetchInstruction fetch keys failed", tag: "", additionalData: nil, error: error)
        }).disposed(by: disposeBag)
    }
    /// 获取V3 Setting配置信息
    private func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]>? {
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = fields
        return try? resolver.resolve(assert: RustService.self).sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).subscribeOn(ConcurrentMainScheduler.instance)
    }
    /// 成功获取跳转配置
    private func handleInstruction(url: GuideIndexInstructionUrl) {
        instructionUrl = url
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    /// 获取跳转的链接
    private func jumpUrl() -> String? {
        switch self.bizScene {
        case .addMenu:
            return instructionUrl?.plusMenu?.helpUrl
        case .msgAction:
            return instructionUrl?.messageAction?.helpUrl
        }
    }
    /// 跳转的链接是否有效
    func jumpUrlValid() -> Bool {
        return !(jumpUrl()?.isEmpty ?? true)
    }
}
