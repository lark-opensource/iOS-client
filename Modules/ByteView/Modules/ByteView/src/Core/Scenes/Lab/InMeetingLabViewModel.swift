//
//  InMeetingLabViewModel.swift
//  ByteView
//
//  Created by liquanmin on 2020/9/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewMeeting
import ByteViewSetting
import ByteViewRtcBridge

enum LabFromSource {
    case inMeet
    case preview
    case preLobby
    case inLobby

    func toLabCameraScene() -> RtcCameraScene {
        switch self {
        case .inMeet:
            return .inMeetLab
        case .preview:
            return .previewLab
        case .preLobby:
            return .prelobbyLab
        case .inLobby:
            return .lobbyLab
        }
    }
}

enum InterviewSourceChangeType {
    case add
    case remove
    case none
}

// 监听 Virtual Bg 的数据源变化
protocol VirtualBgDataDelegate: AnyObject {
    func dataSetChanged()
}

protocol EffectBgDataDelegate: AnyObject {
    func dataSetChanged()
}

final class InMeetingLabViewModel: MeetingBasicServiceProvider {

    struct LabPageDesc {
        let index: Int
        let title: String
        let pageType: EffectType
        let selectedRelay = BehaviorRelay<Bool>(value: false)
    }

    let disposeBag = DisposeBag()
    let fromSource: LabFromSource
    let pages: [LabPageDesc]// 底部页面描述
    let currentPageType = BehaviorRelay<EffectType?>(value: nil) // 当前页面类型

    var virtualBgs: [VirtualBgModel] = []
    var anmojiModels: [ByteViewEffectModel] = []
    var filterModels: [ByteViewEffectModel] = []
    var retuschierenModels: [ByteViewEffectModel] {
        if isBeautySetting { // 指针指向 美颜真正model or 设置model
            return retuschierenSettingsModels
        } else {
            return retuschierenRealModels
        }
    }
    var retuschierenRealModels: [ByteViewEffectModel] = []
    var retuschierenSettingsModels: [ByteViewEffectModel] = []

    weak var virtualBgDataDelegate: VirtualBgDataDelegate?
    weak var anmojiBgDataDelegate: EffectBgDataDelegate?
    weak var filterBgDataDelegate: EffectBgDataDelegate?
    weak var retuschierenBgDataDelegate: EffectBgDataDelegate?

    var isDeleting: Bool = false
    var isBeautySetting: Bool = false
    var isFromInMeet: Bool { return fromSource == .inMeet }
    var isInterviewer: Bool = false
    var beforeInterviewMeetingBgsModel: VirtualBgModel?

    private(set) lazy var camera = PreviewCameraManager(scene: fromSource.toLabCameraScene(), service: service, effectManger: effectManger, isFromLab: true)
//    var effect: RtcEffect { camera.effect }

    /// 判断进入特效页前是否开启摄像头
    let isCameraOnBeforeLab: Bool
    let service: MeetingBasicService

    var meetingId: String { service.meetingId }
    var setting: MeetingSettingManager { service.setting }
    var virtualBgService: EffectVirtualBgService
    var pretendService: EffectPretendService
    var effectManger: MeetingEffectManger

    init(service: MeetingBasicService, effectManger: MeetingEffectManger, fromSource: LabFromSource, isInterviewer: Bool = false, isCameraOnBeforeLab: Bool = false) {
        self.service = service
        self.effectManger = effectManger
        self.virtualBgService = effectManger.virtualBgService
        self.pretendService = effectManger.pretendService
        self.fromSource = fromSource
        self.isInterviewer = isInterviewer
        self.isCameraOnBeforeLab = isCameraOnBeforeLab
        let setting = service.setting
        pages = Self.buildPages(setting: setting)
        if pages.isEmpty {
            Logger.lab.error("lab: Pages is empty.")
        }

        // 虚拟背景可用，则默认虚拟背景
        if setting.isVirtualBgEnabled {
            currentPageType.accept(.virtualbg)
        } else if setting.isAnimojiEnabled {
            currentPageType.accept(.animoji)
        } else if setting.isFilterEnabled {
            currentPageType.accept(.filter)
        } else if setting.isRetuschierenEnabled {
            currentPageType.accept(.retuschieren)
        }

        if setting.isVirtualBgEnabled {
            initForVirtualBg()
        }

        if setting.isAnimojiEnabled {
            initForAnimoji()
        }

        if setting.isFilterEnabled {
            initForFilter()
        }

        if setting.isRetuschierenEnabled {
            initForBeauty()
        }

        if setting.isAnimojiEnabled || setting.isFilterEnabled || setting.isRetuschierenEnabled {
            pretendService.addListener(self, fireImmediately: true)
        }
    }

    func initForVirtualBg() {
        Logger.effectBackGround.info("vm init loadingStatus:\(virtualBgService.loadingStatus), isFileEmpty: \(virtualBgService.isFileEmpty())")
        if virtualBgService.loadingStatus == .unStart {  // 入会没用虚拟背景的话不会走流程，打开特效页的时候这里再走
            virtualBgService.checkForVirtualBg(ignoreUsed: true)
        } else if virtualBgService.loadingStatus == .done && virtualBgService.isFileEmpty() { // 会中清除了缓存，会重新拉
            virtualBgService.checkForVirtualBg(ignoreFired: true)
        }
        virtualBgService.addListener(self, fireImmediately: true)
    }

    func initForAnimoji() {
        if pretendService.animojiLoadingStatus == .unStart { // 之前没下过animoji，打开labvc需要下载
            pretendService.checkAndLoadForAnimoji()
        }
    }

    func initForFilter() {
        if !pretendService.hasFetchFilterList { // 没拉过滤镜list，打开labvc需要拉
            pretendService.checkAndLoadForFilter(ignoreUsed: true)
        }
    }

    func initForBeauty() {
        if !pretendService.hasFetchBeautyList { // 没拉过美颜list，打开labvc需要拉
            pretendService.checkAndLoadForBeauty(ignoreUsed: true)
        }

        self.isBeautySetting = true
        self.retuschierenSettingsModels = pretendService.retuschierenSettingArray
        self.retuschierenBgDataDelegate?.dataSetChanged()
    }

    deinit {
        Logger.lab.info("lab: labvm deinit")
        virtualBgService.removeListener(self)
        pretendService.removeListener(self)
    }
}

extension InMeetingLabViewModel: EffectVirtualBgListener {
    func didChangeVirtualBgList(bgModelList: [VirtualBgModel]) {
        Util.runInMainThread {
            self.virtualBgs = self.virtualBgService.virtualBgsArray
            if self.isDeleting {
                self.changeVirtualToDelete(isDelete: true)
            }
            self.virtualBgDataDelegate?.dataSetChanged()
            Logger.lab.info("labVM revice loadVirtualBgs count \(self.virtualBgs.count)")
        }
    }
}

// MARK: select cell
extension InMeetingLabViewModel {
    func selectVirtualBg(index: Int) {
        if index < 0 || index > virtualBgs.count {
            return
        }
        if virtualBgs[index].isSelected {
            return
        }
        let selectedModel = virtualBgs[index]
        if selectedModel.status.isLoading {
            return
        }
        LabTrackV2.trackLabSelectedVirtualBg(model: selectedModel, source: fromSource)
        switch selectedModel.bgType {
        case .setNone:
            LabTrack.trackVirtualBgSelected(model: selectedModel)
            LabTrack.trackLabSelectedVirtualBg(source: fromSource, model: selectedModel)
            virtualBgService.changeSelectedVirtualBg(bgModel: selectedModel)
        case .blur:
            LabTrack.trackVirtualBgSelected(model: selectedModel)
            LabTrack.trackLabSelectedVirtualBg(source: fromSource, model: selectedModel)
            virtualBgService.changeSelectedVirtualBg(bgModel: selectedModel)
        case .virtual:
            LabTrack.trackVirtualBgSelected(model: selectedModel)
            LabTrack.trackLabSelectedVirtualBg(source: fromSource, model: selectedModel)
            virtualBgService.changeSelectedVirtualBg(bgModel: selectedModel)
        case .add:
            LabTrack.trackClickAddd(source: fromSource)
            self.showImagePicker()
        }
    }

    func selectEffect(index: Int) {
        var tempEffectArray: [ByteViewEffectModel] = []
        switch self.currentPageType.value {
        case .animoji:
            tempEffectArray = self.anmojiModels
        case .filter:
            tempEffectArray = self.filterModels
        case .retuschieren:
            tempEffectArray = self.retuschierenModels
        default:
            break
        }

        if index < 0 || index > tempEffectArray.count { return } // 越界 return
        if tempEffectArray[index].isSelected { return } // 如果已经选中了 return

        // 重新设置状态
        tempEffectArray.forEach { model in
            model.isSelected = false
        }
        let selectedModel = tempEffectArray[index]
        selectedModel.isSelected = true

        if selectedModel.currentValue == nil {
            if selectedModel.labType == .retuschieren {  // 美颜交互 美颜默认值为0
                selectedModel.currentValue = 0
            } else {
                selectedModel.currentValue = selectedModel.defaultValue
            }
        }

        if selectedModel.labType != .animoji {
            pretendService.saveEffectSetting(effectModel: selectedModel)
        }

        LabTrack.trackLabSelectedEffect(source: fromSource, model: selectedModel)
        LabTrackV2.trackLabSelectedEffect(model: selectedModel, source: fromSource)
    }

    func selectEffectNew(index: Int) {
        var tempEffectArray: [ByteViewEffectModel] = []
        switch self.currentPageType.value {
        case .animoji:
            tempEffectArray = self.anmojiModels
        case .filter:
            tempEffectArray = self.filterModels
        case .retuschieren:
            tempEffectArray = self.retuschierenModels
        default:
            break
        }

        if index < 0 || index > tempEffectArray.count {
            return
        }

        // 如果已经选中了 return
        if tempEffectArray[index].isSelected {
            return
        }

        let selectedModel = tempEffectArray[index]
        if selectedModel.currentValue == nil {
            if selectedModel.labType == .retuschieren {  // 美颜交互 美颜默认值为0
                selectedModel.currentValue = 0
            } else {
                selectedModel.currentValue = selectedModel.defaultValue
            }
        }

        LabTrack.trackLabSelectedEffect(source: fromSource, model: selectedModel)
        LabTrackV2.trackLabSelectedEffect(model: selectedModel, source: fromSource)
    }

    func selectDecorate() {
        LabTrack.trackShowDecorate()
    }
}

// MARK: apply

extension InMeetingLabViewModel {

    // animoji、滤镜、美颜单项
    func applyEffect(model: ByteViewEffectModel, shouldTrack: Bool = true) {
//        LabEffectService.shared?.applyEffect(model: model, shouldTrack: shouldTrack)
        pretendService.applyPretend(model: model, shouldTrack: shouldTrack, applyType: .set)
    }

    // 自动（现在只有美颜）
    func autoEffect(model: ByteViewEffectModel) {
        if model.labType == .retuschieren {
            pretendService.autoEffectForBeauty(shouldTrack: true)
        }
    }

    // 自定义(现在只有美颜)
    func customizeEffect(model: ByteViewEffectModel) {
        if model.labType == .retuschieren {
            pretendService.customizeEffectForBeauty()
        }
    }

    // animoji、滤镜、美颜设置项, pretendService.cancelPretend内部异化
    func cancelEffect(model: ByteViewEffectModel) {
        pretendService.cancelPretend(model: model)
    }
}

// MARK: view action
extension InMeetingLabViewModel {
    func changeVirtualToDelete(isDelete: Bool) {
        virtualBgs.forEach { model in
            model.isShowDelete = isDelete ? model.isDeleteEnable() : false
        }
    }

    func deleteVirtualBg(model: VirtualBgModel) {
        virtualBgService.deleteVirtualBg(key: model.key)
    }

    func effectSliderEnded() {
        if self.currentPageType.value == .retuschieren && !isBeautySetting {
            self.retuschierenBgDataDelegate?.dataSetChanged()
        }
    }

    func unSelectedBeautyEffect() {
        retuschierenRealModels.forEach { model in
            model.isSelected = false
        }
    }

    func downLoadEffect(model: ByteViewEffectModel, willDownload: @escaping () -> Void, didDownload: @escaping (Error?, String?) -> Void) {
        willDownload()
        LabEffectDataLoader.fetchEffect(model: model.effectModel, callback: { (error, path) in
            didDownload(error, path)
        })
    }
}

// MARK: loading status && reload
extension InMeetingLabViewModel {
    func reloadVirtualBg() { // 点击重试
        virtualBgService.checkForVirtualBg(ignoreUsed: true, ignoreFired: true)
        LabTrackV2.trackLabReload(source: fromSource, type: .virtualbg)
    }

    func reloadAnimoji() {  // 点击重试
        pretendService.checkAndLoadForAnimoji()
        LabTrackV2.trackLabReload(source: fromSource, type: .animoji)
    }

    func reloadFilter() { // 点击重试
        pretendService.checkAndLoadForFilter(ignoreUsed: true, ignoreFired: true)
        LabTrackV2.trackLabReload(source: fromSource, type: .filter)
    }

    func reloadRetuschieren() { // 点击重试
        pretendService.checkAndLoadForBeauty(ignoreUsed: true, ignoreFired: true)
        LabTrackV2.trackLabReload(source: fromSource, type: .retuschieren)
    }
}

// MARK: protocol
extension InMeetingLabViewModel: EffectPretendDataListener {
    func didChangePretendList(type: EffectType, data: [ByteViewEffectModel]) {
        guard !data.isEmpty else { return }

        Util.runInMainThread { [weak self] in
            Logger.effectPretend.info("labVM revice \(type) count \(data.count), currentAnimoji: \(self?.pretendService.currentAnimojiModel?.title), currentFilter: \(self?.pretendService.currentFilterModel?.title)")
            if type == .animoji {
                self?.anmojiModels = data
                self?.anmojiBgDataDelegate?.dataSetChanged()
            }
            if type == .filter {
                self?.filterModels = data
                self?.filterBgDataDelegate?.dataSetChanged()
            }
            if type == .retuschieren {
                self?.retuschierenRealModels = data
                self?.retuschierenBgDataDelegate?.dataSetChanged()
            }
        }
    }
}

// MARK: static method
private extension InMeetingLabViewModel {
    static func buildPages(setting: MeetingSettingManager) -> [LabPageDesc] {
        // 构建翻页器
        var tempPages: [LabPageDesc] = []
        var index = 0
        if setting.isVirtualBgEnabled {
            Logger.lab.info("lab effect: add Virtual")
            tempPages.append(LabPageDesc(index: index,
                                         title: I18n.View_VM_VirtualBackground,
                                         pageType: .virtualbg))
            index += 1
        }

        if setting.isAnimojiEnabled {
            Logger.lab.info("lab effect: add Animoji")
            tempPages.append(LabPageDesc(index: index,
                                         title: I18n.View_VM_Avatar,
                                         pageType: .animoji))
            index += 1
        }

        if setting.isRetuschierenEnabled {
            Logger.lab.info("lab effect: add Retuschieren")
            tempPages.append(LabPageDesc(index: index,
                                         title: I18n.View_VM_TouchUpShort,
                                         pageType: .retuschieren))
            index += 1
        }

        if setting.isFilterEnabled {
            Logger.lab.info("lab effect: add Filter")
            tempPages.append(LabPageDesc(index: index,
                                         title: I18n.View_G_Filters,
                                         pageType: .filter))
            index += 1
        }

        return tempPages
    }
}
