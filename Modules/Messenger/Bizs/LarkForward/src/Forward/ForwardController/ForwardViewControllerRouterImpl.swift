//
//  ForwardViewControllerRouterImpl.swift
//  LarkForward
//
//  Created by 姚启灏 on 2018/11/30.
//

import UIKit
import Foundation
import LarkContainer
import Swinject
import EENavigator
import RxSwift
import LarkModel
import LarkUIKit
import LarkMessengerInterface
import LarkAlertController
import LarkSDKInterface
import LarkAccountInterface
import LarkFeatureGating
import LarkNavigation
import LKCommonsLogging
import RustPB
import AppReciableSDK
import UniverseDesignToast

public protocol ForwardViewControllerRouterProtocol: ForwardViewControllerRouter & NewForwardViewControllerRouter & ForwardComponentViewControllerRouter {
    func creatChat(forwardVC: ForwardComponentVCType,
                   forwardIncludeConfigs: [EntityConfigType]?,
                   forwardEnabledConfigs: [EntityConfigType]?,
                   forwardDisabledClosure: ForwardItemDisabledBlock?)
}

private enum CreateGroupEvent: ReciableEventable {
    case createGroupChat
    var eventKey: String {
        switch self {
        case .createGroupChat:
            return "create_group_chat"
        }
    }
}

// swiftlint:disable line_length file_length
final class ForwardViewControllerRouterImpl: ForwardViewControllerRouterProtocol, SearchPickerDelegate {
    let userResolver: UserResolver
    // 业务给转发配的过滤参数
    var forwardIncludeConfigs: [EntityConfigType]?
    // 业务给转发配的置灰参数
    var forwardEnabledConfigs: [EntityConfigType]?
    // 业务给转发配的置灰闭包，优先级比置灰参数高
    var forwardDisabledClosure: ForwardItemDisabledBlock?
    weak fileprivate var forwardVC: ForwardComponentVCType?
    let disposeBag = DisposeBag()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func creatChat(vc: ForwardViewController) {
        _creatChat(vc: vc)
    }
    func creatChat(vc: NewForwardViewController) {
        _creatChat(vc: vc)
    }
    func creatChat(vc: ForwardComponentViewController) {
        _creatChat(vc: vc)
    }

    func creatChat(forwardVC: ForwardComponentVCType,
                   forwardIncludeConfigs: [EntityConfigType]?,
                   forwardEnabledConfigs: [EntityConfigType]?,
                   forwardDisabledClosure: ForwardItemDisabledBlock?) {
        guard let from = forwardVC.navigationController else {
            assertionFailure()
            return
        }
        self.forwardVC = forwardVC
        self.forwardIncludeConfigs = forwardIncludeConfigs
        self.forwardEnabledConfigs = forwardEnabledConfigs
        self.forwardDisabledClosure = forwardDisabledClosure
        let pickerSearchConfigs = ForwardConfigUtils.transToPickerSearchConfigs(forwardIncludeConfigs: forwardIncludeConfigs)
        self.onPresentCreateGroupAndForwardPage(searchEntities: pickerSearchConfigs, fromVC: from)
    }

    fileprivate func _creatChat(vc: VC) {
        guard let from = vc.navigationController else {
            assertionFailure()
            return
        }

        let body = CreateGroupBody(createGroupBlock: getCreateGroupBlock(vc: vc),
                                   isShowGroup: false,
                                   canCreateSecretChat: false,
                                   from: .forward,
                                   createConfirmButtonTitle: BundleI18n.LarkForward.Lark_IM_CreateGroupAndSend_MobileButton,
                                   title: BundleI18n.LarkForward.Lark_IM_CreateGroupAndSend_Title)
        userResolver.navigator.present(
            body: body,
            from: from,
            prepare: { (viewController) in
                viewController.modalPresentationStyle = .formSheet
            })
    }

    private func transChatToForwardItem(chat: Chat) -> ForwardItem {
        let userService = try? self.userResolver.resolve(assert: PassportUserService.self)
        var item = ForwardItem(avatarKey: chat.avatarKey,
                               name: chat.displayWithAnotherName,
                               subtitle: chat.chatter?.department ?? "",
                               description: chat.chatter?.description_p.text ?? "",
                               descriptionType: chat.chatter?.description_p.type ?? .onDefault,
                               localizeName: chat.localizedName,
                               id: chat.id,
                               chatId: chat.id,
                               type: .chat,
                               isCrossTenant: chat.isCrossTenant,
                               isCrossWithKa: chat.isCrossWithKa,
                               isCrypto: false,
                               isThread: chat.chatMode == .thread || chat.chatMode == .threadV2,
                               doNotDisturbEndTime: chat.chatter?.doNotDisturbEndTime ?? 0,
                               hasInvitePermission: true,
                               userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
                               enableThreadMiniIcon: false,
                               isOfficialOncall: chat.isOfficialOncall,
                               tags: chat.tags,
                               tagData: chat.tagData)
        item.chatUserCount = chat.userCount
        return item
    }

    private func trackMessageForwardCreateGroup(content: ForwardAlertContent?, chat: Chat) {
        let userCount = Int(chat.userCount)
        var source: String?
        if let content = content as? OpenShareContentAlertContent {
            source = content.sourceAppName
        }
        Tracer.trackMessageForweardCreateGroup(
            isExternal: chat.isCrossTenant,
            isPublic: chat.isPublic,
            isThread: false,
            chatterNumbers: userCount,
            source: source
        )
    }

    private func getCreateGroupBlock(forwardVC: ForwardComponentVCType) -> CreateGroupBlock {
        let createGroupBlock: CreateGroupBlock = { [weak forwardVC, weak self] (chat, rootvc, _, _, _)  in
            guard let chat = chat else { return }
            self?.trackMessageForwardCreateGroup(content: forwardVC?.content(), chat: chat)
            rootvc.dismiss(animated: true, completion: { [weak forwardVC, weak self] in
                guard let self else { return }
                let item = self.transChatToForwardItem(chat: chat)
                ForwardLogger.shared.info(module: .createGroup, event: "forwardItem with id:\(chat.id), chatId:\(chat.id), type:chat")
                forwardVC?.selectNew(item: item)
            })
        }
        return createGroupBlock
    }

    private func getCreateGroupBlock(vc: VC) -> CreateGroupBlock {
        let createGroupBlock: CreateGroupBlock = { [weak vc, weak self] (chat, rootvc, _, _, _) in
            guard let chat = chat else {
                return
            }
            self?.trackMessageForwardCreateGroup(content: vc?.content(), chat: chat)
            rootvc.dismiss(animated: true, completion: { [weak vc, weak self] in
                guard let self else { return }
                let item = self.transChatToForwardItem(chat: chat)
                ForwardLogger.shared.info(module: .createGroup, event: "init forwardItem with id:\(chat.id), chatId:\(chat.id), type:chat")
                vc?.selectNew(item: item)
            })
        }
        return createGroupBlock
    }
    fileprivate typealias VC = ForwardViewControllerType & UIViewController
    fileprivate typealias CreateGroupBlock = ((Chat?, UIViewController, Int64, [AddExternalContactModel], Im_V1_CreateChatResponse.ChatPageLinkResult?) -> Void)
// MARK: - CreateGroupWithNewPicker
    // 调起新Picker页面，定制navBar标题、过滤参数、置灰函数，finish行为
    private func onPresentCreateGroupAndForwardPage(searchEntities: [EntityConfigType],
                                                    fromVC: UIViewController) {
        let pickerMultiSelectConfig = PickerFeatureConfig.MultiSelection(isOpen: true,
                                                                         isDefaultMulti: true,
                                                                         canSwitchToMulti: true,
                                                                         canSwitchToSingle: false)
        // navbar配置中设置标题文案和右侧按钮文案
        let pickerNavigationBarConfig = PickerFeatureConfig.NavigationBar(title: BundleI18n.LarkForward.Lark_IM_CreateGroupAndSend_Title,
                                                                          sureText: BundleI18n.LarkForward.Lark_IM_CreateGroupAndSend_MobileButton)
        // searchBar配置中设置placeHolder文案
        let pickerSearchBarConfig = PickerFeatureConfig.SearchBar(placeholder: BundleI18n.LarkForward.Lark_IM_SelectDepartmentForGroupChat)
        // 目标预览配置中打开目标预览功能
        let pickerTargetPreviewConfig = PickerFeatureConfig.TargetPreview(isOpen: true)
        let featureConfig = PickerFeatureConfig(scene: .imCreateAndForward,
                                                multiSelection: pickerMultiSelectConfig,
                                                navigationBar: pickerNavigationBarConfig,
                                                searchBar: pickerSearchBarConfig,
                                                targetPreview: pickerTargetPreviewConfig)
        // 建群场景不支持拉MyAi
        let searchConfig = PickerSearchConfig(entities: searchEntities.filter { $0.type != .myAi },
                                              permission: [.inviteSameChat, .shareMessageSelectUser])
        let contactConfig = PickerContactViewConfig(entries: [PickerContactViewConfig.OwnedGroup(),
                                                              PickerContactViewConfig.External(),
                                                              PickerContactViewConfig.Organization()])
        var contactSearchPickerBody = ContactSearchPickerBody()
        contactSearchPickerBody.featureConfig = featureConfig
        contactSearchPickerBody.searchConfig = searchConfig
        contactSearchPickerBody.contactConfig = contactConfig
        contactSearchPickerBody.delegate = self
        self.userResolver.navigator.present(body: contactSearchPickerBody, from: fromVC, prepare: { $0.modalPresentationStyle = .formSheet })
    }
// MARK: - SearchPickerDelegate
    // 创建群组并转发Picker选人完成委托方法，定义本场景选人完成的自定义逻辑
    // 1. 选人结果符合预期时调用创建群组接口
    // 2. 不符合预期时弹窗，例如结果中包含过多未授权结果
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard let forwardVC = self.forwardVC else { return false }
        if ForwardConfigUtils.getSelectedUnFriendNum(pickerItems: items) >= Const.maxUnauthExternalContactsSelectNumber {
            let alert = LarkAlertController()
            alert.setContent(text: BundleI18n.LarkForward.Lark_NewContacts_PermissionRequestSelectUserMax)
            alert.addPrimaryButton(text: BundleI18n.LarkForward.Lark_Legacy_Sure)
            pickerVc.present(alert, animated: true, completion: nil)
            return false
        }
        let chatterMetas = items.compactMap {
            if case let .chatter(chatterMeta) = $0.meta { return chatterMeta }
            return nil
        }
        let chatterPickEntities = ForwardConfigUtils.chatterInfos(pickerChatterMeta: chatterMetas, userResolver: self.userResolver)
        let chatIds = items.filter { $0.meta.type == .chat }.map { $0.id }
        let pickerEntities = CreateGroupResult.CreateGroupPickEntities(chatters: chatterPickEntities,
                                                                       chats: chatIds,
                                                                       departments: [])
        self.createGroupAndForward(pickEntities: pickerEntities,
                                   forwardVC: forwardVC,
                                   pickerVC: pickerVc)
        return false
    }
    // 调用接口创建群组
    // 群组创建成功则关闭Picker，在转发页面弹转发确认框；群组创建失败则在Picker页面弹错误提示
    private func createGroupAndForward(pickEntities: CreateGroupResult.CreateGroupPickEntities,
                                       forwardVC: ForwardComponentVCType,
                                       pickerVC: UIViewController) {
        let notFriendContacts = pickEntities.chatters
            .filter { $0.isNotFriend }
            .map { info in
                AddExternalContactModel(ID: info.ID,
                                        name: info.name,
                                        avatarKey: info.avatarKey)
            }
        guard let ob = try? self.userResolver.resolve(assert: ChatService.self).createGroupChat(name: "",
                                                                                                desc: "",
                                                                                                chatIds: pickEntities.chats,
                                                                                                departmentIds: pickEntities.departments,
                                                                                                userIds: pickEntities.chatters.filter { !$0.isNotFriend }.map { $0.ID },
                                                                                                fromChatId: "",
                                                                                                messageIds: [],
                                                                                                messageId2Permissions: [:],
                                                                                                linkPageURL: nil,
                                                                                                isCrypto: false,
                                                                                                isPublic: false,
                                                                                                isPrivateMode: false,
                                                                                                chatMode: .default) else {
            ForwardLogger.shared.error(module: .createGroup, event: "createGroup ob is nil")
            return
        }
        guard let window = forwardVC.view.window else {
            ForwardLogger.shared.error(module: .createGroup, event: "window is nil")
            return
        }
        let hud = UDToast.showLoading(with: BundleI18n.LarkForward.Lark_Legacy_CreatingGroup, on: window, disableUserInteraction: true)
        let start = Date()
        ob.observeOn(MainScheduler.instance)
            .map { $0.chat }
            .subscribe(onNext: { [weak self, weak forwardVC, weak pickerVC] (chat) in
                hud.remove()
                guard let self else { return }
                Tracer.trackForwardCreateGroupSuccess(chat: chat)
                let cost = Int64(Date().timeIntervalSince(start) * 1000)
                if let forwardVC = forwardVC, let pickerVC = pickerVC {
                    let createGroupBlock = self.getCreateGroupBlock(forwardVC: forwardVC)
                    createGroupBlock(chat, pickerVC, cost, notFriendContacts, nil)
                }
                let isExternal = pickEntities.chatters.contains(where: {
                    $0.isExternal
                })
                let count = pickEntities.chatters.count + pickEntities.chats.count + pickEntities.departments.count
                Tracer.tarckCreateGroup(chatID: chat.id,
                                        isCustom: false,
                                        isExternal: isExternal,
                                        isPublic: false,
                                        modeType: "classic",
                                        count: count)
                AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                                      scene: .Chat,
                                                                      eventable: CreateGroupEvent.createGroupChat,
                                                                      cost: Int(cost),
                                                                      page: nil,
                                                                      extra: Extra(isNeedNet: true,
                                                                                   category: ["create_group_scene": "other"])))
                ForwardLogger.shared.info(module: .createGroup, event: "createGroup Succeed")
            }, onError: { (error) in
                hud.remove()
                AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                scene: .Chat,
                                                                eventable: CreateGroupEvent.createGroupChat,
                                                                errorType: .SDK,
                                                                errorLevel: .Fatal,
                                                                errorCode: (error as NSError).code,
                                                                userAction: nil,
                                                                page: nil,
                                                                errorMessage: (error as NSError).description,
                                                                extra: Extra(isNeedNet: true,
                                                                             category: ["create_group_scene": "other"])))
                ForwardLogger.shared.error(module: .createGroup, event: "createGroup Failed, Error: \(error)")
            }).disposed(by: self.disposeBag)
    }
    // 创建群组并转发Picker willSelect委托方法，定义本场景搜索和推荐列表置灰item的弹窗逻辑
    func pickerWillSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) -> Bool {
        switch item.meta {
        case .chatter(let chatterMeta):
            return ForwardConfigUtils.checkSearchChatterDeniedReasonForWillSelected(chatterMeta: chatterMeta, on: pickerVc.view.window)
        case .chat(let chatMeta):
            if chatMeta.isOuter == true {
                UDToast.showTips(with: BundleI18n.LarkForward.Lark_Group_UnableSelectExternalGroup, on: pickerVc.view)
                return false
            }
        default:
            if self.pickerDisableItem(item) {
                guard let window = pickerVc.view.window else { return true }
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Lark_Legacy_ShareUnsupportTypeError,
                    on: window
                )
                return false
            }
        }
        return true
    }
    // 创建群组并转发Picker置灰委托方法，定义本场景搜索和推荐列表的置灰逻辑
    func pickerDisableItem(_ item: PickerItem) -> Bool {
        // item置灰逻辑由四部分共同作用
        // 1.业务实现的转发置灰闭包
        // 2.业务配置的转发置灰参数
        // 3.业务配置的转发过滤参数（转发过滤参数只影响Picker搜索，不影响Picker推荐列表，所以需要在置灰委托方法中考虑转发过滤参数的作用）
        // 4.老创建群组并转发的置灰逻辑（老页面有一些内置的置灰逻辑，需要迁移到新页面，保证新老页面置灰逻辑的兼容完备）
        var isDisabledByClosure = false
        var isDisabledByDisabledConfigs = false
        var isDisabledByFilterConfigs = false
        var isDisabledByCreateGroup = false
        // 根据转发业务配置的置灰闭包来判断是否需要置灰当前item，闭包为nil表示闭包逻辑不置灰该item
        isDisabledByClosure = self.forwardDisabledClosure?(item) ?? false
        // 转发业务配置的置灰参数
        isDisabledByDisabledConfigs = ForwardConfigUtils.isPickerItemDisabled(pickerItem: item,
                                                                              currentChatterID: userResolver.userID,
                                                                              enabledConfigs: self.forwardEnabledConfigs)
        // 转发业务配置的过滤参数
        isDisabledByFilterConfigs = ForwardConfigUtils.isPickerItemDisabled(pickerItem: item,
                                                                            includeConfigs: self.forwardIncludeConfigs)
        isDisabledByCreateGroup = ForwardConfigUtils.isPickerItemDisabledInCreateGroup(pickerItem: item)
        let isDisabled = isDisabledByClosure || isDisabledByDisabledConfigs || isDisabledByFilterConfigs || isDisabledByCreateGroup
        if isDisabled {
            ForwardLogger.shared.info(module: .createGroup, event: "isDisabledByClosure: \(isDisabledByClosure), isDisabledByDisabledConfigs: \(isDisabledByDisabledConfigs), isDisabledByFilterConfigs: \(isDisabledByFilterConfigs), isDisabledByCreateGroup: \(isDisabledByCreateGroup)")
        }
        return isDisabled
    }
    // 强制选中自己
    func pickerForceSelectedItem(_ item: PickerItem) -> Bool {
        return (item.meta.type == .chatter) && (item.id == userResolver.userID)
    }
}

private protocol ForwardViewControllerType: AnyObject {
    func content() -> ForwardAlertContent
    // 建群后单选
    func selectNew(item: ForwardItem)
}

extension ForwardViewController: ForwardViewControllerType {}
extension NewForwardViewController: ForwardViewControllerType {}
extension ForwardComponentViewController: ForwardViewControllerType {}
extension ForwardViewControllerRouterImpl {
    enum Const {
        static let maxUnauthExternalContactsSelectNumber: Int = 50
    }
}
// swiftlint:enable line_length file_length
