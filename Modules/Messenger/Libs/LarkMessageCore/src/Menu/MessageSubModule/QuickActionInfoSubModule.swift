//
//  QuickActionInfoSubModule.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/8/7.
//

import Foundation
import LarkEMM
import RxSwift
import RxCocoa
import ServerPB
import LarkOpenChat
import LarkRustClient
import LarkMessageBase
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignDialog
import LarkSensitivityControl

public final class QuickActionInfoSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()

    public override var type: MessageActionType {
        return .quickActionInfo
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    /// 只在MyAI的会话 & MyAI的回复才展示
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        guard model.chat.isP2PAi, model.message.fromChatter?.type == .ai else { return false }
        return self.context.userResolver.fg.dynamicFeatureGatingValue(with: "lark.my_ai.debug_mode")
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: "Debug Info",
                                 icon: BundleResources.Menu.menu_quick_action_info,
                                 trackExtraParams: ["click": "quick_action_info", "target": "none"]) { [weak self] in
            self?.getQuickActionInfo(messageId: model.message.id)
        }
    }

    private func getQuickActionInfo(messageId: String) {
        guard let targetVC = self.context.pageAPI, let rustClient = try? self.context.userResolver.resolve(type: RustService.self) else { return }

        let hud = UDToast.showLoading(on: targetVC.view)
        var request = ServerPB_Ai_engine_DebugInfoRequest()
        request.messageID = messageId
        request.mode = .chat
        // 透传请求
        rustClient.sendPassThroughAsyncRequest(request, serCommand: .larkAiGetDebugInfo).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res: ServerPB_Ai_engine_DebugInfoResponse) in
                hud.remove()
                let dialog = UDDialog()
                dialog.setTitle(text: "Debug Info")
                // UDDialog内部无法添加UIScrollView视图，UIScrollView无法被内容撑开
                // dialog.setContent(view: textView)
                let attributedText = NSMutableAttributedString(string: res.debugInfo)
                attributedText.addAttribute(.font, value: UIFont.ud.body0(.fixed))
                attributedText.addAttribute(.foregroundColor, value: UIColor.ud.textTitle)
                let paragraphStyle = NSMutableParagraphStyle(); paragraphStyle.alignment = .left; paragraphStyle.lineSpacing = 4
                attributedText.addAttribute(.paragraphStyle, value: paragraphStyle)
                let contentLabel = UILabel(); contentLabel.attributedText = attributedText; contentLabel.numberOfLines = 0; contentLabel.isUserInteractionEnabled = true
                dialog.setContent(view: contentLabel)
                // 覆盖一个UIScrollView上去，让内容支持滚动
                let label = UILabel(); label.attributedText = attributedText; label.numberOfLines = 0; label.isUserInteractionEnabled = false
                let scrollView = UIScrollView(); scrollView.backgroundColor = UIColor.ud.bgFloat; scrollView.bounces = false
                scrollView.addSubview(label); label.snp.makeConstraints { make in make.edges.equalToSuperview(); make.width.equalToSuperview() }
                contentLabel.addSubview(scrollView); scrollView.snp.makeConstraints { make in make.edges.equalToSuperview() }
                dialog.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_Copy, dismissCompletion: {
                    let config = PasteboardConfig(token: Token("LARK-PSDA-message_menu_copy_quick_action_info"))
                    SCPasteboard.general(config).string = res.debugInfo
                    UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_JssdkCopySuccess, on: targetVC.view)
                })
                dialog.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)
                if let window = targetVC.view.window { self?.context.userResolver.navigator.present(dialog, from: window) }
            }, onError: { error in
                UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_NetworkOrServiceError, on: targetVC.view, error: error)
            }).disposed(by: self.disposeBag)
    }
}
