//
//  InMeetWhiteboardViewModel.swift
//  ByteView
//
//  Created by Prontera on 2022/3/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon
import Whiteboard
import RxSwift
import RxRelay

enum DataType {
    case sync
    case draw
}

protocol InMeetWhiteboardViewModelDelegate: AnyObject {
    func updateSharingUserName(_ name: String)
    func didChangeWhiteboardInfo(_ info: WhiteboardInfo)
    func didChangeEditAuthority(canEdit: Bool)
    func whiteboardDidShowMenu()
    func whiteboardDidHideMenu(isUpdate: Bool)
}

extension InMeetWhiteboardViewModelDelegate {
    func updateSharingUserName(_ name: String) {}
    func didChangeWhiteboardInfo(_ info: WhiteboardInfo) {}
    func didChangeEditAuthority(canEdit: Bool) {}
    func whiteboardDidShowMenu() {}
    func whiteboardDidHideMenu(isUpdate: Bool) {}
}

final class InMeetWhiteboardViewModel {

    weak var delegate: InMeetWhiteboardViewModelDelegate? {
        didSet {
            guard oldValue !== delegate else {
                return
            }
            fireImmediately()
        }
    }

    var userNameObservable: Observable<String> {
        userNameRelay.asObservable()
    }

    var userName: String = "" {
        didSet {
            delegate?.updateSharingUserName(userName)
            userNameRelay.accept(userName)
        }
    }

    var meeting: InMeetMeeting {
        resolver.meeting
    }
    @RwAtomic
    var whiteboardInfo: WhiteboardInfo? {
        didSet {
            setUserName()
        }
    }

    var shouldShowMenuFromFloatingWindow: Bool {
        get {
            resolver.viewContext.isNeedAutoShowWbMenu
        }
        set {
            resolver.viewContext.isNeedAutoShowWbMenu = newValue
        }
    }

    var canPadEditWhiteboard: Bool = false

    let disposeBag = DisposeBag()

    let resolver: InMeetViewModelResolver
    let shareWatermark: ShareWatermarkManager
    let startCanvasSize: CGSize
    let renderFPS: Int
    let sendIntervalMs: Int
    let maxPageCount: Int
    @RwAtomic
    var upVersion: Int64 = 0
    var defaultWhiteboardToolConfig = DefaultWhiteboardToolConfig(pen: BrushAndColorMemory(color: .black, brushType: .light), highlighter: BrushAndColorMemory(color: .red, brushType: .bold), shape: ShapeTypeAndColor(shape: .rectangle, color: .black))
    /// 白板编辑菜单是否正在展示
    var isWhiteboardMenuDisplaying: Bool = false
    // 展示白板前是否为共享状态
    var preIsSharing: Bool = false
    // 是否为自己共享白板
    var isSelfSharingWb: Bool = false

    private let userNameRelay = BehaviorRelay(value: "")
    private static let logger = Logger.whiteboard
    private var httpClient: HttpClient { meeting.httpClient }
    private var onlyPresenterCanAnnotate: Bool = false
    private let shouldShowMenuFirst: Bool

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        let whiteboardConfig = resolver.meeting.setting.whiteboardConfig
        let canvasSizeOfSettings = CGSize(width: CGFloat(whiteboardConfig.canvasSize.width), height: CGFloat(whiteboardConfig.canvasSize.height))
        if let info = resolver.meeting.shareData.shareContentScene.whiteboardData {
            self.startCanvasSize = info.whiteboardSettings.canvasSize
        } else {
            self.startCanvasSize = canvasSizeOfSettings
        }
        self.renderFPS = whiteboardConfig.replaySyncDataFps
        self.sendIntervalMs = whiteboardConfig.sendSyncDataIntervalMs
        self.maxPageCount = whiteboardConfig.larkPageMaxCount
        self.whiteboardInfo = resolver.meeting.shareData.shareContentScene.whiteboardData
        self.shareWatermark = resolver.resolve()!
        if resolver.meeting.shareData.isSelfSharingWhiteboard {
            self.shouldShowMenuFirst = true
            self.isSelfSharingWb = true
        } else {
            self.shouldShowMenuFirst = false
        }
        if let info = meeting.data.inMeetingInfo, info.meetingSettings.onlyPresenterCanAnnotate == true {
            self.onlyPresenterCanAnnotate = true
        }
        meeting.data.addListener(self)
        meeting.shareData.addListener(self)
        meeting.router.addListener(self, fireImmediately: true)
    }

    private func fireImmediately() {
        Self.logger.info("fireImmediately \(delegate)")
        guard let info = whiteboardInfo else {
            Self.logger.error("fireImmediately failed: whiteboardInfo is nil")
            return
        }
        delegate?.didChangeWhiteboardInfo(info)
        let canEdit = getEditAuthority(info)
        canPadEditWhiteboard = canEdit
        delegate?.didChangeEditAuthority(canEdit: canEdit)
        setUserName()
    }

    private func setUserName() {
        guard let whiteboardInfo = whiteboardInfo else {
            return
        }
        let participantService = httpClient.participantService
        participantService.participantInfo(pid: whiteboardInfo.sharer, meetingId: meeting.meetingId) { info in
            self.userName = info.name
        }
    }

    func getWbVC(viewStyle: WhiteboardViewStyle? = nil) -> WhiteboardViewController {
        if let wbManager = resolver.resolve(InMeetWbManager.self) {
            if let wbStoredVC = wbManager.getStoredVC() {
                return wbStoredVC
            } else {
                let defaultToolConfig = DefaultWhiteboardToolConfig(pen: wbManager.penBrushAndColor, highlighter: wbManager.highlighterBrushAndColor, shape: wbManager.shapeTypeAndColor)
                let wbVC = createWhiteboardVC(defaultToolConfig, viewStyle: viewStyle)
                wbManager.storeWbViewController(wbVC)
                return wbVC
            }
        } else {
            return createWhiteboardVC()
        }
    }

    private func createWhiteboardVC(_ defaultToolConfig: DefaultWhiteboardToolConfig? = nil, viewStyle: WhiteboardViewStyle? = nil) -> WhiteboardViewController {
        let canEditWhiteboard = getEditAuthority(self.whiteboardInfo)
        canPadEditWhiteboard = canEditWhiteboard
        var currentViewStyle: WhiteboardViewStyle
        let isFixedViewStyle: Bool = Display.phone ? true : false
        if let viewStyle = viewStyle {
            currentViewStyle = viewStyle
        } else {
            currentViewStyle = Display.phone ? .phone : .ipad
        }
        let clientConfig = WhiteboardClientConfig(meetingID: self.meeting.meetingId, renderFPS: self.renderFPS, sendIntervalMs: self.sendIntervalMs, maxPageCount: self.maxPageCount, canvasSize: self.startCanvasSize, account: meeting.account)
        let initData = WhiteboardInitData(clientConfig: clientConfig,
                                          canEdit: canEditWhiteboard,
                                          shouldShowMenuFirst: shouldShowMenuFirst,
                                          viewStyle: currentViewStyle,
                                          isFixedViewStyle: isFixedViewStyle,
                                          isSaveEnabled: meeting.setting.isWhiteboardSaveEnabled,
                                          defaultToolConfig: defaultToolConfig ?? self.defaultWhiteboardToolConfig,
                                          whiteboardInfo: self.whiteboardInfo)
        return WhiteboardViewController(initData: initData)
    }

    func getEditAuthority(_ info: WhiteboardInfo? = nil) -> Bool {
        guard let info = info else { return false }
        if !info.whiteboardIsSharing {
            return false
        }
        let canEditWhiteboard: Bool
        if onlyPresenterCanAnnotate {
            if whiteboardInfo?.sharer == meeting.account {
                canEditWhiteboard = true
            } else {
                canEditWhiteboard = false
            }
        } else {
            canEditWhiteboard = true
        }
        return canEditWhiteboard
    }
}

extension InMeetWhiteboardViewModel: InMeetDataListener, InMeetShareDataListener {

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        onlyPresenterCanAnnotate = inMeetingInfo.meetingSettings.onlyPresenterCanAnnotate
        let canEdit = getEditAuthority(inMeetingInfo.whiteboardInfo)
        canPadEditWhiteboard = canEdit
        delegate?.didChangeEditAuthority(canEdit: canEdit)
    }

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        preIsSharing = newScene.isWhiteboard && [.othersSharingScreen, .selfSharingScreen, .magicShare, .shareScreenToFollow].contains(oldScene.shareSceneType)
        guard newScene.shareSceneType == .whiteboard || oldScene.shareSceneType == .whiteboard else { return }
        let newWhiteboardData = newScene.whiteboardData
        if let validNewWhiteboardData = newWhiteboardData {
            self.whiteboardInfo = validNewWhiteboardData
            self.isSelfSharingWb = meeting.shareData.isSelfSharingWhiteboard
            delegate?.didChangeWhiteboardInfo(validNewWhiteboardData)
            let canEdit = getEditAuthority(validNewWhiteboardData)
            canPadEditWhiteboard = canEdit
            delegate?.didChangeEditAuthority(canEdit: canEdit)
        }
        if oldScene.isWhiteboard && !newScene.isWhiteboard {
            let oldWhiteboardData = oldScene.whiteboardData
            if oldWhiteboardData?.whiteboardID != nil {
                InMeetWhiteboardViewController.hasShowToast = false
                Self.trackStopWhiteboard(meeting: meeting)
                DispatchQueue.main.async {
                    self.resolver.viewContext.isWhiteboardEditEnable = false
                    self.resolver.viewContext.isWhiteboardMenuEnabled = false
                }
            }
        } else if !oldScene.isWhiteboard && newScene.isWhiteboard {
            let whiteboardType: StartWhiteboardType = meeting.shareData.isSelfSharingWhiteboard ? .newBoard : .joinBoard
            Self.trackStartWhiteboard(meeting: meeting, startType: whiteboardType, preIsSharing: preIsSharing)
        }
    }
}

extension InMeetWhiteboardViewModel: Whiteboard.Dependencies {

    func showToast(_ text: String) {
        Toast.show(text)
    }

    func getWatermarkView(completion: @escaping (UIView?) -> Void) {
        let block: (UIView?) -> Void = { watermarkView in
            watermarkView?.frame = .init(origin: .zero, size: self.startCanvasSize)
            completion(watermarkView)
        }
        let getGlobalWatermarkView: () -> Void = {
            self.meeting.service.larkUtil.getWatermarkView {
                block($0)
            }
        }
        if shareWatermark.showWatermarkRelay.value {
            // 若有全局水印会返回 nil，此时需要重新拉取全局水印
            meeting.service.larkUtil.getVCShareZoneWatermarkView()
                .take(1)
                .subscribe(onNext: {
                    if let watermarkView = $0 {
                        block(watermarkView)
                    } else {
                        getGlobalWatermarkView()
                    }
                }).disposed(by: disposeBag)
        } else {
            getGlobalWatermarkView()
        }
    }

    func nicknameBy(userID: String, deviceID: String, userType: Int, completion: @escaping (String) -> Void) {
        let pid = ParticipantId(id: userID, type: ParticipantType(rawValue: userType), deviceId: deviceID)
        let participantService = httpClient.participantService
        participantService.participantInfo(pid: pid, meetingId: meeting.meetingId) { info in
            completion(info.name)
        }
    }

    // MARK: - 白板菜单
    func setWhiteboardMenuDisplayStatus(to isShowState: Bool, isUpdate: Bool) {
        isWhiteboardMenuDisplaying = isShowState
        if isShowState {
            delegate?.whiteboardDidShowMenu()
        } else {
            delegate?.whiteboardDidHideMenu(isUpdate: isUpdate)
        }
    }

    func setNeedChangeAlphaOfSuspensionComponent(isOpaque: Bool) {
        if Display.phone { resolver.viewContext.post(.whiteboardOperateStatus, userInfo: isOpaque) }
    }

    func didChangePenBrush(brush: BrushType) {
        if let wbManager = resolver.resolve(InMeetWbManager.self) {
            wbManager.penBrushAndColor.brushType = brush
        }
    }

    func didChangePenColor(color: ColorType) {
        if let wbManager = resolver.resolve(InMeetWbManager.self) {
            wbManager.penBrushAndColor.color = color
        }
    }

    func didChangeHighlighterBrush(brush: BrushType) {
        if let wbManager = resolver.resolve(InMeetWbManager.self) {
            wbManager.highlighterBrushAndColor.brushType = brush
        }
    }

    func didChangeHighlighterColor(color: ColorType) {
        if let wbManager = resolver.resolve(InMeetWbManager.self) {
            wbManager.highlighterBrushAndColor.color = color
        }
    }

    func didChangeShapeType(shape: ActionToolType) {
        if let wbManager = resolver.resolve(InMeetWbManager.self) {
            wbManager.shapeTypeAndColor.shape = shape
        }
    }

    func didChangeShapeColor(color: ColorType) {
        if let wbManager = resolver.resolve(InMeetWbManager.self) {
            wbManager.shapeTypeAndColor.color = color
        }
    }
}

extension InMeetWhiteboardViewModel: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        guard Display.phone else { return }
        if isFloating, resolver.viewContext.isWhiteboardMenuEnabled {
            resolver.viewContext.isNeedAutoShowWbMenu = true
        }
    }
}

extension InMeetWhiteboardViewModel {
    static var startWhiteboardTime: TimeInterval = CACurrentMediaTime()
    static var stopWhiteboradTime: TimeInterval = CACurrentMediaTime()
    static func trackStartWhiteboard(meeting: InMeetMeeting, startType: StartWhiteboardType, preIsSharing: Bool) {
        startWhiteboardTime = CACurrentMediaTime()
        WhiteboardTracks.trackStartWhiteboard(
            type: startType,
            isSharing: preIsSharing,
            isSharer: meeting.shareData.isSelfSharingWhiteboard,
            participantNum: meeting.info.participants.onTheCall.count,
            isOnthecall: true
        )
    }

    static func trackStopWhiteboard(meeting: InMeetMeeting, isEndMeeting: Bool? = nil) {
        stopWhiteboradTime = CACurrentMediaTime()
        // nolint-next-line: magic number
        let duration = round((stopWhiteboradTime - startWhiteboardTime) * 1e6) / 1e3
        let participantNum: Int = meeting.info.participants.onTheCall.count
        let quiteType: StopWhiteboardType = isEndMeeting == true ? .quiteLeaveMeeting : .quiteFromShare
        WhiteboardTracks.trackStopWhiteboard(
            type: quiteType,
            duration: duration,
            whiteboardId: meeting.shareData.shareContentScene.whiteboardData?.whiteboardID ?? 0,
            isSharing: true,
            isSharer: meeting.shareData.isSelfSharingWhiteboard,
            participantNum: participantNum,
            isOnthecall: true
        )
    }
}
