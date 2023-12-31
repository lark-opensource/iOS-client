//
//  OpenPluginLocation+OpenLocationV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 4/20/22.
//

import Foundation
import Foundation
import OPSDK
import LarkSetting
import CoreLocation
import LarkOpenAPIModel
import LarkCoreLocation
import LarkLocationPicker
import LarkPrivacySetting
import LarkOpenPluginManager

extension OpenPluginLocationV2 {
    /// openLocation 合规版本实现
    public func openLocationV2(params: OpenAPIOpenLocationParamsV2,
                               context: OpenAPIContext,
                               callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        OpenLocationMonitorUtils.report(apiName: "openLocationV2",
                                        locationType: params.type.rawValue,
                                        context: context)

        /// 只有国内才有Map 所以这个可以用来判断是否是lark
        let isLark = !FeatureUtils.isAMap()
        // Lark上传gcj02. 则直接报错;(这边逻辑是双端对齐且和getLocation对齐的)
        if isLark && params.type == .gcj02 {
            let msg = "openLocationV2 cannot use gcj02 type without amap"
            context.apiTrace.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setMonitorMessage(msg)
            callback(.failure(error: error))
            return
        }
        let locationType: OPLocationType
        let coordinate2D: CLLocationCoordinate2D
        let originCoordinate2D = CLLocationCoordinate2D(latitude: params.latitude, longitude: params.longitude)
        ///在飞书上，type为84 且高德有数据都应该使用02坐标
        if !isLark,
            params.type == .wgs84,
            FeatureUtils.AMapDataAvailableForCoordinate(originCoordinate2D) {
            locationType = .gcj02
            coordinate2D = FeatureUtils.convertWGS84ToGCJ02(coordinate: originCoordinate2D)
        } else {
            locationType = params.type
            coordinate2D = originCoordinate2D
        }

        context.apiTrace.info("openLocationV2 start params:\(params)")
        guard let gadgetContext = context.gadgetContext,
              let controller = gadgetContext.controller else {
                  let msg = "host controller is nil, has gadgetContext? \(context.gadgetContext != nil)"
                  context.apiTrace.error(msg)
                  let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                      .setMonitorMessage(msg)
                  callback(.failure(error: error))
                  return
              }
        let setting = LocationSetting(
            name: params.name ?? "", // POI name
            description: params.address ?? "", // POI address
            center: coordinate2D, // location, CLLocationCoordinate2D
            zoomLevel: Double(params.scale), // map zoom level
            isCrypto: false, // 是否密聊，一般场景传入false
            isInternal: locationType == .gcj02, // 坐标国内或者国外
            defaultAnnotation: true, // 是否展示默认annotation
            needRightBtn: false // 是否需要右上角发送按钮
        )
        context.apiTrace.info("openLocationV2 openController locationSetting:\(setting)")
        let locationController = OpenLocationController(setting: setting)
        OPNavigatorHelper.push(locationController, window: controller.view.window, animated: true)
        callback(.success(data: nil))
    }
}
