//
//  VirtualBgService.swift
//  ByteView
//
//  Created by ByteDance on 2023/7/13.
//

import Foundation
import ByteViewMeeting
import ByteViewSetting
import ByteViewNetwork
import ByteViewCommon
import ByteViewUI
import RxRelay
import RxSwift

// 使用的时候注意线程
protocol EffectVirtualBgListener: AnyObject {
    func didChangeVirtualBgloadingStatus(status: EffectLoadingStatus)
    func didChangeCurrentVirtualBg(bgModel: VirtualBgModel)
    func didChangeVirtualBgList(bgModelList: [VirtualBgModel])
}

protocol EffectVirtualBgCalendarListener: AnyObject {
    func didChangeExtrabgDownloadStatus(status: ExtraBgDownLoadStatus)
    func didChangeVirtualBgAllow(allowInfo: AllowVirtualBgRelayInfo)
}

class EffectVirtualBgService: MeetingBasicServiceProvider {
    private let setting: MeetingSettingManager
    let logger = Logger.effectBackGround
    var httpClient: HttpClient
    let storage: UserStorage
    var service: MeetingBasicService
    let queue = DispatchQueue(label: "byteview.effect.virtualBgService")

    private var hasFired: Bool = false  //保证流程只走一次
    var picPath: String? // 图片目录，判空使用
    @RwAtomic var virtualBgsArray: [VirtualBgModel] = []
    @RwAtomic var loadingStatus: EffectLoadingStatus = .unStart {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.logger.info("virtualBg loadingStatus \(self.loadingStatus)")
                self.listeners.forEach{ $0.didChangeVirtualBgloadingStatus(status: self.loadingStatus) }
            }
        }
    }
    var meetingVirtualBgType: MeetingVirtualBgType = .normal //本次会议是普通虚拟背景or面试or统一设置虚拟背景
    @RwAtomic var otherJobList: [MeetingVirtualBgType] = []

    let listeners = Listeners<EffectVirtualBgListener>()
    let calendarListeners = Listeners<EffectVirtualBgCalendarListener>()

    var interviewerBgModel: VirtualBgModel? // people面试图片

    @RwAtomic private(set) var currentVirtualBgsModel: VirtualBgModel? {
        didSet {
            //重置select
            self.logger.info("didset currentBg, name: \(currentVirtualBgsModel?.name), type: \(currentVirtualBgsModel?.bgType), source: \(currentVirtualBgsModel?.imageSource)")
            virtualBgsArray.forEach { $0.isSelected = false }
            currentVirtualBgsModel?.isSelected = true
            //通知监听方
            self.queue.async { [weak self] in
                guard let self = self else { return }
                if let currentModel = self.currentVirtualBgsModel {
                    self.listeners.forEach { $0.didChangeCurrentVirtualBg(bgModel: currentModel) }
                }
                self.listeners.forEach { $0.didChangeVirtualBgList(bgModelList: self.virtualBgsArray) }
            }
            // 保存不放在这里是因为有些情况不需要记忆，比如people、统一背景、初始化设置current。
        }
    }

    // 统一虚拟背景和权限管控
    @RwAtomic var calendarMeetingVirtual: CalendarMeetingVirtual?
    @RwAtomic var extrabgDownloadStatus: ExtraBgDownLoadStatus = .unStart {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.calendarListeners.forEach{ $0.didChangeExtrabgDownloadStatus(status: self.extrabgDownloadStatus) }
            }
        }
    }

    // 日程权限管控
    var allowVirtualBgInfo: AllowVirtualBgRelayInfo = AllowVirtualBgRelayInfo(allow: true, hasUsedBgInAllow: nil) {
        didSet {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.calendarListeners.forEach{ $0.didChangeVirtualBgAllow(allowInfo: self.allowVirtualBgInfo) }
            }
        }
    }
    var hasUsedBgInAllow: Bool? { allowVirtualBgInfo.hasUsedBgInAllow }
    var hasShowedNotAllowToast: Bool = false  // 是否弹过禁用虚拟背景toast
    var hasShowedNotAllowAlert: Bool = false  // 是否显示过无虚拟背景vc
    var hasSetCalenderForUnWebinarAttendee: Bool = false // 之前设置过为嘉宾
    weak var labVC: InMeetingLabViewController?

    var noneVirtualBgModel: VirtualBgModel? {
        return virtualBgsArray.first(where: { $0.bgType == .setNone })
    }

    init(service: MeetingBasicService, setting: MeetingSettingManager, userId: String) {
        self.service = service
        self.setting = setting
        self.httpClient = HttpClient(userId: userId)
        self.storage = service.storage
        setting.addListener(self, for: [.showsEffects, .isVirtualBgEnabled, .isBackgroundBlur])
        setting.addComplexListener(self, for: .virtualBackground)
        initPush(userId: userId)
        fetchMattingMode()
        checkForVirtualBg() // 先check的原因是，可能提前接口就有数据不会回调
    }

    deinit {
        logger.info("EffectVirtualBgService deinit")
    }

    private func initPush(userId: String) {
        Push.virtualBackground.inUser(userId).addObserver(self) { [weak self] message in
            DispatchQueue.global().async {
                self?.handleVirtualBgPush(message)
            }
        }
    }

    func checkForVirtualBg(ignoreUsed: Bool = false, ignoreFired: Bool = false) {
        let isBgEnable = setting.showsEffects && setting.isVirtualBgEnabled
        let hasUsedBlur = setting.isBackgroundBlur
        let hasUsedBg = !setting.virtualBackground.isEmpty

        self.logger.info("VirtualBg checkForVirtualBg isBgEnable: \(isBgEnable), hasUsedBlur: \(hasUsedBlur), hasUsedBg: \(hasUsedBg), key: \(setting.virtualBackground), ignoreUsed: \(ignoreUsed), ignoreFired: \(ignoreFired)")

        // enable + 用户设置过 + 未下载过流程
        if isBgEnable && (hasUsedBlur || hasUsedBg || ignoreUsed) && (!hasFired || ignoreFired) {
            // 下载流程
            self.logger.info("VirtualBg checkForVirtualBg begin download")
            hasFired = true
            loadingStatus = .loading
            fetchImages(settingImages: setting.virtualBgSettingImages, adminImages: setting.virtualBgAdminImages)

            setting.removeListener(self)  //去除对setting的监听，因为改动选择的图片后，Listener还会收到通知，虽然没大问题但是没必要了
            setting.removeComplexListener(self)
        }
    }

    func fetchImages(settingImages: [VirtualBgImage], adminImages: [GetAdminSettingsResponse.MeetingBackground]) {
        let settingImageList = settingImages.compactMap { (bgImage) -> VirtualBgImage? in
            let url = bgImage.url
            let portraitUrl = bgImage.url
            if self.isImageUrl(url: url), self.isImageUrl(url: portraitUrl) {
                return VirtualBgImage(name: bgImage.name, url: url, portraitUrl: portraitUrl, isSetting: true, isPeople: false)
            } else {
                return nil
            }
        }

        let adminImageList = adminImages.filter { $0.type == .image }.map {
            VirtualBgImage(name: $0.name, url: $0.url, portraitUrl: $0.portraitURL, isSetting: false, isPeople: $0.source == .appPeople)
        }

        let bgImages = settingImageList + adminImageList
        self.logger.info("lab bg: begin download images，setting count: \(settingImageList.count), admin count: \(adminImageList.count)， originCount: \(settingImages.count) \(adminImages.count)")

        let downloadRequest = GetVirtualBackgroundRequest(sets: bgImages.compactMap({ image in
            let url = image.url
            var bg = GetVirtualBackgroundRequest.VirtualBackground(name: image.name, url: url)
            if image.isSetting {
                bg.source = .appSettings
            } else if image.isPeople {
                bg.source = .appPeople
            } else {
                bg.source = .appAdmin
            }
            // ⚠️ 千万不要为 bg.portraitURL 赋值为空字符串，否则会导致横图和竖图都下载失败
            if !image.portraitUrl.isEmpty {
                bg.portraitURL = image.portraitUrl
            }
            return bg
        }))

        let startTime = Date().timeIntervalSince1970
        httpClient.getResponse(downloadRequest) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let resp):
                let infos = resp.infos
                self.logger.info("lab bg: Download resp: \(infos.count), cost time: \(Date().timeIntervalSince1970 - startTime) s")

                if infos.isEmpty {
                    self.logger.info("lab bg: Bg images download empty")
                } else {
                    if let path = infos.first?.path {
                        // let index = path.lastIndex(of: "/")
                        self.picPath = path // self.picPath = path.vc.substring(to: index)
                    }
                }

                self.virtualBgsArray = self.generateFullVirtualBg(infos: infos)
                self.logger.info("lab bg: Bg images generateFullVirtual success, count: \(self.virtualBgsArray.count)")

                if self.setting.isBackgroundBlur {
                    self.currentVirtualBgsModel = self.virtualBgsArray.first(where: { $0.bgType == .blur })
                } else if self.setting.virtualBackground.isEmpty {
                    self.currentVirtualBgsModel = self.virtualBgsArray.first(where: { $0.bgType == .setNone })
                } else if let selectedBg = self.virtualBgsArray.first(where: { $0.key == self.setting.virtualBackground }) {
                    self.currentVirtualBgsModel = selectedBg
                } else {
                    self.currentVirtualBgsModel = self.virtualBgsArray.first(where: { $0.bgType == .setNone })
                }
                self.loadingStatus = .done
                self.handleOtherJob()
            case .failure:
                self.loadingStatus = .failed
            }
        }
    }

    private func generateFullVirtualBg(infos: [VirtualBackgroundInfo]) -> [VirtualBgModel] {
        let notSetPath = service.storage.getIsoPath(root: .document, relativePath: virtualBackgroundCatalogue + "notSet.png")
        var resultArr: [VirtualBgModel] = [VirtualBgModel(name: "", bgType: .setNone,
                                                          thumbnailIsoPath: notSetPath,
                                                          landscapeIsoPath: notSetPath,
                                                          portraitIsoPath: notSetPath),
                                           VirtualBgModel(name: "", bgType: .blur,
                                                          thumbnailIsoPath: notSetPath,
                                                          landscapeIsoPath: notSetPath,
                                                          portraitIsoPath: notSetPath)]
        resultArr.append(contentsOf: generateVirtualBg(infos: infos))
        if setting.enableCustomMeetingBackground {
            resultArr.append(VirtualBgModel(name: "", bgType: .add,
                                            thumbnailIsoPath: notSetPath,
                                            landscapeIsoPath: notSetPath,
                                            portraitIsoPath: notSetPath))
        }
        return resultArr
    }

    private func generateVirtualBg(infos: [VirtualBackgroundInfo]) -> [VirtualBgModel] {
        var resultArr: [VirtualBgModel] = []
        var peopleBg: VirtualBgModel?
        infos.forEach { info in
            // 端上兜底，防止admin数据错误，取第一张(最新的)作为people面试的图 老逻辑注释：仅ok之后才需要裁减
            if info.source != .appPeople {
                resultArr.append(info.convertToBgModel(storage: storage)) // 如果不是面试会议，直接加入数组；面试会议只拿最前面一个
            }
            if info.source == .appPeople && peopleBg == nil {
                peopleBg = info.convertToBgModel(storage: storage)
            }
        }
        if let peopleBg = peopleBg {
            self.interviewerBgModel = peopleBg
        }
        return resultArr
    }

    func changeSelectedVirtualBg(bgModel: VirtualBgModel) {
        if bgModel.bgType == .setNone || bgModel.bgType == .blur {  // 无和模糊直接选中
            currentVirtualBgsModel = bgModel
            saveUserSelectBg(model: bgModel)
        } else if bgModel.bgType == .virtual, let selectMode = virtualBgsArray.first(where: { $0.key == bgModel.key }) { // 图片需要check裁剪
            if selectMode.hasCropLandscape() && selectMode.hasCropPortrait() {
                Logger.lab.debug("lab bg: use cropped image")
                currentVirtualBgsModel = selectMode
                saveUserSelectBg(model: selectMode)
            } else {
                DispatchQueue.global().async {
                    let isSuccess: Bool = LabImageCrop.cropImageAt(info: selectMode, service: self.service)
                    Logger.lab.debug("lab bg: crop image \(isSuccess)")
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if isSuccess {
                            self.currentVirtualBgsModel = selectMode
                            self.saveUserSelectBg(model: selectMode)
                        }
                    }
                }
            }
        }
    }

    func saveUserSelectBg(model: VirtualBgModel?) {
        // 面试场景一律不存，统一虚拟背景图片不存
        logger.info("save bg name:\(model?.name), type: \(model?.bgType), source: \(model?.imageSource)")
        guard let model = model, meetingVirtualBgType != .people, model.imageSource != .appCalendar else { return }
        switch model.bgType {
        case .setNone:
            setting.updateLabSettings(enableBlur: false, virtualKey: "", advancedBeauty: nil)
        case .blur:
            setting.updateLabSettings(enableBlur: true, virtualKey: "", advancedBeauty: nil)
        case .virtual:
            setting.updateLabSettings(enableBlur: false, virtualKey: model.key, advancedBeauty: nil)
        case .add:
            break
        }
    }

    private func isImageUrl(url: String) -> Bool {
        return url.hasSuffix(".jpg") || url.hasSuffix(".jpeg") || url.hasSuffix(".png")
    }

    func isFileEmpty() -> Bool {
        if let path = self.picPath {
            let upPath: String = NSString(string: path).deletingLastPathComponent
            let pathContents = try? FileManager.default.contentsOfDirectory(atPath: upPath)
            if let contents = pathContents, !contents.isEmpty {
                return false
            } else {
                return !FileManager.default.fileExists(atPath: path)
            }
        }
        return false
    }

    func fetchMattingMode() {
        let isVirtualBgCoremlEnabled = setting.isVirtualBgCoremlEnabled
        Logger.effectBackGround.info("fetchMattingMode device: \(DeviceUtil.modelNumber), fg: \(isVirtualBgCoremlEnabled)")
        guard isVirtualBgCoremlEnabled else { return } // 不符合使用环境，也不用去拉数据
        LabEffectDataLoader.loadEffectPanels(panel: EffectResource.coremlPanel, category: EffectResource.coremlCategory) { (effectMode, needUpdate) in
            Logger.effectBackGround.info("fetchMattingMode listcount \(effectMode?.count), device: \(DeviceUtil.modelNumber), needUpdate: \(needUpdate)")
            if needUpdate, let mattingMode = effectMode, !mattingMode.isEmpty {
                for mode in mattingMode {
                    LabEffectDataLoader.fetchEffect(model: mode) { (_, path) in
                        Logger.effectBackGround.info("fetchMattingMode download, path: \(path), downloaded: \(mode.downloaded), modelNames:  \(mode.modelNames), resId: \(mode.resourceID)")
                    }
                }
            }
        }
    }
}

// MARK: - 上传虚拟背景图片 + 推送
extension EffectVirtualBgService {
    // nolint: cyclo_complexity
    func handleVirtualBgPush(_ message: GetVirtualBackgroundResponse) {
        if !setting.isVirtualBgEnabled {
            self.logger.info("lab bg: Fg turn off.")
            return
        }
        if message.bizType == .bizWebinarStage {
            self.logger.info("skip webinar stage bg push")
            return
        }
        self.logger.info("lab bg: thread push type: \(message.type) count: \(message.infos.count) thread \(Thread.isMainThread)")

        var virtualBgs: [VirtualBgModel] = []
        switch message.type {
        case .all:
            // 全量替换
            virtualBgs = generateFullVirtualBg(infos: message.infos)

            // 如果是面试会议，需要把面试的图片加上
            if meetingVirtualBgType == .people, let peopleModel = interviewerBgModel, let index = virtualBgsArray.firstIndex(where: { $0.bgType == .blur }) {
                self.logger.info("virtualbg push add peoplebg")
                virtualBgs.insert(peopleModel, at: index+1)
            }

            let lastVirtualBgs = virtualBgsArray
            // 保持选中不变
            if let selectedItems = lastVirtualBgs.first(where: { $0.isSelected }) {
                self.logger.error("virtualbg push select name: \(selectedItems.name), type: \(selectedItems.bgType)")
                switch selectedItems.bgType {
                case .blur:
                    self.currentVirtualBgsModel = virtualBgs.first(where: { $0.bgType == .blur })
                case .setNone:
                    self.currentVirtualBgsModel = virtualBgs.first(where: { $0.bgType == .setNone })
                case .virtual:
                    self.currentVirtualBgsModel = virtualBgs.first(where: { $0.key == selectedItems.key })
                default:
                    return
                }
            }

            // 如果选中状态丢失，则回到第一位 ==> 这是一种不应出现的error case
            if self.currentVirtualBgsModel == nil {
                self.logger.error("virtualbg push current = nil")
                self.currentVirtualBgsModel = virtualBgs.first
            }
        case .add:
            let lastVirtualBgs = virtualBgsArray
            // 去重
            let newItems = message.infos.filter { (info) -> Bool in
                return !lastVirtualBgs.contains(where: { $0.key == info.key })
            }
            // 插入到最后
            let newBgs = generateVirtualBg(infos: newItems)
            virtualBgs = virtualBgsArray
            for item in newBgs {
                virtualBgs = insertToEnd(model: item, array: virtualBgs)
            }
        case .update:
            let lastVirtualBgs = virtualBgsArray
            // 过滤无效的updateInfo
            var items = message.infos.filter { (updateInfo) -> Bool in
                guard let existedBg = lastVirtualBgs.first(where: { $0.key == updateInfo.key }) else {
                    return false
                }
                return existedBg.status != .normal
            }
            // 首先对ok的item进行裁剪
            for index in 0..<items.count {
                if items[index].fileStatus == .ok,
                   let bg = lastVirtualBgs.first(where: { $0.key == items[index].key }) {
                    if LabImageCrop.cropImageAt(info: bg, service: service) {
                        logger.info("lab bg: review success crop success")
                    } else {
                        logger.info("lab bg: review success but crop failed! key: \(items[index].key)")
                        items[index].key = ""
                    }
                }
            }

            // 更新fileStatus
            items = items.filter { !$0.key.isEmpty }
            virtualBgs = virtualBgsArray
            for updateItem in items {
                if let bg = virtualBgs.first(where: { $0.key == updateItem.key }) {
                    bg.status = updateItem.fileStatus.virtualBgStatus
                    if updateItem.fileStatus == .ok
//                        && lastFromSource != .none
                    {
                        // 审核成功后立即选中
                        virtualBgs.forEach { $0.isSelected = false }
                        bg.isSelected = true
                        currentVirtualBgsModel = bg
                        saveUserSelectBg(model: bg)
                    }
                }
            }
        case .delete:
            // 删除
            let lastVirtualBgs = virtualBgsArray
            virtualBgs = lastVirtualBgs
            for item in message.infos {
                if let index = virtualBgs.firstIndex(where: { $0.key == item.key }) {
                    virtualBgs = removeBg(at: index, from: virtualBgs)
                }
            }
        default:
            return
        }
        handleErrorBgIfNeeded(virtualBgs: virtualBgs)
    }

    func uploadVirtualBg(name: String, data: Data) {
        // 先将图片临时保存至本地
        let fileName = NSString(string: "\(Date().timeIntervalSince1970)_\(name)").deletingPathExtension + ".jpeg"
        let tempPath = storage.getIsoPath(root: .document, relativePath: fileName)
        do {
            try tempPath.createFile(with: data, attributes: nil)
            Logger.lab.info("uploadVirtualBg tempPath: \(tempPath)")
        } catch {
            Logger.lab.error("lab bg: Save image failed: \(tempPath), error: \(error)")
            return
        }

        // 构建临时数据
        let uploadPath = service.storage.getIsoPath(root: .document, relativePath: virtualBackgroundCatalogue + "upload.png")
        let model = VirtualBgModel(name: "",
                                   bgType: .virtual,
                                   thumbnailIsoPath: uploadPath,
                                   landscapeIsoPath: uploadPath,
                                   portraitIsoPath: uploadPath,
                                   status: .uploading)
        var virtualBgs = virtualBgsArray

        // 插入临时数据到最后（add之前）并更新整体数据流
        virtualBgs = insertToEnd(model: model, array: virtualBgs)
        updateVirtualBgList(array: virtualBgs)

        let request = SetVirtualBackgroundRequest(name: name, path: tempPath.absoluteString)
        httpClient.getResponse(request) { [weak self] result in
            // 删除临时文件
            try? tempPath.removeItem()
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let item = response.info else { return }
                self.logger.info("lab bg: upload success! response: \(item)")
                // 构建真实数据
                let realVirtualBg = self.generateVirtualBg(infos: [item])[0]
                // 替换临时数据为真实数据
                var lastVirtualBgs = self.virtualBgsArray
                if let index = lastVirtualBgs.firstIndex(where: { $0.status == .uploading }) {
                    lastVirtualBgs[index] = realVirtualBg
                } else {
                    lastVirtualBgs = self.insertToEnd(model: realVirtualBg, array: lastVirtualBgs)
                }
                self.handleErrorBgIfNeeded(virtualBgs: lastVirtualBgs)
            case .failure:
                // 上传失败
                model.status = .uploadError
                let lastVirtualBgs = self.virtualBgsArray
                if lastVirtualBgs.contains(where: { $0.status.isError }) {
                    self.handleErrorBgIfNeeded(virtualBgs: lastVirtualBgs)
                }
            }
        }
    }

    func deleteVirtualBg(key: String) {
        httpClient.send(DelVirtualBackgroundRequest(key: key)) { [weak self] result in
            guard let self = self else { return }
            if result.isSuccess {
                var lastVirtualBgs = self.virtualBgsArray
                if let index = lastVirtualBgs.firstIndex(where: { $0.key == key }) {
                    lastVirtualBgs = self.removeBg(at: index, from: lastVirtualBgs)
                    self.updateVirtualBgList(array: lastVirtualBgs)
                }
            } else {
                self.logger.info("lab bg: delete virtual background failed")
            }
        }
    }

    // 过滤错误bg
    private func handleErrorBgIfNeeded(virtualBgs: [VirtualBgModel]) {
        var clearBgs = virtualBgs
        while true {
            // 依次移除，确保选中态能正确流转，不会丢失
            if let index = clearBgs.firstIndex(where: { $0.status.isError }) {
                clearBgs = removeBg(at: index, from: clearBgs)
            } else {
                break
            }
        }
        updateVirtualBgList(array: clearBgs)

        let firstErrorBg = virtualBgs.first(where: { $0.status.isError })
        if let errorBg = firstErrorBg
        {
            logger.info("lab bg: virtual bg handle error: \(errorBg.status)")
            switch errorBg.status {
            case .sizeLimit:
                LabTrack.trackShowPopupView("background_limit_size_vc")
                let message = I18n.View_G_ImageLoadErrors
                ByteViewDialog.Builder()
                    .title(nil)
                    .message(message)
                    .rightTitle(I18n.View_G_OkButton)
                    .show()
            case .countLimit:
                LabTrack.trackShowPopupView("background_limit_amount_vc")
                Toast.show(I18n.View_G_NumberOfBackgroundsReachedLimit)
            case .reviewTimeout:
                Toast.show(I18n.View_G_ConnectionErrorTryAgain)
            case .reviewFailed:
                LabTrack.trackShowPopupView("background_limit_audit_vc")
                if labVC != nil {
                    ByteViewDialog.Builder()
                        .title(nil)
                        .message(I18n.View_VM_FilesIncludeSensitiveContent)
                        .leftTitle(I18n.View_G_CancelButton)
                        .rightTitle(I18n.View_G_ContinueOpen)
                        .rightHandler({ [weak self] _ in
                            // 跳转回图片选择页
                            self?.labVC?.showImagePicker()
                        })
                        .show()
                } else {
                    Toast.show(I18n.View_VM_FilesIncludeSensitiveContent)
                }
            default:
                break
            }
        }
    }

    // 包含删除时的选中转移逻辑
    private func removeBg(at: Int, from: [VirtualBgModel]) -> [VirtualBgModel] {
        var newArray = from
        if labVC != nil {
            if at < newArray.count, newArray[at].isSelected {
                // 优先转给下一个，没有下一个则转给上一个
                // 首先往后找第一个符合条件的转移对象
                var findNext = false
                var newAt = at + 1
                while newAt < newArray.count && newArray[newAt].bgType == .virtual {
                    if newArray[newAt].status == .normal {
                        findNext = true
                        break
                    }
                    newAt += 1
                }

                // 若后面无符合条件的选项，则往前找第一个符合条件的转移对象
                if !findNext {
                    newAt = at - 1
                    while newAt >= 0 {
                        if newArray[newAt].status == .normal {
                            findNext = true
                            break
                        }
                        newAt -= 1
                    }
                }

                if findNext {
                    newArray[newAt].isSelected = true
                    currentVirtualBgsModel = newArray[newAt]
                    saveUserSelectBg(model: currentVirtualBgsModel)
                }
            }
        } else {
            // 直接标为未选中
            newArray.first?.isSelected = true
            currentVirtualBgsModel = newArray.first
            saveUserSelectBg(model: currentVirtualBgsModel)
        }

        if at < newArray.count {
            newArray.remove(at: at)
        }
        return newArray
    }

    private func insertToEnd(model: VirtualBgModel, array: [VirtualBgModel]) -> [VirtualBgModel] {
        var newArray = array
        if let addIndex = newArray.firstIndex(where: { $0.bgType == .add || $0.status == .uploading }) {
            newArray.insert(model, at: addIndex)
        } else {
            newArray.append(model)
        }
        return newArray
    }
}

// MARK: other jobs
extension EffectVirtualBgService {

    private func handleOtherJob() { // 主流程完成后调用
        if let job = otherJobList.popLast() { //labr 应该是第一个，注意要去除元素
            todoForOtherJob(type: job)
        }
    }

    func addJob(type: MeetingVirtualBgType) {
        self.logger.info("add job: \(type)")
        if loadingStatus == .done {
            todoForOtherJob(type: type)
        } else {
            otherJobList.append(type)
        }
        // 如果用户之前没用过虚拟背景，就永远不会走到具体jobs
        if loadingStatus == .unStart || loadingStatus == .failed {
            logger.info("todoForOtherJob not done")
            checkForVirtualBg(ignoreUsed: true)
        }
    }

    private func todoForOtherJob(type: MeetingVirtualBgType) {
        switch type {
        case .people:
            todoForPeople()
        case .calendar:
            todoForCalendar(type: type)
        case .normal:
            break
        }
    }

    private func todoForPeople() {
        self.logger.info("todoForPeople")
        if let peopleModel = interviewerBgModel,
           let index = virtualBgsArray.firstIndex(where: { $0.bgType == .blur }){
            var virtualBgs = virtualBgsArray
            virtualBgs.insert(peopleModel, at: index+1)
            currentVirtualBgsModel = peopleModel
            updateVirtualBgList(array: virtualBgs)
            meetingVirtualBgType = .people
        }
    }

    private func todoForCalendar(type: MeetingVirtualBgType) {
        guard case let .calendar(res) = type, let res = res else {
            return
        }
        switch res {
        case .success(let result):
            self.logger.info("getExtra success, ExtraBgallow: \(result.allowVirtualBackground), animojiallow: \(result.allowVirtualAvatar), currenttype \(self.currentVirtualBgsModel?.bgType)")
            // 状态改变
            self.allowVirtualBgInfo = AllowVirtualBgRelayInfo(allow: result.allowVirtualBackground, hasUsedBgInAllow: self.currentVirtualBgsModel?.bgType != .setNone)

            // 权限管控不允许流程，现在用了虚拟背景再去改变models
            if !result.allowVirtualBackground, self.hasUsedBgInAllow == true {
                self.logger.info("begin handle notAllow virtualBackground")
                self.currentVirtualBgsModel = self.noneVirtualBgModel
            }
            // 统一设置虚拟背景
            if let virtualBgImage = result.virtualBgImage, result.allowVirtualBackground {
                self.logger.info("ExtraBg name \(virtualBgImage.name)")
                let url = virtualBgImage.url
                var bg = GetVirtualBackgroundRequest.VirtualBackground(name: virtualBgImage.name, url: url)
                bg.source = .appCalendar  // 现在只有这个，可以替换成source
                if !virtualBgImage.portraitUrl.isEmpty {
                    bg.portraitURL = virtualBgImage.portraitUrl
                }
                self.calendarMeetingVirtual?.hasExtraBg = true
                self.downloadExtraVirtualBgs(model: bg)
            } else {
                self.logger.info("noExtraBg or not allow")
                self.calendarMeetingVirtual?.hasExtraBg = false
                self.extrabgDownloadStatus = .failed
            }
        case .failure(let e):
            self.extrabgDownloadStatus = .failed
            self.logger.info("getExtraBg failed \(e)")
        }
    }
}

// MARK: 统一虚拟背景+权限控制
extension EffectVirtualBgService {

    func beginFetchCalendarBgsInfo(meetingId: String?, uniqueId: String?, isWebinar: Bool?, isUnWebinarAttendee: Bool?) {
        calendarMeetingVirtual = CalendarMeetingVirtual(meetingId: meetingId, uniqueId: uniqueId, isWebinar: isWebinar)
        if isUnWebinarAttendee == true {
            self.hasSetCalenderForUnWebinarAttendee = true
        }
        self.extrabgDownloadStatus = .checking
    }

    func downloadExtraVirtualBgs(model: GetVirtualBackgroundRequest.VirtualBackground) {
        self.extrabgDownloadStatus = .download

        let request = GetVirtualBackgroundRequest(sets: [model], fromLocal: false)
        httpClient.getResponse(request) { [weak self] res in
            guard let self = self else {
                self?.extrabgDownloadStatus = .failed
                return
            }
            switch res {
            case .success(let result):
                guard let info = result.infos.first else {
                    self.extrabgDownloadStatus = .failed
                    self.logger.info("downloadExtraVirtualBgs download 0")
                    return
                }
                // 下载、转model、裁剪、插入、应用
                self.logger.info("downloadExtraVirtualBgs resp name: \(info.name), key: \(info.key)")
                var virtualBgs = self.virtualBgsArray
                let extraBg = info.convertToBgModel(storage: self.storage)

                let doAction = {
                    let calendarIndex = virtualBgs.firstIndex(where: { $0.imageSource == .appCalendar })
                    if let index = virtualBgs.firstIndex(where: { $0.bgType == .blur }), calendarIndex == nil {
                        self.logger.info("do downloadExtraVirtualBgs final success")
                        virtualBgs.insert(extraBg, at: index + 1)
                        self.currentVirtualBgsModel = extraBg
                        self.calendarMeetingVirtual?.bgModel = extraBg
                        self.updateVirtualBgList(array: virtualBgs)
                        self.extrabgDownloadStatus = .done
                        self.meetingVirtualBgType = .calendar(res: nil)
                    } else {
                        self.logger.info("do downloadExtraVirtualBgs final failed")
                        self.extrabgDownloadStatus = .failed
                    }
                }
                if extraBg.hasCropLandscape() && extraBg.hasCropPortrait() { //已经裁剪过
                    doAction()
                } else if LabImageCrop.cropImageAt(info: extraBg, service: self.service) { //去裁剪
                    doAction()
                } else { //没有裁剪并且裁剪失败
                    self.extrabgDownloadStatus = .failed
                    self.logger.error("downloadExtraVirtualBgs final failed")
                }
            case .failure:
                self.extrabgDownloadStatus = .failed
                self.logger.info("downloadExtraVirtualBgs failed")
            }
        }
    }

    func canShowMuteBgPreview(isOriginMuted: Bool) -> Bool {
        //不允许虚拟背景+设置过虚拟背景+之前没显示过下面的vc
        return !allowVirtualBgInfo.allow && (hasUsedBgInAllow == true) && !hasShowedNotAllowAlert && !(hasShowedNotAllowToast && !isOriginMuted)
    }
}


// MARK: - listeners
extension EffectVirtualBgService {
    func addListener(_ listener: EffectVirtualBgListener, fireImmediately: Bool = false) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: EffectVirtualBgListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: EffectVirtualBgListener) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            listener.didChangeVirtualBgloadingStatus(status: self.loadingStatus)
            if let currentModel = self.currentVirtualBgsModel {
                listener.didChangeCurrentVirtualBg(bgModel: currentModel)
            }
            listener.didChangeVirtualBgList(bgModelList: self.virtualBgsArray)
        }
    }

    private func updateVirtualBgList(array: [VirtualBgModel]) {
        virtualBgsArray = array
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.listeners.forEach { $0.didChangeVirtualBgList(bgModelList: self.virtualBgsArray) }
        }
    }
}

extension EffectVirtualBgService {
    func addCalendarListener(_ listener: EffectVirtualBgCalendarListener, fireImmediately: Bool = false) {
        calendarListeners.addListener(listener)
        if fireImmediately {
            fireCalendarListenerOnAdd(listener)
        }
    }

    func removeCalendarListener(_ listener: EffectVirtualBgCalendarListener) {
        calendarListeners.removeListener(listener)
    }

    private func fireCalendarListenerOnAdd(_ listener: EffectVirtualBgCalendarListener) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            listener.didChangeExtrabgDownloadStatus(status: self.extrabgDownloadStatus)
            listener.didChangeVirtualBgAllow(allowInfo: self.allowVirtualBgInfo)
        }
    }
}

// MARK: - listen settings

extension EffectVirtualBgService: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: ByteViewSetting.MeetingSettingManager, key: ByteViewSetting.MeetingSettingKey, isOn: Bool) {
        checkForVirtualBg()
    }
}

extension EffectVirtualBgService: MeetingComplexSettingListener {
    func didChangeComplexSetting(_ settings: ByteViewSetting.MeetingSettingManager, key: ByteViewSetting.MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        checkForVirtualBg()
    }
}

extension EffectVirtualBgListener {
    func didChangeVirtualBgloadingStatus(status: EffectLoadingStatus) {}
    func didChangeCurrentVirtualBg(bgModel: VirtualBgModel) {}
    func didChangeVirtualBgList(bgModelList: [VirtualBgModel]) {}
}

extension EffectVirtualBgCalendarListener {
    func didChangeExtrabgDownloadStatus(status: ExtraBgDownLoadStatus) {}
    func didChangeVirtualBgAllow(allowInfo: AllowVirtualBgRelayInfo) {}
}
