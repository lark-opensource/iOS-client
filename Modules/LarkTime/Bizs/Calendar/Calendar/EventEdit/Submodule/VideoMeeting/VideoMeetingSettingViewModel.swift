//
//  VideoMeetingSettingViewModel.swift
//  Calendar
//
//  Created by zhuheng on 2021/4/9.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RustPB
import UniverseDesignIcon
import LarkContainer
import LKCommonsLogging

struct VideoURLInputViewData: VideoURLInputViewDataType {
    var isVisible: Bool = false
    var customSummary: String?
    var summaryPlaceHolder: String?
    var url: String?
    var icon: UIImage = UDIcon.emptyFilled
    var urlLengthLimit = 400  // 服务端支持的最大 url 长度
}

struct VideoTypeSelectViewData: VideoTypeSelectViewDataType {
    var isVisible: Bool = false
    var isSelectFeishu: Bool = false
    var showSettings: Bool = false
    var selectedVideoType: VideoItemType = .unknown
    var zoomInfo: ZoomInfo = ZoomInfo(zoomStatus: .inital)
}

struct ZoomInfo {
    var zoomStatus: ZoomAccountStatus = .inital
    var zoomMeetingConfig: Server.ZoomVideoMeetingConfigs?
    public init (zoomStatus: ZoomAccountStatus, zoomMeetingConfig: Server.ZoomVideoMeetingConfigs? = nil) {
        self.zoomStatus = zoomStatus
        self.zoomMeetingConfig = zoomMeetingConfig
    }
}

final class VideoMeetingSettingViewModel: UserResolverWrapper {

    private let logger = Logger.log(VideoMeetingSettingViewModel.self, category: "calendar.VideoMeetingSettingViewModel")

    private(set) var rxVideoInputViewData: BehaviorRelay<VideoURLInputViewDataType> = .init(value: VideoURLInputViewData())
    private(set) var rxVideoTypeSelectViewData: BehaviorRelay<VideoTypeSelectViewDataType> = .init(value: VideoTypeSelectViewData())
    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?

    let userResolver: UserResolver
    let rxVideoMeeting: BehaviorRelay<Rust.VideoMeeting>
    let rxZoomInfo: BehaviorRelay<ZoomInfo>
    let rxRoute = PublishRelay<Route>()
    let rxToast = PublishRelay<ToastStatus>()

    var zoomAuthUrl: String?
    var organizerID: String?
    private let permissions: PermissionOption
    private let disposeBag = DisposeBag()
    private var originalVideoMeetingType: Rust.VideoMeeting.VideoMeetingType
    private var customVideoURL: String?
    let key: String
    let originalTime: Int64
    let instanceStartTime: Int64
    let instanceEndTime: Int64
    let event: EventEditModel
    var localZoomConfig: Rust.ZoomVideoMeetingConfigs?

    init(event: EventEditModel, permissions: PermissionOption, userResolver: UserResolver) {
        self.event = event
        self.userResolver = userResolver
        self.rxVideoMeeting = BehaviorRelay(value: event.videoMeeting)
        self.rxZoomInfo = BehaviorRelay(value: ZoomInfo(zoomStatus: .inital))
        self.permissions = permissions
        self.organizerID = event.calendar?.userChatterId
        self.originalVideoMeetingType = event.videoMeeting.videoMeetingType
        self.key = event.getPBModel().key
        self.originalTime = event.getPBModel().originalTime
        self.instanceStartTime = event.getPBModel().startTime
        self.instanceEndTime = event.getPBModel().endTime
        if case .other = event.videoMeeting.videoMeetingType {
            self.customVideoURL = event.videoMeeting.meetingURL
        }
        bindVideoTypeSelectViewData()
        bindVideoInputViewData()
    }

    private func bindVideoTypeSelectViewData() {
        // 如果初始状态 默认为zoom会议，则认为此zoom会议状态为normal
        if rxVideoMeeting.value.videoMeetingType == .zoomVideoMeeting {
            rxZoomInfo.accept(ZoomInfo(zoomStatus: .normal, zoomMeetingConfig: zoomConfigModelTransferToServer(rustConfig: rxVideoMeeting.value.zoomConfigs)))
            localZoomConfig = rxVideoMeeting.value.zoomConfigs
        }

        let transform = { [weak self] (videoMeeting: Rust.VideoMeeting, zoomInfo: ZoomInfo) -> VideoTypeSelectViewData in
            guard let self = self else { return VideoTypeSelectViewData() }
            let isVisible = videoMeeting.videoMeetingType != .noVideoMeeting
            let isSelectFeishuVideo: Bool = videoMeeting.videoMeetingType != .other
            var itemType: VideoItemType = .unknown
            switch videoMeeting.videoMeetingType {
            case .vchat:
                itemType = .feishu
            case .zoomVideoMeeting:
                itemType = .zoom
            @unknown default:
                itemType = .custom
                break
            }
            return VideoTypeSelectViewData(isVisible: isVisible,
                                           isSelectFeishu: isSelectFeishuVideo,
                                           selectedVideoType: itemType,
                                           zoomInfo: zoomInfo)
        }

        let viewData = transform(rxVideoMeeting.value, rxZoomInfo.value)
        rxVideoTypeSelectViewData = BehaviorRelay(value: viewData)
        Observable.combineLatest(rxVideoMeeting, rxZoomInfo)
            .map { transform($0.0, $0.1) }
            .bind(to: rxVideoTypeSelectViewData)
            .disposed(by: disposeBag)
    }

    private func bindVideoInputViewData() {
        let transform = { (videoMeeting: Rust.VideoMeeting) -> VideoURLInputViewData in
            var placeHolder: String = BundleI18n.Calendar.Calendar_Edit_JoinVC

            let isVisible = videoMeeting.videoMeetingType == .other
            var videoInputViewData: VideoURLInputViewData
            if case .otherConfigs(let configs) = videoMeeting.customizedConfigs {
                let customSummary = configs.customizedDescription

                if customSummary.isEmpty {
                    switch configs.icon {
                    case .live:
                        placeHolder = BundleI18n.Calendar.Calendar_Edit_EnterLivestream
                    case .videoMeeting:
                        placeHolder = BundleI18n.Calendar.Calendar_Edit_JoinVC
                    @unknown default:
                        break
                    }
                }
                videoInputViewData = VideoURLInputViewData(
                    isVisible: isVisible,
                    customSummary: customSummary,
                    summaryPlaceHolder: placeHolder,
                    url: self.customVideoURL,
                    icon: videoMeeting.videoMeetingIconType.iconNormal)

            } else {
                videoInputViewData = VideoURLInputViewData(
                    isVisible: isVisible,
                    customSummary: "",
                    summaryPlaceHolder: placeHolder,
                    url: nil,
                    icon: videoMeeting.videoMeetingIconType.iconNormal)

            }

            return videoInputViewData
        }

        let videoInputViewData = transform(rxVideoMeeting.value)
        rxVideoInputViewData = BehaviorRelay(value: videoInputViewData)
        rxVideoMeeting.map { transform($0) }.bind(to: rxVideoInputViewData).disposed(by: disposeBag)
    }

    // 此函数看起来没用被使用
    func updateVCBindingData(vcSettingId: String) {
        var videoMeeting = rxVideoMeeting.value
        videoMeeting.larkVcBindingData.vcSettingID = vcSettingId
        rxVideoMeeting.accept(videoMeeting)
    }

    func onVideoTypeChange(videoType: VideoItemType) {
        var videoMeeting = rxVideoMeeting.value
        switch videoType {
        case .feishu:
            videoMeeting.videoMeetingType = .vchat
        case .zoom:
            videoMeeting.videoMeetingType = .zoomVideoMeeting
        default:
            videoMeeting.videoMeetingType = .other
        }

        if videoMeeting.videoMeetingType == .zoomVideoMeeting && rxZoomInfo.value.zoomStatus == .inital {
            loadZoomAccount()
        }

        rxVideoMeeting.accept(videoMeeting)
    }

    func onVideoOpenSwitch(isOn: Bool) {
        var videoMeeting = rxVideoMeeting.value
        if isOn {
            if originalVideoMeetingType == .noVideoMeeting {
                videoMeeting.videoMeetingType = .vchat
                originalVideoMeetingType = videoMeeting.videoMeetingType
            } else {
                videoMeeting.videoMeetingType = originalVideoMeetingType
            }
        } else {
            originalVideoMeetingType = videoMeeting.videoMeetingType
            videoMeeting.videoMeetingType = .noVideoMeeting
        }
        rxVideoMeeting.accept(videoMeeting)
    }

    func onVideoIconChange(iconType: Rust.VideoMeetingIconType) {
        var videoMeeting = rxVideoMeeting.value
        guard videoMeeting.videoMeetingType == .other else {
            return
        }

        if case .otherConfigs(var configs) = videoMeeting.customizedConfigs {
            configs.icon = iconType
            videoMeeting.customizedConfigs = .otherConfigs(configs)
            rxVideoMeeting.accept(videoMeeting)
        } else {
            var configs = RustPB.Calendar_V1_EventVideoMeetingConfig.OtherVideoMeetingConfigs()
            configs.icon = iconType
            videoMeeting.customizedConfigs = .otherConfigs(configs)
            rxVideoMeeting.accept(videoMeeting)
        }
    }

    func onSave(customSummary: String, customUrl: String) {
        var videoMeeting = rxVideoMeeting.value
        guard videoMeeting.videoMeetingType == .other else {
            return
        }
        customVideoURL = customUrl

        var configs = Calendar_V1_EventVideoMeetingConfig.OtherVideoMeetingConfigs()
        if case .otherConfigs(let originalConfig) = videoMeeting.customizedConfigs {
            configs = originalConfig
        }

        if (customSummary == BundleI18n.Calendar.Calendar_Edit_EnterLivestream && configs.icon == .live)
            || (customSummary == BundleI18n.Calendar.Calendar_Edit_JoinVC && configs.icon == .videoMeeting) {
            // 使用默认文案传""
            configs.customizedDescription = ""
        } else {
            configs.customizedDescription = customSummary
        }

        videoMeeting.meetingURL = customUrl
        videoMeeting.customizedConfigs = .otherConfigs(configs)
        rxVideoMeeting.accept(videoMeeting)
    }

    func onSave() {
        var videoMeeting = rxVideoMeeting.value
        guard videoMeeting.videoMeetingType == .zoomVideoMeeting else {
            return
        }

        videoMeeting.zoomConfigs = zoomConfigModelTransferToRust(serverConfig: rxZoomInfo.value.zoomMeetingConfig)
        videoMeeting.meetingURL = rxZoomInfo.value.zoomMeetingConfig?.meetingURL ?? ""
        rxVideoMeeting.accept(videoMeeting)
    }

    func needShowNoUrlAlert() -> Bool {
        if rxVideoMeeting.value.meetingURL.isEmpty
            && rxVideoMeeting.value.videoMeetingType == .other {
            return true
        }
        return false
    }

    func needBindZoomAccount() -> Bool {
        var videoMeeting = rxVideoMeeting.value
        if videoMeeting.videoMeetingType == .zoomVideoMeeting && rxZoomInfo.value.zoomStatus != .normal {
            return true
        }
        return false
    }

    func refreshZoomStatus(status: ZoomAccountStatus) {
        switch status {
        case .unbind, .expired:
            if let url = zoomAuthUrl {
                goOauthVerify(authUrl: url)
            }
        case .datafail:
            createZoomMeeting()
        default: break
        }
    }

    func createZoomMeeting() {
        CalendarMonitorUtil.startTrackZoomMeetingCreate()
        calendarAPI?.createZoomMeetingRequest(startTime: instanceStartTime, startTimeZone: event.getPBModel().startTimezone, topic: event.getPBModel().summary, duration: (instanceEndTime - instanceStartTime) / 60, isRecurrence: !event.getPBModel().rrule.isEmpty)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.rxZoomInfo.accept(ZoomInfo(zoomStatus: .normal,
                                                zoomMeetingConfig: res.zoomMeeting))
                self.localZoomConfig = self.zoomConfigModelTransferToRust(serverConfig: res.zoomMeeting)
                CalendarTracerV2.EventFullCreate.traceClick {
                    $0.click("add_zoom_vc_success")
                }
                CalendarMonitorUtil.endTrackZoomMeetingCreate()
            }, onError: { error in
                if error.errorType() == .calendarZoomAuthenticationFailed {
                    self.rxZoomInfo.accept(ZoomInfo(zoomStatus: .expired))
                    CalendarTracerV2.EventFullCreate.traceClick {
                        $0.click("add_zoom_vc_fail")
                        $0.reason = "auth_failed"
                    }
                } else {
                    CalendarTracerV2.EventFullCreate.traceClick {
                        $0.click("add_zoom_vc_fail")
                        $0.reason = "others"
                    }
                    self.rxZoomInfo.accept(ZoomInfo(zoomStatus: .datafail))
                }
            }).disposed(by: self.disposeBag)
    }

    func loadZoomAccount() {
        rxZoomInfo.accept(ZoomInfo(zoomStatus: .loading))

        calendarAPI?.getZoomAccountRequest()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                switch response.status {
                case .normal:
                    self.createZoomMeeting()
                case .expired:
                    self.rxZoomInfo.accept(ZoomInfo(zoomStatus: .expired))
                case .unbind:
                    self.rxZoomInfo.accept(ZoomInfo(zoomStatus: .unbind))
                @unknown default:
                    break
                }
                self.zoomAuthUrl = response.zoomAuthURL
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("loadZoomAccount failed with: \(error)")
                self.rxZoomInfo.accept(ZoomInfo(zoomStatus: .datafail))
            }).disposed(by: self.disposeBag)
    }

    private func goOauthVerify(authUrl: String) {
        if let url = URL(string: authUrl), !authUrl.isEmpty {
            self.logger.info("jump ZoomAccount auth page")
            rxRoute.accept(.url(url: url))
        } else {
            rxToast.accept(.failure(BundleI18n.Calendar.Calendar_GoogleCal_TryLater))
            self.rxZoomInfo.accept(ZoomInfo(zoomStatus: .unbind))
        }
    }

    private func zoomConfigModelTransferToRust(serverConfig: Server.ZoomVideoMeetingConfigs?) -> Rust.ZoomVideoMeetingConfigs {
        var config: Rust.ZoomVideoMeetingConfigs = Rust.ZoomVideoMeetingConfigs()
        if let serverConfig = serverConfig {
            config.meetingID = serverConfig.meetingID
            config.meetingNo = serverConfig.meetingNo
            config.creatorAccount = serverConfig.creatorAccount
            config.meetingURL = serverConfig.meetingURL
            config.password = serverConfig.password
            config.isEditable = serverConfig.isEditable
            config.creatorUserID = serverConfig.creatorUserID
        }
        return config
    }

    private func zoomConfigModelTransferToServer(rustConfig: Rust.ZoomVideoMeetingConfigs?) -> Server.ZoomVideoMeetingConfigs {
        var config: Server.ZoomVideoMeetingConfigs = Server.ZoomVideoMeetingConfigs()
        if let rustConfig = rustConfig {
            config.meetingID = rustConfig.meetingID
            config.meetingNo = rustConfig.meetingNo
            config.creatorAccount = rustConfig.creatorAccount
            config.meetingURL = rustConfig.meetingURL
            config.password = rustConfig.password
            config.isEditable = rustConfig.isEditable
            config.creatorUserID = rustConfig.creatorUserID
        }
        return config
    }
}

extension VideoMeetingSettingViewModel {
    enum Route {
        case url(url: URL)
    }
}

extension Rust.VideoMeeting {
    var videoMeetingIconType: Rust.VideoMeetingIconType {
        if case .larkLiveHost = videoMeetingType {
            return .live
        }
        if case .other = videoMeetingType {
            if case .otherConfigs(let otherVideoMeetingConfig) = customizedConfigs {
                if case .live = otherVideoMeetingConfig.icon {
                    return .live
                } else {
                    return .videoMeeting
                }
            }
        }
        return .videoMeeting
    }

    func isEqual(to model: Rust.VideoMeeting) -> Bool {
        if videoMeetingType != model.videoMeetingType {
            return false
        }

        if meetingURL != model.meetingURL {
            return false
        }

        if case .otherConfigs(let configs) = customizedConfigs,
           case .otherConfigs(let toConfigs) = model.customizedConfigs {
            if configs.icon != toConfigs.icon {
                return false
            }

            if configs.customizedDescription != toConfigs.customizedDescription {
                return false
            }
        }

        return true
    }
}

extension Rust.VideoMeetingIconType {
    var iconNormal: UIImage {
        switch self {
        case .live:
            return UDIcon.getIconByKeyNoLimitSize(.livestreamOutlined).renderColor(with: .n3)
        @unknown default:
            return UDIcon.getIconByKeyNoLimitSize(.videoOutlined).renderColor(with: .n3)
        }
    }

    var iconGary: UIImage {
        switch self {
        case .live:
            return UDIcon.getIconByKeyNoLimitSize(.livestreamOutlined).renderColor(with: .n3)
        @unknown default:
            return UDIcon.getIconByKeyNoLimitSize(.videoOutlined).renderColor(with: .n3)
        }
    }
}
