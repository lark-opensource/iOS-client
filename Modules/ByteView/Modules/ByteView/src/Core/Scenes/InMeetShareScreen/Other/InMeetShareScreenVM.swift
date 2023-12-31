//
//  InMeetShareScreenVM.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/11/5.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import ByteViewCommon
import Action
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting

enum SketchPermissionStatus: Equatable {
    case invisible
    case enabled
    case disabled
    case isSharingPause
    case noPermission
}

enum SketchEvent: Equatable {
    case none
    case start(ScreenSharedData)
    // only change text or show/dismiss menuView
    case pause(ScreenSharedData)
    case update(old: ScreenSharedData, new: ScreenSharedData)
    //  end old, start new
    case change(old: ScreenSharedData, new: ScreenSharedData)
    case end(ScreenSharedData)
}

protocol InMeetShareScreenViewModelListener: AnyObject {
    // shareScreenData数据更新
    func didChangeScreenSharedData(newData: ScreenSharedData)
    // 鼠标信息更新
    func didChangeCursorInfo(newCursorInfo: CursorInfo)
    // 标注权限更新（能不能打开标注，按钮的显隐），ScreenSharedData数据驱动
    func didChangeSketchPermissionStatus(newStatus: SketchPermissionStatus)
    // 标注按钮是否展示（webniar会议会有此逻辑）
    func didChangeCanShowSketch(canShow: Bool)
    // 标注事件更新
    func didChangeSketchEvent(newEvent: SketchEvent)
    // 标注配置更新（defautlt -> request成功拉取到的）
    func didChangeSketchSettings(newSetting: SketchSettings)
    // 共享暂停事件更新
    func didChangeIsSharingPause(isPause: Bool)
    // 更新自动修正功能的开关状态
    func didChangeAdjustAnnotate(selfNeedAdjust: Bool, sharerNeedAdjust: Bool)
}

extension InMeetShareScreenViewModelListener {
    func didChangeScreenSharedData(newData: ScreenSharedData) {}
    func didChangeCursorInfo(newCursorInfo: CursorInfo) {}
    func didChangeSketchPermissionStatus(newStatus: SketchPermissionStatus) {}
    func didChangeCanShowSketch(canShow: Bool) {}
    func didChangeSketchEvent(newEvent: SketchEvent) {}
    func didChangeSketchSettings(newSetting: SketchSettings) {}
    func didChangeIsSharingPause(isPause: Bool) {}
    func didChangeAdjustAnnotate(selfNeedAdjust: Bool, sharerNeedAdjust: Bool) {}
}

final class InMeetShareScreenVM: InMeetDataListener, MeetingSettingListener, InMeetShareDataListener, InMeetMeetingProvider {

    struct ShareScreenInfo: Equatable {
        var user: ByteviewUser
        var rtcUid: RtcUID?
        var name: String
        var isSharingPause: Bool
    }

    private static let logger = Logger.otherShareScreen
    let disposeBag = DisposeBag()
    let meeting: InMeetMeeting
    let tips: InMeetTipViewModel?
    let context: InMeetViewContext
    @RwAtomic
    var otherCantSeeSketchTipDisplayed = false
    var isMenuShowingWhenSharingPause: Bool = false
    var isMenuShowing: Bool = false
    var currentTool: ActionType = .pen
    var currentColor: UIColor?
    var meetingID: String {
        meeting.meetingId
    }
    /// 投屏转妙享Toast提示
    var triggerToast: ((String) -> Void)?
    private lazy var logDescription = metadataDescription(of: self)
    private(set) var shareScreenGridInfoRelay: BehaviorRelay<ShareScreenInfo?> = BehaviorRelay(value: nil)
    private(set) var isSketchEnabled = false
    let shareWatermark: ShareWatermarkManager

    @RwAtomic
    private(set) var screenSharedData: ScreenSharedData? {
        didSet {
            self.createShareScreenGridInfo()
            self.createSketchSettingStatus()
            if let screenSharedData = screenSharedData {
                self.isSharerNeedAdjustAnnotate = screenSharedData.sketchFitMode == .sketchCubicFitting
                let oldScreenData = oldValue ?? ScreenSharedData()
                self.getNewSketchEvent(oldScreenData: oldScreenData, newScreenData: screenSharedData)
                self.isSharingPause = screenSharedData.isSharingPause
                enableCursorShare = screenSharedData.enableCursorShare
            } else {
                self.sketchEvent = .none
                enableCursorShare = false
            }
            if let screenSharedData = screenSharedData {
                listeners.forEach { $0.didChangeScreenSharedData(newData: screenSharedData)}
            }
        }
    }

    private(set) var isSharingPause: Bool = false {
        didSet {
            guard oldValue != isSharingPause else { return }
            listeners.forEach { $0.didChangeIsSharingPause(isPause: isSharingPause) }
        }
    }

    var shareScreenGridInfo: Observable<ShareScreenInfo?> {
        shareScreenGridInfoRelay.asObservable().distinctUntilChanged().share(replay: 1, scope: .whileConnected)
    }

    // MARK: listeners
    private let listeners = Listeners<InMeetShareScreenViewModelListener>()
    func addListener(_ listener: InMeetShareScreenViewModelListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: InMeetShareScreenViewModelListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: InMeetShareScreenViewModelListener) {
        listener.didChangeAdjustAnnotate(selfNeedAdjust: needAdjustAnnotate, sharerNeedAdjust: isSharerNeedAdjustAnnotate)
        if let screenSharedData = screenSharedData {
            listener.didChangeScreenSharedData(newData: screenSharedData)
        }
        if let cursorInfo = cursorManager?.cursorInfo {
            listener.didChangeCursorInfo(newCursorInfo: cursorInfo)
        }
        if let sketchSettings = sketchSettings {
            listener.didChangeSketchSettings(newSetting: sketchSettings)
        }
        if sketchEvent != .none {
            listener.didChangeSketchEvent(newEvent: sketchEvent)
        }
        listener.didChangeSketchPermissionStatus(newStatus: sketchPermissionStatus)
    }

    // MARK: 鼠标逻辑
    private var cursorManager: InMeetCursorManager?
    private var enableCursorShare: Bool = false {
        didSet {
            if enableCursorShare, cursorManager == nil {
                cursorManager = InMeetCursorManager(meeting: meeting) { [weak listeners] cursorInfo in
                    listeners?.forEach {
                        $0.didChangeCursorInfo(newCursorInfo: cursorInfo)
                    }
                }
            }
        }
    }

    // MARK: 标注逻辑
    // 本地设置是否支持修正标注（默认为支持）
    private(set) var needAdjustAnnotate: Bool {
        didSet {
            guard oldValue != needAdjustAnnotate else { return }
            listeners.forEach { $0.didChangeAdjustAnnotate(selfNeedAdjust: needAdjustAnnotate, sharerNeedAdjust: isSharerNeedAdjustAnnotate)}
        }
    }

    // 共享人是否支持修正标注
    private(set) var isSharerNeedAdjustAnnotate: Bool {
        didSet {
            guard oldValue != isSharerNeedAdjustAnnotate else { return }
            listeners.forEach { $0.didChangeAdjustAnnotate(selfNeedAdjust: needAdjustAnnotate, sharerNeedAdjust: isSharerNeedAdjustAnnotate)}
        }
    }

    private(set) var sketchEvent: SketchEvent = .none {
        didSet {
            guard oldValue != sketchEvent else { return }
            listeners.forEach { $0.didChangeSketchEvent(newEvent: sketchEvent)}
        }
    }

    private(set) lazy var onlyPresenterCanAnnotate: Bool = false {
        didSet {
            guard oldValue != onlyPresenterCanAnnotate else { return }
            self.createSketchSettingStatus()
        }
    }

    private(set) var canShowSketch: Bool = false {
        didSet {
            guard oldValue != canShowSketch else {
                return
            }
            listeners.forEach { $0.didChangeCanShowSketch(canShow: canShowSketch) }
        }
    }

    private(set) var sketchSettings: SketchSettings? {
        didSet {
            if let sketchSettings = sketchSettings {
                listeners.forEach { $0.didChangeSketchSettings(newSetting: sketchSettings) }
            }
        }
    }

    private(set) var sketchPermissionStatus: SketchPermissionStatus = .invisible {
        didSet {
            guard oldValue != sketchPermissionStatus else { return }
            listeners.forEach { $0.didChangeSketchPermissionStatus(newStatus: sketchPermissionStatus) }
        }
    }

    var requestSketchAccessAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            guard let shareScreenID = self.screenSharedData?.shareScreenID else { return .empty() }
            self.requestAccessibility(shareScreenID: shareScreenID)
            return .empty()
        })
    }

    private func createShareScreenGridInfo() {
        guard let screenShareData = self.screenSharedData else {
            self.shareScreenGridInfoRelay.accept(nil)
            return
        }
        let meetingId = self.meetingID
        let participantService = self.meeting.httpClient.participantService
        let rtcUid: RtcUID? = meeting.participant.find(user: screenShareData.participant, in: .activePanels)?.rtcUid
        participantService.participantInfo(pid: screenShareData, meetingId: meetingId) { [weak self] ap in
            self?.shareScreenGridInfoRelay.accept(ShareScreenInfo(user: screenShareData.participant, rtcUid: rtcUid, name: ap.name, isSharingPause: screenShareData.isSharingPause))
        }
    }

    private func getSketchSettings() {
        self.meeting.httpClient.getResponse(GetSettingsRequest(fields: [SketchSettings.sketchSettingField])) { [weak self] result in
            switch result {
            case .success(let rsp):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    if let jsonStr = rsp.fieldGroups[SketchSettings.sketchSettingField], let data = jsonStr.data(using: .utf8) {
                        self?.sketchSettings = try decoder.decode(SketchSettings.self, from: data)
                    } else {
                        ByteViewSketch.logger.error("failed decoding SketchSettings, \(rsp) received")
                        self?.sketchSettings = .default
                    }
                } catch {
                    ByteViewSketch.logger.error("failed decoding SketchSettings error: \(error)")
                    self?.sketchSettings = .default
                }
            case .failure(let error):
                ByteViewSketch.logger.error("request SketchSettings failed, error: \(error)")
                self?.sketchSettings = .default
            }
        }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .showsSketch {
            canShowSketch = isOn
        }
        if key == .needAdjustAnnotate {
            needAdjustAnnotate = isOn
        }
    }

    func startSketch() {
        isSketchEnabled = true
    }

    func stopSketch() {
        isSketchEnabled = false
    }

    func getNewSketchEvent(oldScreenData: ScreenSharedData, newScreenData: ScreenSharedData) {
        switch (oldScreenData.isSketch && oldScreenData.isSharing && oldScreenData.canSketch,
                newScreenData.isSketch && newScreenData.isSharing && newScreenData.canSketch) {
        case (false, false):
            // 该情况可能会有重复推送：如PC端第一次暂停共享的时候，可能会多发一次数据，因此做一下数据过滤。
            if oldScreenData.isSketch == newScreenData.isSketch && oldScreenData.isSharing == newScreenData.isSharing && oldScreenData.canSketch == newScreenData.canSketch && oldScreenData.isSharingPause == newScreenData.isSharingPause {
                ByteViewSketch.logger.info("sketchChange: no change because of same data")
                return
            }
            // 如果在停止标注之前是暂停共享状态，要将之前的共享停止。（重新共享会发生该情况）
            if oldScreenData.isSharingPause {
                ByteViewSketch.logger.info("sketchChange: end because of isSharingPause ")
                self.sketchEvent = .end(oldScreenData)
                return
            }
            // 刚入会的时候，可能就是处于暂停共享状态
            if newScreenData.isSharingPause {
                ByteViewSketch.logger.info("sketchChange: pause because of current isSharingPause")
                self.sketchEvent = .pause(newScreenData)
                return
            }
            ByteViewSketch.logger.info("sketchChange: empty")
            self.sketchEvent = .none
            return
        case (false, true):
            ByteViewSketch.logger.info("sketchChange: start \(newScreenData.shareScreenID)")
            self.sketchEvent = .start(newScreenData)
            return
        case (true, false):
            // 从可以标注 -> 不可以标注，原因之一可能是暂停共享，因此检查一下isSharingPause，如果是，则走暂停共享的逻辑
            if newScreenData.isSharingPause {
                ByteViewSketch.logger.info("sketchChange: pause \(newScreenData.shareScreenID)")
                self.sketchEvent = .pause(newScreenData)
                return
            }
            ByteViewSketch.logger.info("sketchChange: end \(oldScreenData.shareScreenID)")
            self.sketchEvent = .end(oldScreenData)
            return
        case (true, true):
            if oldScreenData.shareScreenID == newScreenData.shareScreenID {
                ByteViewSketch.logger.info("sketchChange: update oldScreenData: \(oldScreenData), newScreenData: \(newScreenData)")
                self.sketchEvent = .update(old: oldScreenData, new: newScreenData)
                return
            } else {
                ByteViewSketch.logger.info("sketchChange: end oldScreenData: \(oldScreenData), newScreenData: \(newScreenData)")
                self.sketchEvent = .change(old: oldScreenData, new: newScreenData)
                return
            }
        }
    }

    func requestAccessibility(shareScreenID: String) {
        let httpClient = self.meeting.httpClient
        let request = ApplyAccessibilityRequest(meetingId: meeting.meetingId, breakoutRoomId: meeting.setting.breakoutRoomId, shareScreenId: shareScreenID)
        httpClient.send(request)
    }

    func showOtherCannotSketchTip() {
        guard isSketchEnabled, !otherCantSeeSketchTipDisplayed else {
            return
        }
        let myself = meeting.myself
        otherCantSeeSketchTipDisplayed = true
        if meeting.type == .call {
            let participantService = meeting.httpClient.participantService
            participantService.participantInfo(pid: myself, meetingId: meeting.meetingId) { [weak self] (ap) in
                guard let self = self, self.isSketchEnabled else { return }
                let info = TipInfo(content: I18n.View_V_CantSeeAnnotationsBraces(ap.name), isFromNotice: false)
                self.tips?.showTipInfo(info)
            }
        } else {
            tips?.showTipInfo(TipInfo(content: I18n.View_M_CantSeeAnnotations, isFromNotice: false))
        }
    }

    func createSketchSettingStatus() {
        guard let screenSharedData = self.screenSharedData else { return }
        let deviceID = meeting.account.deviceId
        if onlyPresenterCanAnnotate && screenSharedData.participant.deviceId != deviceID {
            self.sketchPermissionStatus = .disabled
            return
        }
        if !screenSharedData.canSketch {
            // 从可以标注 -> 不可以标注，原因之一可能是暂停共享，因此检查一下isSharingPause，如果是，则走暂停共享的逻辑
            self.sketchPermissionStatus = screenSharedData.isSharingPause ? .isSharingPause : .disabled
            return
        }
        if !screenSharedData.accessibility {
            self.sketchPermissionStatus = .noPermission
            return
        }
        self.sketchPermissionStatus = .enabled
    }

    private var lastShowPresenterAllowFreeToBrowseHintShareID: String?
    func shouldShowPresenterAllowFreeToBrowseHint() -> Bool {
        if let lastShowTipsShareID = lastShowPresenterAllowFreeToBrowseHintShareID,
           let currentShareID = screenSharedData?.shareScreenID,
           lastShowTipsShareID == currentShareID {
            return false
        }
        return true
    }

    func storeLastShowPresenterAllowFreeToBrowseHintShareID() {
        if let currentShareID = screenSharedData?.shareScreenID {
            lastShowPresenterAllowFreeToBrowseHintShareID = currentShareID
        }
    }

    func clearLastShowPresenterAllowFreeToBrowseHintShareID() {
        lastShowPresenterAllowFreeToBrowseHintShareID = nil
    }

    // MARK: 共享逻辑
    required init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.tips = resolver.resolve()
        self.context = resolver.viewContext
        let screenSharedData = meeting.shareData.shareContentScene.shareScreenData
        self.screenSharedData = screenSharedData
        self.isSharerNeedAdjustAnnotate = screenSharedData?.sketchFitMode == .sketchCubicFitting ? true : false
        self.shareWatermark = resolver.resolve()!
        self.canShowSketch = meeting.setting.showsSketch
        self.needAdjustAnnotate = meeting.setting.needAdjustAnnotate
        self.onlyPresenterCanAnnotate = meeting.data.inMeetingInfo?.meetingSettings.onlyPresenterCanAnnotate ?? false
        self.getSketchSettings()
        self.createSketchSettingStatus()
        self.createShareScreenGridInfo()
        if let screenSharedData = meeting.shareData.shareContentScene.shareScreenData {
            self.getNewSketchEvent(oldScreenData: ScreenSharedData(), newScreenData: screenSharedData)
        }
        meeting.data.addListener(self)
        meeting.shareData.addListener(self)
        meeting.setting.addListener(self, for: [.showsSketch, .needAdjustAnnotate])
        meeting.participant.addListener(self, fireImmediately: false)

        Self.logger.debug("init \(logDescription) \(needAdjustAnnotate) \(isSharerNeedAdjustAnnotate)")
    }

    deinit {
        Self.logger.debug("deinit \(logDescription)")
    }

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        if [.othersSharingScreen, .magicShare, .shareScreenToFollow, .none].contains(newScene.shareSceneType)
            || [.othersSharingScreen, .magicShare, .shareScreenToFollow, .none].contains(oldScene.shareSceneType) {
            let newDocument = newScene.magicShareDocument
            let oldDocument = oldScene.magicShareDocument
            let newScreenSharedData = newScene.shareScreenData
            let oldScreenSharedData = oldScene.shareScreenData

            if newScreenSharedData?.isSharingPause == true {
                isMenuShowingWhenSharingPause = isMenuShowing
            }
            self.screenSharedData = newScreenSharedData
            if oldDocument?.isSSToMS == true,
               newDocument == nil,
               newScreenSharedData?.ccmInfo?.url != "",
               newScreenSharedData?.ccmInfo?.isAllowFollowerOpenCcm == false {
                triggerToast?(I18n.View_G_PresenterOffVOMO)
            }
        }
        if newScene.shareSceneType == .none {
            currentTool = .pen
            currentColor = nil
        }
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        let onlyPresenterCanAnnotate = inMeetingInfo.meetingSettings.onlyPresenterCanAnnotate
        if onlyPresenterCanAnnotate != self.onlyPresenterCanAnnotate {
            self.onlyPresenterCanAnnotate = onlyPresenterCanAnnotate
            createSketchSettingStatus()
        }
    }
}

extension InMeetShareScreenVM: InMeetParticipantListener {
    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        updateRtcUIDIfNeeded()
    }

    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput) {
        updateRtcUIDIfNeeded()
    }

    func updateRtcUIDIfNeeded() {
        guard let screenShareData = self.screenSharedData,
              var gridInfo = self.shareScreenGridInfoRelay.value,
              gridInfo.rtcUid == nil,
              let rtcUid = meeting.participant.find(user: screenShareData.participant, in: .activePanels)?.rtcUid else {
            return
        }
        gridInfo.rtcUid = rtcUid
        self.shareScreenGridInfoRelay.accept(gridInfo)
    }
}
