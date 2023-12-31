//
//  CalendarDependency.swift
//  Calendar
//
//  Created by zhu chao on 2018/8/3.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RxSwift
import RxCocoa
import RustPB
import UniverseDesignToast
import EENavigator
import LarkLocalizations
import UIKit
import LarkStorage
import LarkModel
import LarkSetting

public typealias VideoMeetingUpdatePushGetter = (_ calendarId: String, _ key: String, _ originalTime: Int64) -> Observable<VideoMeeting>
public typealias VideoMeetingStatusUpdatePushGetter = (_ uniqueId: String) -> Observable<Rust.VideoMeetingStatus>

public typealias CalendarDependencyBody = AnyObject & EENavigator.Body

/// 选人组件返回结果
///   - attendees: 人/群/邮箱
///   - departments: 部门
public typealias AttendeeSelectResult = (attendees: [EventAttendeeSeed], departments: [(id: String, name: String)])
/// 展示联系人申请 alert
public typealias ShowApplyContactAlert = () -> Void

public typealias CalendarMemberSelectResult = (members: [CalendarMemberSeed], navi: UINavigationController)

/// 依赖的接口
public protocol CalendarDependency {
    var currentUser: CurrentUserInfo { get }

    /// 获取app当前已使用内存
    func getCurrentMemoryUsageInBytes() -> CGFloat

    func jumpToSelectAndUploadImage(from: UIViewController, anchorView: UIView,
                                    uploadSuccess: @escaping (_ key: String, _ image: UIImage) -> Void)

    // MARK: Messenger
    var is12HourStyle: BehaviorRelay<Bool> { get }
    var helperCenterHost: String { get }

    /// 跳转群忙闲chatter选择页
    func jumpToFreeBusyChatterController(from: UIViewController,
                                         chatId: String,
                                         selectedChatters: [String],
                                         callbackChatters: @escaping ([String]) -> Void)

    /// 跳转个人 profile
    func jumpToProfile(chatterId: String, eventTitle: String, from: UIViewController)

    /// 跳转个人 profile
    func jumpToProfile(chatter: RustPB.Basic_V1_Chatter, eventTitle: String, from: UIViewController)

    /// present 到个人 profile
    func presentToProfile(chatterId: String, eventTitle: String, from: UIViewController)

    /// 跳转个人 profile
    func presentToProfile(chatter: Basic_V1_Chatter, eventTitle: String, from: UIViewController, style: UIModalPresentationStyle)

    /// 跳转日程转发选人界面
    func jumpToEventForwardController(from: UIViewController,
                                      eventTitle: String,
                                      duringTime: String,
                                      shareIcon: UIImage,
                                      canAddExternalUser: Bool,
                                      shouldShowHint: Bool,
                                      pickerCallBack: @escaping ([String], String?, Error?, Bool) -> Void)

    /// 跳转文本转发选人界面
    func jumpToTextForwardController(from: UIViewController,
                                     text: String,
                                     modalPresentationStyle: UIModalPresentationStyle,
                                     sentHandler: ((_ userIds: [String], _ chatIds: [String]) -> Void)?)

    func jumpToImageShareController(from: UIViewController,
                                    image: UIImage,
                                    modalPresentationStyle: UIModalPresentationStyle)

    /// 跳转日程转让选人界面
    func jumpToSearchTransferUserController(eventOrganizerId: String,
                                            from: UIViewController,
                                            doTransfer: @escaping (_ transferUserName: String, _ transferUserId: String, _ pickerController: UIViewController) -> Void)

    /// 跳转大搜界面
    func jumpToMainSearchController(from: UIViewController)

    /// 展示划词翻译界面
    func jumpToSelectTranslateController(selectString: String,
                                         fromVC: UIViewController)
    /// 跳转参与人选择界面
    func jumpToSearchAttendeeController(from: UIViewController,
                                        title: String,
                                        chatterIds: [String],
                                        chatIds: [String],
                                        needSearchOuterTenant: Bool,
                                        enableSearchingOuterTenant: Bool,
                                        callBack: @escaping ([EventAttendeeSeed]) -> Void)

    /// 跳转参与人选择界面
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
                                          callBack: @escaping (UINavigationController?, AttendeeSelectResult, ShowApplyContactAlert?) -> Void)

    /// 跳转选择日历协作者页面
    func jumpToCalendarMemberSelectorController(from: UIViewController,
                                                pickerDelegate: SearchPickerDelegate,
                                                naviConfig: (title: String, sureText: String),
                                                searchPlaceHolder: String,
                                                preSelectMembers: [(id: String, isGroup: Bool)])

    /// 跳转 chat 页面
    func jumpToChatController(from: UIViewController,
                              chatterID: String,
                              onError: @escaping () -> Void)

    /// 跳转 chat 页面
    func jumpToChatController(from: UIViewController,
                              chatID: String,
                              onError: @escaping () -> Void,
                              onLeaveMeeting: @escaping () -> Void)

    /// 跳转 申请入群 
    func jumpToJoinGroupApplyController(from: UIViewController,
                                        chatID: String,
                                        eventID: String)
    /// 跳转 chat 页面
    func presentToChatController(from: UIViewController,
                                 chatID: String,
                                 style: UIModalPresentationStyle,
                                 onError: @escaping () -> Void,
                                 onLeaveMeeting: @escaping () -> Void)

    func jumpToPersonCard(chatterID: String, from: UIViewController)

    func paseRichText(richText: RustPB.Basic_V1_RichText,
                      isShowReadStatus: Bool,
                      checkIsMe: ((_ userId: String) -> Bool)?,
                      maxLines: Int,
                      maxCharLine: Int,
                      customAttributes: [NSAttributedString.Key: Any]) -> (string: NSAttributedString, range: [NSRange: URL])?

    /// 批量回复 messages
    ///
    /// - Parameters:
    ///   - messageId: 被回复的 message 的 id
    ///   - content: 回复内容
    func replyMessages(byIds messageIds: [String], with content: String)

    // MARK: CCM
    /// 跳转附件预览
    func jumpToAttachmentPreviewController(token: String, from: UIViewController)

    func uploadEventAttachment(localPath: String,
                               fileName: String,
                               mountNodePoint: String,
                               mountPoint: String,
                               failedTip: String) -> Observable<(fileToken: String, UploadStatus)>

    func getDocComponentVC(url: URL, delegate: CalendarDocComponentAPIDelegate?) -> CalendarDocComponentAPIProtocol?

    func getThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage>

    func syncThumbnail(fileToken: String, fileType: Int, completion: @escaping (Error?) -> Void)

    /// 创建水平模板列表页
    func createTemplateHorizontalListView(frame: CGRect,
                                          params: CalendarHorizontalTemplateParams,
                                          delegate: CalendarTemplateHorizontalListViewDelegate) -> CalendarTemplateHorizontalListViewProtocol

    /// 根据模板创建文档
    /// - Parameters:
    ///   - docType: 文档类型
    ///   - docToken: 模板文档Token
    ///   - templateId: 模板ID
    ///   - titleParam: 标题参数
    ///   - result: 结果回调
    func createDocsByTemplate(docType: Int,
                              docToken: String?,
                              templateId: String?,
                              titleParam: CalendarCreateDocTitleParams?,
                              callback: ((CalendarDocsTemplateCreateResult?, Error?) -> Void)?)

    /// 获取有效会议分类模板列表
    func fetchMeetingNotesTemplates(categoryId: String, pageIndex: Int, pageSize: Int) -> Observable<[CalendarTemplateItem]>

    func showDocAdjustExternalPanel(from: UIViewController, url: String, callBack: @escaping ((Swift.Result<Void, CalendarAdjustDocPermissionError>) -> Void))

    /// 创建选择模版中心页面
    func createTemplateSelectedPage(from: UIViewController, categoryId: String, delegate: CalendarTemplateHorizontalListViewDelegate) -> UIViewController?

    /// 关联文档picker页面
    func createAssociateDocPickController(pickerDelegate: SearchPickerDelegate) -> UIViewController?

    // MARK: ByteView
    /// 新建视频会议
    func jumpToNewVideoMeeting()

    /// 加入视频会议
    func jumpToJoinVideoMeeting()

    /// 跳转 videoMeeting 设置页面
    func showVideoMeetingSetting(instanceDetails: CalendarInstanceDetails, from: UIViewController)

    /// 首次跳转 videoMeeting 设置页面
    func jumpToCreateVideoMeeting(vcSettingId: String?,
                                  from: UIViewController,
                                  callback: @escaping ((EventVCSettingResponse?, Error?) -> Void))

    /// 加入视频会议
    func joinVideoMeeting(instanceDetails: CalendarInstanceDetails, title: String)

    /// 加入面试视频会议
    func joinInterviewVideoMeeting(uniqueID: String)

    /// 退出 VC 全屏页面
    func floatingOrDismissByteViewWindow()

    /// 获取 Webinar VC Setting 页面
    func createWebinarConfigController(param: WebinarEventConfigParam) -> UIViewController

    /// 获取 webinar 日程 vc 设置二进制信息
    /// - Parameter vc: 需要传入 createWebinarConfigController 返回的 vc
    /// - Returns: 如果 vc as? 失败，会返回 nil
    func getWebinarLocalConfig(vc: UIViewController) -> CalendarWebinarConfigResult?

    /// 获取 webinar 最大参会人数上限
    func pullWebinarMaxParticipantsCount(organizerTenantId: Int64, organizerUserId: Int64, completion: @escaping (Result<Int64, Error>) -> Void)

    /// 获取是否允许发起 webinar 会议
    func pullVCQuotaHasWebinar(completion: @escaping (Result<Bool, Error>) -> Void)
    
    func getSettingJson<T: Decodable>(key: UserSettingKey, defaultValue: T) -> T
    
    func getSettingJson(key: UserSettingKey) -> [String: Any]

    func getForwardTabVC(delegate: CalendarShareForwardDelegate) -> UIViewController?

    func changeForwardVCSelectType(vc: UIViewController, multi: Bool)

    func getForwardVCSelectedResult(vc: UIViewController) -> ForwardSelectResult
}

public typealias AssociatedDocResult = (token: String, type: Int)
public protocol CalendarAssociatedDocPickerDelegate: AnyObject {
    func didSelect(result: AssociatedDocResult)
}
public protocol CalendarShareForwardDelegate: AnyObject {
    func didSelect(result: ForwardSelectResult)
    func selectedChangedInMulti(itemNum: Int)
}

public protocol CalendarDocComponentAPIProtocol: AnyObject {
    var docVC: UIViewController { get }
}

public typealias CalendarDocComponentInvokeCallBack = (([String: Any], Error?) -> Void)
public protocol CalendarDocComponentAPIDelegate: AnyObject {
    // 文档调用宿主（Calendar），获取宿主相关信息
    func onInvoke(data: [String: Any]?, callback: CalendarDocComponentInvokeCallBack?)
    
    // 文档即将关闭
    func willClose()

    // 获取sub_scene
    func getSubScene() -> String
}

public protocol CalendarTemplateHorizontalListViewProtocol: UIView {
    func start()
}

class CalendarTemplateHorizontalListEmptyView: UIView, CalendarTemplateHorizontalListViewProtocol {
    func start() {}
}

public protocol CalendarTemplateHorizontalListViewDelegate: AnyObject {
    /// 点击模板回调
    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, didClick templateId: String) -> Bool

    /// 创建文档回调
    /// - Parameters:
    ///   - result: 创建后的文档结果
    ///   - error: 错误信息
    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, onCreateDoc result: CalendarDocsTemplateCreateResult?, error: Error?)

    /// 选择模版回调
    func templateOnItemSelected(_ viewController: UIViewController, item: CalendarTemplateItem)

    func templateHorizontalListView(_ listView: CalendarTemplateHorizontalListViewProtocol, onFailedStatus: Bool)
}

/// 模板Item  (字段按需增加)
public struct CalendarTemplateItem {

    public let id: String
    public let name: String
    public let objToken: String
    public let objType: Int

    public init(id: String, name: String, objToken: String, objType: Int) {
        self.id = id
        self.name = name
        self.objToken = objToken
        self.objType = objType
    }
}

public struct CalendarHorizontalTemplateParams {
    public let itemHeight: CGFloat
    /// 模板数量
    public let pageSize: Int
    /// 模板分类ID
    public let categoryId: String
    /// 模板创建参数
    public let createDocParams: CalendarCreateDocTitleParams

    public init(itemHeight: CGFloat, pageSize: Int, categoryId: String, createDocParams: CalendarCreateDocTitleParams) {
        self.itemHeight = itemHeight
        self.pageSize = pageSize
        self.categoryId = categoryId
        self.createDocParams = createDocParams
    }
}

public struct CalendarDocsTemplateCreateResult {

    public let url: String
    public let title: String

    public init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}

/// 模板创建参数
public struct CalendarCreateDocTitleParams {
    /// 文档标题
    public let title: String?
    /// 文档标题前缀
    public let titlePrefix: String?
    /// 文档标题后缀
    public let titleSuffix: String?


    public init(title: String? = nil, titlePrefix: String? = nil, titleSuffix: String? = nil) {
        self.title = title
        self.titlePrefix = titlePrefix
        self.titleSuffix = titleSuffix
    }
}

/// 有效会议修改权限失败
public enum CalendarAdjustDocPermissionError: Error {
    case fail
    case disabled
}

public struct WebinarEventConfigParam {
    public let configJson: String?
    public let speakerCanInviteOthers: Bool
    public let speakerCanSeeOtherSpeakers: Bool
    public let audienceCanInviteOthers: Bool
    public let audienceCanSeeOtherSpeakers: Bool

    public init(configJson: String?, speakerCanInviteOthers: Bool, speakerCanSeeOtherSpeakers: Bool, audienceCanInviteOthers: Bool, audienceCanSeeOtherSpeakers: Bool) {
        self.configJson = configJson
        self.speakerCanInviteOthers = speakerCanInviteOthers
        self.speakerCanSeeOtherSpeakers = speakerCanSeeOtherSpeakers
        self.audienceCanInviteOthers = audienceCanInviteOthers
        self.audienceCanSeeOtherSpeakers = audienceCanSeeOtherSpeakers
    }
}

public struct EventVCSettingResponse {
    var vcSettingId: String

    public init(vcSettingId: String) {
        self.vcSettingId = vcSettingId
    }
}

public enum CalendarWebinarConfigResult {
    case success(WebinarEventConfigParam)
    case failure(String)
}

public enum VideoMeetingEventType: Int {
  case normal = 0
  case interview = 1
}

public protocol PSTNInfoResponse {
    var isPstnEnabled: Bool { get }         // pstn 信息是否展示
    var pstnCopyMessage: String { get }     // 复制信息
    var defaultPhoneNumber: String { get }  // 日程详情页展示
    var adminSettings: String { get }
}

// 当期用户信息
public protocol CurrentUserInfo {
    // chatter id
    var id: String { get }
    var displayName: String { get }
    var nameWithAnotherName: String { get }
    var avatarKey: String { get }
    // 是否是C端用户
    var tenantId: String { get }
    var isCustomer: Bool { get }
}

/// Chat
public protocol CalendarChat {
    typealias MeetingMessagePosition = RustPB.Basic_V1_Chat.MessagePosition.Enum
    var id: String { get }
    var isShortCut: Bool { get set }
    var isRemind: Bool { get }
    var isMember: Bool { get }
    var messagePosition: MeetingMessagePosition { get }
}

public enum CalendarRunloopDispatcherPriority {
    case high
    case low
}

public struct CalendarInstanceDetails {
    public let uniqueID: String
    public let key: String
    public let originalTime: Int64
    public let instanceStartTime: Int64
    public let instanceEndTime: Int64

    public init(
        uniqueID: String,
        key: String,
        originalTime: Int64,
        instanceStartTime: Int64,
        instanceEndTime: Int64) {
            self.uniqueID = uniqueID
            self.key = key
            self.originalTime = originalTime
            self.instanceStartTime = instanceStartTime
            self.instanceEndTime = instanceEndTime
    }
}

extension CalendarDependency {
    func presentToAttendeeProfile(calendarApi: CalendarRustAPI,
                                  attendeeCalendarID: String,
                                  eventTitle: String,
                                  style: UIModalPresentationStyle,
                                  from: UIViewController,
                                  bag: DisposeBag) {
        let presentToProfile = self.presentToProfile(chatter:eventTitle:from:style:)
        calendarApi.getChatters(calendarIDs: [attendeeCalendarID])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatterMap) in
                guard let chatter = chatterMap.values.first else {
                    CDProgressHUD.showTextHUD(hint: BundleI18n.Calendar.Calendar_Toast_LoadUserInfoFailed, on: from.view)
                    return
                }
                presentToProfile(chatter, eventTitle, from, style)
            }, onError: { (error) in
                UDToast().showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_LoadUserInfoFailed, on: from.view)
            }).disposed(by: bag)
    }

    func jumpToAttendeeProfile(calendarApi: CalendarRustAPI,
                               attendeeCalendarID: String,
                               eventTitle: String,
                               from: UIViewController,
                               bag: DisposeBag) {
        let jumpToProfile = self.jumpToProfile(chatter:eventTitle:from:)
        calendarApi.getChatters(calendarIDs: [attendeeCalendarID])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatterMap) in
                guard let chatter = chatterMap.values.first else {
                    CDProgressHUD.showTextHUD(hint: BundleI18n.Calendar.Calendar_Toast_LoadUserInfoFailed, on: from.view)
                    return
                }
                jumpToProfile(chatter, eventTitle, from)
            }, onError: { (error) in
                UDToast().showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_LoadUserInfoFailed, on: from.view)
            }).disposed(by: bag)
    }

    func jumpToProfile(userID: String,
                       from: UIViewController,
                       bag: DisposeBag,
                       calendarApi: CalendarRustAPI) {
        let jumpToProfile = self.jumpToProfile(chatter:eventTitle:from:)
        calendarApi.getChatters(userIds: [userID])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatterMap) in
                guard let chatter = chatterMap.values.first else {
                    CDProgressHUD.showTextHUD(hint: BundleI18n.Calendar.Calendar_Toast_LoadUserInfoFailed, on: from.view)
                    return
                }
                jumpToProfile(chatter, "", from)
            }, onError: { (error) in
                UDToast().showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_LoadUserInfoFailed, on: from.view)
            }).disposed(by: bag)
    }

}

extension CalendarDependency {

    /// 当前用户对应的 `LarkStorage.Space`
    public var userSpace: Space? {
        let userId = currentUser.id
        guard !userId.isEmpty else { return nil }
        return .user(id: userId)
    }

    /// 获取当前用户在日历业务对应的 Library 目录
    public func userLibraryPath() -> IsoPath {
        let space = userSpace ?? .global
        let domain = Domain.biz.calendar
        return IsoPath.in(space: space, domain: domain).build(.library)
    }

}
