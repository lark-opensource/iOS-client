//
//  CalendarDependencyImp.swift
//  Lark
//
//  Created by zhu chao on 2018/8/3.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

// 平台层依赖
import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkRustClient
import RustPB
import LarkModel
import LarkContainer
import Swinject
import EENavigator
import LarkSceneManager
import RxCocoa
import LarkFeatureGating
import LarkAccountInterface
import RunloopTools
import LarkAppConfig
import LarkNavigation
import LarkFeatureSwitch
import AnimatedTabBar
import LarkGuide
import WebBrowser
import SuiteAppConfig
import LarkReleaseConfig
import LarkTab
import LarkLocalizations
import LarkAvatar
import LKCommonsLogging
import LKCommonsTracker
import Calendar
#if MessengerMod
import LarkCore
import LarkMessengerInterface
import LarkSDKInterface
import LarkSendMessage
import LarkSearchCore
#endif
#if ByteViewMod
import ByteViewInterface
#endif
#if CCMMod
import SpaceInterface
#endif
#if GadgetMod
import TTMicroApp
#endif
import LarkSetting

final class CalendarDependencyImpl: BaseCalendarDependencyImpl, CalendarDependency {

    private let disposeBag = DisposeBag()

    #if CCMMod
    private var calendarTemplate: CalendarTemplate?
    #endif

    static let logger = Logger.log(CalendarDependencyImpl.self, category: "Calendar.Dependency.Service")

    // MARK: Messenger
    var currentUser: CurrentUserInfo {
        LoginUser(user: userService.user)
    }

    var helperCenterHost: String {
        #if MessengerMod
        let userGeneralSetting = try? resolver.resolve(assert: UserGeneralSettings.self)
        return userGeneralSetting?.helpDeskBizDomainConfig.helpCenterHost ?? ""
        #else
        return ""
        #endif
    }

    /// 时间制
    lazy var is12HourStyle: BehaviorRelay<Bool> = {
        #if MessengerMod
        guard let userGeneralSetting = try? resolver.resolve(assert: UserGeneralSettings.self) else {
            return BehaviorRelay<Bool>(value: true)
        }
        let is24HourTime = userGeneralSetting.is24HourTime
        let is12HourStyle = BehaviorRelay<Bool>(value: !is24HourTime.value)
        is24HourTime
            .map { !$0 }
            .bind(to: is12HourStyle)
            .disposed(by: disposeBag)
        return is12HourStyle
        #else
        BehaviorRelay<Bool>(value: true)
        #endif
    }()

    func jumpToFreeBusyChatterController(from: UIViewController,
                                         chatId: String,
                                         selectedChatters: [String],
                                         callbackChatters: @escaping ([String]) -> Void) {
        Self.logger.info("chatId:\(chatId), selectedChatters:\(selectedChatters)")
        #if MessengerMod
        let body = GroupFreeBusyBody(chatId: chatId, selectedChatterIds: selectedChatters, selectCallBack: callbackChatters)
        resolver.navigator.push(body: body, from: from)
        #endif
    }

    func jumpToSelectTranslateController(selectString: String,
                                         fromVC: UIViewController) {

        Self.logger.info("jump to SelectTranslate")
        #if MessengerMod
        let selectTranslateService = try? self.resolver.resolve(assert: SelectTranslateService.self)
        let params: [String: Any] = ["cardSource": "app_schedule"]
        selectTranslateService?.showSelectTranslateView(selectString: selectString, fromVC: fromVC, trackParam: params)
        #endif
    }
    func jumpToProfile(chatterId: String, eventTitle: String, from: UIViewController) {
        Self.logger.info("chatterId:\(chatterId)")
        #if MessengerMod
        let body = PersonCardBody(chatterId: chatterId,
                                  sourceName: eventTitle,
                                  source: .calendar)
        if Display.pad {
            resolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            resolver.navigator.push(body: body,
                                  from: from)
        }
        #endif
    }

    func presentToProfile(chatter: Basic_V1_Chatter, eventTitle: String, from: UIViewController, style: UIModalPresentationStyle) {
        Self.logger.info("chatter.id:\(chatter.id)")
        #if MessengerMod
        let chatter = LarkModel.Chatter.transform(pb: chatter)
        if chatter.type == .bot {
            return
        }
        let body = PersonCardBody(chatterId: chatter.id,
                                  sourceName: eventTitle,
                                  source: .calendar)

        resolver.navigator.present(body: body,
                                 wrap: LkNavigationController.self,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = style })
        #endif
    }


    func presentToProfile(chatterId: String, eventTitle: String, from: UIViewController) {
        Self.logger.info("chatter.id:\(chatterId)")
        #if MessengerMod
        let body = PersonCardBody(chatterId: chatterId,
                                  sourceName: eventTitle,
                                  source: .calendar)

        resolver.navigator.present(body: body,
                                 wrap: LkNavigationController.self,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen })
        #endif
    }

    func jumpToProfile(chatter: Basic_V1_Chatter, eventTitle: String, from: UIViewController) {
        Self.logger.info("chatter.id:\(chatter.id)")
        #if MessengerMod
        let chatter = LarkModel.Chatter.transform(pb: chatter)
        if chatter.type == .bot {
            return
        }
        let body = PersonCardBody(chatterId: chatter.id,
                                  sourceName: eventTitle,
                                  source: .calendar)
        if Display.pad {
            resolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            resolver.navigator.push(body: body,
                                  from: from)
        }
        #endif
    }

    func jumpToEventForwardController(from: UIViewController,
                                      eventTitle: String,
                                      duringTime: String,
                                      shareIcon: UIImage,
                                      canAddExternalUser: Bool,
                                      shouldShowHint: Bool,
                                      pickerCallBack: @escaping ([String], String?, Error?, Bool) -> Void) {
        Self.logger.info("canAddExternalUser:\(canAddExternalUser), shouldShowHint:\(shouldShowHint)")
        #if MessengerMod
        let body = EventShareBody(currentChatId: "",
                                  shareMessage: eventTitle,
                                  subMessage: duringTime,
                                  shareImage: shareIcon,
                                  shouldShowExternalUser: canAddExternalUser,
                                  shouldShowHint: shouldShowHint,
                                  callBack: pickerCallBack)
        resolver.navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
        #else
        pickerCallBack(["6805366427986493441"], "留言", nil, true)// 群：LarkTime iOS 技术委员会
        #endif
    }

    func jumpToTextForwardController(from: UIViewController,
                                     text: String,
                                     modalPresentationStyle: UIModalPresentationStyle,
                                     sentHandler: ((_ userIds: [String], _ chatIds: [String]) -> Void)? = nil) {
        Self.logger.info("calendar forward text")
        #if MessengerMod
        let body = ForwardTextBody(text: text, sentHandler: sentHandler)
        resolver.navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = modalPresentationStyle })
        #endif
    }

    func jumpToImageShareController(from: UIViewController,
                                    image: UIImage,
                                    modalPresentationStyle: UIModalPresentationStyle) {
        Self.logger.info("calendar share image")
        #if MessengerMod
        let body = ShareImageBody(image: image)
        resolver.navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = modalPresentationStyle })
        #endif
    }

    func jumpToSearchTransferUserController(eventOrganizerId: String,
                                            from: UIViewController,
                                            doTransfer: @escaping (_ transferUserName: String, _ transferUserId: String, _ pickerController: UIViewController) -> Void) {
        Self.logger.info("eventOrganizerId:\(eventOrganizerId)")
        #if MessengerMod
        weak var controller: UIViewController?
        let body = SearchUserCalendarBody(eventOrganizerId: eventOrganizerId, doTransfer: { (transferUserName: String, transferUserId: String) -> Void in
            doTransfer(transferUserName, transferUserId, controller ?? from)
        })
        resolver.navigator.present(body: body, from: from, prepare: { (pickerVC: UIViewController) -> Void in
            pickerVC.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            controller = pickerVC
        })
        #else
        doTransfer("荣鑫", "6864875990628204545", from)
        #endif
    }

    func jumpToMainSearchController(from: UIViewController) {
        Self.logger.info("jumpToMainSearchController")
        #if MessengerMod
        let searchMainBody = SearchMainBody(topPriorityScene: .rustScene(.searchCalendarEventScene), sourceOfSearch: .calendar)
        resolver.navigator.push(body: searchMainBody, from: from)
        #else
        guard let interface = try? resolver.resolve(assert: CalendarInterface.self) else { return }
        let searchController = interface.getSearchController(query: "", searchNavBar: nil)
        from.navigationController?.pushViewController(searchController, animated: true)
        #endif
    }

    func jumpToSearchAttendeeController(from: UIViewController,
                                          title: String,
                                          chatterIds: [String],
                                          chatIds: [String],
                                          needSearchOuterTenant: Bool,
                                          enableSearchingOuterTenant: Bool,
                                          callBack: @escaping ([EventAttendeeSeed]) -> Void) {
        Self.logger.info("chatterIds:\(chatterIds), chatIds:\(chatIds), needSearchOuterTenant:\(needSearchOuterTenant), enableSearchingOuterTenant:\(enableSearchingOuterTenant)")
        #if MessengerMod
        var body = CalendarChatterPickerBody()
        body.title = title
        body.allowSelectNone = true
        body.needSearchOuterTenant = needSearchOuterTenant
        body.enableSearchingOuterTenant = enableSearchingOuterTenant
        body.defaultSelectedChatterIds = chatterIds
        body.defaultSelectedChatIds = chatIds
        body.selectedCallback = { controller, contactPickerResult in
            var attendeeSeeds = [EventAttendeeSeed]()
            attendeeSeeds.append(contentsOf: contactPickerResult.chatIds.map { .group(chatId: $0) })
            let chatterIDs = contactPickerResult.chatterInfos.map { $0.ID }
            attendeeSeeds.append(contentsOf: chatterIDs.map { .user(chatterId: $0) })
            callBack(attendeeSeeds)
            controller.dismiss(animated: true, completion: nil)
        }
        resolver.navigator.present(body: body,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen })
        #endif
    }

    // 旧版日历编辑 + 日程编辑
    // swiftlint:disable:next function_parameter_count
    func jumpToAttendeeSelectorController(from: UIViewController,
                                          selectedUserIDs: [String],
                                          selectedGroupIDs: [String],
                                          selectedMailContactIDs: [String],
                                          enableSearchingOuterTenant: Bool,
                                          canCrossTenant: Bool,
                                          enableEmailContact: Bool,
                                          isForCalendarAttendee: Bool,
                                          checkInvitePermission: Bool,
                                          chatterPickerTitle: String,
                                          blockTip: String,
                                          beBlockedTip: String,
                                          alertTitle: String,
                                          alertContent: String,
                                          alertContentWithUser: @escaping (String, Lang?) -> String,
                                          searchPlaceholder: String?,
                                          callBack: @escaping (UINavigationController?, AttendeeSelectResult, ShowApplyContactAlert?) -> Void) {
        Self.logger.info("selectedUserIDs:\(selectedUserIDs), enableSearchingOuterTenant:\(enableSearchingOuterTenant), canCrossTenant:\(canCrossTenant), isForCalendarAttendee:\(isForCalendarAttendee)")
        #if MessengerMod
        var body = CalendarChatterPickerBody()
        body.checkInvitePermission = checkInvitePermission
        body.title = chatterPickerTitle
        body.contactOptPickerModel.blockTip = blockTip
        body.contactOptPickerModel.beBlockedTip = beBlockedTip
        body.enableSearchingOuterTenant = enableSearchingOuterTenant
        body.allowSelectNone = true
        body.needSearchOuterTenant = canCrossTenant
        if isForCalendarAttendee {
            body.needSearchMail = false
        } else {
            body.needSearchMail = true
            body.supportSelectOrganization = true
        }
        body.eventSearchMeetingGroup = !isForCalendarAttendee
        body.enableEmailContact = canCrossTenant && enableSearchingOuterTenant && enableEmailContact
        body.needSearchMail = enableEmailContact

        body.searchPlaceholder = searchPlaceholder
        body.forceSelectedChatterIds = selectedUserIDs
        body.forceSelectedChatIds = selectedGroupIDs
        body.forceSelectedMailContactIds = selectedMailContactIDs
        body.defaultSelectedChatterIds = selectedUserIDs
        body.defaultSelectedChatIds = selectedGroupIDs
        body.defaultSelectedMailContactIds = selectedMailContactIDs

        body.selectedCallback = { controller, contactPickerResult in
            // contactPickerResult 过滤和类型转换
            var selectResult = (attendees: [EventAttendeeSeed](), departments: [(id: String, name: String)]())
            selectResult.attendees.append(contentsOf: contactPickerResult.chatInfos.map { .group(chatId: $0.id) })
            let chatterIDs: [String]
            var pickerCountSelected: Int = 0
            if isForCalendarAttendee {
                chatterIDs = contactPickerResult.chatterInfos.map(\.ID)
            } else {
                selectResult.departments = contactPickerResult.departments.map { (id: $0.id, name: $0.name) }
                chatterIDs = contactPickerResult.chatterInfos.filter({ !$0.isNotFriend }).map(\.ID)
            }
            selectResult.attendees.append(contentsOf: chatterIDs.map { .user(chatterId: $0) })
            selectResult.attendees.append(contentsOf: contactPickerResult.mails.map { .email(address: $0) })
            selectResult.attendees.append(contentsOf: contactPickerResult.meetingGroupChatIds.map { .meetingGroup(chatId: $0) })
            selectResult.attendees.append(contentsOf: contactPickerResult.mailContacts.map { (mailContact: LarkMessengerInterface.SelectMailInfo) -> EventAttendeeSeed in
                let emailTypeInCalendar: CalendarEventAttendee.MailContactType
                switch mailContact.type {
                case .unknown, .chatter, .group, .external, .noneType: emailTypeInCalendar = .normalMail
                case .nameCard: emailTypeInCalendar = .mailContact
                case .sharedMailbox: emailTypeInCalendar = .publicMail
                case .mailGroup: emailTypeInCalendar = .mailGroup
                }
                return .emailContact(address: mailContact.email,
                                     name: mailContact.displayName,
                                     avatarKey: mailContact.avatarKey,
                                     entityId: mailContact.entityId,
                                     type: emailTypeInCalendar)
            })

            guard !isForCalendarAttendee else {
                // 共享日历场景，不做联系人权限申请
                callBack(controller, selectResult, nil)
                return
            }

            // 非联系人权限申请
            let applyContacts = contactPickerResult.chatterInfos
                .filter { $0.isNotFriend }
                .map { AddExternalContactModel(ID: $0.ID, name: $0.name, avatarKey: $0.avatarKey) }
            guard !applyContacts.isEmpty else {
                callBack(controller, selectResult, nil)
                return
            }
            let showApplyContactAlert = {
                let onlyAddOneAttendee = contactPickerResult.chatterInfos.count == 1
                && contactPickerResult.chatIds.isEmpty
                && contactPickerResult.mails.isEmpty
                && contactPickerResult.meetingGroupChatIds.isEmpty
                if applyContacts.count == 1 && onlyAddOneAttendee {
                    let userInfo = applyContacts[0]
                    var source = Source()
                    source.sourceType = .calendar
                    let body = AddContactApplicationAlertBody(
                        userId: userInfo.ID,
                        chatId: nil,
                        source: source,
                        token: nil,
                        displayName: userInfo.name,
                        title: alertTitle,
                        content: alertContentWithUser(userInfo.name, nil),
                        targetVC: from,
                        businessType: .eventConfirm
                    )
                    self.resolver.navigator.present(body: body, from: from)
                } else {
                    let body = MAddContactApplicationAlertBody(
                        contacts: applyContacts,
                        title: alertTitle,
                        text: alertContent,
                        showConfirmApplyCheckBox: true,
                        source: .calendar,
                        dependecy: .init(source: .calendar),
                        businessType: .eventConfirm,
                        sureCallBack: nil
                    )
                    self.resolver.navigator.present(body: body, from: from)
                }
            }
            callBack(controller, selectResult, showApplyContactAlert)
        }
        resolver.navigator.present(body: body,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = .formSheet })
        #else
        var result = (attendees: [EventAttendeeSeed](), departments: [(id: String, name: String)]())
        result.departments = [
            (id: "6942378619645722644", name: "部门一"),
            (id: "6961984685807239188", name: "部门二"),
            (id: "6961984761849970707", name: "部门三"),
            (id: "6961984796549447700", name: "部门四"),
            (id: "6961984871333888019", name: "部门五")
        ]
        DispatchQueue.main.async {
            callBack(nil, result, nil)
        }
        #endif
    }

    func jumpToCalendarMemberSelectorController(from: UIViewController,
                                                pickerDelegate: SearchPickerDelegate,
                                                naviConfig: (title: String, sureText: String),
                                                searchPlaceHolder: String,
                                                preSelectMembers: [(id: String, isGroup: Bool)]) {
        #if MessengerMod
        var body = ContactSearchPickerBody()
        let preSelectedItems: [PickerItem] = preSelectMembers.map { memberInfo -> PickerItem in
            if memberInfo.isGroup {
                return PickerItem(meta: .chat(.init(id: memberInfo.id, type: .group)))
            } else {
                return PickerItem(meta: .chatter(.init(id: memberInfo.id)))
            }
        }
        body.featureConfig = .init(
            scene: .calendarShareMember,
            multiSelection: .init(isOpen: true, preselectItems: preSelectedItems),
            navigationBar: .init(title: naviConfig.title, sureText: naviConfig.sureText),
            searchBar: .init(placeholder: searchPlaceHolder)
        )

        body.searchConfig = PickerSearchConfig(entities: [
            PickerConfig.ChatterEntityConfig(tenant: .all, talk: .all, field: .init()),
            PickerConfig.ChatEntityConfig(tenant: .all, field: .init(relationTag: true))
        ], permission: [.checkBlock])

        body.contactConfig = .init(entries: [
            PickerContactViewConfig.OwnedGroup(),
            PickerContactViewConfig.External(),
            PickerContactViewConfig.Organization(),
            PickerContactViewConfig.RelatedOrganization()
        ])

        body.delegate = pickerDelegate

        resolver.navigator.present(body: body,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen })
        #endif
    }

    func jumpToChatController(from: UIViewController,
                              chatterID: String,
                              onError: @escaping () -> Void) {
        Self.logger.info("chatterID:\(chatterID)")
        #if MessengerMod
        let body = ChatControllerByChatterIdBody(
            chatterId: chatterID,
            fromWhere: .card,
            isCrypto: false
        )
        let from = WindowTopMostFrom(vc: from)

        if Display.pad {
            let padHandler: (NavigatorFrom) -> Void = {[weak self] from in
                self?.resolver.navigator.switchTab(Tab.feed.url, from: from, animated: true) {[weak self] _ in
                    let context: [String: Any] = [
                        FeedSelection.contextKey: FeedSelection(feedId: chatterID, selectionType: .skipSame)
                    ]
                    self?.resolver.navigator.showDetail(body: body,
                                                context: context,
                                                wrap: LkNavigationController.self,
                                                from: from) { (_, res) in
                        if res.error != nil {
                            onError()
                            Self.logger.error("navigator.showDetail failed with:\(String(describing: res.error))")
                        }
                    }
                }
            }

            // 区分iPad端是否开启多Scene功能 在指定的Scene上执行统一的padHandler操作
            if SceneManager.shared.supportsMultipleScenes {
                // iPad with multiple scene
                SceneManager.shared.active(scene: .mainScene(), from: from.fromViewController) { mainSceneWindow, _ in
                    if let window = mainSceneWindow {
                        Self.logger.info("success get mainSceneWindow from SceneManager")
                        padHandler(WindowTopMostFrom(window: window))
                    } else {
                        onError()
                        Self.logger.error("failed get mainSceneWindow from SceneManager")
                    }
                }
            } else {
                // iPad without multiple scene
                padHandler(from)
            }
        } else {
            resolver.navigator.push(body: body, from: from) { (_, res) in
                if res.error != nil {
                    onError()
                    Self.logger.error("navigator.push failed with:\(String(describing: res.error))")
                }
            }
        }
        #endif
    }

    func jumpToChatController(from: UIViewController,
                              chatID: String,
                              onError: @escaping () -> Void,
                              onLeaveMeeting: @escaping () -> Void) {
        Self.logger.info("chatID:\(chatID)")
        #if MessengerMod
        guard let pushCenter = try? resolver.userPushCenter else { return }
        let disposeBag = self.disposeBag
        var body = ChatControllerByIdBody(chatId: chatID, fromWhere: .card)
        let from = WindowTopMostFrom(vc: from)

        if Display.pad {
            openChatForPad(from: from, body: body, chatID: chatID, onError: onError)
        } else {
            resolver.navigator.push(body: body, from: from) { (_, res) in
                if res.error != nil {
                    onError()
                    Self.logger.error("navigator.push failed with:\(String(describing: res.error))")
                }
            }
        }
        pushCenter.driver(for: PushLocalLeaveGroupChannnel.self).drive(onNext: { (channnel) in
            if channnel.channelId == chatID {
                onLeaveMeeting()
            }
        }).disposed(by: disposeBag)
        #endif
    }

    func jumpToJoinGroupApplyController(from: UIViewController,
                                        chatID: String,
                                        eventID: String) {
        Self.logger.info("chatID:\(chatID)")
        #if MessengerMod
        guard let pushCenter = try? resolver.userPushCenter else { return }
        let disposeBag = self.disposeBag

        var body = JoinGroupApplyBody(chatId: chatID, way: .viaCalendar(eventID: eventID))
        let from = WindowTopMostFrom(vc: from)

        resolver.navigator.push(body: body, from: from)
        #endif
    }

    func presentToChatController(from: UIViewController,
                                 chatID: String,
                                 style: UIModalPresentationStyle,
                                 onError: @escaping () -> Void,
                                 onLeaveMeeting: @escaping () -> Void) {
        Self.logger.info("chatID:\(chatID)")
        #if MessengerMod
        guard let pushCenter = try? resolver.userPushCenter else { return }
        let disposeBag = self.disposeBag
        var body = ChatControllerByIdBody(chatId: chatID, fromWhere: .card)
        let from = WindowTopMostFrom(vc: from)

        if Display.pad {
            openChatForPad(from: from, body: body, chatID: chatID, onError: onError)
        } else {
            resolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = style }) { (_, res) in
                if res.error != nil {
                    onError()
                    Self.logger.error("navigator.present failed with:\(String(describing: res.error))")
                }
            }
        }
        pushCenter.driver(for: PushLocalLeaveGroupChannnel.self).drive(onNext: { (channnel) in
            if channnel.channelId == chatID {
                onLeaveMeeting()
            }
        }).disposed(by: disposeBag)
        #endif
    }

    func jumpToPersonCard(chatterID: String, from: UIViewController) {
        Self.logger.info("chatterID:\(chatterID)")
        #if MessengerMod
        let body = PersonCardBody(chatterId: chatterID)
        resolver.navigator.push(body: body, from: from)
        #endif
    }

    #if MessengerMod
    private func openChatForPad(from: WindowTopMostFrom,
                                body: ChatControllerByIdBody,
                                chatID: String,
                                onError: @escaping () -> Void) {
        Self.logger.info("ready to openChatForPad")
        let padHandler: (NavigatorFrom) -> Void = {[weak self] from in
            self?.resolver.navigator.switchTab(Tab.feed.url, from: from, animated: true) { [weak self] _ in
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: chatID, selectionType: .skipSame)
                ]
                self?.resolver.navigator.showDetail(body: body,
                                            context: context,
                                            wrap: LkNavigationController.self,
                                            from: from) { (_, res) in
                    if res.error != nil {
                        Self.logger.error("navigator.showDetail failed with:\(String(describing: res.error))")
                        onError()
                    }
                }
            }
        }

        // 区分iPad端是否开启多Scene功能 在指定的Scene上执行统一的padHandler操作
        if SceneManager.shared.supportsMultipleScenes {
            // iPad with multiple scene
            SceneManager.shared.active(scene: .mainScene(), from: from.fromViewController) { mainSceneWindow, _ in
                if let window = mainSceneWindow {
                    Self.logger.error("success get mainSceneWindow from SceneManager")
                    padHandler(WindowTopMostFrom(window: window))
                } else {
                    onError()
                    Self.logger.error("failed get mainSceneWindow from SceneManager")
                }
            }
        } else {
            // iPad without multiple scene
            padHandler(from)
        }
    }
    #endif

    func paseRichText(richText: RustPB.Basic_V1_RichText,
                      isShowReadStatus: Bool,
                      checkIsMe: ((_ userId: String) -> Bool)?,
                      maxLines: Int,
                      maxCharLine: Int,
                      customAttributes: [NSAttributedString.Key: Any]) -> (string: NSAttributedString, range: [NSRange: URL])? {
        Self.logger.info("isShowReadStatus:\(isShowReadStatus), maxLines:\(maxLines), maxCharLine:\(maxCharLine)")
        #if MessengerMod
        let attributeElement = LarkCoreUtils.parseRichText(richText: richText,
                                                           isShowReadStatus: isShowReadStatus,
                                                           checkIsMe: checkIsMe,
                                                           maxLines: maxLines,
                                                           maxCharLine: maxCharLine,
                                                           customAttributes: customAttributes)
        return (attributeElement.attriubuteText, attributeElement.urlRangeMap)
        #else
        return nil
        #endif
    }

    func replyMessages(byIds messageIds: [String], with content: String) {
        Self.logger.info("reply message ids:\(messageIds)")
        #if MessengerMod
        let messageAPI = try? resolver.resolve(assert: MessageAPI.self)
        messageAPI?.fetchMessages(ids: messageIds)
            .subscribe(onNext: { [weak self] messages in
                self?.doReplyMessages(messages, with: content)
            })
            .disposed(by: disposeBag)
        #endif
    }

    private func doReplyMessages(_ messages: [Message], with content: String) {
        Self.logger.info("do Reply messages")
        #if MessengerMod
        let sendMessageAPI = try? resolver.resolve(assert: SendMessageAPI.self)
        let richText = RustPB.Basic_V1_RichText.text(content)
        for message in messages {
            sendMessageAPI?.sendText(
                context: nil,
                content: richText,
                parentMessage: message,
                chatId: message.channel.id,
                threadId: nil,
                stateHandler: nil
            )
        }
        #endif
    }

    // MARK: CCM
    func jumpToAttachmentPreviewController(token: String, from viewController: UIViewController) {
        Self.logger.info("token:\(token)")
        #if CCMMod
        let files = [DriveThirdPartyFileEntity(fileToken: token, docsType: 12, mountNodePoint: nil, mountPoint: "calendar")]
        let body = DriveThirdPartyAttachControllerBody(files: files, index: 0, bussinessId: "calendar")
        resolver.navigator.present(body: body,
                                 wrap: LkNavigationController.self,
                                 from: viewController,
                                 prepare: { $0.modalPresentationStyle = .fullScreen })
        #endif
    }

    func uploadEventAttachment(localPath: String,
                               fileName: String,
                               mountNodePoint: String,
                               mountPoint: String,
                               failedTip: String) -> Observable<(fileToken: String, UploadStatus)> {
        #if CCMMod
        let uploadProtocol = try? resolver.resolve(assert: DocCommonUploadProtocol.self)
        return uploadProtocol?
            .upload(
                localPath: localPath,
                fileName: fileName,
                mountNodePoint: mountNodePoint,
                mountPoint: mountPoint
            ).map { (_, progress, fileToken, status) -> (fileToken: String, UploadStatus) in
                var uploadStatus: UploadStatus = .uploading(progress)
                if status == .cancel {
                    uploadStatus = .cancel
                } else if status == .failed {
                    uploadStatus = .failed(failedTip)
                } else if status == .success {
                    uploadStatus = .success
                }

                return (fileToken, uploadStatus)
            } ?? .empty()
        #else
        return .empty()
        #endif
    }

    /// 创建DocComponent
    func getDocComponentVC(url: URL, delegate: CalendarDocComponentAPIDelegate?) -> CalendarDocComponentAPIProtocol? {
        #if CCMMod
        /// url 参数配置定义：https://bytedance.feishu.cn/docx/WjTddzO5QoYNZSxGxYCcQhoXnLh
        let parameters: [String: String] = [
            "agenda_platform": "calendar_ios",
            "scene": "agenda",
            "sub_scene": delegate?.getSubScene() ?? "",
            "doc_app_id": "301"
        ]
        let url = url.append(parameters: parameters)
        let docComponentSDK = try? resolver.resolve(assert: DocComponentSDK.self)
        guard let docComponent: DocComponentAPI = docComponentSDK?.create(url: url, config: DocComponentConfig(module: "calendar", sceneID: "301")) else {
            return nil
        }
        let docComponentAPI = CalendarDocComponentAPI(docComponentAPI: docComponent)
        docComponentAPI.delegate = delegate
        return docComponentAPI
        #endif
        return nil
    }

    // 获取缩略图
    func getThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage> {
        #if CCMMod
        if let docsApi = try? resolver.resolve(assert: DocSDKAPI.self) {
            return docsApi.getThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageViewSize: imageViewSize, forceUpdate: true)
        } else {
            return .empty()
        }
        #else
        return .empty()
        #endif
    }

    /// 同步生成最新缩略图
    /// fileType 表示 pbType，举例 docx 的 objTypeRawValue 值为 22，pbTypeRawValue 值为 8，日历业务域内只使用 pbType
    func syncThumbnail(fileToken: String, fileType: Int, completion: @escaping (Error?) -> Void) {
        #if CCMMod
        if let docsApi = try? resolver.resolve(assert: DocSDKAPI.self) {
            docsApi.syncThumbnail(token: fileToken, fileType: fileType, completion: completion)
        }
        #endif
    }

    /// 创建水平模板列表页
    func createTemplateHorizontalListView(frame: CGRect,
                                          params: CalendarHorizontalTemplateParams,
                                          delegate: CalendarTemplateHorizontalListViewDelegate) -> CalendarTemplateHorizontalListViewProtocol {
        let view = CalendarTemplateHorizontalListView()
        #if CCMMod
        guard let templateAPI = try? resolver.resolve(assert: TemplateAPI.self) else {
            return view
        }
        let ccmParams = HorizontalTemplateParams(
            itemHeight: params.itemHeight,
            pageSize: params.pageSize,
            categoryId: params.categoryId,
            createDocParams: CreateDocTitleParams(
                title: params.createDocParams.title,
                titlePrefix: params.createDocParams.titlePrefix,
                titleSuffix: params.createDocParams.titleSuffix
            ),
            templateSource: "calendar_create",
            docComponentSceneId: "301",
            uiConfig: HorizontalTemplateUIConfig(
                minimumLineSpacing: 12,
                sectionInset: .init(top: 10, left: 16, bottom: 13, right: 24)
            ),
            templatePageConfig: TemplatePageConfig(useTemplateType: .template,
                                                   autoDismiss: false,
                                                   isModalInPresentation: true,
                                                   clickTemplateItemType: .select,
                                                   hideItemSubTitle: true)
        )
        view.delegate = delegate
        let viewProtocol = templateAPI.createTemplateHorizontalListView(frame: frame,
                                                                        params: ccmParams,
                                                                        delegate: view)
        view.templateView = viewProtocol
        #endif
        return view
    }

    func createDocsByTemplate(docType: Int,
                              docToken: String?,
                              templateId: String?,
                              titleParam: CalendarCreateDocTitleParams?,
                              callback: ((CalendarDocsTemplateCreateResult?, Error?) -> Void)?) {
        #if CCMMod
        let templateAPI = try? resolver.resolve(assert: TemplateAPI.self)
        let makeTitleParam: (() -> CreateDocTitleParams?) = {
            guard let params = titleParam else { return nil }
            return .init(title: params.title, titlePrefix: params.titlePrefix, titleSuffix: params.titleSuffix)
        }
        let makeResult: ((DocsTemplateCreateResult?) -> CalendarDocsTemplateCreateResult?) = { docResult in
            guard let result = docResult else { return nil }
            return .init(url: result.url, title: result.title)
        }
        templateAPI?.createDocsByTemplate(docType: docType,
                                         docToken: docToken,
                                         templateId: templateId,
                                         templateSource: "calendar_create",
                                         titleParam: makeTitleParam(),
                                         callback: { (result, error) in
            callback?(makeResult(result), error)
        })
        #endif
    }

    func fetchMeetingNotesTemplates(categoryId: String, pageIndex: Int, pageSize: Int) -> Observable<[CalendarTemplateItem]> {
        #if CCMMod
        guard let templateAPI = try? resolver.resolve(assert: TemplateAPI.self) else {
            return .empty()
        }
        return templateAPI.fetchTemplateData(categoryId: categoryId,
                                             pageIndex: pageIndex,
                                             pageSize: pageSize,
                                             docsType: .docX,
                                             templateSource: "calendar_create")
        .map { pageInfo in
            return pageInfo.templates.map {
                CalendarTemplateItem(id: $0.id,
                                     name: $0.name,
                                     objToken: $0.objToken,
                                     objType: DocsType(rawValue: $0.objType).pbRawValue)
            }
        }
        #endif
        return .empty()
    }

    /// 展示 Doc 调整外部权限弹窗
    func showDocAdjustExternalPanel(from vc: UIViewController, url: String, callBack: @escaping ((Swift.Result<Void, CalendarAdjustDocPermissionError>) -> Void)) {
        #if CCMMod
        let docPermission = try? resolver.resolve(assert: DocPermissionProtocol.self)
        docPermission?.showAdjustExternalPanel(from: vc, docUrl: url, callback: { result in
            switch result {
            case .success:
                callBack(.success(()))
            case .failure(let err):
                switch err {
                case .fail: callBack(.failure(.fail))
                case .disabled: callBack(.failure(.disabled))
                }
            }
        })
        #endif
    }

    /// 创建选择模版中心页面
    func createTemplateSelectedPage(
        from vc: UIViewController,
        categoryId: String,
        delegate: CalendarTemplateHorizontalListViewDelegate
    ) -> UIViewController? {
        #if CCMMod
        guard let templateAPI = try? resolver.resolve(assert: TemplateAPI.self) else {
            return nil
        }
        calendarTemplate = CalendarTemplate(templateAPI)
        return calendarTemplate?.createTemplateSelectedVC(fromVC: vc, categoryId: categoryId, delegate: delegate)
        #endif
        return nil
    }

    /// 关联文档picker页面
    func createAssociateDocPickController(pickerDelegate: SearchPickerDelegate) -> UIViewController? {
        Self.logger.info("createAssociateDocPickController")
        #if MessengerMod
        let userID = resolver.userID
        let controller = SearchPickerNavigationController(resolver: resolver)
        controller.defaultView = PickerRecommendListView(resolver: resolver)

        //配置搜索用户作为所有者的文档
        let docConfig = PickerConfig.DocEntityConfig(
            belongUser: .belong([userID]),
            types: [.docx, .wiki])

        //配置搜索用户作为所有者的文档
        let wikiConfig = PickerConfig.WikiEntityConfig(
            belongUser: .belong([userID]),
            types: [.docx, .wiki])

        controller.searchConfig = PickerSearchConfig(entities: [
            docConfig, wikiConfig
        ])

        //配置导航栏
        let naviBarConfig = PickerFeatureConfig.NavigationBar(
            title: BundleI18n.CalendarMod.Calendar_G_ChooseToLink_Title,
            subtitle: BundleI18n.CalendarMod.Calendar_G_CanLinkDocsYouOwn_Desc,
            showSure: false
        )

        controller.featureConfig = PickerFeatureConfig(scene: .calendarAgendaAssociate,
                                                       navigationBar: naviBarConfig,
                                                       searchBar: .init(hasBottomSpace: false))

        controller.pickerDelegate = pickerDelegate

        return controller
        #endif
        return nil
    }

    // MARK: ByteView
    func jumpToNewVideoMeeting() {
        Self.logger.info("jumpToNewVideoMeeting")
        #if ByteViewMod
        let body = StartMeetingBody(entrySource: .calendarDetails)
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        resolver.navigator.push(body: body, from: fromVC)
        #endif
    }

    func jumpToJoinVideoMeeting() {
        Self.logger.info("jumpToJoinVideoMeeting")
        #if ByteViewMod
        let body = JoinMeetingBody(id: "", idType: .number, entrySource: .calendarDetails)
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        resolver.navigator.push(body: body, from: fromVC)
        #endif
    }

    func jumpToCreateVideoMeeting(vcSettingId: String?,
                                  from: UIViewController,
                                  callback: @escaping ((EventVCSettingResponse?, Error?) -> Void)) {
        Self.logger.info("vcSettingId:\(vcSettingId)")
        #if ByteViewMod
        let videoApi = try? resolver.resolve(assert: ByteViewInterface.CalendarSettingService.self)
        videoApi?.openSettingForStart(vcSettingId: vcSettingId, from: from) { result in
            switch result {
            case .success(let resp):
                callback(EventVCSettingResponse(vcSettingId: resp.vcSettingId), nil)
            case .failure(let error):
                callback(nil, error)
            }
        }
        #endif
    }

    func showVideoMeetingSetting(instanceDetails: CalendarInstanceDetails, from: UIViewController) {
        Self.logger.info("uniqueId:\(instanceDetails.uniqueID)")
        #if ByteViewMod
        let body = VCCalendarSettingsBody(uniqueID: instanceDetails.uniqueID,
                                          uid: instanceDetails.key,
                                          originalTime: instanceDetails.originalTime,
                                          instanceStartTime: instanceDetails.instanceStartTime,
                                          instanceEndTime: instanceDetails.instanceEndTime)
        resolver.navigator.present(body: body, wrap: LkNavigationController.self, from: from,
                                   prepare: { $0.modalPresentationStyle = .formSheet })
        #endif
    }

    func joinVideoMeeting(instanceDetails: CalendarInstanceDetails, title: String) {
        Self.logger.info("uniqueID:\(instanceDetails.uniqueID)")
        #if ByteViewMod
        let body = JoinMeetingByCalendarBody(uniqueId: instanceDetails.uniqueID,
                                             uid: instanceDetails.key,
                                             originalTime: instanceDetails.originalTime,
                                             instanceStartTime: instanceDetails.instanceStartTime,
                                             instanceEndTime: instanceDetails.instanceEndTime,
                                             title: title,
                                             entrySource: .calendarDetails,
                                             linkScene: false, isStartMeeting: false, isWebinar: false)
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        resolver.navigator.push(body: body, from: fromVC)
        #endif
    }

    func joinInterviewVideoMeeting(uniqueID: String) {
        Self.logger.info("uniqueID:\(uniqueID)")
        #if ByteViewMod
        let body = JoinMeetingBody(id: uniqueID, idType: .interview, entrySource: .calendarDetails)
        let fromVC = resolver.navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        resolver.navigator.push(body: body, from: fromVC)
        #endif
    }

    func floatingOrDismissByteViewWindow() {
        #if ByteViewMod
        try? resolver.resolve(assert: MeetingService.self).floatingOrDismissWindow()
        #endif
    }

    func createWebinarConfigController(param: WebinarEventConfigParam) -> UIViewController {
        #if ByteViewMod
        guard let videoApi = try? resolver.resolve(assert: ByteViewInterface.CalendarSettingService.self) else {
            return UIViewController()
        }
        let videoParam = WebinarConfigParam(
            configJson: param.configJson,
            speakerCanInviteOthers: param.speakerCanInviteOthers,
            speakerCanSeeOtherSpeakers: param.speakerCanSeeOtherSpeakers,
            audienceCanInviteOthers: param.audienceCanInviteOthers,
            audienceCanSeeOtherSpeakers: param.audienceCanSeeOtherSpeakers
        )
        return videoApi.createWebinarConfigController(param: videoParam) ?? UIViewController()
        #else
        return UIViewController()
        #endif
    }

    func getWebinarLocalConfig(vc: UIViewController) -> CalendarWebinarConfigResult? {
        #if ByteViewMod
        let videoApi = try? resolver.resolve(assert: ByteViewInterface.CalendarSettingService.self)
        guard let result = videoApi?.getWebinarLocalConfig(vc: vc) else { return nil }
        switch result {
        case .success(let data):
            return .success(
                WebinarEventConfigParam(
                    configJson: data.configJson,
                    speakerCanInviteOthers: data.speakerCanInviteOthers,
                    speakerCanSeeOtherSpeakers: data.speakerCanSeeOtherSpeakers,
                    audienceCanInviteOthers: data.audienceCanInviteOthers,
                    audienceCanSeeOtherSpeakers: data.audienceCanSeeOtherSpeakers)
            )
        case .failure(let error):
            return .failure(error.localizedDescription)
        }
        #endif
        let params = WebinarEventConfigParam(
            configJson: "{\"vc_security_setting\":0,\"can_join_meeting_before_owner_joined\":false,\"mute_microphone_when_join\":false,\"put_no_permission_user_in_lobby\":true,\"auto_record\":false,\"is_parti_unmute_forbidden\":false,\"only_host_can_share\":false,\"only_presenter_can_annotate\":false,\"is_parti_change_name_forbidden\":false,\"interpretation_setting\":{},\"is_audience_change_name_forbidden\":false,\"is_audience_im_forbidden\":false,\"is_audience_hands_up_forbidden\":false,\"panelist_permission\":{\"allow_send_message\":true,\"allow_send_reaction\":true,\"allow_virtual_background\":true,\"allow_virtual_avatar\":true}}",
            speakerCanInviteOthers: true,
            speakerCanSeeOtherSpeakers: true,
            audienceCanInviteOthers: true,
            audienceCanSeeOtherSpeakers: true
        )
        return .success(params)
    }

    func pullWebinarMaxParticipantsCount(organizerTenantId: Int64, organizerUserId: Int64, completion: @escaping (Result<Int64, Error>) -> Void) {
        #if ByteViewMod
        let videoApi = try? resolver.resolve(assert: ByteViewInterface.CalendarSettingService.self)
        videoApi?.pullWebinarMaxParticipantsCount(organizerTenantId: organizerTenantId, organizerUserId: organizerUserId, completion: completion
        )
        #endif
    }

    func pullVCQuotaHasWebinar(completion: @escaping (Result<Bool, Error>) -> Void) {
        #if ByteViewMod
        let videoApi = try? resolver.resolve(assert: ByteViewInterface.CalendarSettingService.self)
        videoApi?.pullWebinarSuiteQuota(completion: completion)
        #else
        completion(.success(false))
        #endif
    }
    
    /// 获取Setting， 根据Key返回json String
    func getSettingJson<T: Decodable>(key: UserSettingKey, defaultValue: T) -> T {
        let settingService = try? resolver.resolve(assert: SettingService.self)
        let setting = try? settingService?.setting(with: T.self, key: key)
        return setting ?? defaultValue
    }
    
    /// 获取Setting，根据Key 返回json Dic
    func getSettingJson(key: UserSettingKey) -> [String: Any] {
        let settingService = try? resolver.resolve(assert: SettingService.self)
        let setting = try? settingService?.setting(with: key)
        return setting ?? [:]
    }

    // MARK: Gadget
    /// 获取app当前已使用内存
    func getCurrentMemoryUsageInBytes() -> CGFloat {
        #if GadgetMod
        BDPMemoryMonitor.currentMemoryUsageInBytes()
        #else
        0.0
        #endif
    }

    #if MessengerMod
    private let forwardVCDelegateWrapper = CalendarTestDelegate()
    #endif

    func getForwardTabVC(delegate: CalendarShareForwardDelegate) -> UIViewController? {
        // calendar demo 未注册该服务，需 podfile 中打开 messengerDependency 依赖调试
        #if MessengerMod
        let content = CalendarForwardAlertContentImp()
        let provider = CalendarForwrdAlertProvider(userResolver: resolver, content: content)
        guard let forwardService = try? resolver.resolve(assert: ForwardViewControllerService.self) else { return nil }
        forwardVCDelegateWrapper.delegate = delegate
        let vc = forwardService.getForwardVC(provider: provider, delegate: forwardVCDelegateWrapper)
        return vc
        #else
        return UIViewController()
        #endif
    }

    func changeForwardVCSelectType(vc: UIViewController, multi: Bool) {
        #if MessengerMod
        guard let vc = vc as? ForwardComponentVCType else {
            assertionFailure("only used for forwardVC")
            return
        }
        vc.isMultiSelectMode = multi
        #endif
    }

    func getForwardVCSelectedResult(vc: UIViewController) -> ForwardSelectResult {
        #if MessengerMod
        guard let vc = vc as? ForwardComponentVCType else {
            assertionFailure("only used for forwardVC")
            return ([], false)
        }
        let items = vc.currentSelectItems.compactMap { item -> CalendarMemberSeed? in
            guard !item.isPrivate else { return nil }
            switch item.type {
            case .chat:
                return .group(chatId: item.id, avatarKey: item.avatarKey)
            case .user:
                return .user(chatterId: item.id, avatarKey: item.avatarKey)
            default: return nil
            }
        }
        return (items, items.count != vc.currentSelectItems.count)
        #else
        return ([], false)
        #endif
    }
 }

#if MessengerMod
public class CalendarTestDelegate: ForwardComponentDelegate {

    weak var delegate: CalendarShareForwardDelegate?

    public func forwardVC(_ forwardVC: ForwardComponentVCType, didSelectItem: ForwardItem, isMultipleMode: Bool, addSelected: Bool) {
        if !isMultipleMode {
            guard addSelected else { return }

            guard !didSelectItem.isPrivate else {
                delegate?.didSelect(result: ([], true))
                return
            }

            var result: CalendarMemberSeed
            switch didSelectItem.type {
            case .chat: result = .group(chatId: didSelectItem.id, avatarKey: didSelectItem.avatarKey)
            case .user: result = .user(chatterId: didSelectItem.id, avatarKey: didSelectItem.avatarKey)
            default: return
            }
            delegate?.didSelect(result: ([result], false))
        } else {
            delegate?.selectedChangedInMulti(itemNum: forwardVC.currentSelectItems.count)
        }
    }

    public func confirmButtonTapped(pickerSelectedVC: UIViewController) {
        pickerSelectedVC.popSelf()
    }
}
#endif
