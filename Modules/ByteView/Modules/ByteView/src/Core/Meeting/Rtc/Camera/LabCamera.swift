//
//  LabCamera.swift
//  ByteView
//
//  Created by kiri on 2022/8/20.
//

import Foundation
import RxSwift
import ByteViewSetting
import ByteViewRtcBridge

/// 带特效的摄像头
final class LabCamera: RtcCamera {
    private let disposeBag = DisposeBag()
    var isVirtualBgEnabled: Bool
    var effectManger: MeetingEffectManger?
    var setting: MeetingSettingManager
    let service: MeetingBasicService

    init(engine: MeetingRtcEngine,
         scene: RtcCameraScene,
         service: MeetingBasicService,
         effectManger: MeetingEffectManger?,
         isFromLab: Bool) {
        self.isVirtualBgEnabled = service.setting.isVirtualBgEnabled
        self.service = service
        self.effectManger = effectManger
        self.setting = service.setting
        super.init(engine: engine, scene: scene)

        if !isFromLab { // 如果是labvc的摄像头，就不用监听特效变化设置特效，设置特效会在preview和inmmet camera中
            service.startRtcForEffect() //初始化rtc
            effectManger?.virtualBgService.addListener(self, fireImmediately: true)
            effectManger?.pretendService.addListener(self, fireImmediately: true)
        }
    }

    deinit {
        Logger.effect.info("labcamera deinit")
        effectManger?.virtualBgService.removeListener(self)
        effectManger?.pretendService.removeListener(self)
    }

    override func switchCamera() {
        super.switchCamera()
        AladdinTracks.trackCamSelected(isFront: isFrontCamera)
    }

    override func setMuted(_ isMuted: Bool, file: String = #fileID, function: String = #function, line: Int = #line) {
        super.setMuted(isMuted, file: file, function: function, line: line)
    }

    func enableBackgroundBlur(_ isEnable: Bool) {
        if isVirtualBgEnabled {
            let loggerString = "labcamera setBackgroundImage Blur \(isEnable)"
            Logger.effectBackGround.info(loggerString)
            effect.enableBackgroundBlur(isVirtualBgEnabled ? isEnable : false)
        }
    }

    func setBackgroundImage(imagePath: String, name: String) {
        if isVirtualBgEnabled {
            let loggerString = "labcamera setBackgroundImage: path \(imagePath.isEmpty ? "empty" : "notEmpty"), name: \(name)"
            Logger.effectBackGround.info(loggerString)
            Logger.lab.info(loggerString)
            effect.setBackgroundImage(imagePath)
        }
    }

    // 内部底层调用pretend类型特效封装，一般不需要动
    func applyPretend(model: ByteViewEffectModel, applyType: EffectSettingType) {
        var params: [NSNumber] = []
        var tags: [String] = []
        let applyValue = model.applyValue(for: applyType)
        for item in model.extraItem {
            if let value = applyValue {
                params.append(NSNumber(value: value))
            }
            if let tag = item["tag"] as? String {
                tags.append(tag)
            }
        }
        // 每个种类内部使用（比如美颜下面有四个选项，用EffectType_BuildIn，头像内部间互斥EffectType_Exclusive）
        let rtcEffectType: RtcEffectType
        switch model.labType {
        case .retuschieren:
            rtcEffectType = .buildIn
        default:
            rtcEffectType = .exclusive
        }
        let info = RtcFetchEffectInfo(resId: model.resourceId, resPath: model.effectModel.filePath,
                                      category: model.category, panel: model.panel,
                                      tagNum: model.extraItem.count, tags: tags, params: params)
        effect.applyEffect(info, with: rtcEffectType, contextId: "", cameraEffectType: model.labType.rtcCameraDeviceType)
    }
}

extension LabCamera: EffectVirtualBgListener, EffectPretendDataListener {
    func didChangeCurrentVirtualBg(bgModel: VirtualBgModel) {
        Util.runInMainThread {
            Logger.effectBackGround.info("will set name: \(bgModel.name), bgtype: \(bgModel.bgType), \(self)")
            switch bgModel.bgType {
            case .setNone:
                self.setBackgroundImage(imagePath: "", name: "")
                self.enableBackgroundBlur(false)
            case .blur:
                self.enableBackgroundBlur(true)
            case .virtual:
                if !bgModel.hasCropLandscape() || !bgModel.hasCropPortrait() {  //兜底逻辑，正常不会走到这里
                    if LabImageCrop.cropImageAt(info: bgModel, service: self.service) {
                        Logger.effectBackGround.warn("crop image in labcamera")
                        self.setBackgroundImage(imagePath: bgModel.rtcPath, name: bgModel.name)
                    }
                } else {
                    self.setBackgroundImage(imagePath: bgModel.rtcPath, name: bgModel.name)
                }
            case .add:
                break
            }
        }
    }

    func applyPretend(type: EffectType, model: ByteViewEffectModel, applyType: EffectSettingType) {
        if !model.effectModel.downloaded {  //兜底逻辑，正常不会走到这里
            Logger.effectPretend.error("labcamera apply undownload effect \(model.category) name:\(model.title) value:\(model.applyValue(for: applyType))")
            LabEffectDataLoader.fetchEffect(model: model.effectModel) { [weak self] error, path in
                if error == nil && path != nil {
                    self?.applyPretend(model: model, applyType: applyType)
                    Logger.effectPretend.info("labcamera apply effect \(model.category) name:\(model.title) value:\(model.applyValue(for: applyType))")
                }
            }
        } else {
            applyPretend(model: model, applyType: applyType)
            Logger.effectPretend.info("labcamera apply effect \(model.category) name:\(model.title) value:\(model.applyValue(for: applyType))")
        }
    }

    func cancelPretend(model: ByteViewEffectModel) {
        Logger.effectPretend.info("labcamera cancel effect \(model.category) name:\(model.title)")
        effect.cancelEffect(model.panel, cameraEffectType: model.labType.rtcCameraDeviceType)
    }
}
