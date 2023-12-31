//
//  BlockSenderManager.swift
//  MailSDK
//
//  Created by raozhongtao on 2023/3/29.
//

import Foundation
import UIKit
import UniverseDesignActionPanel
import RustPB
import ServerPB
import RxSwift
import LarkAlertController

typealias AddUserAllowBlockReq = Email_Client_V1_MailAddUserAllowBlockRequest
typealias DeleteThreadsFromBlockReq = Email_Client_V1_MailDeleteThreadsFromBlockRequest

protocol BlockSenderDelegate: AnyObject {
    func addBlockSuccess(isAllow: Bool, num: Int)
}
struct BlockItem {
    var threadId: String
    var messageId: String?
    var addressList: [Email_Client_V1_Address]
}
enum SenderScene {
    case searchThread
    case homeThread
    case messageThread
    case message
}
class BlockSenderManager {
    var accountContext: MailAccountContext
    var labelID: String
    var feedCardId: String?
    var scene: SenderScene
    var originBlockItems: [BlockItem] // threadId: [address]
    private(set) var disposeBag = DisposeBag()
    weak var delegate: BlockSenderDelegate?
    
    init(accountContext: MailAccountContext,
         labelID: String,
         scene: SenderScene,
         originBlockItems: [BlockItem],
         feedCardId: String? = nil) {
        self.accountContext = accountContext
        self.labelID = labelID
        self.scene = scene
        self.originBlockItems = originBlockItems
        self.feedCardId = feedCardId
    }
    
    private func isMe(address: Email_Client_V1_Address) -> Bool {
        if (Store.settingData.getCachedCurrentAccount()?.mailSetting.emailAlias.allAddresses ?? []).filter({ $0.larkEntityType != .enterpriseMailGroup}).map({ $0.address.lowercased() }).contains(address.address.lowercased()) {
            return true
        }
        return false
    }
    struct BlockCheckRes {
        var threadIds: [String]
        var messageId: String?
        var canBlock: Bool
        var multiSender: Bool // 是否包含多个发件人
        var addressList: [Email_Client_V1_Address]
        var feedCardId: String?
    }
    
    private func blockCheck() -> BlockCheckRes {
        /// 1 屏蔽单封邮件 && 是本人邮件 > 提示无法操作
        /// 2 屏蔽一整封会话，若会话只包含本人邮件 > 提示无法操作；
        ///  若包含了非本人邮件 > 优先屏蔽时间最近的非本人邮件的发件人（无弹窗提示）
        /// 3 屏蔽多封会话/邮件，若其中某个会话仅包含本人邮件 > 提示无法操作
        var resAddressList: [Email_Client_V1_Address] = []
        var resThreads: [String] = []
        var resMessage: String? = nil
        var resMultiSender: Bool = self.originBlockItems.count > 1 ? true : false
        for item in self.originBlockItems {
            if !resMultiSender && item.addressList.count > 1 {
                resMultiSender = true
            }
            let filteredList = item.addressList.filter { address in
                !self.isMe(address: address)
            }
            if let address = filteredList.last {
                resAddressList.append(address)
                resThreads.append(item.threadId)
                resMessage = item.messageId
            } else {
                // 如果有message全部是自己，则直接返回
                return BlockCheckRes(threadIds: [item.threadId],
                                     messageId: item.messageId,
                                     canBlock: false,
                                     multiSender: resMultiSender,
                                     addressList: item.addressList,
                                     feedCardId: self.feedCardId)
            }
        }
        var filteredList: [Email_Client_V1_Address] = []
        var resAddressStrs: [String] = []
        resAddressList.forEach { address in
            if !resAddressStrs.contains(address.address) {
                filteredList.append(address)
                resAddressStrs.append(address.address)
            }
        }
        return BlockCheckRes(threadIds: resThreads,
                             messageId: resMessage,
                             canBlock: true,
                             multiSender: resMultiSender,
                             addressList: filteredList,
                             feedCardId: self.feedCardId)
    }
    
    private func showBlockAlert(blockRes: BlockCheckRes,
                                isAllow: Bool,
                                fromVC: UIViewController) {
        let alert = LarkAlertController()
        if !blockRes.canBlock {
            // 不能屏蔽
            alert.setTitle(text: BundleI18n.MailSDK.Mail_BlockTrustSender_OperationFailed_Title)
            var content = ""
            if !blockRes.multiSender {
                content = BundleI18n.MailSDK.Mail_BlockSender_OperationFailed_SingleSender_Desc(blockRes.addressList.first?.address ?? "")
            } else {
                content = BundleI18n.MailSDK.Mail_BlockSender_OperationFailed_MultiSender_Desc(blockRes.addressList.first?.address ?? "")
            }
            if isAllow {
                if !blockRes.multiSender {
                    content = BundleI18n.MailSDK.Mail_TrustSender_OperationFailed_SingleSender_Desc(blockRes.addressList.first?.address ?? "")
                } else {
                    content = BundleI18n.MailSDK.Mail_TrustSender_OperationFailed_MultiSender_Desc(blockRes.addressList.first?.address ?? "")
                }
            }
            alert.setContent(text: content, alignment: .center)
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_TrustBlockSender_OperationFailed_OK_Button)
            
        } else {
            // 屏蔽，弹对应信息
            var title = ""
            var content = ""
            if blockRes.addressList.count == 1 {
                var resName = String(blockRes.addressList.first?.address.split(separator: "@").first ?? "")
                if let display = blockRes.addressList.first?.displayName,
                    !display.isEmpty {
                    resName = display
                } else if let name = blockRes.addressList.first?.name,
                          !name.isEmpty {
                    resName = name
                }
                // 屏蔽文案
                if !isAllow {
                    if self.labelID == Mail_LabelId_Trash {
                        if blockRes.threadIds.count > 1 {
                            content = BundleI18n.MailSDK.Mail_BlockSenderInTrash_MultiMailsSingleSender_Desc(blockRes.addressList.first?.address ?? "")
                        } else {
                            content = BundleI18n.MailSDK.Mail_BlockSenderInTrash_SingleMailSingleSender_Desc(blockRes.addressList.first?.address ?? "")
                        }
                    } else {
                        content = BundleI18n.MailSDK.Mail_BlockSender_SingleMailSingleSender_Desc(blockRes.addressList.first?.address ?? "")
                    }
                    title = BundleI18n.MailSDK.Mail_BlockSender_SingleMailSingleSender_Title(resName)
                } else {
                    // 信任文案
                    content = BundleI18n.MailSDK.Mail_TrustSender_SingleSender_Desc(address: blockRes.addressList.first?.address ?? "")
                    title = BundleI18n.MailSDK.Mail_TrustSender_SingleSender_Title(resName)
                }
                
            } else if blockRes.addressList.count > 1 {
                let address1 = blockRes.addressList[0].address
                let address2 = blockRes.addressList[1].address
                if blockRes.addressList.count == 2 {
                    if !isAllow {
                        if self.labelID == Mail_LabelId_Trash {
                            content = BundleI18n.MailSDK.Mail_BlockSenderInTrash_MultiMails2Sender_Desc(address1: address1, address2: address2)
                        } else {
                            content = BundleI18n.MailSDK.Mail_BlockSender_MultiMails2Senders_Desc(address1: address1, address2: address2)
                        }
                    } else {
                        content = BundleI18n.MailSDK.Mail_TrustSender_2Senders_Desc(address1: address1, address2: address2)
                        
                    }
                    
                } else if blockRes.addressList.count > 2 {
                    if !isAllow {
                        if self.labelID == Mail_LabelId_Trash {
                            content = BundleI18n.MailSDK.Mail_BlockSenderInTrash_MultiMailsMultiSender_Desc(num: blockRes.addressList.count, address1: address1, address2: address2)
                        } else {
                            content = BundleI18n.MailSDK.Mail_BlockSender_MultiMailsMultiSenders_Desc(num: blockRes.addressList.count, address1: address1, address2: address2)
                        }
                        
                    } else {
                        content = BundleI18n.MailSDK.Mail_TrustSender_MultiSenders_Desc(num: blockRes.addressList.count, address1: address1, address2: address2)
                    }
                    
                }
                if !isAllow {
                    title = BundleI18n.MailSDK.Mail_BlockSender_MultiMailsMultiSenders_Title(blockRes.addressList.count)
                } else {
                    title = BundleI18n.MailSDK.Mail_TrustSender_MultiSenders_Title(blockRes.addressList.count)
                }
                
            }
            alert.setTitle(text: title)
            alert.setContent(text: content, alignment: .center)
            let actionText = !isAllow ? BundleI18n.MailSDK.Mail_BlockSender_Block_Button : BundleI18n.MailSDK.Mail_TrustSender_Trust_Button
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_BlockSender_Cancel_Button, dismissCompletion: nil)
            alert.addPrimaryButton(text: actionText, dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                self.accountContext.dataService.addUserAllowBlock(addressList: blockRes.addressList, isAllow: isAllow).subscribe(onNext: { [weak self] in
                    guard let `self` = self else { return }
                    if !isAllow {
                        self.deleteThreads(blockRes: blockRes, fromVC: fromVC)
                    } else {
                        self.delegate?.addBlockSuccess(isAllow: isAllow,
                                                       num: blockRes.addressList.count)
                    }
                }, onError: { (error) in
                    MailLogger.info("[block] addUserAllowBlock fail \(error)")
                    if let errorCode = error.errorCode(), errorCode == 250450 {
                        MailRoundedHUD.showFailure(with:BundleI18n.MailSDK.Mail_AddBlockedEmailAddressesDomains_WrongFormatCantAdd_Toast,
                                                   on: fromVC.view)
                    } else {
                        MailRoundedHUD.showFailure(with:BundleI18n.MailSDK.Mail_Toast_OperationFailed,
                                                   on: fromVC.view)
                    }
                    
                }).disposed(by: self.disposeBag)
            })
            
        }
        self.accountContext.navigator.present(alert, from: fromVC)
    }
    
    func showPopupMenu(fromVC: UIViewController) {
        guard !self.originBlockItems.isEmpty else {
            MailLogger.info("[blocker] origin list is empty")
            return
        }
        let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false))
        ///todo:
        ///处理popupmenu的文案逻辑：
        ///1 含多个发件人 > 显示 屏蔽发件人
        ///2 仅一个发件人 > 显示 屏蔽xxx
        ///从不屏蔽 同理
        let blockRes = blockCheck()
        var blockText = BundleI18n.MailSDK.Mail_BlockSender_MenuItem
        var trustText = BundleI18n.MailSDK.Mail_TrustSender_MenuItem
        if self.scene == .message {
            if let name = blockRes.addressList.first?.mailDisplayNameNoMe {
                blockText = BundleI18n.MailSDK.Mail_BlockName_MenuItem(name)
                trustText = BundleI18n.MailSDK.Mail_TrustName_MenuItem(name)
            }
        }
        pop.addDefaultItem(text: blockText) { [weak self] in
            guard let `self` = self else { return }
            self.showBlockAlert(blockRes: blockRes, isAllow: false, fromVC: fromVC)
        }
        pop.addDefaultItem(text: trustText) { [weak self] in
            guard let `self` = self else { return }
            self.showBlockAlert(blockRes: blockRes, isAllow: true, fromVC: fromVC)
        }
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel) {
            
        }
        self.accountContext.navigator.present(pop, from: fromVC)
    }
    private func deleteThreads(blockRes: BlockCheckRes, fromVC: UIViewController) {
        self.accountContext.dataService
            .deleteThreadsFromBlockRequest(threadIds: blockRes.threadIds,
                                           messageId: blockRes.messageId,
                                           feedCardId: blockRes.feedCardId,
                                           labelId: self.labelID).subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
                self.delegate?.addBlockSuccess(isAllow: false,
                                               num: blockRes.addressList.count)
        }, onError: { (error) in
            MailLogger.info("[block] deleteThreads fail \(error)")
            MailRoundedHUD.showFailure(with:BundleI18n.MailSDK.Mail_Toast_OperationFailed,
                                       on: fromVC.view)
        }).disposed(by: self.disposeBag)
    }
}

extension DataService {
    func addUserAllowBlock(addressList: [Email_Client_V1_Address], isAllow: Bool) -> Observable<Void> {
        var request = AddUserAllowBlockReq()
        request.scene = .blockSender
        request.isAllow = isAllow
        request.multiFrom = addressList
        return sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }
    func deleteThreadsFromBlockRequest(threadIds: [String],
                                       messageId: String?,
                                       feedCardId: String?,
                                       labelId: String) -> Observable<Void> {
        var request = DeleteThreadsFromBlockReq()
        if let feedCardId = feedCardId {
            request.feedCardID = feedCardId
        }
        request.threadIds = threadIds
        if let id = messageId {
            request.messageID = id
        }
        request.fromLabel = labelId
        return sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }
}
