//
//  GetUserInfoHandler.swift
//  LarkWeb
//
//  Created by 李论 on 2019/9/11.
//

import LKCommonsLogging
import RxSwift
import LarkSDKInterface
import WebBrowser

class GetUserInfoHandler: JsAPIHandler {
    static let logger = Logger.log(GetUserInfoHandler.self, category: "Module.JSSDK")

    private let userId: String?
    private let chatter: ChatterAPI?
    private let disposeBag = DisposeBag()

    var needAuthrized: Bool {
        return true
    }
    init(userID: String?, userAPI: ChatterAPI?) {
        self.userId = userID
        self.chatter = userAPI
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        guard let user = userId, let chatAPi = chatter else {
            GetUserInfoHandler.logger.log(level: .error, "userId is nil or chatter is nil")
            callback.callbackFailure(param: NewJsSDKErrorAPI.requestError.description())
            return
        }
        let rsp = chatAPi.fetchUserProfileInfomation(userId: user, contactToken: "")
        rsp
            .subscribe(
                onNext: { (p) in
                    let data = [
                        "code": 0,
                        "employeeId": p.employeeId,
                        "name": p.name,
                        "gender": p.gender,
                        "email": p.email
                        ] as [String: Any]
                    callback.callbackSuccess(param: data)
                },
                onError: { (err) in
                    GetUserInfoHandler.logger.error("request profile failed, \(err)")   //  原来的Log方法编译不通过
                    callback.callbackFailure(param: NewJsSDKErrorAPI.GetUserInfo.getUserInfoFail.description())
                }
            )
            .disposed(by: disposeBag)
    }
}
