//
//  LabEffectService+DataLoader.swift
//  ByteView
//
//  Created by wangpeiran on 2021/11/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift
import UniverseDesignIcon
import EffectPlatformSDK

class LabEffectDataLoader {
    let isLark: Bool
    init(isLark: Bool) {
        self.isLark = isLark
    }

    lazy var animojiLoadingStatusSubject = ReplaySubject<EffectLoadingStatus>.create(bufferSize: 1)
    lazy var filterBeautyLoadingStatusSubject = ReplaySubject<EffectLoadingStatus>.create(bufferSize: 1)
    lazy var filterNormalLoadingStatusSubject = ReplaySubject<EffectLoadingStatus>.create(bufferSize: 1)
    lazy var filterLoadingStatusSubject = ReplaySubject<EffectLoadingStatus>.create(bufferSize: 1)
    lazy var retuschierenLoadingStatusSubject = ReplaySubject<EffectLoadingStatus>.create(bufferSize: 1)

    func loadEffectList(type: EffectInnerType, completionHandler: @escaping (Result<[ByteViewEffectModel], Error>) -> Void) {
        guard let (panel, category) = EffectResource.effectPanel(isLark: isLark)[type] else {
            return
        }
        LabEffectDataLoader.loadEffectPanels(panel: panel, category: category) { (effectModelArray, _) in
            let loadSuccess = effectModelArray != nil
            if !loadSuccess {
                Logger.effect.error("load loadEffectPanels, \(effectModelArray?.count) \(loadSuccess)")
                completionHandler(.failure(VCError.unknown))
                return
            }

            var effectArray = effectModelArray ?? []
            var tempArray: [ByteViewEffectModel] = []
            var realType: EffectType

            switch type {
            case .animoji:
                realType = .animoji
                effectArray.reverse()
            case .retuschieren:
                realType = .retuschieren
            case .filter:
                realType = .filter
            }

            let emptyModel = ByteViewEffectModel(effectModel: IESEffectModel(), panel: panel, category: category, labType: realType)
            emptyModel.isSelected = true
            emptyModel.bgType = .none
            emptyModel.title = I18n.View_VM_None
            emptyModel.resourceId = EffectResource.effectEmptyId

            switch type {
            case .animoji:
                tempArray.append(emptyModel)
                _ = effectArray.map({ (model) in
                    let newModel = ByteViewEffectModel(effectModel: model, panel: panel, category: category, labType: realType)
                    LabEffectDataLoader.buildAnimojiEffectModel(model: newModel)
                    tempArray.append(newModel)
                })
            case .retuschieren:
                _ = effectArray.map({ (model) in
                    let newModel = ByteViewEffectModel(effectModel: model, panel: panel, category: category, labType: realType)
                    LabEffectDataLoader.buildUnAnimojiEffectModel(model: newModel)
                    tempArray.append(newModel)
                })
            case .filter:
                tempArray.append(emptyModel)
                _ = effectArray.map({ (model) in
                    let newModel = ByteViewEffectModel(effectModel: model, panel: panel, category: category, labType: realType)
                    LabEffectDataLoader.buildUnAnimojiEffectModel(model: newModel)
                    tempArray.append(newModel)
                })
            }
            completionHandler(.success(tempArray))
        }
    }

    /// 加载特定Panel下的特效, 加载过程一般分成两步：检查更新，然后根据是否需要更新来加载列表数据。
    static func loadEffectPanels(panel: String, category: String, completionHandler: @escaping (([IESEffectModel]?, Bool)) -> Void) {
        // 检查更新
        EffectPlatform.checkEffectUpdate(withPanel: panel, category: category, effectTestStatusType: .default) { (needUpadte) in
            // 获取缓存
            let cachedResponse: IESEffectPlatformNewResponseModel? = EffectPlatform.cachedEffects(ofPanel: panel, category: category)
            Logger.effect.info("lab effect: need update \(needUpadte), panel: \(panel), category: \(category)")

            if needUpadte || cachedResponse == nil {
                EffectPlatform.downloadEffectList(withPanel: panel, category: category, pageCount: 0, cursor: 0, sortingPosition: 0) { (error, responseModel) in
                    if let responseModel = responseModel,
                       !responseModel.categoryEffects.effects.isEmpty,
                       error == nil {
                        // list数据请求成功，使用response
                        Logger.effect.info("lab effect: fetch list success, \(needUpadte) \(panel) \(category) \(responseModel.categoryEffects.effects.count)")
                        completionHandler((responseModel.categoryEffects.effects, needUpadte))
                    } else {
                        // 数据请求失败 如果有缓存数据依然用缓存，没有返回空
                        Logger.effect.info("lab effect: fetch list error, \(needUpadte) \(panel) \(category) -- \(error?.localizedDescription)")
                        let errorCode: Int = LabEffectDataLoader.parsePlatformErrorCode(message: "\(error)") ?? 0
                        CommonReciableTracker.trackThirdHttpError(thirdType: "platform_sdk",
                                                                  errorUrl: "\(error)",
                                                                  errorMsg: error?.localizedDescription ?? "",
                                                                  code: errorCode)
                        if let cachedResponse = cachedResponse,
                           !cachedResponse.categoryEffects.effects.isEmpty {
                            Logger.effect.info("lab effect: download list error use cache list \(panel) \(category)")
                            completionHandler((cachedResponse.categoryEffects.effects, needUpadte))
                        } else {
                            completionHandler((nil, needUpadte))
                        }
                    }
                }
            } else {
                // 如果缓存存在并且不需要更新，直接使用缓存数据 cachedResponse
                Logger.effect.info("lab effect: use cache list, panel \(panel), listcount: \(cachedResponse?.categoryEffects.effects.count)")
                completionHandler((cachedResponse?.categoryEffects.effects ?? [], needUpadte))
            }
        }
    }

    /// 获取具体某个effect资源
    static func fetchEffect(model: IESEffectModel, callback: @escaping (Error?, String?) -> Void) {
        if model.downloaded {  // 已经下载
            Logger.effect.info("lab effect: has download \(model.effectName) \(model.filePath)")
            callback(nil, model.filePath)
        } else {
            EffectPlatform.downloadEffect(model, progress: { (progress) in
                Logger.effect.info("lab effect: downloading \(model.effectName) \(progress)")
            }, completion: { (error, filePath) in
                if let error {
                    Logger.effect.info("lab effect: downloading \(model.effectName) error \(error.localizedDescription)")
                    let errorCode: Int = self.parsePlatformErrorCode(message: "\(error)") ?? 0
                    CommonReciableTracker.trackThirdHttpError(thirdType: "platform_sdk",
                                                              errorUrl: "\(error)",
                                                              errorMsg: error.localizedDescription,
                                                              code: errorCode)
                } else {
                    Logger.effect.info("lab effect: downloading \(model.effectName) success") //model.filePath
                }
                callback(error, filePath)
            })
        }
    }

    static func buildAnimojiEffectModel(model: ByteViewEffectModel) {
        if !model.effectModel.extra.isEmpty,
           let extra = Util.convertToDictionary(text: model.effectModel.extra),
           let realExtra = extra["vc_says_effect"] as? String,
           let realExtraDic = Util.convertToDictionary(text: realExtra) {
            if let resource = realExtraDic["resource"] as? String {
                model.resource = resource
            }
            if let items = realExtraDic["items"] as? [[String: String]] {
                model.extraItem = items
            }
        }
    }

    static func buildUnAnimojiEffectModel(model: ByteViewEffectModel) {
        if !model.effectModel.extra.isEmpty,
           let extra = Util.convertToDictionary(text: model.effectModel.extra),
           let realExtra = extra["vc_says_effect"] as? String,
           let realExtraDic = Util.convertToDictionary(text: realExtra) {
            if let resource = realExtraDic["resource"] as? String {
                model.resource = resource
            }
            if let items = realExtraDic["items"] as? [[String: Any]] {
                model.extraItem = items
                if let itemDic = items.first,
                   let min = itemDic["min"] as? Int,
                   let max = itemDic["max"] as? Int {
                    model.min = min
                    model.max = max
                    if let value = itemDic["value"] as? Int, model.labType != .retuschieren {
                        model.defaultValue = value
                    }
                }
            }
        }
    }

    static func parsePlatformErrorCode(message: String) -> Int? {
        // example: Error Domain=com.bytedance.ies.effect Code=2008 "Category does not exist" UserInfo={NSLocalizedDescription=Category does not exist}
        var errorCode: Int?
        do {
            let regex = try NSRegularExpression(pattern: "Code=\\d+", options: [])
            if let result = regex.matches(message).first?.replacingOccurrences(of: "Code=", with: "") {
                errorCode = Int(result)
            }
        } catch {
            Logger.lab.info("parse errorCode failed: \(error)")
        }
        return errorCode
    }
}

class ByteViewEffectModel {
    var min: Int?
    var max: Int?
    var defaultValue: Int?
    var currentValue: Int?  // 特别注意：美颜在auto的时候不是取这个值，current保存的是自定义的
    var isSelected: Bool = false
    var icon: UDIconType?
    var title: String = ""

    var resource: String?
    var resourceId: String
    var extraItem: [[String: Any]] = []

    let panel: String
    let category: String
    var bgType: EffectSettingType   // 是空取消还是有effect
    let labType: EffectType   // 哪种类型的effect

    var effectModel: IESEffectModel

    init(effectModel: IESEffectModel, panel: String, category: String, labType: EffectType, bgType: EffectSettingType = .set) {
        self.effectModel = effectModel
        self.panel = panel
        self.category = category
        self.labType = labType
        self.bgType = bgType
        self.resourceId = effectModel.resourceId
        self.title = effectModel.effectName

        // 美颜本地映射图片文字数据
        if labType == .retuschieren {
            let defaultValue = EffectResource.retuschieren[effectModel.resourceId]?.defaultValue
            self.defaultValue = defaultValue // 美颜交互，将默认值写死到本地

            switch bgType {
            case .none:
                self.title = I18n.View_MV_BeautyOriginal
                self.icon = .banOutlined
                self.bgType = .none
            case .auto:
                self.title = I18n.View_MV_BeautyAuto
                self.icon = .touchUpOutlined
                self.bgType = .auto
            case .customize:
                self.title = I18n.View_MV_BeautyCustomize
                self.icon = .adminOutlined
                self.bgType = .customize
            case .set:
                let name = EffectResource.retuschieren[effectModel.resourceId]?.name
                let icon = EffectResource.retuschieren[effectModel.resourceId]?.icon
                if let name = name {
                    self.title = name
                }
                if let icon = icon {
                    self.icon = icon
                }
            }
        }
    }

    func applyValue(for applyType: EffectSettingType) -> Int? {
        switch applyType {
        case .none:    // 取消，针对于美颜，apply设置为0
            return 0
        case .auto:    // 自动，针对于美颜，apply设置为默认值
            return defaultValue
        case .customize, .set:
            return currentValue
        }
    }
}
