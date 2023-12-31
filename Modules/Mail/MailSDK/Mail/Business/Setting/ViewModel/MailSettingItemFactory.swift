//
//  MailSettingFactory.swift
//  MailSDK
//
//  Created by majx on 2020/9/7.
//

import Foundation
import RxSwift
import RustPB
import UIKit
import LarkSwipeCellKit
import ServerPB

typealias MailSettingSwitchHandler = (_ status: Bool) -> Void
typealias MailSettingSwitchHandler2 = (_ status: Bool) -> Bool // 可返回Switch重置的值，用于无法操作的开关做UI回滚
typealias MailSettingInputHandler = (_ content: String) -> Void
typealias MailUnbindHandler = () -> Void

struct MailSettingSectionModel {
    var items: [MailSettingItemProtocol] = []
    var headerText: String = ""
    var footerText: String = ""

    init(items: [MailSettingItemProtocol]) {
        self.items = items
    }
}

protocol MailSettingItemProtocol {
    var cellIdentifier: String { get }
    var accountId: String { get }
}

struct MailSettingSwitchModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
    var switchHandler: MailSettingSwitchHandler
}

struct MailSettingPushModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var hasMore: Bool
    var status: Bool
    var switchHandler: MailSettingSwitchHandler
}

struct MailSettingAttachmentModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var location: MailAttachmentLocation
}

struct MailSettingSwipeActionsModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
}

struct MailSettingSwipeOrientationModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var actions: [MailThreadCellSwipeAction]
    var orientation: SwipeActionsOrientation
    var status: Bool
    var switchHandler: MailSettingSwitchHandler
}

struct MailSettingSwipeActionModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var action: MailThreadCellSwipeAction
    var status: Bool
    var switchHandler: MailSettingSwitchHandler
}

struct MailSettingPushScopeModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var scope: MailNotificationScope = .default
    var status: Bool
    var clickHandler: (() -> Void)
}

struct MailSettingPushTypeModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
    var channel: Int32
    var switchHandler: MailSettingSwitchHandler
    var type: MailChannelPosition = .push
}

struct MailSettingConversationModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
    var detail: String
    var switchHandler: MailSettingSwitchHandler
}

struct MailSettingInputModel: MailSettingItemProtocol {
    enum TitleType {
        case normal(title: String)
        case infoButton(title: String, clickBlock: () -> Void)
    }
    var cellIdentifier: String
    var accountId: String
    var title: TitleType
    let placeholder: String
    var content: String
    var errorTip: String?
    var validateInputBlock: ((String) -> String?)?
    var textfieldHandler: MailSettingInputHandler
}

struct MailSettingSmartInboxModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
    var switchHandler: MailSettingSwitchHandler
}

struct MailSettingStrangerModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
    var switchConfirm: Bool
    var switchHandler: MailSettingSwitchHandler2
}

struct MailSettingSignatureModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
}

struct MailAliasSettingModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
}

struct MailAliasAvailableAddressModel: MailSettingItemProtocol {
    var accountId: String
    var cellIdentifier: String
    var address: String
}

struct MailSettingEditableModel: MailSettingItemProtocol {
    var accountId: String
    var cellIdentifier: String
    var alias: String
    var placeHolder: String
}

struct MailSettingOOOModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
}

class MailSettingAttachmentsModel: MailSettingItemProtocol {
    init(cellIdentifier:String, accountId:String, title: String, byte: Int64) {
        self.cellIdentifier = cellIdentifier
        self.accountId = accountId
        self.title = title
        self.byte = byte
    }
    enum capacity {
        case refresh
    }
    @DataManagerValue<capacity> var capacityChange
    var cellIdentifier: String
    var accountId: String
    var title: String
    var byte: Int64
}

class MailSettingCacheModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var detail: String
    @DataManagerValue<()> var cacheStatusChange

    init(cellIdentifier:String, accountId:String, title: String, detail: String) {
        self.cellIdentifier = cellIdentifier
        self.accountId = accountId
        self.title = title
        self.detail = detail
    }
}

struct MailSettingSyncRangeModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var detail: String
}

struct MailDraftLangModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var currentLanguage: MailReplyLanguage
}

struct MailSettingAutoCCModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
}

struct MailSettingUnlinkModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var unbindHandler: MailUnbindHandler?
}

struct MailSettingRelinkModel: MailSettingItemProtocol {
    enum LinkType {
        case gmail
        case exchange
        case mailClient
    }
    var cellIdentifier: String
    var accountId: String
    var type: LinkType
    var provider: MailTripartiteProvider
}

struct MailSettingUndoModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
    var status: Bool
}

struct MailSettingAddOperationModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
}

struct MailSettingServerConfigModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
}

struct MailSettingSenderAliasModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
}

enum MailAccountStatusType {
    case noAccountAttach
    case refreshAccount
    case accountAvailable
    case exchangeNewUser
    case exchangeAvailable
    case reVerify
}

struct MailSettingWebImageModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var shouldIntercept: Bool
    
    var statusTitle: String {
        shouldIntercept
        ? BundleI18n.MailSDK.Mail_Settings_ExterImagesAskBeforeShowing_Option
        : BundleI18n.MailSDK.Mail_Settings_ExterImagesAlwaysShow_Option
    }
}

/// Email Account Info Model
struct MailSettingAccountInfoModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String

    var name: String
    var address: String
    var isShared: Bool
    var type: MailAccountStatusType = .accountAvailable
}

/// Email Account Model
struct MailSettingAccountModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String

    var type: MailAccountStatusType = .accountAvailable
    var title: String
    var subTitle: String
    var avatarKey: String?
    var icon: UIImage?
    var unbindHandler: MailUnbindHandler?

    var larkUserId: String?
    var isShared: Bool
    var isMailClient: Bool
    var showDetail: Bool
    var showTag: Bool

    init(cellIdentifier: String,
         accountId: String,
         title: String,
         subTitle: String,
         isShared: Bool = false,
         isMailClient: Bool = false,
         showDetail: Bool = false,
         showTag: Bool = false,
         avatarKey: String? = nil,
         larkUserId: String? = nil) {
        self.cellIdentifier = cellIdentifier
        self.accountId = accountId
        self.title = title
        self.subTitle = subTitle
        self.isShared = isShared
        self.isMailClient = isMailClient
        self.avatarKey = avatarKey
        self.larkUserId = larkUserId
        self.showDetail = showDetail
        self.showTag = showTag
//        self.mailAccountId = account?.mailAccountID ?? ""
//        self.larkUserId = account?.larkUserID
//        self.newMailNotification = account?.config.newMailNotification ?? false
    }
}

struct MailSettingAliasAccountCellModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var address: MailAddress
    var isDefault: Bool
    var isMailGroup: Bool
}

struct MailSettingAddAliasModel: MailSettingItemProtocol {
    var cellIdentifier: String
    var accountId: String
    var title: String
}

struct MailSettingItemFactory {
    // 通知设置页内部的CellModel
    static func createAccountMailPushModel(status: Bool,
                                           accountId: String,
                                           address: String,
                                           switchHandler: @escaping MailSettingSwitchHandler) -> MailSettingPushModel {
        return MailSettingPushModel(cellIdentifier: MailSettingPushCell.lu.reuseIdentifier,
                                    accountId: accountId,
                                    title: address,
                                    hasMore: false,
                                    status: status,
                                    switchHandler: switchHandler)
    }

    static func createConversationModeModel(status: Bool,
                                            accountId: String,
                                            hasMore: Bool,
                                            detail: String,
                                            switchHandler: @escaping MailSettingSwitchHandler) -> MailSettingConversationModel {
        return MailSettingConversationModel(cellIdentifier: hasMore ? MailSettingConversationCell.lu.reuseIdentifier : MailSettingSwitchCell.lu.reuseIdentifier,
                                            accountId: accountId,
                                            title: hasMore ? BundleI18n.MailSDK.Mail_Settings_EmailOrganize : BundleI18n.MailSDK.Mail_Settings_ChatsModeMobile,
                                            status: status,
                                            detail: detail,
                                            switchHandler: switchHandler)
    }

    static func createMailPushModel(status: Bool,
                                    accountId: String,
                                    hasMore: Bool,
                                    switchHandler: @escaping MailSettingSwitchHandler) -> MailSettingPushModel {
        return MailSettingPushModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                    accountId: accountId,
                                    title: BundleI18n.MailSDK.Mail_Setting_NewEmailNotification,
                                    hasMore: hasMore, // 控制是否显示switchButton
                                    status: status,
                                    switchHandler: switchHandler)
    }
    
    static func createMailSwipeActionsModel(accountId: String) -> MailSettingSwipeActionsModel {
        return MailSettingSwipeActionsModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                            accountId: accountId, title: BundleI18n.MailSDK.Mail_Settings_EmailSwipeActions_Text)
    }

    static func createSmartInboxModel(status: Bool, accountId: String, switchHandler: @escaping MailSettingSwitchHandler) -> MailSettingSmartInboxModel {
        return MailSettingSmartInboxModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                          accountId: accountId,
                                          title: BundleI18n.MailSDK.Mail_Setting_SmartSortEmails,
                                          status: status,
                                          switchHandler: switchHandler)
    }
    
    static func createStrangerModel(status: Bool, accountId: String, switchHandler: @escaping MailSettingSwitchHandler2) -> MailSettingStrangerModel {
        return MailSettingStrangerModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                        accountId: accountId,
                                        title: BundleI18n.MailSDK.Mail_StrangerInbox_Setting_Toggle,
                                        status: status,
                                        switchConfirm: true,
                                        switchHandler: switchHandler)
    }
    
    static func createUndoModel(status: Bool, accountId: String) -> MailSettingUndoModel {
        return MailSettingUndoModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                    accountId: accountId,
                                    title: BundleI18n.MailSDK.Mail_Setting_UndoSend,
                                    status: status)
    }

    static func createAutoCCModel(status: Bool, accountId: String) -> MailSettingAutoCCModel {
        return MailSettingAutoCCModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                      accountId: accountId,
                                      title: BundleI18n.MailSDK.Mail_Settings_AutoCcOrBcc_Name,
                                      status: status)
    }

    static func createSignatureModel(status: Bool, accountId: String) -> MailSettingSignatureModel {
        var title = FeatureManager.realTimeOpen(.enterpriseSignature, openInMailClient: true)
        ? BundleI18n.MailSDK.Mail_BusinessSignature_EmailSignature
        : BundleI18n.MailSDK.Mail_Setting_Signaturecontrol
        if Store.settingData.isMailClient(accountId) {
            title = BundleI18n.MailSDK.Mail_ThirdClient_MobileSignature
        }
        return MailSettingSignatureModel(cellIdentifier: MailSettingSignatureCell.lu.reuseIdentifier,
                                         accountId: accountId,
                                         title: title,
                                         status: status)
    }

    static func createAliasSettingModel(accountId: String) -> MailAliasSettingModel {
        return MailAliasSettingModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                        accountId: accountId,
                                     title: BundleI18n.MailSDK.Mail_ManageSenders_Popover_Title)
    }

    static func createMailAliasAvailableAddressModel(address: String) -> MailAliasAvailableAddressModel {
        return MailAliasAvailableAddressModel(accountId: "",
                                              cellIdentifier: MailSettingAliasAvailableAddressCell.lu.reuseIdentifier,
                                              address: address)
    }

    static func createAliasAccountCellModel(accountId: String,
                                            mailAddress: MailAddress,
                                            isDefault: Bool) -> MailSettingAliasAccountCellModel {
        let isMailGroup = mailAddress.type == .enterpriseMailGroup
        return MailSettingAliasAccountCellModel(cellIdentifier: MailSettingAliasAccountCell.lu.reuseIdentifier,
                                                accountId: accountId,
                                                address: mailAddress,
                                                isDefault: isDefault,
                                                isMailGroup: isMailGroup)
    }

    static func createMailSettingEditableModel(alias: String, placeHolder: String) -> MailSettingEditableModel {
        return MailSettingEditableModel(accountId: "",
                                        cellIdentifier: MailSettingEditableCell.lu.reuseIdentifier,
                                        alias: alias,
                                        placeHolder: placeHolder)
    }

    static func createAttachmentsModel(accountId: String, byte: Int64) -> MailSettingAttachmentsModel {
        let model = MailSettingAttachmentsModel(cellIdentifier:
                                                MailSettingAttachmentsCell.lu.reuseIdentifier,
                                                accountId: accountId,
                                                title: BundleI18n.MailSDK.Mail_Shared_Settings_LargeAttachmentStorage_Title,
                                                byte: byte)
        return model
    }
    
    static func createOOOModel(status: Bool, accountId: String) -> MailSettingOOOModel {
        return MailSettingOOOModel(cellIdentifier: MailSettingOOOCell.lu.reuseIdentifier,
                                   accountId: accountId,
                                   title: BundleI18n.MailSDK.Mail_Setting_EmailAutoReply,
                                   status: status)
    }

    static func createCacheModel(accountId: String, detail: String) -> MailSettingCacheModel {
        return MailSettingCacheModel(cellIdentifier: MailSettingCacheCell.lu.reuseIdentifier,
                                     accountId: accountId,
                                     title: BundleI18n.MailSDK.Mail_EmailCache_Setting_Title,
                                     detail: detail)
    }

    static func createSyncRangeModel(accountId: String, detail: String) -> MailSettingSyncRangeModel {
        return MailSettingSyncRangeModel(cellIdentifier: MailSettingSyncRangeCell.lu.reuseIdentifier,
                                     accountId: accountId,
                                     title: BundleI18n.MailSDK.Mail_Shared_AddEAS_EmailSync_Title,
                                     detail: detail)
    }

    static func createAccountInfoModel(name: String,
                                       address: String,
                                       accountId: String,
                                       isShared: Bool,
                                       type: MailSetting.UserType,
                                       status: MailClientConfig.ConfigStatus?) -> MailSettingAccountInfoModel {
        var item = MailSettingAccountInfoModel(cellIdentifier: MailSettingAccountInfoCell.lu.reuseIdentifier,
                                               accountId: accountId,
                                               name: name,
                                               address: address,
                                               isShared: isShared)
        item.type = .accountAvailable
        if type == .exchangeClient {
            item.type = .exchangeAvailable
        } else if type == .exchangeClientNewUser {
            item.type = .exchangeNewUser
        }
        if type == .newUser || type == .oauthClient {
            if let status = status {
                if status != .valid {
                    item.type = .refreshAccount
                }
            } else {
                item.type = .noAccountAttach
            }
        }
        if type == .tripartiteClient {
            if status == nil {
                item.type = .accountAvailable // 先把你给整活了！
            } else if status == .expired {
                item.type = .reVerify
            }
        }
        return item
    }

    static func createAccountModel(name: String,
                                   address: String,
                                   accountId: String,
                                   isShared: Bool,
                                   showDetail: Bool = false,
                                   showTag: Bool = false,
                                   userType: MailSetting.UserType,
                                   status: MailClientConfig.ConfigStatus?) -> MailSettingAccountModel {
//        let subTitle = BundleI18n.MailSDK.Mail_Setting_LinkedEmailAccountDescriptionMobile
        var item = MailSettingAccountModel(cellIdentifier: MailSettingAccountCell.lu.reuseIdentifier,
                                           accountId: accountId,
                                           title: name,
                                           subTitle: address,
                                           isShared: isShared,
                                           isMailClient: userType == .tripartiteClient,
                                           showDetail: showDetail,
                                           showTag: showTag,
                                           avatarKey: nil)
        item.type = MailSettingItemFactory.getAccountStatusType(userType: userType, status: status)
        return item
    }

    static func getAccountStatusType(userType: MailSetting.UserType, status: MailClientConfig.ConfigStatus?) -> MailAccountStatusType {
        var type: MailAccountStatusType = .accountAvailable
        if userType == .exchangeClient {
            type = .exchangeAvailable
        } else if userType == .exchangeClientNewUser {
            type = .exchangeNewUser
        }
        
        if userType == .newUser || userType == .oauthClient {
            if FeatureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false), userType == .newUser {
                type = .noAccountAttach
            } else if let status = status {
                if status != .valid {
                    type = .refreshAccount
                }
            } else {
                type = .noAccountAttach
            }
        }

        if userType == .tripartiteClient {
            if status == nil {
                type = .accountAvailable // 先把你给整活了！
            } else if status == .expired {
                type = .reVerify
            }
        }
        return type
    }

    static func createUnlinkModel(accountId: String, subTitle: String, unbindHandler: @escaping MailUnbindHandler) -> MailSettingUnlinkModel {
        let item = MailSettingUnlinkModel(cellIdentifier: MailSettingUnlinkCell.lu.reuseIdentifier,
                                          accountId: accountId,
                                          title: subTitle,
                                          unbindHandler: unbindHandler)
        return item
    }

    static func createRelinkModel(accountId: String, type: MailSettingRelinkModel.LinkType, provider: MailTripartiteProvider) -> MailSettingRelinkModel {
        let item = MailSettingRelinkModel(cellIdentifier: MailSettingRelinkCell.lu.reuseIdentifier,
                                          accountId: accountId,
                                          type: type,
                                          provider: provider)
        return item
    }

    static func createClientInputModel(
        accountId: String,
        title: MailSettingInputModel.TitleType,
        placeholder: String,
        content: String,
        validateBlock: ((String) -> String?)? = nil,
        textfieldHandler: @escaping MailSettingInputHandler
    ) -> MailSettingInputModel {
        let item = MailSettingInputModel(cellIdentifier: MailClientAdSettingInputCell.lu.reuseIdentifier,
                                         accountId: accountId, title: title, placeholder: placeholder,
                                         content: content, validateInputBlock: validateBlock, textfieldHandler: textfieldHandler)
        return item
    }

    static func createClientProtocolModel(accountId: String, title: String, proto: MailClientProtocol,
                                          protocolHandler: MailSettingProtocolHandler? = nil) -> MailClientSettingProtocolModel {
        let item = MailClientSettingProtocolModel(accountId: accountId,
                                                  cellIdentifier: MailClientAdSettingSelectionCell.lu.reuseIdentifier,
                                                  title: title, proto: proto, protocolHandler: protocolHandler)
        return item
    }

    static func createClientEncryptionModel(
        accountId: String,
        title: String,
        canSelect: Bool,
        encryption: MailClientEncryption,
        encryptionHandler: @escaping MailSettingEncryptionHandler) -> MailClientSettingEncryptionModel
    {
        let item = MailClientSettingEncryptionModel(accountId: accountId,
                                                    cellIdentifier: MailClientAdSettingSelectionCell.lu.reuseIdentifier,
                                                    title: title, encryption: encryption, encryptionHandler: encryptionHandler, canSelect: canSelect)
        return item
    }
    
    static func createWebImageModel(accountId: String, shouldIntercept: Bool) -> MailSettingWebImageModel {
        return MailSettingWebImageModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                        accountId: accountId,
                                        shouldIntercept: shouldIntercept)
    }

    static func createAttachmentModel(accountId: String, location: MailAttachmentLocation) -> MailSettingAttachmentModel {
        return MailSettingAttachmentModel(cellIdentifier: MailSettingStatusCell.lu.reuseIdentifier,
                                          accountId: accountId,
                                          title: BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_Title,
                                          location: location)
    }
}
