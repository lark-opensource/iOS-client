//
//  InMeetTrackViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewNetwork
import ByteViewTracker
import LarkMedia

final class InMeetTrackViewModel: InMeetDataListener, InMeetingChangedInfoPushObserver, InMeetCameraListener {
    static let logger = Logger.ui
    let disposeBag = DisposeBag()
    private let meetingId: String
    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private var isFirstLoadSuggestedParticipants: Bool = true
    private var effectManger: MeetingEffectManger?

    init(resolver: InMeetViewModelResolver) {
        let meeting = resolver.meeting
        self.meetingId = meeting.meetingId
        self.meeting = meeting
        self.context = resolver.viewContext
        self.effectManger = meeting.effectManger
        self.isMyCameraMutedRelay = BehaviorRelay(value: meeting.camera.isMuted)
        self.virtualBgChangedRelay = BehaviorRelay(value: effectManger?.virtualBgService.currentVirtualBgsModel)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        meeting.camera.addListener(self)
        DispatchQueue.global().async { [weak self] in
            self?.trackLab()
            self?.configEffectTracks()
            self?.trackSetting()
        }
    }

    deinit {
        effectManger?.virtualBgService.removeListener(self)
        effectManger?.pretendService.removeListener(self)
        endLabTrack()
    }

    func didReceiveInMeetingChangedInfo(_ message: InMeetingData) {
        // 多人会议主持人转移
        if message.meetingID == self.meetingId, message.type == .hostTransferred, let host = message.hostTransferData?.host {
            TrackContext.shared.updateContext(for: meeting.sessionId) { context in
                context.host = host
            }
        }
    }

    private func trackLab() {
        if let effectManger = effectManger {
            LabTrack.trackOnTheCall(meetType: meeting.type, effectManger: effectManger)
        }
    }

    /// 入会时性能静态检测与会中特效生效状态监控埋点
    /// 特效生效 = 特效开启 & 会中摄像头开启
    private func configEffectTracks() {
        initTracks()
        bindData()
        effectManger?.virtualBgService.addListener(self)
        effectManger?.pretendService.addListener(self)
    }

    /// 入会时埋点
    private func initTracks() {
        trackForbiddenFeatures()
        trackCurrentEffects()
    }

    /// 离会时埋点
    private func endLabTrack() {
        trackCurrentEffects(forceClose: true)
    }

    /// 绑定数据流
    private func bindData() {
        bindVirtualBgTrack()
        bindAnimojiTrack()
        bindFilterTrack()
        bindBeauty()
    }

    private let isMyCameraMutedRelay: BehaviorRelay<Bool>
    private var isMyCameraMutedObservable: Observable<Bool> {
        isMyCameraMutedRelay.asObservable().distinctUntilChanged().share()
    }

    private let virtualBgChangedRelay: BehaviorRelay<VirtualBgModel?>
    private var virtualBgChangedObservable: Observable<VirtualBgModel> {
        virtualBgChangedRelay.asObservable().compactMap { $0 }.share()
    }

    private var effectModelChangedSubject = PublishSubject<ByteViewEffectModel?>()

    private var effectModelChangedObservable: Observable<ByteViewEffectModel?> {
        return effectModelChangedSubject.asObservable().share()
    }
    private var animojiModelChangedObservable: Observable<ByteViewEffectModel> {
        return effectModelChangedObservable.compactMap { $0 }
            .filter { $0.labType == .animoji }
    }
    private var filterModelChangedObservable: Observable<ByteViewEffectModel> {
        return effectModelChangedObservable.compactMap { $0 }
            .filter { $0.labType == .filter }
    }
    private var beautyModelChangedObservable: Observable<ByteViewEffectModel> {
        return effectModelChangedObservable.compactMap { $0 }
            .filter { $0.labType == .retuschieren }
    }

    func didChangeCameraMuted(_ camera: InMeetCameraManager) {
        let isMuted = camera.isMuted
        isMyCameraMutedRelay.accept(isMuted)
    }

    /// 美颜参数字典，用来比较两次美颜数据是否有变化
    var beautyDictionary = [String: String]()

    private func bindVirtualBgTrack() {
        // vbg变化，video打开，埋点
        virtualBgChangedObservable
            .filterByLatestFrom(isMyCameraMutedObservable.map { !$0 })
            .subscribe(onNext: { [weak self] (virtualBgModel: VirtualBgModel) in
                let isVBgEffective = virtualBgModel.bgType != .setNone
                self?.effectManger?.isVirtualBgEffective = isVBgEffective
                LabTrack.trackVirtualBg(virtualBgModel, isVirtualBgEffective: isVBgEffective)
            }).disposed(by: disposeBag)
        // video开关变化，如判断vbg的effective，埋点
        isMyCameraMutedObservable
            .skip(1)
            .subscribe(onNext: { [weak self] (isMyVideoMuted: Bool) in
                guard let labBgService = self?.effectManger?.virtualBgService,
                      let curVBgModel = labBgService.currentVirtualBgsModel else {
                    return
                }
                let curVBgEffective: Bool = (curVBgModel.bgType != .setNone) && !isMyVideoMuted
                let lastVBgEffective = self?.effectManger?.isVirtualBgEffective
                if curVBgEffective != lastVBgEffective {
                    self?.effectManger?.isVirtualBgEffective = curVBgEffective
                    LabTrack.trackVirtualBg(curVBgModel, isVirtualBgEffective: curVBgEffective)
                }
            }).disposed(by: disposeBag)
    }

    private func bindAnimojiTrack() {
        // animoji变化，video打开时，埋点
        animojiModelChangedObservable
            .filterByLatestFrom(isMyCameraMutedObservable.map { !$0 })
            .subscribe(onNext: { [weak self] (animojiModel: ByteViewEffectModel) in
                let isAniEffective = animojiModel.bgType != .none
                self?.effectManger?.isAnimojiEffective = isAniEffective
                LabTrack.trackAnimoji(animojiModel, isAnimojiEffective: isAniEffective)
            }).disposed(by: disposeBag)
        // animoji开关变化，判断animoji的effective，埋点
        isMyCameraMutedObservable
            .skip(1)
            .subscribe(onNext: { [weak self] (isMyVideoMuted: Bool) in
                guard let effectManger = self?.effectManger,
                      let curAniModel = effectManger.pretendService.currentAnimojiModel else {
                    return
                }
                let curAniEffective: Bool = (curAniModel.bgType != .none) && !isMyVideoMuted
                let lastAniEffective = effectManger.isAnimojiEffective
                if curAniEffective != lastAniEffective {
                    effectManger.isAnimojiEffective = curAniEffective
                    LabTrack.trackAnimoji(curAniModel, isAnimojiEffective: curAniEffective)
                }
            }).disposed(by: disposeBag)
    }

    private func bindFilterTrack() {
        // filter变化，video打开时，埋点
        filterModelChangedObservable
            .filterByLatestFrom(isMyCameraMutedObservable.map { !$0 })
            .subscribe(onNext: { [weak self] (filterModel: ByteViewEffectModel) in
                let isFilEffective = filterModel.bgType != .none
                self?.effectManger?.isFilterEffective = isFilEffective
                self?.effectManger?.curFilterValue = filterModel.currentValue
                LabTrack.trackFilter(filterModel, isFilterEffective: isFilEffective)
            }).disposed(by: disposeBag)
        // video开关变化，判断filter的effective，埋点
        isMyCameraMutedObservable
            .skip(1)
            .subscribe(onNext: { [weak self] (isMyVideoMuted: Bool) in
                guard let effectManger = self?.effectManger,
                      let curFilModel = effectManger.pretendService.currentFilterModel else {
                    return
                }
                let curFilEffective: Bool = (curFilModel.bgType != .none) && !isMyVideoMuted
                let curFilValue = curFilModel.currentValue
                let lastFilEffective = effectManger.isFilterEffective
                let lastFilValue = effectManger.curFilterValue
                if curFilEffective != lastFilEffective || curFilValue != lastFilValue {
                    effectManger.isFilterEffective = curFilEffective
                    effectManger.curFilterValue = curFilValue
                    LabTrack.trackFilter(curFilModel, isFilterEffective: curFilEffective)
                }
            }).disposed(by: disposeBag)
    }

    private func bindBeauty() {
        // beauty变化，video打开时，埋点
        beautyModelChangedObservable
            .filterByLatestFrom(isMyCameraMutedObservable.map { !$0 })
            .subscribe(onNext: {[weak self] (beautyModel: ByteViewEffectModel) in
                let applyType = self?.effectManger?.pretendService.beautyCurrentStatus ?? .customize
                guard var curDic = self?.beautyDictionary,
                      let modelValue = beautyModel.applyValue(for: applyType),
                      (!curDic.keys.contains(beautyModel.resourceId) || curDic[beautyModel.resourceId] != "\(modelValue)") else {
                    return
                }
                curDic[beautyModel.resourceId] = "\(modelValue)"
                self?.beautyDictionary = curDic
                if let self = self {
                    LabTrack.trackBeauty(self.generateBeautyModelArray(), pretendService: self.effectManger?.pretendService)
                }
            }).disposed(by: disposeBag)
        // video开关变化时，判断beauty&videoMute的变化，埋点
        isMyCameraMutedObservable
            .skip(1)
            .subscribe(onNext: {[weak self] (isMyVideoMuted: Bool) in
                guard let effectManger = self?.effectManger else {
                    return
                }
                if let self = self {
                    let curBeautyModelArray = self.generateBeautyModelArray()
                    let curDic = self.generateBeautyDictionary(curBeautyModelArray)
                    if curDic != self.beautyDictionary || effectManger.isBeautyEffective != !isMyVideoMuted {
                        self.beautyDictionary = curDic
                        effectManger.isBeautyEffective = !isMyVideoMuted
                        LabTrack.trackBeauty(curBeautyModelArray, isBeautyEffective: !isMyVideoMuted, pretendService: effectManger.pretendService)
                    }
                }
            }).disposed(by: disposeBag)
    }

    /// 会中，检查特效是否满足静态检测，并埋点
    private func trackForbiddenFeatures() {
        let isEffectDisabled: Bool = !meeting.setting.featurePerformanceConfig.isEffectValid
        VCTracker.post(name: .vc_meeting_onthecall_view,
                       params: ["is_disabled": isEffectDisabled,
                                "disabled_feature": ["effect": isEffectDisabled ? 1 : 0]])
    }

    /// 入会时，检查特效是否生效，如果生效做相应埋点；离会时，检查生效中的特效，埋“关闭”
    /// - Parameters:
    ///   - forceEnd: 会议结束时传false，埋点参数为特效关闭
    private func trackCurrentEffects(forceClose: Bool = false) {
        guard !meeting.camera.isMuted else {
            // logger: video is muted, no need to track
            return
        }

        if let virtualBgModel = effectManger?.virtualBgService.currentVirtualBgsModel,
           virtualBgModel.bgType != .setNone {
            if forceClose {
                LabTrack.trackVirtualBg(virtualBgModel, isVirtualBgEffective: false)
            } else {
                effectManger?.isVirtualBgEffective = true
                LabTrack.trackVirtualBg(virtualBgModel)
            }
        }
        if let aniModel = effectManger?.pretendService.currentAnimojiModel {
            if forceClose {
                LabTrack.trackAnimoji(aniModel, isAnimojiEffective: false)
            } else if aniModel.bgType != .none {
                effectManger?.isAnimojiEffective = true
                LabTrack.trackAnimoji(aniModel)
            }
        }
        if let filModel = effectManger?.pretendService.currentFilterModel,
           filModel.bgType != .none {
            if forceClose {
                LabTrack.trackFilter(filModel, isFilterEffective: false)
            } else {
                effectManger?.isFilterEffective = true
                effectManger?.curFilterValue = filModel.currentValue
                LabTrack.trackFilter(filModel)
            }
        }
        if let retArray = effectManger?.pretendService.retuschierenArray,
           effectManger?.pretendService.isBeautyOn() == true {
            if forceClose {
                LabTrack.trackBeauty(retArray, isBeautyEffective: false, pretendService: effectManger?.pretendService)
            } else {
                self.beautyDictionary = self.generateBeautyDictionary()
                effectManger?.isBeautyEffective = true
                LabTrack.trackBeauty(retArray, pretendService: effectManger?.pretendService)
            }
        }
    }

    func trackSetting() {
        var background_status = "no_background"
        var background_type = ""
        if let bgModel = effectManger?.virtualBgService.currentVirtualBgsModel {
            let nameType = LabTrack.virtualBgNameType(model: bgModel)
            background_status = nameType.0
            background_type = nameType.1
        }

        var avatar_status = "close"
        if let avatar = effectManger?.pretendService.currentAnimojiModel, avatar.bgType != .none {
            avatar_status = avatar.title
        }

        var touch_up_status = ""
        var touch_up_custom_value: [[String: Any]] = []
        if let beautyArray = effectManger?.pretendService.retuschierenArray,
           !beautyArray.isEmpty {
            var valueSum = 0
            var defaultSum = 0
            var array: [[String: Any]] = []

            let applyType = effectManger?.pretendService.beautyCurrentStatus ?? .customize
            for item in beautyArray {
                if item.effectModel.downloaded, let currentValue = item.applyValue(for: applyType) { // 只统计点击过的
                    valueSum += currentValue
                    if currentValue == item.defaultValue { // 是不是等于默认值
                        defaultSum += 1
                    }
                    let dic: [String: Any] = ["id": item.resourceId, "value": currentValue, "is_default": currentValue == item.defaultValue ? 1 : 0]
                    array.append(dic)
                }
            }

            if valueSum == 0 {
                touch_up_status = "close"
            } else if defaultSum == beautyArray.count {
                touch_up_status = "default"
            } else {
                touch_up_status = "custom"
                touch_up_custom_value = array
            }
        }

        var filter_status = "close"
        var filter_filter = ""
        if let filter = effectManger?.pretendService.currentFilterModel, filter.bgType != .none {
            filter_status = filter.title
            if let value = filter.currentValue {
                filter_filter = String(value)
            }
        }

        let is_cam_on = !meeting.camera.isMuted

        var mobile_speaker = "other"
        if meeting.audioDevice.output.isMuted {
            mobile_speaker = "mute"
        } else if LarkAudioSession.shared.currentOutput == .speaker {
            mobile_speaker = "loudspeaker"
        } else if LarkAudioSession.shared.currentOutput == .receiver {
            mobile_speaker = "receiver"
        }

        let room = meeting.myself.settings.targetToJoinTogether
        let isUltrasonicOn = meeting.setting.isUltrawaveEnabled
        let roomStatus = isUltrasonicOn ? (room != nil ? "ultrasonic_room_found" : "ultrasonic_room_not_found") : "ultrasonic_off"
        VCTracker.post(name: .vc_setting_status,
                       params: ["always_show_toolbar": context.fullScreenDetector?.autoHideToolStatusBar == false,
                                "use_ultrasonic": isUltrasonicOn,
                                "is_mirror": meeting.setting.isVideoMirrored,
                                "background_status": background_status,
                                "background_type": background_type,
                                "avatar_status": avatar_status,
                                "touch_up_status": touch_up_status,
                                "touch_up_custom_value": touch_up_custom_value,
                                "filter_status": filter_status,
                                "filter_filter": filter_filter,
                                "is_cam_on": is_cam_on,
                                "mobile_speaker": mobile_speaker,
                                "is_ultrasonic_sync_join_setting_on": isUltrasonicOn,
                                "room_scan_status": roomStatus,
                                "high_resolution": meeting.setting.isHDModeEnabled
                               ])
    }
}

extension InMeetTrackViewModel: EffectVirtualBgListener, EffectPretendDataListener {
    func didChangeCurrentVirtualBg(bgModel: VirtualBgModel) {
        virtualBgChangedRelay.accept(bgModel)
    }

    func applyPretend(type: EffectType, model: ByteViewEffectModel, applyType: EffectSettingType) {
        effectModelChangedSubject.onNext(model)
    }

    func cancelPretend(model: ByteViewEffectModel) {
        effectModelChangedSubject.onNext(model)
    }
}

extension InMeetTrackViewModel {
    func generateBeautyDictionary(_ targetArray: [ByteViewEffectModel]? = nil) -> [String: String] {
        guard let beautyArray = targetArray ?? effectManger?.pretendService.retuschierenArray else {
            return [String: String]()
        }
        var resultDic = [String: String]()
        let applyType = effectManger?.pretendService.beautyCurrentStatus ?? .customize
        for beautyItem in beautyArray {
            let currentValue = beautyItem.applyValue(for: applyType)
            resultDic[beautyItem.resourceId] = "\(currentValue)"
        }
        return resultDic
    }

    func generateBeautyModelArray() -> [ByteViewEffectModel] {
        return effectManger?.pretendService.retuschierenArray ?? [ByteViewEffectModel]()
    }
}

extension InMeetTrackViewModel: InMeetParticipantListener {

    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        TrackContext.shared.updateContext(for: meeting.sessionId) { context in
            context.participantNum = output.counts.nonRinging
        }
    }

    func didReceiveSuggestedParticipants(_ suggested: GetSuggestedParticipantsResponse) {
        if isFirstLoadSuggestedParticipants {
            VCTracker.post(name: .vc_user_list_setting_status, params: ["userlist_advice_num": suggested.suggestedParticipants.count])
        }
        isFirstLoadSuggestedParticipants = false
    }
}
