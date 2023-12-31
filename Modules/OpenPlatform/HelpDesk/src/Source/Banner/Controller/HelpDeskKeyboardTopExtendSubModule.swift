//
//  HelpDeskKeyboardTopExtendSubModule.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/27.
//

import Foundation
import LarkOpenChat
import Swinject
import ECOProbe
import LKCommonsLogging
import LarkFeatureGating

/// 技术方案： https://bytedance.feishu.cn/docs/doccnfwJLRzCBVHrC1D7CrDlUBc#
public final class HelpDeskKeyboardTopExtendSubModule: ChatKeyboardTopExtendSubModule {
    private var bannerController: BannerController?
    
    public override var type: ChatKeyboardTopExtendType {
        return .helpdesk
    }
    
    deinit {
        openBannerLogger.info("HelpDeskKeyboardTopExtendSubModule.deinit")
    }

    public override func contentView() -> UIView? {
        guard let contentView = self.bannerController?.bannerView else {
            openBannerLogger.info("contentView is nil")
            return nil
        }
        openBannerLogger.info("return contentView.\(contentView.showBannerView)")
        return contentView.showBannerView ? contentView : nil
    }

      /// FG开时才初始化
    public override class func canInitialize(context: ChatKeyboardTopExtendContext) -> Bool {
        return true
    }

    ///如果需要根据model变更做视图状态变化，可以在这里处理
    public override func modelDidChange(model: ChatKeyboardTopExtendMetaModel) {

    }

    /// 能力提供者是自身
    public override func handler(model: ChatKeyboardTopExtendMetaModel) -> [Module<ChatKeyboardTopExtendContext, ChatKeyboardTopExtendMetaModel>] {
        return [self]
    }

    public override func canHandle(model: ChatKeyboardTopExtendMetaModel) -> Bool {
        // 只有 Oncall 场景生效
        return model.chat.isOncall
    }

    public override func createContentView(model: ChatKeyboardTopExtendMetaModel) {
        openBannerLogger.info("createContentView chatId:\(model.chat.id) oncallId:\(model.chat.oncallId)")
        //构造视图
        let bannerController = BannerController(model: model, resolver: self.context.resolver)
        bannerController.delegate = self
        self.bannerController = bannerController
    }
}

extension HelpDeskKeyboardTopExtendSubModule: BannerControllerProtocol {
    
    func refreshView() {
        self.context.refresh(type: .helpdesk)
    }
}
