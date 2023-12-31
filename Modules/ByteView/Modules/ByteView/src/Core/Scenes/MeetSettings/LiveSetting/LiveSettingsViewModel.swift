//
//  LiveSettingsViewModel.swift
//  ByteView
//
//  Created by 李凌峰 on 2020/3/24.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import RichLabel
import ByteViewNetwork
import ByteViewCommon
import ByteViewUI

enum LiveProvider: Equatable {
    case larkLive
    case byteLive
}

enum LiveSettings: Equatable {
    case privilege(LivePrivilege, [LivePrivilege: String], Bool, LiveProvider)
    case layout(LiveLayout, Bool, LiveProvider)
    case copyLink(Bool, LiveProvider)
    case enablePlayback(Bool, Bool, LiveProvider = .larkLive)
    case enableChat(Bool, Bool, LiveProvider)
    case chooseByteLive(Bool, Bool, LiveProvider)

    var liveProvider: LiveProvider {
        switch self {
        case .privilege(_, _, _, let lp):
            return lp
        case .layout(_, _, let lp):
            return lp
        case .copyLink(_, let lp):
            return lp
        case .enablePlayback(_, _, let lp):
            return lp
        case .enableChat(_, _, let lp):
            return lp
        case .chooseByteLive(_, _, let lp):
            return lp
        }
    }

    mutating func enable() {
        switch self {
        case .privilege(let arg0, let arg1, _, let arg3):
            self = .privilege(arg0, arg1, true, arg3)
        case .layout(let arg0, _, let arg2):
            self = .layout(arg0, true, arg2)
        case .copyLink(_, let arg1):
            self = .copyLink(true, arg1)
        case .enablePlayback(let arg0, _, let arg2):
            self = .enablePlayback(arg0, true, arg2)
        case .enableChat(let arg0, _, let arg2):
            self = .enableChat(arg0, true, arg2)
        case .chooseByteLive(let arg0, _, let arg2):
            self = .chooseByteLive(arg0, true, arg2)
        }
    }

    mutating func disable() {
        switch self {
        case .privilege(let arg0, let arg1, _, let arg3):
            self = .privilege(arg0, arg1, false, arg3)
        case .layout(let arg0, _, let arg2):
            self = .layout(arg0, false, arg2)
        case .copyLink(_, let arg1):
            self = .copyLink(false, arg1)
        case .enablePlayback(let arg0, _, let arg2):
            self = .enablePlayback(arg0, false, arg2)
        case .enableChat(let arg0, _, let arg2):
            self = .enableChat(arg0, false, arg2)
        case .chooseByteLive(let arg0, _, let arg2):
            self = .chooseByteLive(arg0, false, arg2)
        }
    }

    var order: Int {
        switch self {
        case .chooseByteLive:
            return 0
        case .privilege:
            return 1
        case .layout:
            return 2
        case .copyLink:
            return 3
        case .enablePlayback:
            return 4
        case .enableChat:
            return 5
        }
    }
}

protocol LiveSettingViewModelDelegate: AnyObject {
    func isLegalButtonSelected() -> Bool
    func selectLegalButton()
    func updatePickedMemberData(members: [LivePermissionMember], isFromInit: Bool)
    func configDisableLiveButton()
}

final class LiveSettingsViewModel: InMeetMeetingProvider {
    typealias DisplayStatus = PullLiveSettingResponse.DisplayStatus
    typealias LiveSettingElementV2 = PullLiveSettingResponse.LiveSettingElementV2
    typealias DisplayConditionKey = PullLiveSettingResponse.DisplayConditionKey

    enum LiveSource {
        /// 主持人发起的录制
        case host
        /// 参会人请求主持人录制，参数：请求者的 id
        case participantAskLiving(ByteviewUser)

        var action: UpdateLiveAction {
            switch self {
            case .host:
                return .start
            case .participantAskLiving:
                return .hostAccept
            }
        }
    }

    static let logger = Logger.liveSetting

    private let live: InMeetLiveViewModel
    let meeting: InMeetMeeting
    private var liveSource: LiveSource
    private var placeholderId: String?

    private let disposeBag = DisposeBag()
    private let itemsRelay: BehaviorRelay<[LiveSettingsSectionModel]>
    private var larkLiveItems: [LiveSettings] = [] {
        didSet {
            guard !isByteLive else { return }
            items = larkLiveItems
        }
    }
    private var byteLiveItems: [LiveSettings] = [] {
        didSet {
            guard isByteLive else { return }
            items = byteLiveItems
        }
    }
    private var items: [LiveSettings] = [] {
        didSet {
            let sections = items.map { item -> LiveSettingsSectionModel in
                var section = LiveSettingsSectionModel(items: [item])
                switch item {
                case .privilege:
                    section.headText = I18n.View_M_WebViewerPermissionsNew
                case .layout:
                    section.headText = I18n.View_M_WebViewingLayout
                default:
                    break
                }
                return section
            }
            itemsRelay.accept(sections)
        }
    }

    var itemsObservable: Observable<[LiveSettingsSectionModel]> {
        return itemsRelay.asObservable()
    }

    private let liveProviderStatusRelay: BehaviorRelay<LiveProviderAvailableStatus>
    var liveProviderStatusObservable: Observable<LiveProviderAvailableStatus> {
        return liveProviderStatusRelay.asObservable()
    }
    var liveProviderStatus: LiveProviderAvailableStatus {
        return liveProviderStatusRelay.value
    }

    var isByteLive: Bool {
        return self.liveProviderStatus.isProviderByteLive
    }

    var selectedMembers: [LivePermissionMember]?
    var memberIdentityData: LivePermissionMemberResponse?
    var byteLiveMemberData: GetLivePermissionMembersByteLiveResponse?
    weak var delegate: LiveSettingViewModelDelegate?

    var needReload: Bool = true
    var isSettingPlaybackEnable: Bool?
    var displayConditionMap: [DisplayConditionKey: LiveSettingElementV2]?
    private var _externalDisplayStatus: DisplayStatus?
    var externalDisplayStatus: DisplayStatus? {
        get {
            if isByteLive {
                return .normal
            } else {
                return _externalDisplayStatus
            }
        }
        set {
            _externalDisplayStatus = newValue
        }
    }
    private var _disableUserKey: String?
    var disableUserKey: String? {
        get {
            if isByteLive {
                return nil
            } else {
                return _disableUserKey
            }
        }
        set {
            _disableUserKey = newValue
        }
    }
    private var _disableGroupKey: String?
    var disableGroupKey: String? {
        get {
            if isByteLive {
                return nil
            } else {
                return _disableGroupKey
            }
        }
        set {
            _disableGroupKey = newValue
        }
    }
    var byteLiveConfig: ByteLiveConfigForMeeting?
    private var httpClient: HttpClient { meeting.httpClient }

    init(meeting: InMeetMeeting, live: InMeetLiveViewModel, liveProviderStatus: LiveProviderAvailableStatus, liveSource: LiveSource) {
        self.live = live
        self.meeting = meeting
        self.liveProviderStatusRelay = BehaviorRelay(value: liveProviderStatus)
        self.liveSource = liveSource
        self.byteLiveItems = []
        self.larkLiveItems = []
        self.items = []
        self.itemsRelay = BehaviorRelay(value: items.map { LiveSettingsSectionModel(items: [$0]) })

        live.liveMeetingDataObservable
            .filter { $0.type == .participantRequest }
            .subscribe(onNext: { [weak self] (liveData) in
                self?.liveSource = .participantAskLiving(liveData.requester)
            })
            .disposed(by: disposeBag)

        live.liveInfoObservable
            .map { liveInfo -> Bool in
                return liveInfo?.isLiving ?? false
            }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.configOrUpdateChooseByteLiveAction()
            })
            .disposed(by: disposeBag)

        configItems()
    }
    // disable-lint: long function
    private func configLarkLiveItems() {
        live.liveInfoObservable
            .subscribe(onNext: { liveInfo in
                guard let liveInfo = liveInfo else { return }
                let info = """
                isLiving: \(liveInfo.isLiving), \
                privilege: \(liveInfo.privilege) defaultPrivilege: \(liveInfo.defaultPrivilege), \
                enableLiveComment: \(liveInfo.enableLiveComment), \
                enablePlayBack: \(liveInfo.enablePlayback), \
                livePermissionMemberChanged \(liveInfo.livePermissionMemberChanged), \
                layoutStyle: \(liveInfo.layoutStyle) defaultLayoutStyle: \(liveInfo.defaultLayoutStyle), \
                liveURL: \(liveInfo.liveURL)
                """
                LiveSettingsViewModel.logger.debug(info)
            })
            .disposed(by: disposeBag)

        live.liveInfoObservable
            .map { liveInfo -> LivePrivilege? in
                return liveInfo?.privilege
            }
            .flatMap({ [weak self] (privilege) -> Observable<(LivePrivilege?, PullLiveSettingResponse)> in
                guard let self = self else { return .empty() }
                if !self.liveProviderStatus.isLarkLiveAvailable {
                    return .empty()
                }
                return self.fetchLiveSettings().asObservable().map { (privilege, $0) }
            })
            .distinctUntilChanged({ (pre, post) -> Bool in
                return pre != post
            })
            .subscribe(onNext: { [weak self] privilege, settingResp in
                var disablePrivileges: [LivePrivilege: String] = [:]
                if settingResp.privilegeScopeSetting.scopePublic.isDisabled {
                    disablePrivileges[.anonymous] = settingResp.privilegeScopeSetting.scopePublic.disableHoverKey
                }
                if settingResp.privilegeScopeSetting.scopeTenant.isDisabled {
                    disablePrivileges[.employee] = settingResp.privilegeScopeSetting.scopeTenant.disableHoverKey
                }
                if settingResp.privilegeScopeSetting.scopeCustom.isDisabled {
                    disablePrivileges[.custom] = settingResp.privilegeScopeSetting.scopeCustom.disableHoverKey
                }
                self?.replaceOrInsertItem(.privilege(privilege ?? .unknown, disablePrivileges, true, .larkLive))

                self?.displayConditionMap = settingResp.displayConditionMap
                self?.configPlayBackStatus(displayConditionMap: settingResp.displayConditionMap)
                self?.configLiveStatus(displayConditionMap: settingResp.displayConditionMap)
                self?.configLiveExternalStatus(displayConditionMap: settingResp.displayConditionMap)
            })
            .disposed(by: disposeBag)

        live.liveInfoObservable
            .map { liveInfo -> Bool? in
                return liveInfo?.enableLiveComment
        }
        .distinctUntilChanged()
        .subscribe(onNext: { [weak self] enable in
            guard let enable = enable else { return }
            self?.replaceOrInsertItem(.enableChat(enable, true, .larkLive))
        })
            .disposed(by: disposeBag)

        live.liveInfoObservable
            .map { liveInfo -> LiveLayout? in
                if liveInfo?.isLiving == true {
                    return liveInfo?.layoutStyle
                } else {
                    return liveInfo?.defaultLayoutStyle
                }
        }
        .distinctUntilChanged()
        .subscribe(onNext: { [weak self] layoutStyle in
            guard let layoutStyle = layoutStyle else { return }
            self?.replaceOrInsertItem(.layout(layoutStyle, true, .larkLive))
        })
            .disposed(by: disposeBag)

        live.liveInfoObservable
            .map { liveInfo -> Bool? in
                return liveInfo?.enablePlayback
        }
        .distinctUntilChanged()
        .subscribe(onNext: { [weak self] enable in
        guard let enable = enable else { return }
            self?.isSettingPlaybackEnable = enable
            if let displayConditionMap = self?.displayConditionMap {
                self?.configPlayBackStatus(displayConditionMap: displayConditionMap)
            }
        })
            .disposed(by: disposeBag)

        live.liveInfoObservable
            .map { liveInfo -> Bool? in
                return liveInfo?.livePermissionMemberChanged
        }
        .distinctUntilChanged()
        .subscribe(onNext: { [weak self] livePermissionMemberChanged in
            guard let livePermissionMemberChanged = livePermissionMemberChanged else { return }
            if livePermissionMemberChanged {
                if let needReLoad = self?.needReload, needReLoad {
                    self?.getLivePermissionMembers()
                } else {
                    self?.needReload = true
                }
            }
        })
            .disposed(by: disposeBag)

        getLivePermissionMembers(false)

        self.configOrUpdateChooseByteLiveAction(from: .larkLive)
        self.replaceOrInsertItem(.copyLink(true, .larkLive))
    }
    // enable-lint: long function

    private func fetchLiveSettings() -> Single<PullLiveSettingResponse> {
        let httpClient = self.httpClient
        let request = PullLiveSettingRequest(meetingId: meeting.meetingId)
        return RxTransform.single {
            httpClient.getResponse(request, completion: $0)
        }.do(onSuccess: { Self.logger.info("fetch VideoChatPullLiveSetting success: \($0)") },
             onError: { Self.logger.error("fetch VideoChatPullLiveSetting error: \($0)") })
    }

    private func getLivePermissionMembers (_ isHandleError: Bool = true) {
        let request = LivePermissionMemberRequest(meetingId: meeting.meetingId, liveId: placeholderId)
        var options = NetworkRequestOptions()
        options.shouldHandleError = isHandleError
        meeting.httpClient.getResponse(request, options: options) { [weak self] result in
            switch result {
            case .success(let memberData):
                self?.memberIdentityData = memberData
                DispatchQueue.main.async {
                    self?.delegate?.updatePickedMemberData(members: memberData.members, isFromInit: true)
                }
                Self.logger.info("getLivePermissionMembers success: \(memberData)")
            case .failure(let error):
                Self.logger.error("getLivePermissionMembers error: \(error)")
            }
        }
    }

    private func replaceOrInsertItem(_ item: LiveSettings) {
        var items = self.larkLiveItems
        if item.liveProvider == .byteLive {
            items = self.byteLiveItems
        }

        var playBackIndex: Int?
        if let index = items.firstIndex(where: { $0.order == item.order }) {
            if displayConditionMap?[.conditionEnablePlayback]?.displayStatus == .hidden, item.order == 3 {
                playBackIndex = index
            }
                items[index] = item
        } else {
            items.append(item)
            items.sort { $0.order < $1.order }
        }

        if let playBackIndex = playBackIndex {
            items.remove(at: playBackIndex)
        }

        if item.liveProvider == .byteLive {
            self.byteLiveItems = items
        } else {
            self.larkLiveItems = items
        }
    }

    func didSelect(_ item: LiveSettings) {
        switch item {
        case .copyLink:
            copyLink()
        case .privilege:
            break
        case .layout:
            break
        case .enableChat:
            break
        case .enablePlayback:
            checkNeedToastUnableChangeInLiving()
        case .chooseByteLive:
            break
        }
    }

    func refuseLiveIfNeeded() {
        if case .participantAskLiving(let requester) = liveSource {
            live.updateLiveAction(action: .hostRefuse,
                                     user: requester,
                                     voteID: nil,
                                     privilege: nil,
                                     enableChat: nil,
                                     enablePlayback: nil,
                                     layout: nil,
                                     member: nil)
                .subscribe(onCompleted: nil, onError: nil)
                .disposed(by: disposeBag)
        }
    }

    func toastByI18Key(_ errToastString: String) {
        httpClient.i18n.get(errToastString) { [weak self] result in
            if self != nil, let s = result.value {
                Util.runInMainThread {
                    Toast.show(s)
                }
            }
        }
    }

    func configLiveExternalStatus(displayConditionMap: [DisplayConditionKey: LiveSettingElementV2]?) {
        self.externalDisplayStatus = displayConditionMap?[.conditionEnableLiveExternal]?.displayStatus
        switch externalDisplayStatus {
        case .disabled:
            if let userKey = displayConditionMap?[.conditionEnableLiveExternal]?.i18nKeyMap[.disablePickerExternalUserKey],
               let groupKey = displayConditionMap?[.conditionEnableLiveExternal]?.i18nKeyMap[.disablePickerExternalGroupKey] {
                httpClient.i18n.get([userKey, groupKey]) { [weak self] result in
                    guard let self = self, let map = result.value else { return }
                    if let s = map[userKey] {
                        self.disableUserKey = s
                    }
                    if let s = map[groupKey] {
                        self.disableGroupKey = s
                    }
                }
            }
        default: break
        }
    }
}

extension LiveSettingsViewModel {

    private func copyLink() {
        LiveSettingTracks.trackCopyLink(isLiving: live.isLiving, liveId: live.liveInfo?.liveID)
        LiveSettingTracksV2.tracLivekCopyLink(liveId: live.liveInfo?.liveID, liveStatus: live.liveInfo?.isLiving, liveSessionId: live.liveInfo?.liveSessionID)
        if self.isByteLive {
            guard let url = self.byteLiveConfig?.liveUrl else {
                showCopyLiveURLError()
                return
            }
            if self.service.security.copy(url, token: .liveCopyLink, shouldImmunity: true) {
                Toast.show(I18n.View_M_LivestreamingLinkCopiedNew)
            }
        } else {
            guard let url = live.liveInfo?.liveURL,
                !url.isEmpty else {
                    showCopyLiveURLError()
                    return
            }
            if self.service.security.copy(url, token: .liveCopyLink, shouldImmunity: true) {
                Toast.show(I18n.View_M_LivestreamingLinkCopiedNew)
            }
        }
    }

    func showCopyLiveURLError() {
        Toast.show(I18n.View_M_CopyLivestreamLinkErrorTryAgainLaterNew, type: .error)
    }

}

extension LiveSettingsViewModel {
    func trackSettingStatus () {
        LiveSettingTracksV2.trackSettingViewStatus(liveId: live.liveInfo?.liveID, liveStatus: live.liveInfo?.isLiving, liveSessionId: live.liveInfo?.liveSessionID )
    }
}

extension LiveSettingsViewModel {

    private var selectedPrivilege: LivePrivilege? {
        for item in items {
            if case .privilege(let p, _, _, _) = item {
                return p
            }
        }
        return nil
    }

    private var disabledPrivileges: [LivePrivilege: String] {
        for item in items {
            if case .privilege(_, let ps, _, _) = item {
                return ps
            }
        }
        return [:]
    }

    func selectPrivilege(_ privilege: LivePrivilege, _ members: [LivePermissionMember]? = nil) {
        let oldPrivilege = selectedPrivilege
        guard privilege != oldPrivilege || privilege == .custom else { return }
        selectedMembers = members
        LiveSettingTracks.trackSelectPrivilege(privilege, isLiving: live.isLiving, liveId: live.liveInfo?.liveID)
        // 预设设置成功，同步数据与视图一致
        replaceOrInsertItem(.privilege(privilege, disabledPrivileges, true, isByteLive ? .byteLive : .larkLive))
        toastPrivilegeSelected(privilege: privilege)

        live.updateLiveAction(action: .liveSetting,
                                 user: nil,
                                 voteID: nil,
                                 privilege: privilege,
                                 enableChat: nil,
                                 enablePlayback: nil,
                                 layout: nil,
                                 member: members)
            .subscribe(onError: { [weak self] _ in
                guard let self = self else { return }
                // 重置当前权限
                if let privilege = oldPrivilege {
                    self.replaceOrInsertItem(.privilege(privilege, self.disabledPrivileges, true, self.isByteLive ? .byteLive : .larkLive))
                }
            })
            .disposed(by: disposeBag)
    }

    func toastPrivilegeSelected(privilege: LivePrivilege) {
        switch privilege {
        case .employee:
            Toast.show(I18n.View_MV_OrgViewerThisLive_Toast)
        case .anonymous:
            Toast.show(I18n.View_MV_AllViewerThisLive_Toast)
        default:
            break
        }
    }

    func configMemberData(_ members: [LivePermissionMember]?) -> [LivePermissionMember] {
        var membersData: [LivePermissionMember] = []
        guard let members = members else { return [] }
        for item in members {
            switch item.memberType {
            case .memberTypeDepartment:
                if item.memberName != nil {
                    membersData.append(LivePermissionMember(memberId: item.memberId, memberType: .memberTypeDepartment, avatarUrl: nil, isExternal: nil, isChatManager: nil, isUserInChat: nil, userCount: 0, memberName: item.memberName))
                }
            case .memberTypeChat:
                if item.memberName != nil, let count = item.userCount, let key = item.avatarUrl {
                    membersData.append(LivePermissionMember(memberId: item.memberId, memberType: .memberTypeChat, avatarUrl: key, isExternal: nil, isChatManager: nil, isUserInChat: nil, userCount: count, memberName: item.memberName))
                }
            case .memberTypeUser:
                if item.memberName != nil, let count = item.userCount, let key = item.avatarUrl {
                    membersData.append(LivePermissionMember(memberId: item.memberId, memberType: .memberTypeUser, avatarUrl: key, isExternal: nil, isChatManager: nil, isUserInChat: nil, userCount: count, memberName: item.memberName))
                }
            default:
                break
            }
        }
        return membersData
    }


    func trackPickerClicked() {
        LiveSettingTracksV2.trackLiveMemberManageClick(liveId: live.liveInfo?.liveID, liveStatus: live.liveInfo?.isLiving, liveSessionId: live.liveInfo?.liveSessionID)
    }

    func checkPrivilegeChanged(privilege: LivePrivilege) -> Bool {
        if let selectedPrivilege = selectedPrivilege {
            return !(selectedPrivilege == privilege)
        }
        return true
    }
}

extension LiveSettingsViewModel {

    private var selectedLayout: LiveLayout? {
        for item in items {
            if case .layout(let style, _, _) = item {
                return style
            }
        }
        return nil
    }

    func selectLayout(_ layout: LiveLayout) {
        let oldLayout = selectedLayout
        guard layout != oldLayout else { return }
        LiveSettingTracks.trackSelectLayout(layout, isLiving: live.isLiving, liveId: live.liveInfo?.liveID)
        // 预设设置成功，同步数据与视图一致
        replaceOrInsertItem(.layout(layout, true, isByteLive ? .byteLive : .larkLive))
        toastLayoutSelected(layout: layout)

        live.updateLiveAction(action: .liveSetting,
                                 user: nil,
                                 voteID: nil,
                                 privilege: nil,
                                 enableChat: nil,
                                 enablePlayback: nil,
                                 layout: layout,
                                 member: nil)
            .subscribe(onError: { [weak self] _ in
                guard let self = self else { return }
                // 重置当前样式
                if let layout = oldLayout {
                    self.replaceOrInsertItem(.layout(layout, true, self.isByteLive ? .byteLive : .larkLive))
                }
            })
            .disposed(by: disposeBag)
    }

    func toastLayoutSelected(layout: LiveLayout) {
        switch layout {
        case .list:
            Toast.show(I18n.View_MV_SideViewBar_Toast)
        case .gallery:
            Toast.show(I18n.View_MV_GalleryView_Toast)
        case .simple:
            Toast.show(I18n.View_MV_FullScreen_Toast)
        case .speaker:
            Toast.show(I18n.View_M_SpeakerViewSelected_Toast)
        default:
            break
        }
    }
}

extension LiveSettingsViewModel {

    private var isLiveChatEnabled: Bool? {
        for item in items {
            if case .enableChat(let enable, _, _) = item {
                return enable
            }
        }
        return nil
    }

    var liveChatEnableAction: CompletableAction<Bool> {
        return CompletableAction<Bool> { [weak self] enable in
            guard let self = self else { return .empty() }
            LiveSettingTracks.trackLiveChatEnable(enable, isLiving: self.live.isLiving,
                                                  liveId: self.live.liveInfo?.liveID)
            self.toastEnableChat(enable: enable)
            self.live.updateLiveAction(action: .liveSetting,
                                          user: nil,
                                          voteID: nil,
                                          privilege: nil,
                                          enableChat: enable,
                                          enablePlayback: nil,
                                          layout: nil,
                                          member: nil)
            .subscribe(onError: { [weak self] _ in
                guard let self = self else { return }
                // 重置当前状态
                self.replaceOrInsertItem(.enableChat(!enable, true, self.isByteLive ? .byteLive : .larkLive))
            })
            .disposed(by: self.disposeBag)
            return .empty()
        }
    }

    func toastEnableChat(enable: Bool) {
        if enable {
            Toast.show(I18n.View_MV_ViewerInteract_Toast)
        } else {
            Toast.show(I18n.View_MV_ViewerInteractOff_Toast)
        }
    }
}

extension LiveSettingsViewModel {

    private var isPlaybackEnabled: Bool? {
        for item in items {
            if case .enablePlayback(let enable, !self.live.isLiving, _) = item {
                return (enable)
            }
        }
        return nil
    }

    var livePlaybackEnableAction: CompletableAction<Bool> {
        return CompletableAction<Bool> { [weak self] enable in
            guard let self = self else { return .empty() }

            self.toastEnablePlayback(enable: enable)

            LiveSettingTracks.trackPlaybackEnable(enable, isLiving: self.live.isLiving, liveId: self.live.liveInfo?.liveID)
            self.live.updateLiveAction(action: .liveSetting,
                                          user: nil,
                                          voteID: nil,
                                          privilege: nil,
                                          enableChat: nil,
                                          enablePlayback: enable,
                                          layout: nil,
                                          member: nil)
                .subscribe(onError: { [weak self] _ in
                        // 重置当前状态
                        if let enable = self?.live.liveInfo?.enablePlayback {
                            self?.replaceOrInsertItem(.enablePlayback(enable, !(self?.live.isLiving ?? false)))
                        }
                })
                .disposed(by: self.disposeBag)
            return .empty()
        }
    }

    func toastEnablePlayback(enable: Bool) {
        if enable {
            Toast.show(I18n.View_MV_SaveReplayOn_Toast)
        } else {
            Toast.show(I18n.View_MV_SaveReplayOff_Toast)
        }
    }

    func checkNeedToastUnableChangeInLiving() {
        if displayConditionMap?[.conditionEnablePlayback]?.displayStatus == .disabled {
            if let errToastString = displayConditionMap?[.conditionEnablePlayback]?.i18nKeyMap[.disablePlaybackKey] {
                toastByI18Key(errToastString)
            }
            return
        }

        if live.isLiving {
            Toast.show(I18n.View_MV_LiveCantChange_Tooltip)
        }
    }

    func configPlayBackStatus(displayConditionMap: [DisplayConditionKey: LiveSettingElementV2]?) {
        switch displayConditionMap?[.conditionEnablePlayback]?.displayStatus {
        case .normal:
            replaceOrInsertItem(.enablePlayback(self.isSettingPlaybackEnable ?? true, !self.live.isLiving))
        case .disabled:
            replaceOrInsertItem(.enablePlayback(self.isSettingPlaybackEnable ?? false, false))
        default: break
        }
    }
}

extension LiveSettingsViewModel {
    var chooseByteLiveAction: CompletableAction<Bool> {
        return CompletableAction<Bool> { [weak self] isByteLive in
            guard let self = self else { return .empty() }
            if let isLiving = self.live.liveInfo?.isLiving, isLiving {
                // 重置当前状态
                self.configOrUpdateChooseByteLiveAction()
                return .empty()
            }
            if isByteLive && !self.liveProviderStatus.isByteLiveAvailable {
                if let role = self.liveProviderStatus.response?.userInfo.role {
                    LiveSettingUnavailableAlert
                        .unavailableAlert(type: self.liveProviderStatus.byteLiveUnAvailableType, role: role)
                        .leftHandler({ [weak self] _ in
                            self?.configOrUpdateChooseByteLiveAction()
                        })
                        .rightHandler({ [weak self] _ in
                            guard let self = self else { return }
                            self.configOrUpdateChooseByteLiveAction()
                            self.live.showByteLiveAppIfNeeded()
                            self.live.showByteLiveBotAndSendMessageIfNeeded()
                        })
                        .show()
                } else {
                    self.configOrUpdateChooseByteLiveAction()
                }
                return .empty()
            }
            self.switchChooseByteLiveItem(isByteLive)
            self.disableAllItems()
            self.delegate?.configDisableLiveButton()

            let newLiveBrand: LiveBrand = isByteLive ? .byteLive : .larkLive
            LiveSettingTracks.trackSwitchLiveBrand(isLiving: self.live.isLiving, liveId: self.live.liveInfo?.liveID, newLiveBrand: newLiveBrand)
            let request = VideoChatSwitchLiveBrandRequest(meetingId: self.meeting.meetingId, switchTo: newLiveBrand)
            let httpClient = self.meeting.httpClient
            httpClient.getResponse(request) { [weak self] result in
                Util.runInMainThread {
                    guard let self = self else { return }
                    self.enableAllItems()
                    switch result {
                    case .success(let response):
                        Self.logger.info("VideoChatSwitchLiveBrandRequest success: \(response)")
                        let liveProviderStatus = self.liveProviderStatus
                        liveProviderStatus.isProviderByteLive = !liveProviderStatus.isProviderByteLive
                        self.liveProviderStatusRelay.accept(liveProviderStatus)
                        self.updateItems(response)
                        self.showSwitchSuccessToast()
                    case .failure(let error):
                        Self.logger.error("VideoChatSwitchLiveBrandRequest error: \(error)")
                        // 重置当前状态
                        self.configOrUpdateChooseByteLiveAction()
                    }
                }
            }
            return .empty()
        }
    }

    func configOrUpdateChooseByteLiveAction(from: LiveProvider? = nil) {
        guard liveProviderStatus.isLarkLiveAvailable else { return }
        guard let response = liveProviderStatus.response else { return }
        guard response.byteLiveInfo.hasByteLive else { return }

        let isLiving = self.live.liveInfo?.isLiving ?? false
        var liveProvider: LiveProvider = isByteLive ? .byteLive : .larkLive
        if let provider = from {
            liveProvider = provider
        }
        let isCreated = response.liveSettings.liveHistory == .createAndHasStarted
        let hasByteLive = liveProviderStatus.response?.byteLiveInfo.hasByteLive ?? false
        let enable = !isLiving && !isCreated && hasByteLive
        self.replaceOrInsertItem(.chooseByteLive(isByteLive, enable, liveProvider))
    }

    func showSwitchSuccessToast() {
        if self.isByteLive {
            Toast.show(I18n.View_MV_LiveSwitchEnterpriseLive)
        } else {
            Toast.show(I18n.View_MV_LiveSwitchApp(Util.appName))
        }
    }

    func switchChooseByteLiveItem(_ isByteLive: Bool) {
        for (index, item) in larkLiveItems.enumerated() {
            switch item {
            case .chooseByteLive(_, let arg1, let arg2):
                larkLiveItems[index] = .chooseByteLive(isByteLive, arg1, arg2)
            default:
                break
            }
        }
        for (index, item) in byteLiveItems.enumerated() {
            switch item {
            case .chooseByteLive(_, let arg1, let arg2):
                byteLiveItems[index] = .chooseByteLive(isByteLive, arg1, arg2)
            default:
                break
            }
        }
    }

    func disableAllItems() {
        byteLiveItems = byteLiveItems.map({
            var item = $0
            item.disable()
            return item
        })
        larkLiveItems = larkLiveItems.map({
            var item = $0
            item.disable()
            return item
        })
    }

    func enableAllItems() {
        byteLiveItems = byteLiveItems.map({
            var item = $0
            item.enable()
            return item
        })
        larkLiveItems = larkLiveItems.map({
            var item = $0
            item.enable()
            return item
        })
    }
}

extension LiveSettingsViewModel {

    var liveButtonAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] in
            guard let `self` = self else { return .empty() }
            LiveSettingTracksV2.trackClickLiveButton(isLiving: self.live.isLiving,
                                                     isLiveChatEnabled: self.isLiveChatEnabled,
                                                     selectedLayout: self.selectedLayout,
                                                     selectedPrivilege: self.selectedPrivilege,
                                                     brand: self.isByteLive ? .byteLive : .larkLive,
                                                     liveId: self.live.liveInfo?.liveID,
                                                     liveSessionId: self.live.liveInfo?.liveSessionID)
            if self.isByteLive {
                guard self.liveProviderStatus.isByteLiveCreatorSameWithUser else { return .empty() }
                if self.live.isLiving {
                    self.stopLivestreaming()
                } else {
                    if self.delegate?.isLegalButtonSelected() ?? false {
                        self.startLivestreaming()
                    } else {
                        self.showLegalAlertController()
                    }
                }
            } else {
                /// admin关闭直播功能
                if self.displayConditionMap?[.conditionEnableLive]?.displayStatus == .disabled {
                    if let errToastString = self.displayConditionMap?[.conditionEnableLive]?.i18nKeyMap[.disableStartLiveKey] {
                        self.toastByI18Key(errToastString)
                    }
                    self.router.dismissTopMost()
                    return .empty()
                }

                if self.live.isLiving {
                    self.stopLivestreaming()
                } else {
                    self.startLivestreaming()
                }
            }
            return .empty()
        })
    }

    var isLiving: Bool {
        return live.isLiving
    }

    var isLiveObserable: Observable<Bool> {
        return live.isLiveObservable
        .distinctUntilChanged()
    }

    var needDismissObservable: Observable<Bool> {
        return isLiveObserable
            .flatMap { [weak self] inLive -> Observable<Bool> in
                guard let `self` = self, !inLive else {
                    return .just(false)
                }
                return self.isLiveObserable
                    .skip(1)
                    .map { _ in true }
        }
    }

    var keyDeletedObservable: Observable<Bool> {
        return isLiveObserable
            .skip(1)
            .map({ !$0 })
            .distinctUntilChanged()
    }

    private func showLegalAlertController() {
        let linkText = LinkTextParser.parsedLinkText(from: I18n.View_MV_PleaseAgreeToSplice)
        let linkHandler: (Int, LinkComponent) -> Void = { _, _ in
            guard let urlString = self.liveProviderStatus.response?.byteLiveInfo.byteLivePrivacyPolicyUrl else { return }
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
        ByteViewDialog.Builder()
            .linkText(linkText, handler: linkHandler)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_Agree)
            .rightHandler { [weak self] _ in
                self?.delegate?.selectLegalButton()
            }
            .show()
    }

    private func startLivestreaming() {
        LiveSettingTracks.trackStartLiveStreaming(isLiving: live.isLiving,
                                                  liveId: live.liveInfo?.liveID,
                                                  isLiveChatEnabled: isLiveChatEnabled,
                                                  selectedLayout: selectedLayout,
                                                  selectedPrivilege: selectedPrivilege,
                                                  brand: self.isByteLive ? .byteLive : .larkLive)
        live.updateLiveAction(action: liveSource.action,
                                 user: nil,
                                 voteID: nil,
                                 privilege: selectedPrivilege,
                                 enableChat: isLiveChatEnabled,
                                 enablePlayback: isPlaybackEnabled,
                                 layout: selectedLayout,
                                 member: isByteLive ? selectedMembers : nil)
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] _ in
                self?.router.dismissTopMost()
            })
            .disposed(by: disposeBag)
        Self.logger.info("Manage live: true")
    }

    private func stopLivestreaming() {
        ByteViewDialog.Builder()
            .id(.stopLive)
            .colorTheme(.redLight)
            .title(I18n.View_M_StopLivestreamingQuestionNew)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                LiveSettingTracks.trackStopLiveAlert(isConfirm: false)
                LiveSettingTracksV2.trackClickStopLiveConfirmAlert(isConfirm: false)
            })
            .rightTitle(I18n.View_G_StopButton)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                LiveSettingTracks.trackStopLiveAlert(isConfirm: true)
                LiveSettingTracksV2.trackClickStopLiveConfirmAlert(isConfirm: true)
                self.live.updateLiveAction(action: .stop,
                                              user: nil,
                                              voteID: nil,
                                              privilege: nil,
                                              enableChat: nil,
                                              enablePlayback: nil,
                                              layout: nil,
                                              member: nil)
                    .observeOn(MainScheduler.instance)
                    .subscribe({ [weak self] _ in
                        self?.router.dismissTopMost()
                    })
                    .disposed(by: self.disposeBag)
                Self.logger.info("Manage live: false")
            })
            .show { [weak self] in
                weak var weakAlert = $0
                let disposable = Disposables.create {
                    weakAlert?.dismiss()
                }
                self?.disposeBag.insert(disposable)
            }
        LiveSettingTracks.trackStopLivestreaming(liveId: self.live.liveInfo?.liveID)
        LiveSettingTracksV2.trackStopLiveConfirmAlertView()
    }

    func configLiveStatus(displayConditionMap: [DisplayConditionKey: LiveSettingElementV2]?) {
        switch displayConditionMap?[.conditionEnableLive]?.displayStatus {
        case .disabled:
            Util.runInMainThread {
                self.delegate?.configDisableLiveButton()
            }
        default: break
        }
    }
}

extension LiveSettingsViewModel {
    func fetchLivePolicy(completion: @escaping (Result<([LKTextLink], NSAttributedString), Error>) -> Void) {
        let meetingType = meeting.type
        let isFeishuBrand = meeting.setting.isFeishuBrand
        let livePolicyUrl = meeting.setting.clientDynamicLink.livePolicyUrl
        let key = "fetchLivePolicyMega|\(meetingType.rawValue)"
        if let megaI18n = HttpCache.shared.read(key: key, type: MegaI18n.self) {
            completion(.success(megaI18n.transformLivePolicy(livePolicyUrl: livePolicyUrl)))
        } else {
            httpClient.getResponse(FetchLivePolicyRequest()) { result in
                switch result {
                case .success(let resp):
                    let megaI18n: MegaI18n
                    if !isFeishuBrand {
                        switch meetingType {
                        case .call:
                            megaI18n = resp.policyOverseaForCallPc
                        case .meet:
                            megaI18n = resp.policyOverseaForMeetingPc
                        default:
                            completion(.failure(NetworkError.unsupportedType))
                            return
                        }
                    } else {
                        megaI18n = resp.policyWithoutSetting
                    }
                    HttpCache.shared.write(key: key, value: megaI18n)
                    completion(.success(megaI18n.transformLivePolicy(livePolicyUrl: livePolicyUrl)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

private extension MegaI18n {
    func transformLivePolicy(livePolicyUrl: String) -> ([LKTextLink], NSAttributedString) {
        let linkText = LinkTextParser.parsedLinkText(from: BundleI18n.ByteView.View_G_ReadLivestreamingTermsOfServiceThenAgree())
        var links: [LKTextLink] = []
        let linkFont = VCFontConfig.tinyAssist.font
        for component in linkText.components {
            var link = LKTextLink(range: component.range, type: .link,
                                  attributes: [.foregroundColor: UIColor.ud.primaryContentDefault, .font: linkFont],
                                  activeAttributes: [:])
            link.linkTapBlock = { (_, _) in
                if livePolicyUrl.isEmpty {
                    guard let livePolicyUrl = self.data["live_policy_link"]?.payload, let url = URL(string: livePolicyUrl) else { return }
                    UIApplication.shared.open(url)
                } else {
                    guard let url = URL(string: livePolicyUrl) else { return }
                    UIApplication.shared.open(url)
                }
            }
            links.append(link)
        }
        let attributedString = NSAttributedString(string: linkText.result, config: .tinyAssist, alignment: .center, textColor: UIColor.ud.textPlaceholder)
        return (links, attributedString)
    }
}

extension LiveSettingsViewModel {

    func fetchByteLiveSettings() -> Single<VideoChatPullLiveSettingByteLiveResponse> {
        return RxTransform.single {
            let request = VideoChatPullLiveSettingByteLiveRequest(meetingId: self.meeting.meetingId)
            let httpClient = self.meeting.httpClient
            httpClient.getResponse(request, completion: $0)
        }.do(onSuccess: { Self.logger.info("fetchByteLiveSettings success: \($0)") },
             onError: { Self.logger.error("fetchByteLiveSettings error: \($0)") })
    }

    private func getLivePermissionMembersByteLive() {
        let request = GetLivePermissionMembersByteLiveRequest(meetingId: meeting.meetingId)
        meeting.httpClient.getResponse(request) { [weak self] result in
            switch result {
            case .success(var memberData):
                memberData.members = memberData.members.filter {
                    return $0.source == .lark
                }
                self?.byteLiveMemberData = memberData
                DispatchQueue.main.async {
                    self?.delegate?.updatePickedMemberData(members: memberData.members.map({ $0.larkMember() }), isFromInit: true)
                }
                Self.logger.info("getLivePermissionMembersByteLive success: \(memberData)")
            case .failure(let error):
                Self.logger.error("getLivePermissionMembersByteLive error: \(error)")
            }
        }
    }

    func configByteLiveItems() {
        fetchByteLiveSettings().subscribe(onSuccess: { [weak self] response in
            guard let self = self else { return }
            Util.runInMainThread {
                self.configByteLiveItems(config: response.byteLiveConfig)
            }
        })
        .disposed(by: disposeBag)

        getLivePermissionMembersByteLive()
    }

    func configByteLiveItems(config: ByteLiveConfigForMeeting) {
        let enable = liveProviderStatus.isByteLiveCreatorSameWithUser

        byteLiveConfig = config
        byteLiveItems = []

        replaceOrInsertItem(.privilege(config.livePermission.livePrivilege, [.other: ""], enable, .byteLive))
        replaceOrInsertItem(.layout(config.layoutTypeSetting, enable, .byteLive))
        replaceOrInsertItem(.copyLink(true, .byteLive))
        replaceOrInsertItem(.enableChat(config.enableLiveComment, enable, .byteLive))
        configOrUpdateChooseByteLiveAction(from: .byteLive)

        if !enable {
            delegate?.configDisableLiveButton()
        }
    }

    func configItems() {
        if isByteLive {
            configByteLiveItems()
        } else {
            configLarkLiveItems()
        }
    }

    func updateItems(_ request: VideoChatSwitchLiveBrandResponse) {
        selectedMembers = nil

        if isByteLive {
            configByteLiveItems(config: request.byteLiveConfig)
            getLivePermissionMembersByteLive()
            if let memberData = self.byteLiveMemberData {
                self.delegate?.updatePickedMemberData(members: memberData.members.map({ $0.larkMember() }), isFromInit: true)
            }
            return
        }

        if self.larkLiveItems.isEmpty {
            configLarkLiveItems()
        } else {
            items = larkLiveItems
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.isByteLive {
                if let memberData = self.memberIdentityData {
                    self.delegate?.updatePickedMemberData(members: memberData.members, isFromInit: true)
                }
            }
        }
    }
}
