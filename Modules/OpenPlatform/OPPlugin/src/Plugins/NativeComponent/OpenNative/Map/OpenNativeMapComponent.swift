//
//  OpenNativeMapComponent.swift
//  OPPlugin
//
//  Created by yi on 2021/8/24.
//
// map组件

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPPluginBiz
import LarkWebviewNativeComponent
import LKCommonsLogging

final class OpenNativeMapComponent: OpenNativeBaseComponent {
    var map: BDPMapView?
    private static let logger = Logger.oplog(OpenNativeMapComponent.self, category: "LarkWebviewNativeComponent")

    // 组件标签名字
    override class func nativeComponentName() -> String {
        return "map"
    }

    // 组件插入接收，返回view
    override func insert(params: [AnyHashable: Any]) -> UIView? {
        do {
            let model = try BDPMapViewModel(dictionary: params)
            if let viewModelError = OpenMapValidator.checkBDPMapViewModel(model: model) {
                Self.logger.error("map component, insert error, param is invalid", error: viewModelError)
                return nil
            }
            let page = webView as? BDPWebView
            map = BDPMapView(model: model, componentID: 0, engine: page)
            return map
        } catch {
            Self.logger.error("map component, insert error, BDPMapViewModel init error")
        }
        return nil
    }

    // 组件更新
    override func update(nativeView: UIView?, params: [AnyHashable: Any]) {
        do {
            let model = try BDPMapViewModel(dictionary: params)
            if let viewModelError = OpenMapValidator.checkBDPMapViewModel(model: model, checkRule: .onlyValuedParam) {
                Self.logger.error("map component, update error, param is invalid", error: viewModelError)
                return
            }
            if let map = nativeView as? BDPMapView {
                map.update(with: model, checkRule: .onlyValuedParam)
            } else {
                Self.logger.error("map component, update error, mapView is nil")
            }
        } catch {
            Self.logger.error("map component, update error, BDPMapViewModel init error")
        }
    }

    // 组件删除
    override func delete() {

    }

    // 接收JS派发的消息
    override func dispatchAction(methodName: String, data: [AnyHashable: Any]) {
        guard let map = map else {
            Self.logger.error("map component, dispatchAction error, mapView is nil")
            return
        }

        if methodName == "moveToLocation" {
            if let latitude = data["latitude"] as? CLLocationDegrees, let longitude = data["longitude"] as? CLLocationDegrees {
                if latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 {
                    let location = CLLocationCoordinate2DMake(latitude, longitude)
                    map.move(to: location)
                } else {
                    Self.logger.error("map component, dispatchAction error, latitude or longitude invalid, latitude \(latitude) longitude \(longitude)")
                }
            } else {
                map.moveToCurrentLocation()
            }
        }
    }
}
