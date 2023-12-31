//
//  OpenPluginLocation+ChooseLocationV2.swift
//  OPPlugin
//
//  Created by zhangxudong on 4/20/22.
//

import Foundation
import OPSDK
import LarkSetting
import CoreLocation
import LarkOpenAPIModel
import LarkCoreLocation
import LarkLocationPicker
import LarkPrivacySetting
import LarkOpenPluginManager
import LarkUIKit
extension OpenPluginLocationV2 {
    /// chooseLocation 合规版本实现
    public func chooseLocationV2(params: OpenAPIBaseParams,
                                 context: OpenAPIContext,
                                 callback: @escaping (OpenAPIBaseResponse<OpenAPIChooseLocationResultV2>) -> Void) {
        context.apiTrace.info("chooseLocationV2 enter parms:\(params)")

        let viewController = ChooseLocationViewController()
        viewController.cancelCallBack = {
            context.apiTrace.info("ChooseLocationViewController return user cancel")
            let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPILocationErrno.userCancel)
                .setOuterMessage("user cancel")
            callback(.failure(error: apiError))
        }

        viewController.sendLocationCallBack = { (location) in
            let locationType: OPLocationType = location.isInternal ? .gcj02 : .wgs84
            let result = OpenAPIChooseLocationResultV2(name: location.name,
                                                     address: location.address,
                                                     latitude:location.location.latitude,
                                                     longitude: location.location.longitude,
                                                     type: locationType)
            context.apiTrace.info("ChooseLocationViewController return user select location\(location) result:\(result)")
            callback(.success(data: result))
        }


        guard let gadgetContext = context.gadgetContext,
              let controller = gadgetContext.controller else {
                  let msg = "host controller is nil, has gadgetContext? \(context.gadgetContext != nil)"
                  context.apiTrace.error(msg)
                  let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                      .setMonitorMessage(msg)
                  callback(.failure(error: error))
                  return
              }

        guard let topMostAppController = OPNavigatorHelper.topMostAppController(window: controller.view.window) else {
            let msg = "topMostAppController is nil, can not push location picker"
            context.apiTrace.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage(msg)
            callback(.failure(error: error))
            return
        }
        let navi = LkNavigationController(rootViewController: viewController)
        navi.modalPresentationStyle = .overFullScreen
        navi.navigationBar.isTranslucent = false
        context.apiTrace.info("present ChooseLocationViewController")
        topMostAppController.present(navi, animated: true, completion: nil)
    }
}
