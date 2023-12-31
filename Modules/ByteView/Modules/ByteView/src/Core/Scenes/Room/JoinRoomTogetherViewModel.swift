//
//  JoinRoomTogetherViewModel.swift
//  ByteView
//
//  Created by kiri on 2022/4/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import QuartzCore
import ByteViewUI
import ByteViewSetting
import ByteViewMeeting

enum JoinRoomPopoverFrom: String {
    case preview
    case prelobby
    case inMeet
}

enum JoinRoomSourceFrom: String {
    case toolbarMore
    case navibar

    var track: String {
        switch self {
        case .toolbarMore:
            return "mobile_more"
        case .navibar:
            return "pad_topbar"
        }
    }
}

protocol JoinRoomTogetherViewModelDelegate: AnyObject {
    /// 主线程回调
    func roomStateDidChange()
    /// 主线程回调
    func roomInfoDidUpdate()
    /// 主线程回调
    func roomVerifyCodeStateDidChange()
}

protocol JoinRoomTogetherViewModelProvider {
    var initialRoom: ByteviewUser? { get }
    var shareCodeFilter: GetShareCodeInfoRequest.RoomBindFilter { get }
    /// call before scan
    func prepareScan(completion: @escaping () -> Void)
    func resetAfterScan()
    func connectRoom(_ room: ByteviewUser, completion: @escaping (Result<Void, Error>) -> Void)
    func disconnectRoom(_ room: ByteviewUser?, completion: @escaping (Result<Void, Error>) -> Void)
    func fetchRoomInfo(_ room: ByteviewUser, completion: @escaping (ParticipantUserInfo) -> Void)

    var shouldDoubleCheckDisconnection: Bool { get }

    var isInMeet: Bool { get }
    /// for track
    var popoverFrom: JoinRoomPopoverFrom { get }
    /// 埋点参数，会议是否在共享内容
    var isSharingContent: Bool { get }

    var supportedInterfaceOrientations: UIInterfaceOrientationMask { get }
}

class JoinRoomTogetherViewModel {
    private lazy var logDescription: String = "\(metadataDescription(of: self)), provider: \(self.provider)"

    @RwAtomic
    private(set) var room: ByteviewUser?
    @RwAtomic
    private(set) var state: JoinRoomScanState = .idle {
        didSet {
            if state != oldValue {
                Logger.ui.info("roomStateDidChange \(oldValue) => \(state)")
                Util.runInMainThread { [weak self] in
                    self?.delegate?.roomStateDidChange()
                }
            }
        }
    }

    var fromAutoScan: Bool = false

    /// roomInfo仅在主线程更新和使用
    private var roomInfo: ParticipantUserInfo?

    var roomName: String? {
        assertMain()
        return roomInfo?.room?.fullName
    }

    var roomNameAbbr: String? {
        assertMain()
        return roomInfo?.room?.primaryName
    }

    var isInMeet: Bool { provider.isInMeet }
    var shouldDoubleCheckDisconnection: Bool { provider.shouldDoubleCheckDisconnection }
    var supportedInterfaceOrientations: UIInterfaceOrientationMask { provider.supportedInterfaceOrientations }

    private let provider: JoinRoomTogetherViewModelProvider

    weak var delegate: JoinRoomTogetherViewModelDelegate?

    var lastShareCodeInfo: GetShareCodeInfoResponse?
    @RwAtomic
    private(set) var connectionState: JoinRoomConnectionState = .none

    @RwAtomic
    private(set) var verifyCodeState: JoinRoomVerifyCodeState = .idle {
        didSet {
            if verifyCodeState != oldValue {
                Logger.ui.info("roomVerifyCodeStateDidChange \(oldValue) => \(verifyCodeState)")
                Util.runInMainThread { [weak self] in
                    self?.delegate?.roomVerifyCodeStateDidChange()
                }
            }
        }
    }

    let service: MeetingBasicService
    var setting: MeetingSettingManager { service.setting }
    var httpClient: HttpClient { service.httpClient }
    let audioOutputManager: AudioOutputManager?
    let source: JoinRoomSourceFrom?

    init(service: MeetingBasicService, provider: JoinRoomTogetherViewModelProvider, audioOutputManager: AudioOutputManager? = nil, source: JoinRoomSourceFrom? = nil) {
        self.provider = provider
        self.service = service
        self.audioOutputManager = audioOutputManager
        self.source = source
        if let room = provider.initialRoom {
            self.room = room
            self.state = .connected
        }
        self.updateRoomInfo()
        Logger.ui.info("init \(logDescription)")
    }

    deinit {
        cancelScanning()
        Logger.ui.info("deinit \(logDescription)")
    }

    @RwAtomic
    private var ultrasonicCode: String = ""
    func scan() {
        self.scan(isAutomatic: false, onRoomFound: nil)
    }

    func autoscan(onRoomFound: @escaping () -> Void) {
        self.scan(isAutomatic: true, onRoomFound: onRoomFound)
    }

    private func scan(isAutomatic: Bool, onRoomFound: (() -> Void)?) {
        self.ultrasonicCode = ""
        self.verifyCode = ""
        self.lastShareCodeInfo = nil
        guard isUltrasonicEnabled else { return }
        Logger.ui.info("start scanning room, isAutomatic = \(isAutomatic)")
        self.state = .scanning
        self.verifyCodeState = .idle
        let tracks = ScanTracks(isUserAction: !isAutomatic, from: self.provider.popoverFrom)
        self.provider.prepareScan { [weak self] in
            guard let self = self else { return }
            var isSpeakerOn: Bool?
            if !self.isInMeet, let audio = self.audioOutputManager?.currentOutput {
                isSpeakerOn = audio == .speaker
            }
            UltrawaveManager.shared.startRecv(config: self.setting.nfdScanConfig, usageType: self.getNFDUsageType(isAutomatic: isAutomatic), isSpeakerOn: isSpeakerOn, isInMeet: self.isInMeet) { [weak self] r1 in
                guard let self = self, self.state == .scanning else { return }
                self.provider.resetAfterScan()
                switch r1 {
                case .success(let code):
                    Logger.ui.info("UltrawaveManager scan success, code = \(code)")
                    self.ultrasonicCode = code
                    tracks.onUltrawaveSuccess(code: code)
                    let request = GetShareCodeInfoRequest(shareCode: code, roomBindFilter: self.provider.shareCodeFilter)
                    self.httpClient.getResponse(request) { [weak self] r2 in
                        guard let self = self, self.state == .scanning else { return }
                        if let resp = r2.value, resp.statusCode.isRoomFound, let user = resp.user {
                            self.lastShareCodeInfo = resp
                            Logger.ui.info("getShareCodeInfo success, resp = \(resp)")
                            self.room = user
                            self.updateRoomInfo { [weak self] isSuccess in
                                guard let self = self, self.state == .scanning, isSuccess else { return }
                                tracks.onRoomFound(room: user, status: resp.statusCode)
                                self.state = .roomFound(resp.statusCode)
                                onRoomFound?()
                            }
                        } else {
                            Logger.ui.info("getShareCodeInfo failed, result = \(r2)")
                            tracks.onRoomNotFound()
                            self.state = .roomNotFound
                        }
                    }
                default:
                    Logger.ui.info("UltrawaveManager scan failed, result = \(r1)")
                    tracks.onUltrawaveFail()
                    tracks.onRoomNotFound()
                    self.state = .roomNotFound
                }
            }
        }
    }

    private func getNFDUsageType(isAutomatic: Bool) -> UltrawaveManager.NFDUsageType {
        switch (isAutomatic, self.isInMeet) {
        case (true, true):
            return .onthecall_auto
        case (true, false):
            return .preview_auto
        case (false, false):
            return .preview_manual
        case (false, true):
            return .onthecall_manual
        }
    }

    private func updateRoomInfo(completion: ((Bool) -> Void)? = nil) {
        if let room = self.room {
            provider.fetchRoomInfo(room) { [weak self] userInfo in
                if let self = self, self.room == room {
                    Util.runInMainThread { [weak self] in
                        self?.roomInfo = userInfo
                        self?.delegate?.roomInfoDidUpdate()
                        completion?(true)
                    }
                } else {
                    completion?(false)
                }
            }
        } else {
            self.roomInfo = nil
            completion?(true)
        }
    }

    func gotoVerifyCode() {
        self.state = .verifyCode
    }

    func connectRoom(isFromAutoScan: Bool = false, completion: ((Result<Void, Error>) -> Void)? = nil) {
        if let room = self.room {
            provider.connectRoom(room) { [weak self] result in
                if let self = self, self.state.canConnect {
                    if result.isSuccess {
                        self.connectionState = isFromAutoScan ? .automatic : .manual
                        self.state = .connected
                    }
                }
                completion?(result)
            }
        }
    }

    func disconnectRoom(completion: ((Result<Void, Error>) -> Void)? = nil) {
        provider.disconnectRoom(self.room) { [weak self] result in
            if let self = self, result.isSuccess, self.state == .connected {
                self.connectionState = .none
                self.room = nil
                self.roomInfo = nil
                self.state = .idle
            }
            completion?(result)
        }
    }

    func cancelScanning() {
        assertMain()
        guard self.state == .scanning else { return }
        self.state = .idle
        UltrawaveManager.shared.stopRecv()
        provider.resetAfterScan()
    }

    @RwAtomic
    private var lastRequestingVerifyCode: String?
    @RwAtomic
    private(set) var verifyCode: String = ""
    /// https://bytedance.feishu.cn/docx/B8PxdyyUmoG5URxZSGrcavJnnTc
    func onVerifyCodeChanged(_ code: String) {
        self.verifyCode = code
        if code.count == 6 {
            self.verifyCodeState = .loading
            self.lastRequestingVerifyCode = code
            let request = GetShareCodeInfoRequest(shareCode: code, roomBindFilter: .none)
            self.httpClient.getResponse(request) { [weak self] r2 in
                guard let self = self, self.state == .verifyCode, self.lastRequestingVerifyCode == code else { return }
                if let resp = r2.value, resp.statusCode == .success, let user = resp.user, self.room == user {
                    Logger.ui.info("getVerifyCodeInfo success, resp = \(resp)")
                    self.verifyCodeState = .success
                    self.connectRoom()
                } else {
                    Logger.ui.info("getVerifyCodeInfo failed, result = \(r2)")
                    self.verifyCode = ""
                    self.verifyCodeState = .error
                }
            }
        } else {
            self.lastRequestingVerifyCode = nil
            self.verifyCodeState = .idle
        }
    }

    var isUltrasonicEnabled: Bool {
        setting.isUltrawaveEnabled
    }

    /// 是否可以直接连上会议室
    /// - https://bytedance.feishu.cn/docx/KJfmdcfLfoUloixJ77mczBIMnYg
    var canAutoConnect: Bool {
        if case .roomFound(.success) = self.state, let resp = self.lastShareCodeInfo {
            return resp.isRoomInMeeting
        }
        return false
    }

    /// 是否是建议会议室
    /// - https://bytedance.feishu.cn/docx/KJfmdcfLfoUloixJ77mczBIMnYg
    var isSuggestedRoom: Bool {
        if case .roomFound = self.state, let resp = self.lastShareCodeInfo {
            if resp.isRoomInMeeting {
                return resp.statusCode == .success
            } else {
                return resp.isRoomInCalendar && resp.isUserInCalendar
            }
        }
        return false
    }
}

extension JoinRoomTogetherViewModel {
    func trackShowPopover() {
        let scanStatus: String
        switch state {
        case .scanning:
            scanStatus = "ultrasonic_room_scan_loading"
        case .roomFound, .connected:
            scanStatus = "ultrasonic_room_found"
        case .roomNotFound:
            scanStatus = "ultrasonic_room_not_found"
        default:
            return
        }
        VCTracker.post(name: .vc_ultrasonic_popover_view, params: [
            "ultrasonic_room_scan_status": scanStatus,
            "is_popup_from": provider.popoverFrom,
            "is_share": provider.isSharingContent
        ])
    }

    func trackConnect() {
        VCTracker.post(name: .vc_ultrasonic_popover_click, params: [.click: "connect", "is_popup_from": provider.popoverFrom])
    }

    func trackConnectWhenPreview() {
        if provider.popoverFrom == .preview {
            VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "connect_room"])
        }
    }

    func trackDisconnect() {
        VCTracker.post(name: .vc_ultrasonic_popover_click, params: [.click: "disconnect", "is_popup_from": provider.popoverFrom])
        if provider.popoverFrom == .inMeet {
            VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "disconnect_room"])
            if let source = source {
                VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "disconnect_room", .from_source: source.track])
            }
        } else if provider.popoverFrom == .preview {
            VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "disconnect_room"])
        }
    }

    func trackVerifyCodeResult(isSuccess: Bool) {
        let click = isSuccess ? "input_share_code_success" : "input_share_code_wrong"
        VCTracker.post(name: .vc_ultrasonic_popover_click, params: [.click: click, "is_popup_from": provider.popoverFrom])
    }

    func trackDisconnectConfirm() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "ultrasonic_room_disconnect_confirm"])
        if provider.popoverFrom == .inMeet {
            VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "disconnect_room"])
        }
    }

    func trackRescan() {
        VCTracker.post(name: .vc_ultrasonic_popover_click, params: [
            .click: "refresh",
            "is_popup_from": provider.popoverFrom,
            "ultrasonic_room_scan_status": room == nil ? "ultrasonic_room_not_found" : "ultrasonic_room_found"
        ])
    }

    private class ScanTracks {
        private let startTime = CACurrentMediaTime()
        private let uuid = UUID().uuidString
        private let from: JoinRoomPopoverFrom
        private let isUserAction: Bool

        init(isUserAction: Bool, from: JoinRoomPopoverFrom) {
            self.from = from
            self.isUserAction = isUserAction
            VCTracker.post(name: .vc_client_signal_dev, params: [.action_name: "ultrasonic_load_request", "uss_scan_id": uuid])
        }

        func onUltrawaveSuccess(code: String) {
            VCTracker.post(name: .vc_client_signal_dev, params: [.action_name: "ultrasonic_load_result", "uss_scan_id": uuid,
                                                                 "result_code": "\(code.hash)"])
        }

        func onUltrawaveFail() {
            VCTracker.post(name: .vc_client_signal_dev, params: [.action_name: "ultrasonic_load_result", "uss_scan_id": uuid])
        }

        func onRoomFound(room: ByteviewUser, status: GetShareCodeInfoResponse.StatusCode) {
            VCTracker.post(name: .vc_ultrasonic_status, params: ["room_scan_status": "ultrasonic_room_found",
                                                                 "uss_scan_id": uuid,
                                                                 "scan_type": "\(from.trackText)_manual",
                                                                 "scan_duration": Int((CACurrentMediaTime() - startTime) * 1000),
                                                                 "scan_room_id": room.id,
                                                                 "connect_type": "\(from.trackText)_manual",
                                                                 "connect_room_status": status.trackText])
            if isUserAction, from == .preview {
                let roomAudioStatus = status == .roomTaken ? "occupied" : "normal"
                VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "rescan", "room_audio_status": roomAudioStatus])
            }
        }

        func onRoomNotFound() {
            VCTracker.post(name: .vc_ultrasonic_status, params: ["room_scan_status": "ultrasonic_room_not_found",
                                                                 "uss_scan_id": uuid,
                                                                 "connect_type": "\(from.trackText)_manual",
                                                                 "connect_room_status": "room_not_found"])
            if isUserAction, from == .preview {
                VCTracker.post(name: .vc_meeting_pre_click, params: [.click: "rescan", "room_audio_status": "no_result"])
            }
        }
    }
}

private extension GetShareCodeInfoResponse.StatusCode {
    var isRoomFound: Bool {
        switch self {
        case .success, .roomTaken, .roomNeedVerify:
            return true
        default:
            return false
        }
    }

    var trackText: String {
        switch self {
        case .success:
            return "connect_ready"
        case .roomTaken:
            return "room_occupied"
        case .roomNeedVerify:
            return "room_found_input_share_code"
        default:
            return ""
        }
    }
}

enum JoinRoomConnectionState {
    case none
    case automatic
    case manual
}

enum JoinRoomVerifyCodeState {
    case idle
    case loading
    case success
    case error
}

enum JoinRoomScanState: Equatable, CustomStringConvertible {
    case idle
    case scanning
    case roomFound(GetShareCodeInfoResponse.StatusCode)
    case verifyCode
    case roomNotFound
    case connected

    var isRoomTaken: Bool {
        switch self {
        case .roomFound(.roomTaken):
            return true
        default:
            return false
        }
    }

    var canConnect: Bool {
        switch self {
        case .roomFound(.success), .verifyCode:
            return true
        default:
            return false
        }
    }

    var description: String {
        switch self {
        case .idle:
            return "idle"
        case .scanning:
            return "scanning"
        case .roomFound(let statusCode):
            return "roomFound(\(statusCode))"
        case .roomNotFound:
            return "roomNotFound"
        case .verifyCode:
            return "verifyCode"
        case .connected:
            return "connected"
        }
    }
}

private extension JoinRoomPopoverFrom {
    var trackText: String {
        switch self {
        case .preview, .prelobby:
            return "preview"
        case .inMeet:
            return "onthecall"
        }
    }
}
