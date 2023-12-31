//
//  CreateLimitedNotifyRequest.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/7/27.
//  

import Foundation
import SwiftyJSON
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import EENavigator
import SKInfra

public final class CreateLimitedNotifyRequest {
    public class func notifysuitebot() {
        let req = DocsRequest<JSON>(path: OpenAPI.APIPath.notifysuitebot, params: nil)
            .set(method: .GET)
            .start { (res, err) in
                guard let mainSceneWindow = Navigator.shared.mainSceneWindow else { return }
                if (res?["code"].int ?? -1 != 0) || err != nil {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: mainSceneWindow)
                } else {
                    UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_Reminded, on: mainSceneWindow)
                }
            }
        req.makeSelfReferenced()
    }

    public class func report(_ confirm: Bool) {
        let param: [String: String] = confirm ? ["action": "notify_admin"] : ["action": "cancel"]
        DocsTracker.log(enumEvent: .clientCommerce, parameters: param)
    }
}
