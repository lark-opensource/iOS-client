//
//  UtilProfileService.swift
//  Alamofire
//
//  Created by Huang JinZhu on 2018/10/19.
//

import UIKit
import SKCommon
import SKFoundation
import SKUIKit

public final class UtilProfileService: BaseJSService {
    private weak var showUserListVC: UIViewController?
}

extension UtilProfileService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilProfile, .utilShowUserList, .getCurrentUserInfo]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilProfile.rawValue:
            guard let userId = params["userId"] as? String else {
                DocsLogger.info("error profile params", extraInfo: params, error: nil, component: nil)
                spaceAssertionFailure()
                return
            }
            DocsLogger.info("\(String(describing: model?.jsEngine.editorIdentity)) show profile: \(userId)")
            self.navigator?.showUserProfile(token: userId)
            
        case DocsJSService.utilShowUserList.rawValue:
            var data: [UserInfoData.UserData] = []
            guard let userdata = params["data"] as? Array<Any> else {
                DocsLogger.info("\(String(describing: model?.jsEngine.editorIdentity)) data is nil")
                return
            }
            
            guard showUserListVC == nil else {
                DocsLogger.info("showUserListVC not nil")
                return
            }
            
            userdata.forEach { oriData in
                if let dic = oriData as? [String: Any] {
                    data.append(UserInfoData.UserData.init(data: dic))
                }
            }
            guard data.count > 0 else {
                DocsLogger.info("\(String(describing: model?.jsEngine.editorIdentity)) show userlist is empty")
                return
            }
            showUserListVC = self.navigator?.showUserList(data: data, title: params["title"] as? String)
        case DocsJSService.getCurrentUserInfo.rawValue:
            guard let callback = params["callback"] as? String else {
                return
            }
            var userInfo: [String: Any] = [:]
            userInfo["tanent_tag"] = User.current.info?.userType?.rawValue
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: userInfo, completion: nil)
        default:
            spaceAssertionFailure("event \(serviceName) not handled")
        }
    }

}
