//
//  InMeetFollowViewModel.swift
//  ByteView
//
//  Created by liurundong.henry on 2019/9/24.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewCommon
import ByteViewNetwork

// swiftlint:disable file_length
class InMeetFollowViewModel: InMeetMeetingProvider {

    static let logger = Logger.vcFollow

    let magicShareDocumentRelay: BehaviorRelay<MagicShareDocument?>
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    /// 远端记录正在共享的MS文档
    var remoteMagicShareDocument: MagicShareDocument? { meeting.shareData.shareContentScene.magicShareData }
    let isRemoteEqualLocalRelay: BehaviorRelay<Bool>
    let magicShareLocalDocumentsRelay: BehaviorRelay<[MagicShareDocument]>
    let isInterpreterComponentDisplayRelay: BehaviorRelay<Bool>
    let manager: InMeetFollowManager
    var localDocuments: [MagicShareDocument] { manager.localDocuments }
    /// 本地记录当前共享的上一篇文档
    var localSecondLastDocument: MagicShareDocument? {
        let documents = manager.localDocuments
        let count = documents.count
        if count >= 2 {
            return documents[count - 2]
        }
        return nil
    }

    let isViewOnMyOwnRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    let status: BehaviorRelay<InMeetFollowViewModelStatus>
    let exitEvent = PublishSubject<Void>()

    let bag: DisposeBag = DisposeBag()

    var followServiceBag: DisposeBag = DisposeBag()

    let manualGuideTrigger = PublishRelay<Void>()
    let layoutStyleChangedTrigger = PublishRelay<Void>()
    var currentContentOffset: CGFloat = 0
    var lastContentOffset: CGFloat = 0
    var topViewHiddenHeight: CGFloat = 0
    var lastOffsetY: CGFloat = 0
    var topViewHiddenHeightRelay = BehaviorRelay<CGFloat>(value: 0)
    var variationRelay = BehaviorRelay<CGFloat>(value: 0)
    var endEventRelay = PublishSubject<Void>()
    var resetEventRelay = PublishSubject<Void>()
    var loadingRelay = BehaviorRelay<Bool>(value: false)

    var directionSubject = PublishSubject<MagicShareDirectionViewModel.Direction>()

    let msExternalPermChangedInfoObservable: Observable<MSExternalPermChangedInfo>
    let shouldShowExternalPermissionTips: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    let didReadySubject = PublishSubject<Void>()

    var fullScreenDetector: InMeetFullScreenDetector? { context.fullScreenDetector }

    let isContentChangeHintDisplayingObservable: Observable<Bool>
    let isContentChangeHintDisplayingSubject = BehaviorRelay<Bool>(value: false)
    let resolver: InMeetViewModelResolver

    init(meeting: InMeetMeeting, context: InMeetViewContext, manager: InMeetFollowManager, resolver: InMeetViewModelResolver) {
        self.meeting = meeting
        self.context = context
        self.manager = manager
        self.resolver = resolver
        self.magicShareDocumentRelay = .init(value: manager.magicShareDocument)
        self.magicShareLocalDocumentsRelay = .init(value: manager.localDocuments)
        self.isRemoteEqualLocalRelay = .init(value: manager.magicShareDocument?.token == manager.localDocuments.last?.token)
        self.msExternalPermChangedInfoObservable = NoticeService.shared.msExternalPermChangedInfoObservable
        self.isInterpreterComponentDisplayRelay = BehaviorRelay<Bool>(value: manager.meeting.myself.settings.interpreterSetting?.confirmStatus == .confirmed)
        self.status = .init(value: manager.status)
        self.isTranslationOnRelay.accept(meeting.myself.settings.isTranslationOn ?? false)
        isContentChangeHintDisplayingObservable = self.isContentChangeHintDisplayingSubject.asObservable()
        bindFlow()
        manager.addListener(self)
        meeting.shareData.addListener(self)
        meeting.participant.addListener(self)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.addMyselfListener(self)
        self.isContentChangeHintDisplayingSubject.accept(manager.shouldShowPresenterChangedContentHint)
    }

    func bindFlow() {
        bindExternalPermissionChanged()
    }

    var followDocumentNameDriver: Driver<String> {
        return Observable
            .combineLatest(status, magicShareLocalDocumentsRelay, isRemoteEqualLocal)
            .flatMap { (status, documents, isSameFile) -> Observable<String> in
                guard let document = documents.last else {
                    return .just("")
                }
                let title = document.nonEmptyDocTitle
                if case .sharing = status {
                    return .just(I18n.View_VM_YouAreSharingFileName(title))
                } else if case .shareScreenToFollow = status {
                    return .just(title)
                } else if case .free = status {
                    return .just(title)
                } else if isSameFile {
                    let otherSharerPre = I18n.View_VM_NameIsSharing(document.userName)
                    return .just("\(otherSharerPre)\(title)")
                } else {
                    return .just(I18n.View_VM_YouAreViewingFileName(title))
                }
        }
        .asDriver(onErrorJustReturn: "")
    }

    var meetingID: String {
        meeting.meetingId
    }

    private let displayTopicRelay = BehaviorRelay<String>(value: "")
    private(set) lazy var displayTopic: Driver<String> = displayTopicRelay.asDriver()

    var isFollowing: Observable<Bool> {
        return status.map { $0.isFollowing() }
    }

    var isSharing: Observable<Bool> {
        return status.map { $0.isSharing() }
    }

    var shareStatusObservable: Observable<MSShareStatus> {
        return status.map { $0.msShareStatus }
    }

    var isRemoteEqualLocal: Observable<Bool> {
        return isRemoteEqualLocalRelay.asObservable()
    }

    var isInterpreterComponentDisplay: Observable<Bool> {
        return isInterpreterComponentDisplayRelay.asObservable()
    }

    private var sharerIdentifier = ""
    private let shareUserNameRelay = BehaviorRelay(value: "")
    private(set) lazy var shareUserName: Observable<String> = shareUserNameRelay.asObservable()
    private let sharerAvatarInfoRelay = BehaviorRelay<AvatarInfo?>(value: nil)
    private(set) lazy var sharerAvatarInfoObservable: Observable<AvatarInfo> = sharerAvatarInfoRelay.asObservable().compactMap { $0 }

    /// 是否应显示转移列表：如果除自己外有其他用户，为true；否则为false
    private let showPassOnSharingRelay = BehaviorRelay<Bool>(value: false)
    private(set) lazy var showPassOnSharingObservable = showPassOnSharingRelay.asObservable()

    /// 是否应显示返回按钮：如果本地记录的跳转文档数量>1则为true；否则为false
    var showBackButtonObservable: Observable<Bool> {
        return magicShareLocalDocumentsRelay.asObservable()
            .map { $0.count }
            .distinctUntilChanged()
            .map { $0 > 1 }
    }

    /// 共享被抢走时，弹窗应消失
    lazy var openLinkConfirmAlertDismissTrigger: Observable<Void> = {
        return isSharing
            .distinctUntilChanged()
            .filter { !$0 }
            .map { _ in Void() }
    }()

    private var followTokenRequestTime: TimeInterval = 0
    private func requestFollowToken() {
        let lastTime = followTokenRequestTime
        followTokenRequestTime = Date.timeIntervalSinceReferenceDate
        if followTokenRequestTime - lastTime < 1 {
            return
        }
        guard let data = remoteMagicShareDocument else {
            Self.logger.debug("magic share document is nil when receive request share token")
            return
        }
        httpClient.follow.grantFollowToken(data.urlString, meetingId: meetingID, breakoutRoomId: meeting.data.breakoutRoomId, accessToken: meeting.accountInfo.accessToken, passportDomain: meeting.setting.passportDomain)
    }

    /// 字幕是否开启，影响OperationView高度
    let isTranslationOnRelay = BehaviorRelay<Bool>(value: false)
}

extension InMeetFollowViewModel {
    func resetPresenterDirection() {
        directionSubject.onNext(.free)
        manager.currentRuntime?.setLastDirection(.free)
    }
}

extension InMeetFollowViewModel: InMeetingChangedInfoPushObserver {
    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        if data.meetingID == meetingID, data.type == .requestFollowToken {
            Self.logger.debug("receive request share token")
            requestFollowToken()
        }
    }
}

extension InMeetFollowViewModel: InMeetParticipantListener {
    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        updateShareUserInfoIfNeeded()
        let showPassOnSharing = meeting.participant.otherParticipant != nil
        if showPassOnSharing != showPassOnSharingRelay.value {
            showPassOnSharingRelay.accept(showPassOnSharing)
        }
        manager.currentRuntime?.updateParticipantCount(output.sumCount)
    }

    func didChangeAnotherParticipant(_ participant: Participant?) {
        updateTopic()
    }
}

extension InMeetFollowViewModel: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        updateShareUserInfoIfNeeded()
        let newDocument = newScene.magicShareDocument
        let oldDocument = oldScene.magicShareDocument
        if newDocument != oldDocument {
            self.magicShareDocumentRelay.accept(newDocument)
            let isEqual = newDocument?.token == manager.localDocuments.last?.token
            if isEqual != self.isRemoteEqualLocalRelay.value {
                self.isRemoteEqualLocalRelay.accept(isEqual)
            }
        }

        if let oldCCMInfo = oldScene.shareScreenData?.ccmInfo,
        let newCCMInfo = newScene.shareScreenData?.ccmInfo {
            if oldCCMInfo.isAllowFollowerOpenCcm == true, newCCMInfo.isAllowFollowerOpenCcm == false,
               oldCCMInfo.rawURL == newCCMInfo.rawURL {
                ShareScreenToFollowTracks.trackClickBackToShareScreenButton(with: .closeAuthority)
            } else if oldCCMInfo.rawURL != newCCMInfo.rawURL {
                ShareScreenToFollowTracks.trackClickBackToShareScreenButton(with: .changeTag)
            }
        }
    }

    private func updateShareUserInfoIfNeeded() {
        guard let sharerIdentifier = meeting.shareData.shareContentScene.magicShareData?.identifier,
              !sharerIdentifier.isEmpty, sharerIdentifier != self.sharerIdentifier,
              let shareUser = meeting.shareData.shareContentScene.magicShareData?.user,
              let sharer = meeting.participant.find(user: shareUser) else {
            return
        }
        self.sharerIdentifier = sharerIdentifier
        let participantService = self.httpClient.participantService
        participantService.participantInfo(pid: sharer, meetingId: meeting.meetingId) { [weak self] (ap) in
            guard let self = self, self.sharerIdentifier == sharerIdentifier else { return }
            let avatar = ap.avatarInfo
            if avatar != self.sharerAvatarInfoRelay.value {
                self.sharerAvatarInfoRelay.accept(avatar)
            }
            let name = ap.name
            if name != self.shareUserNameRelay.value {
                self.shareUserNameRelay.accept(name)
            }
        }
    }

    private func updateTopic() {
        let topic: String
        switch meeting.type {
        case .meet:
            topic = "\(I18n.View_M_MeetingIDShort)\(meeting.info.formattedMeetingNumber)"
        case .call:
            topic = meeting.participant.another?.userInfo?.name ?? I18n.View_G_ServerNoTitle
        default:
            topic = I18n.View_G_ServerNoTitle
        }
        if topic != displayTopicRelay.value {
            displayTopicRelay.accept(topic)
        }
    }
}

extension InMeetFollowViewModel: InMeetFollowListener {
    func didUpdateLocalDocuments(_ documents: [MagicShareDocument], oldValue: [MagicShareDocument]) {
        self.magicShareLocalDocumentsRelay.accept(documents)
        let isEqual = remoteMagicShareDocument?.token == documents.last?.token
        if isEqual != self.isRemoteEqualLocalRelay.value {
            self.isRemoteEqualLocalRelay.accept(isEqual)
        }
    }

    func didUpdateFollowStatus(_ status: InMeetFollowViewModelStatus, oldValue: InMeetFollowViewModelStatus) {
        self.status.accept(status)
    }

    func didUpdateShowPresenterChangedContentHint(_ showHint: Bool) {
        self.isContentChangeHintDisplayingSubject.accept(showHint)
    }
}

extension InMeetFollowViewModel: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        guard myself.status != .idle else {
            Self.logger.info("failed to get subtitle status")
            return
        }
        if let isTranslationOn = myself.settings.isTranslationOn {
            self.isTranslationOnRelay.accept(isTranslationOn)
            self.manager.isTranslationOn = isTranslationOn
        }
    }
}

// swiftlint:enable file_length
