//
//  MeetingServiceImpl.swift
//  LarkByteView
//
//  Created by chentao on 2019/4/18.
//

import Foundation
import AppContainer
import LarkContainer
import ByteViewCommon
import ByteViewInterface
import ByteView
import ByteViewNetwork
import ByteViewSetting
import ByteViewMeeting
import ByteViewUI
import AVFoundation
import UniverseDesignIcon
import LarkShortcut

extension Logger {
    static let interface = getLogger("Interface")
}

final class MeetingServiceImpl: MeetingService {
    private let logger = Logger.interface
    private let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private func resolveDependency() throws -> MeetingDependency {
        try MeetingDependencyImpl(userResolver: userResolver)
    }

    var isCompanyCallEnabled: Bool {
        if let service = try? userResolver.resolve(assert: UserSettingManager.self) {
            return service.isEnterprisePhoneEnabled
        } else {
            return false
        }
    }

    private lazy var associatedMeetingService: AssociatedMeetingService? = {
        try? AssociatedMeetingService(userResolver: userResolver)
    }()

    func getAssociatedMeeting(groupId: String, callback: @escaping (Result<String?, Error>) -> Void) {
        if let service = self.associatedMeetingService {
            service.getAssociatedMeetingId(groupId: groupId, callback: callback)
        } else {
            callback(.failure(CommonError.serviceNotFound))
        }
    }

    lazy var resources: MeetingResources = MeetingResourcesImpl()

    var isCameraDenied: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) != .authorized
    }

    var isMicrophoneDenied: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) != .authorized
    }

    func showCameraAlert() {
        ByteViewDialog.Builder()
            .id(.camera)
            .title(I18n.View_VM_AccessToCameraDenied)
            .message(I18n.View_VM_NeedsCameraAppNameBraces(Util.appName))
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_Settings)
            .rightHandler({ _ in
                Self.openSettings()
            })
            .show()
    }

    func showMicrophoneAlert() {
        ByteViewDialog.Builder()
            .id(.microphone)
            .title(I18n.View_VM_AccessToMicDenied)
            .message(I18n.View_G_NeedsMicAppNameBraces(Util.appName))
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_Settings)
            .rightHandler({ _ in
                Self.openSettings()
            })
            .show()
    }

    private static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func createMeetingObserver() -> ByteViewInterface.MeetingObserver {
        MeetingObserverImpl()
    }

    func floatingOrDismissWindow() {
        if let meeting = self.currentMeeting,
           let client = try? userResolver.resolve(assert: ShortcutService.self).getClient(.vc) {
            client.run(FloatWindowAction(sessionId: meeting.sessionId, isFloating: true, leaveWhenUnfloatable: true))
        }
    }
}

import RxSwift
private final class AssociatedMeetingService {
    private static let logger = Logger.getLogger("AssociatedMeetingService")
    private var pushSubject = PublishSubject<GetAssociatedVideoChatStatusResponse>()
    private let disposeBag = DisposeBag()
    private let httpClient: HttpClient

    init(userResolver: UserResolver) throws {
        self.httpClient = try userResolver.resolve(assert: HttpClient.self)
        Push.associatedVideoChatStatus.inUser(userResolver.userID).addObserver(self) { [weak self] in
            self?.didGetAssociatedVideoChatStatus($0)
        }
    }

    func didGetAssociatedVideoChatStatus(_ status: GetAssociatedVideoChatStatusResponse) {
        pushSubject.onNext(status)
    }

    func getAssociatedMeetingId(groupId: String, callback: @escaping (Result<String?, Error>) -> Void) {
        httpClient.getResponse(GetAssociatedVideoChatStatusRequest(id: groupId, idType: .groupID)) { [weak self] result in
            guard let self = self else { return }
            if case .success(let resp) = result {
                callback(.success(resp.activeMeetingId))
            }
            self.pushSubject.filter { $0.id == groupId && $0.idType == .groupID }.subscribe(onNext: { resp in
                callback(.success(resp.activeMeetingId))
            }).disposed(by: self.disposeBag)
        }
    }
}

final class MeetingResourcesImpl: MeetingResources {
    var serviceCallName: String { I18n.View_V_VideoCallName }
    var serviceCallIcon: UIImage { UDIcon.getIconByKey(.videoOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24))  }
    var isInCallText: String { I18n.View_G_CurrentlyInCall }
    var inRingingCannotJoinMeeting: String { I18n.View_M_IncomingCallCannotJoin }
    var inRingingCannotCallVoIP: String { I18n.View_G_IncomingCallCannotCall }
}

private final class MeetingObserverImpl: ByteViewInterface.MeetingObserver, ByteView.MeetingObserverDelegate {
    private let observer = ByteView.MeetingObserver()
    private weak var delegate: ByteViewInterface.MeetingObserverDelegate?
    var meetings: [ByteViewInterface.Meeting] { observer.meetings.map(MeetingImpl.init(_:)) }
    func setDelegate(_ delegate: ByteViewInterface.MeetingObserverDelegate?) {
        self.observer.setDelegate(self)
        self.delegate = delegate
    }
    func meetingObserver(_ observer: ByteView.MeetingObserver, meetingChanged meeting: ByteView.MeetingObserver.Meeting, oldValue: ByteView.MeetingObserver.Meeting?) {
        self.delegate?.meetingObserver(self, meetingChanged: MeetingImpl(meeting), oldValue: oldValue.map(MeetingImpl.init(_:)))
    }
}

private struct MeetingImpl: ByteViewInterface.Meeting {
    let proxy: ByteView.MeetingObserver.Meeting
    init(_ proxy: ByteView.MeetingObserver.Meeting) {
        self.proxy = proxy
    }
    var sessionId: String { proxy.sessionId }
    var meetingId: String { proxy.meetingId }
    var type: ByteViewInterface.MeetingType { proxy.type.toInterface() }
    var isPending: Bool { proxy.isPending }
    var state: ByteViewInterface.MeetingState  { proxy.state.toInterface() }
    var windowInfo: ByteViewInterface.MeetingWindowInfo { MeetingWindowInfoImpl(proxy.windowInfo) }
    var isMicrophoneMuted: Bool { proxy.isMicrophoneMuted }
    var isCameraMuted: Bool { proxy.isCameraMuted }
    var isCameraEffectOn: Bool { proxy.isCameraEffectOn }
    var isSharingDocument: Bool { proxy.isSharingDocument }
    var isBoxSharing: Bool { proxy.isBoxSharing }
    var isCallKit: Bool { proxy.isCallKit }
    var magicSharePerformanceInfo: ByteViewInterface.MeetingMagicSharePerfInfo { MeetingMagicSharePerfInfoImpl(proxy.magicSharePerformanceInfo) }
}

private struct MeetingWindowInfoImpl: ByteViewInterface.MeetingWindowInfo {
    let proxy: ByteView.MeetingObserver.WindowInfo
    init(_ proxy: ByteView.MeetingObserver.WindowInfo) {
        self.proxy = proxy
    }
    var hasWindow: Bool { proxy.hasWindow }
    var isFloating: Bool { proxy.isFloating }
    var isAuxScene: Bool { proxy.isAuxScene }
    @available(iOS 13.0, *)
    var windowScene: UIWindowScene? { proxy.windowScene }
}

private extension ByteViewNetwork.MeetingType {
    func toInterface() -> ByteViewInterface.MeetingType {
        switch self {
        case .call:
            return .call
        case .meet:
            return .meet
        default:
            return .unknown
        }
    }
}

private extension ByteViewMeeting.MeetingState {
    func toInterface() -> ByteViewInterface.MeetingState {
        switch self {
        case .start:
            return .start
        case .preparing:
            return .preparing
        case .dialing:
            return .dialing
        case .calling:
            return .calling
        case .ringing:
            return .ringing
        case .prelobby:
            return .prelobby
        case .lobby:
            return .lobby
        case .onTheCall:
            return .onTheCall
        case .end:
            return .end
        @unknown default:
            fatalError()
        }
    }
}

private struct MeetingMagicSharePerfInfoImpl: ByteViewInterface.MeetingMagicSharePerfInfo {
    let proxy: ByteView.MeetingObserver.MagicSharePerformanceInfo
    init(_ proxy: ByteView.MeetingObserver.MagicSharePerformanceInfo) {
        self.proxy = proxy
    }
    /// 妙享性能表现总评分
    var level: CGFloat { proxy.level }
    /// 系统负载开关评分
    var systemLoadScore: CGFloat { proxy.systemLoadScore }
    /// 系统负载动态评分
    var dynamicScore: CGFloat { proxy.dynamicScore }
    /// 设备温度评分
    var thermalScore: CGFloat { proxy.thermalScore }
    /// 创建文档频率评分
    var openDocScore: CGFloat { proxy.openDocScore }
}
