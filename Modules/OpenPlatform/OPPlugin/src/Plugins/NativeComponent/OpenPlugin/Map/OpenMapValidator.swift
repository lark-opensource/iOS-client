//
//  OpenMapValidator.swift
//  OPPlugin
//
//  Created by yi on 2021/8/24.
//
// 地图组件数据校验工具

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPPluginBiz

final class OpenMapValidator: NSObject {
    /// 检测BDPMapViewModel参数是否合法 合法返回nil
    /// @param model 地图数据model
    class func checkBDPMapViewModel(model: BDPMapViewModel?) -> NSError? {
        return checkBDPMapViewModel(model: model, checkRule: .allMust)
    }

    /// 检测BDPMapViewModel参数是否合法 合法返回nil
    /// @param model 地图数据model
    /// @param checkRule 参数校验规则
    class func checkBDPMapViewModel(model: BDPMapViewModel?, checkRule: BDPMapViewModelCheckRule) -> NSError? {
        guard let model = model else {
            return NSError(domain: "MapError", code: -1, userInfo: [NSLocalizedDescriptionKey: "no map info"])
        }

        /// 是否需要校验该参数
        /// return true为需要校验，false为不需要校验
        func needCheck(paramKey: String) -> Bool {
            if checkRule == .onlyValuedParam {
                return !model.isEmptyParam(paramKey)
            }
            return true
        }
        if needCheck(paramKey: "latitude"), model.latitude < -90 || model.latitude > 90 {
            return NSError(domain: "MapError", code: -1, userInfo: [NSLocalizedDescriptionKey: "invaild latitude"])
        }
        if needCheck(paramKey: "longitude"), model.longitude < -180 || model.longitude > 180 {
            return NSError(domain: "MapError", code: -1, userInfo: [NSLocalizedDescriptionKey: "invaild longitude"])
        }
        if needCheck(paramKey: "scale"), model.scale < 3 || model.scale > 20 {
            model.scale = 3
        }

        var error: NSError?
        for item in model.markers ?? [] {
            error = checkBDPMapMarkerModel(model: item)
            if error != nil {
                break
            }
        }
        if error != nil {
            return error
        }
        for item in model.circles ?? [] {
            error = checkBDPMapCircleModel(model: item)
            if error != nil {
                break
            }
        }
        return error
    }

    /// 检查BDPMapMarkerModel是否合法 合法返回nil
    /// @param model marker数据模型
    class func checkBDPMapMarkerModel(model: BDPMapMarkerModel?) -> NSError? {
        guard let model = model else {
            return nil
        }
        if model.latitude < -90 || model.latitude > 90 {
            return NSError(domain: "MapError", code: -1, userInfo: [NSLocalizedDescriptionKey: "invaild latitude"])
        }
        if model.longitude < -180 || model.longitude > 180 {
            return NSError(domain: "MapError", code: -1, userInfo: [NSLocalizedDescriptionKey: "invaild longitude"])
        }
        return nil
    }

    /// 检查BDPMapMarkerModel是否合法 合法返回nil
    /// @param model 圆数据模型
    class func checkBDPMapCircleModel(model: BDPMapCircleModel?) -> NSError? {
        guard let model = model else {
            return nil
        }
        if model.latitude < -90 || model.latitude > 90 {
            return NSError(domain: "MapError", code: -1, userInfo: [NSLocalizedDescriptionKey: "invaild latitude"])
        }
        if model.longitude < -180 || model.longitude > 180 {
            return NSError(domain: "MapError", code: -1, userInfo: [NSLocalizedDescriptionKey: "invaild longitude"])
        }
        if model.radius <= 0 {
            model.radius = 1
        }
        if model.strokeWidth < 0 {
            model.strokeWidth = 0
        }
        return nil
    }

}
