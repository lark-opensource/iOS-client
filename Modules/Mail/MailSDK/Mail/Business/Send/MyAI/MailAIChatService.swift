//
//  MailAIService.swift
//  MailSDK
//
//  Created by tanghaojin on 2023/6/1.
//


import UIKit
import RustPB
import LarkAIInfra
import RxSwift
import ThreadSafeDataStructure
import ServerPB

class MailAIChatService: NSObject {
    private var chatId: String = ""
    private var chatModeId: String = ""
    let accountContext: MailAccountContext
    let disposeBag = DisposeBag()
    typealias IDBlock = (String, String) -> ()
    var threadContentMap = SafeDictionary<String, String>(synchronization: .readWriteLock)
    
    init(accountContext: MailAccountContext ) {
        self.accountContext = accountContext
        super.init()
        self.chatId = accountContext.accountKVStore.value(forKey: UserDefaultKeys.mailAIChatId) ?? ""
        self.chatModeId = accountContext.accountKVStore.value(forKey:UserDefaultKeys.mailAIChatModeId) ?? ""
    }
    
    public func getChatIDs(_ block: @escaping IDBlock) {
        if chatId.isEmpty || chatModeId.isEmpty {
            // 未初始化
            getChatIDsFromServer(block: block)
            return
        }
        // 检查chatModeId是否合法
        MailDataServiceFactory.commonDataService?.checkChatStatus(id: chatModeId)
            .subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                // 合法的直接返回
                if resp {
                    block(self.chatId, self.chatModeId)
                } else {
                    MailLogger.info("[MailAIChat] id not valid req again")
                    self.getChatIDsFromServer(block: block)
                }
        }, onError: { (error) in
            MailLogger.error("[MailAIChat] checkChatStatus error: \(error)")
            self.getChatIDsFromServer(block: block)
        }).disposed(by: self.disposeBag)
    }
    
    private func getChatIDsFromServer(block: @escaping IDBlock) {
        var link = ""
        if self.accountContext.featureManager.open(.aiHistoryLink, openInMailClient: false) {
            link = self.accountContext.sharedServices.provider.settingConfig?.aiHistoryLinkConfig?.chatInitUrl ?? ""
        }
        MailDataServiceFactory.commonDataService?.getChatIDsFormServer(link: link)
            .subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                self.chatId = resp.0
                self.chatModeId = resp.1
                // 保存到kvStore
                self.accountContext.accountKVStore.set(self.chatId, forKey: UserDefaultKeys.mailAIChatId)
                self.accountContext.accountKVStore.set(self.chatModeId, forKey: UserDefaultKeys.mailAIChatModeId)
                block(resp.0, resp.1)
        }, onError: { (error) in
            MailLogger.error("[MailAIChat] getChatIDs error: \(error)")
            block("", "")
        }).disposed(by: self.disposeBag)
    }
    func getLocalContent(threadId: String, label: String) -> String? {
        return threadContentMap[threadId + label]
    }
    func chatModeCopyReport(label: String) {
        AIReport(event: .email_myai_chat_click,
                 params: ["select_message_cnt": "1",
                          "label_item": label,
                          "click": "copy",
                          "is_shortcut": "false",
                                                        "mail_account_type":Store.settingData.getMailAccountType()])
    }
    func chatModeClickReport() {
        AIReport(event: .email_navibar_click,
                 params: ["click": "myai_chat",
                          "mail_account_type":Store.settingData.getMailAccountType()])
    }
    func chatModeViewReport(label: String) {
        AIReport(event: .email_myai_chat_view,
                 params: ["select_message_cnt": "1",
                                                        "label_item": label,
                                                        "mail_account_type":Store.settingData.getMailAccountType()])
    }
    // ai数据上报
    func AIReport(event: NewCoreEvent.EventName, params: [String: Any]) {
        let event = NewCoreEvent(event: event)
        event.params = params
        event.post()
    }
}

/// 相关请求
extension DataService {
    func getChatIDsFormServer(link: String) -> Observable<(String, String)> {
        var req = ServerPB_Office_ai_AIChatModeInitRequest()
        req.appScene = "Email"
        if !link.isEmpty {
            req.link = link
        }
        
        return sendPassThroughAsyncRequest(req, serCommand: .larkOfficeAiChatModeInit)
            .observeOn(MainScheduler.instance).map { (resp: ServerPB_Office_ai_AIChatModeInitResponse) -> (String, String) in
                return (resp.chatID, resp.aiChatModeID)
            }
    }
    
    func checkChatStatus(id: String) -> Observable<Bool> {
        var req = ServerPB_Office_ai_PullAIChatModeThreadRequest()
        req.aiChatModeID = id
        return sendPassThroughAsyncRequest(req, serCommand: .larkOfficeAiPullChatModeThread)
            .observeOn(MainScheduler.instance).map { (resp: ServerPB_Office_ai_PullAIChatModeThreadResponse) -> Bool in
                return resp.status == .open
            }
    }
}
