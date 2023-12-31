//
//  IMMentionPanel.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/20.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignActionPanel
import LarkAccountInterface
import LarkContainer

/// IM mention面板
public final class IMMentionPanel: UDActionPanel, IMMentionType {
    private let disposeBag = DisposeBag()
    private var context: IMMentionContext
    // 群相关信息
    public var chat: IMMentionChatConfigType
    // 事件回调
    public weak var delegate: IMMentionPanelDelegate?
    // mention控制器
    private var mentionVC: IMMentionViewController

    private var allProvider: AllProvider
    let userResolver: LarkContainer.UserResolver
    // 展示
    public func show(from vc: UIViewController) {
        IMMentionLogger.shared.info(module: .panel, event: "show")
        mentionVC.delegate = delegate
        mentionVC.show(from: self)
        vc.present(self, animated: true)
    }

    public init(resolver: LarkContainer.UserResolver, mentionChatModel: IMMentionChatConfigType, delegate: IMMentionPanelDelegate? = nil) {
        self.userResolver = resolver
        self.chat = mentionChatModel
        IMMentionLogger.shared.info(module: .panel, event: "init", parameters: "chatId=\(chat.id)&count=\(chat.userCount)&enableAll=\(chat.isEnableAtAll)")
        self.context = IMMentionContext(currentChatterId: AccountServiceAdapter.shared.currentTenant.tenantId,
                                        currentTenantId: AccountServiceAdapter.shared.currentTenant.tenantId,
                                        currentChatId: mentionChatModel.id,
                                        chatUserCount: mentionChatModel.userCount,
                                        isEnableAtAll: mentionChatModel.isEnableAtAll,
                                        showChatUserCount: mentionChatModel.showChatUserCount)
        // 云文档采用大搜解决
        var docParameters = IMMentionSearchParameters()
        // 不需要群组
        docParameters.chat = nil
        // 不需要人员
        docParameters.chatter = nil
        self.allProvider = AllProvider(resolver: resolver, context: context, parameters: docParameters)
        self.delegate = delegate
        self.mentionVC = IMMentionViewController(context: context, provider: self.allProvider)
        let navigationVC = IMMentionNavigationController(rootViewController: mentionVC)
        var config = UDActionPanelUIConfig()
        config.originY = UIScreen.main.bounds.height * 0.2
        // 下拉组件自己实现
        config.canBeDragged = false
        config.dismissByDrag = {
            delegate?.panelDidCancel()
        }
        super.init(customViewController: navigationVC, config: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class IMMentionData {
    public class func preLoading(chatId: String) {
//        @Injected var chatterAPI: ChatterAPI
//        _ = chatterAPI.fetchAtListWithLocalOrRemote(chatId: chatId, query: nil)
//            .subscribe()
    }
}
