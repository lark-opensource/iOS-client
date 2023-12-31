//
//  EffectService.swift
//  ByteView
//
//  Created by ByteDance on 2023/7/13.
//

import Foundation
import ByteViewMeeting
import ByteViewSetting
import EffectPlatformSDK

/*
    1.Animoji由fg和admin控制，美颜和滤镜由fg控制
 */

protocol EffectPretendDataListener: AnyObject {
    func didChangePretendloadingStatus(type: EffectType, status: EffectLoadingStatus)
    func didChangePretendList(type: EffectType, data: [ByteViewEffectModel])
    func applyPretend(type: EffectType, model: ByteViewEffectModel, applyType: EffectSettingType) // applyType只针对美颜用，为了区分美颜是none、还是auto、还是custom
    func cancelPretend(model: ByteViewEffectModel)
}

protocol EffectPretendCalendarListener: AnyObject {
    func didChangeAnimojAllow(isAllow: Bool)
}

class EffectPretendService {
    private var setting: MeetingSettingManager
    let logger = Logger.effectPretend
    private lazy var effectDataLoader = LabEffectDataLoader(isLark: setting.packageIsLark || !setting.isFeishuBrand)
    let listeners = Listeners<EffectPretendDataListener>()
    let calendarListeners = Listeners<EffectPretendCalendarListener>()
    let queue = DispatchQueue(label: "byteview.effect.pretendService")

    var hasFetchFilterList: Bool = false
    var hasFetchBeautyList: Bool = false

    var efffectSaveDic: [String: String] = [:]
    var beautyCurrentStatus: EffectSettingType = .none

    // animoji权限管控
    var isAllowAnimoji: Bool = true {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.calendarListeners.forEach{ $0.didChangeAnimojAllow(isAllow: self.isAllowAnimoji) }
            }
        }
    }

    @RwAtomic private(set) var animojiArray: [ByteViewEffectModel] = [] {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.listeners.forEach { $0.didChangePretendList(type: .animoji, data: self.animojiArray) }
            }
        }
    }

    @RwAtomic private(set) var filterArray: [ByteViewEffectModel] = [] {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.listeners.forEach { $0.didChangePretendList(type: .filter, data: self.filterArray) }
            }
        }
    }

    @RwAtomic private(set) var retuschierenArray: [ByteViewEffectModel] = [] {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.listeners.forEach { $0.didChangePretendList(type: .retuschieren, data: self.retuschierenArray) }
            }
        }
    }

    @RwAtomic private(set) var animojiLoadingStatus: EffectLoadingStatus = .unStart {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.listeners.forEach{ $0.didChangePretendloadingStatus(type: .animoji, status: self.animojiLoadingStatus) }
            }
        }
    }

    @RwAtomic private(set) var filterLoadingStatus: EffectLoadingStatus = .unStart {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.listeners.forEach{ $0.didChangePretendloadingStatus(type: .filter, status: self.filterLoadingStatus) }
            }
        }
    }

    @RwAtomic private(set) var beautyLoadingStatus: EffectLoadingStatus = .unStart {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.listeners.forEach{ $0.didChangePretendloadingStatus(type: .retuschieren, status: self.beautyLoadingStatus) }
            }
            Logger.effectPretend.info("didset beautyLoadingStatus: \(beautyLoadingStatus), cCurrentStatus: \(self.beautyCurrentStatus)")
            if beautyLoadingStatus == .done && self.beautyCurrentStatus != .none {
                self.initApplyForBeauty()
            }
        }
    }

    var currentAnimojiModel: ByteViewEffectModel? {
        return animojiArray.first(where: { $0.isSelected == true })
    }
    var noneAnimojiModel: ByteViewEffectModel? {
        return animojiArray.first(where: { $0.bgType == .none })
    }
    var currentFilterModel: ByteViewEffectModel? {
        return filterArray.first(where: { $0.isSelected == true })
    }
    var noneFilterModel: ByteViewEffectModel? {
        return filterArray.first(where: { $0.bgType == .none })
    }
    var currentBeautySettingModel: ByteViewEffectModel? {
        return retuschierenSettingArray.first(where: { $0.isSelected == true })
    }
    var noneBeautySettingModel: ByteViewEffectModel? {
        return retuschierenSettingArray.first(where: { $0.bgType == .none })
    }

    var retuschierenSettingArray: [ByteViewEffectModel] = {
        let noneMode = ByteViewEffectModel(effectModel: IESEffectModel(), panel: "none", category: "none", labType: .retuschieren, bgType: .none)
        noneMode.resourceId = EffectResource.effectEmptyId
        let autoMode = ByteViewEffectModel(effectModel: IESEffectModel(), panel: "auto", category: "auto", labType: .retuschieren, bgType: .auto)
        autoMode.resourceId = EffectResource.beautyAutoId
        let customizeMode = ByteViewEffectModel(effectModel: IESEffectModel(), panel: "customize", category: "customize", labType: .retuschieren, bgType: .customize)
        customizeMode.resourceId = EffectResource.beautyCustomizeId
        return [noneMode, autoMode, customizeMode]
    }()

    init(setting: MeetingSettingManager) {
        self.setting = setting

        setting.wait(for: .firstFetch) { [weak self] in
            guard let self = self else { return }
            self.logger.info("wait success, isAnimojiEnabled: \(setting.isAnimojiEnabled), isRetuschierenEnabled: \(setting.isRetuschierenEnabled), isFilterEnabled: \(setting.isFilterEnabled), advancedBeauty: \(setting.advancedBeauty)")

            // 恢复用户记忆数据
            self.efffectSaveDic = self.recoverFromUserSetting(video: setting.advancedBeauty)
            self.recoverBeautySettingSelect()

            // animoji不会记忆，所以不需要先拉；
            self.checkAndLoadForFilter()
            self.checkAndLoadForBeauty()
        }
    }

    deinit {
        logger.info("pretend deinit")
    }

    func checkAndLoadForAnimoji() {
        if setting.isAnimojiEnabled {
            loadForAnimoji()
        }
    }

    func checkAndLoadForFilter(ignoreUsed: Bool = false, ignoreFired: Bool = false) {
        let isEnable = setting.showsEffects && setting.isFilterEnabled
        let hasUsed = !efffectSaveDic.isEmpty

        //labr 看选中的值是不是0
        // enable + 用户设置过 + 未下载过流程
        if  isEnable && (hasUsed || ignoreUsed) && (!hasFetchFilterList || ignoreFired) {
            hasFetchFilterList = true
            loadForFilter()
        }
    }

    func checkAndLoadForBeauty(ignoreUsed: Bool = false, ignoreFired: Bool = false) {
        let isEnable = setting.showsEffects && setting.isRetuschierenEnabled
        let hasUsed = !efffectSaveDic.isEmpty

        if  isEnable && (hasUsed || ignoreUsed) && (!hasFetchBeautyList || ignoreFired) {
            hasFetchBeautyList = true
            loadForBeauty()
        }
    }

    func applyPretend(model: ByteViewEffectModel, shouldTrack: Bool = true, applyType: EffectSettingType) {
        if !checkAuth(model: model, applyType: applyType) {  // 检查是否可以设置特效
            Logger.effectPretend.error("labcamera apply return \(model.category) name:\(model.title)")
            return
        }
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.listeners.forEach { $0.applyPretend(type: model.labType, model: model, applyType: applyType)}
        }
    }

    // 包括animoji、美颜、滤镜，美颜无关闭，apply为0，不过一起收敛在这个方法里
    func cancelPretend(model: ByteViewEffectModel) {
        if model.labType == .retuschieren {
            Logger.effectPretend.info("cancelPretend beauty effect")
            beautyCurrentStatus = .none
            applyEffectForBeauty(applyType: .none, shouldTrack: true)
        } else {
            Logger.effectPretend.info("cancelPretend effect \(model.title)--\(model.currentValue ?? -1)")
            self.queue.async { [weak self] in
                self?.listeners.forEach { $0.cancelPretend(model: model)}
            }
        }
    }

    func saveEffectSetting(effectModel: ByteViewEffectModel?) {
        guard let effectModel = effectModel else {
            return
        }
        let resourceId = effectModel.resourceId
        var currentValue = ""
        if let value = effectModel.currentValue {
            currentValue = String(value)
        }
        if effectModel.labType == .filter { // filter记录最后选中的effect
            efffectSaveDic.updateValue(resourceId, forKey: EffectResource.selectfilter)
        }
        if effectModel.labType == .retuschieren, effectModel.bgType != .set { // 美颜记录最后选中的effect 以前是记录具体美颜，后改为记住外面的none，auto、custom
            efffectSaveDic.updateValue(resourceId, forKey: EffectResource.selectedBeauty)
        }
        efffectSaveDic.updateValue(currentValue, forKey: resourceId) // 记录每一个value
        let jsonString = Util.dicValueString(efffectSaveDic) // dic转为json字符串然后保存
        logger.info("lab effect: saving effect\(jsonString ?? "")")
        setting.updateSettings({ $0.labEffect = jsonString ?? "" })
    }

    func recoverFromUserSetting(video: String) -> [String: String] {
        let video = setting.advancedBeauty
        var advancedBeauty = ""
        var saveEffectDic: [String: String] = [:]
        if !video.isEmpty {
            advancedBeauty = video
            if let dic = Util.convertToDictionary(text: advancedBeauty) as? [String: String] {
                saveEffectDic = dic
            }
        }
        logger.info("lab effect: get save data \(saveEffectDic)")
        return saveEffectDic
    }

    /// 美颜兼容老版本
    func recoverBeautySettingSelect() {
        let selectBeauty = efffectSaveDic[EffectResource.selectedBeauty]
        if let selectBeauty = selectBeauty,
           selectBeauty == EffectResource.effectEmptyId || selectBeauty == EffectResource.beautyAutoId || selectBeauty == EffectResource.beautyCustomizeId { // 有美颜setting select记录
            for item in self.retuschierenSettingArray where item.resourceId == selectBeauty {
                item.isSelected = true
                beautyCurrentStatus = item.bgType
            }
        } else { // 无值 给none
            beautyCurrentStatus = .none
            retuschierenSettingArray[0].isSelected = true
        }
        Logger.effectPretend.info("lab effect: init beautyCurrentStatus \(self.beautyCurrentStatus)")
    }

    private func checkAuth(model: ByteViewEffectModel, applyType: EffectSettingType) -> (Bool) {
        switch model.labType {
        case .animoji:
            return setting.isAnimojiEnabled
        case .filter:
            return setting.isFilterEnabled && (model.currentValue != nil)
        case .retuschieren:
            if setting.isRetuschierenEnabled {
                switch applyType {
                case .set, .customize:
                    return model.currentValue != nil
                case .auto:
                    return model.defaultValue != nil
                case .none:
                    return true
                }
            } else {
                return false
            }
        default:
            return true
        }
    }
}

// MARK: - fetch data
extension EffectPretendService {
    private func loadForAnimoji() {
        logger.info("begin fetch animoji list")
        animojiLoadingStatus = .loading
        effectDataLoader.loadEffectList(type: .animoji) { [weak self] result in
            switch result {
            case .success(let effectModels):
                self?.logger.info("fetch animoji list success, count \(effectModels.count)")
                self?.animojiArray = effectModels
                self?.animojiLoadingStatus = .done
            case .failure:
                self?.logger.info("fetch animoji list error")
                self?.animojiLoadingStatus = .failed
            }
        }
    }

    private func loadForBeauty() {
        logger.info("begin fetch beauty list")
        beautyLoadingStatus = .loading
        effectDataLoader.loadEffectList(type: .retuschieren) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let effectModels):
                self.logger.info("fetch beauty list success, count \(effectModels.count)")
                for (key, value) in self.efffectSaveDic {  //恢复之前设置过的值
                    for item in effectModels where item.resourceId == key {
                        item.currentValue = Int(value)
                    }
                }
                let (isAllDownload, effectArray) = self.isBeautyAllDownloaded(models: effectModels)
                if isAllDownload {  // 模型已下载下来
                    self.retuschierenArray = effectModels
                    self.beautyLoadingStatus = .done
                    self.logger.info("fetch beauty list success, all model has downloaded")
                } else { // 有模型未下载
                    self.loadBeautyModels(models: effectArray) { [weak self] res in
                        guard let self = self else { return }
                        if res {
                            self.logger.info("fetch beauty list success, downloaded all model success ")
                            self.retuschierenArray = effectModels
                            self.beautyLoadingStatus = .done
                        } else {
                            self.logger.info("fetch beauty list error, has downloaded")
                            self.beautyLoadingStatus = .failed
                        }
                    }
                }
            case .failure:
                self.logger.info("fetch beauty list error")
                self.beautyLoadingStatus = .failed
            }
        }
    }

    private func loadBeautyModels(models: [IESEffectModel], completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().async {
            Logger.effectPretend.info("download BeautyModels count: \(models.count)")
            let group = DispatchGroup()
            var results = [Bool]()
            for item in models {
                group.enter()
                LabEffectDataLoader.fetchEffect(model: item) { error, path in
                    group.leave()
                    if error == nil && path != nil && item.downloaded {
                        results.append(true)
                        Logger.effectPretend.info("download \(item.effectName) model success")
                    } else {
                        Logger.effectPretend.info("download \(item.effectName) model \(error)")
                        results.append(false)
                    }
                }
            }
            group.notify(queue: .main) {
                if results.contains(false) {
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    private func loadForFilter() {
        logger.info("begin fetch filter list")
        filterLoadingStatus = .loading
        effectDataLoader.loadEffectList(type: .filter) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let effectModels):
                self.logger.info("fetch filter list success, count \(effectModels.count)")
                var isFindWithNotEmpty = false  // 找到非empty的，然后再empty的select置空
                let selectFilter = self.efffectSaveDic[EffectResource.selectfilter]
                for (key, value) in self.efffectSaveDic { // 恢复每个滤镜之前设置过的值
                    for item in effectModels {
                        if item.resourceId == key {
                            item.currentValue = Int(value)
                        }
                    }
                }
                for item in effectModels {
                    if item.resourceId == selectFilter { // 被选滤镜
                        item.isSelected = true
                        self.applyPretend(model: item, applyType: .set)
                        isFindWithNotEmpty = item.bgType == .set ? true : false
                    }
                }
                if isFindWithNotEmpty, !effectModels.isEmpty {
                    effectModels[0].isSelected = false
                }
                self.filterArray = effectModels
                self.filterLoadingStatus = .done
            case .failure:
                self.logger.info("fetch filter list error")
                self.filterLoadingStatus = .failed
            }
        }
    }
}

// MARK: - apply
extension EffectPretendService {

    // 会议开始设置初始美颜
    private func initApplyForBeauty() {
        logger.info("lab effect: initApplyForBeauty, applyType: \(beautyCurrentStatus)")
        if beautyCurrentStatus == .auto || beautyCurrentStatus == .customize {
            applyEffectForBeauty(applyType: beautyCurrentStatus, shouldTrack: false)
        }
    }

    // 美颜设置自动
    func autoEffectForBeauty(shouldTrack: Bool) {
        Logger.effectPretend.info("lab effect: apply beauty auto")
        beautyCurrentStatus = .auto
        applyEffectForBeauty(applyType: .auto, shouldTrack: shouldTrack)
    }

    // 美颜设置自定义
    func customizeEffectForBeauty() {
        logger.info("lab effect: apply beauty customize")
        retuschierenArray.forEach({ effectMode in
            if effectMode.currentValue == nil { //labr currentValue
                effectMode.currentValue = 0
            }
        })
        beautyCurrentStatus = .customize
        applyEffectForBeauty(applyType: .customize, shouldTrack: true)
    }

    private func applyEffectForBeauty(applyType: EffectSettingType, shouldTrack: Bool) {
        logger.info("lab effect: applyEffectForBeauty type \(applyType)")
        for item in retuschierenArray {
            applyPretend(model: item, shouldTrack: shouldTrack, applyType: applyType)
        }
    }

    private func isBeautyAllDownloaded(models: [ByteViewEffectModel]) -> (Bool, [IESEffectModel]) {
        var effectArray: [IESEffectModel] = []
        for item in models where !item.effectModel.downloaded {
            effectArray.append(item.effectModel)
        }
        return (effectArray.isEmpty, effectArray)
    }
}

// MARK: - listeners
extension EffectPretendService {
    func addListener(_ listener: EffectPretendDataListener, fireImmediately: Bool = false) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: EffectPretendDataListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: EffectPretendDataListener) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            listener.didChangePretendList(type: .animoji, data: self.animojiArray)
            listener.didChangePretendList(type: .filter, data: self.filterArray)
            listener.didChangePretendList(type: .retuschieren, data: self.retuschierenArray)

            if let model = self.currentAnimojiModel {
                listener.applyPretend(type: .animoji, model: model, applyType: .set)
            }
            if let model = self.currentFilterModel {
                listener.applyPretend(type: .filter, model: model, applyType: .set)
            }
            if self.beautyCurrentStatus == .auto || self.beautyCurrentStatus == .customize {
                Logger.effectPretend.info("beauty fireListener")
                self.applyEffectForBeauty(applyType: self.beautyCurrentStatus, shouldTrack: false)
            }
        }
    }
}

extension EffectPretendService {
    func addCalendarListener(_ listener: EffectPretendCalendarListener, fireImmediately: Bool = false) {
        calendarListeners.addListener(listener)
        if fireImmediately {
            fireCalendarListenerOnAdd(listener)
        }
    }

    func removeCalendarListener(_ listener: EffectPretendCalendarListener) {
        calendarListeners.removeListener(listener)
    }

    private func fireCalendarListenerOnAdd(_ listener: EffectPretendCalendarListener) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            listener.didChangeAnimojAllow(isAllow: self.isAllowAnimoji)
        }
    }
}

extension EffectPretendDataListener {
    func didChangePretendloadingStatus(type: EffectType, status: EffectLoadingStatus) {}
    func didChangePretendList(type: EffectType, data: [ByteViewEffectModel]) {}
    func applyPretend(type: EffectType, model: ByteViewEffectModel, applyType: EffectSettingType) {}
    func cancelPretend(model: ByteViewEffectModel) {}
}
