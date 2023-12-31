//
//  SetCloaseHandler.swift
//  Action
//
//  Created by Yiming Qu on 2019/5/20.
//

import LarkUIKit
import RxSwift
import RxCocoa
import WebBrowser
import LKCommonsLogging
import JsSDK
import LarkAccountInterface
import LarkContainer

class SetCloseHandler: JsAPIHandler {

    static let logger = Logger.log(SetCloseHandler.self, category: "Module.JSSDK")

    @Provider var dependency: PassportWebViewDependency

    private var disposeBag = DisposeBag()

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        dependency.monitorSensitiveJsApi(apiName: "biz.account.setClose", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        SetCloseHandler.logger.info("SetCloseHandler args: \(args)")
        let onSuccess = args["onSuccess"] as? String
        let funcArgs = args["args"] as? [Any]

        // 自定义点击事件
        if let success = onSuccess, !success.isEmpty {
            if let closeItem = api.getLeftCloseItem() {
                let tap = self.removeAction(closeItem)
                tap.subscribe(onNext: {
                    callback.callDeprecatedFunction(name: success, param: [1] + (funcArgs ?? []), isWrappedParam: true)
                }).disposed(by: disposeBag)
            }

            if let backItem = api.getLeftBackItem() {
                let tap = self.removeAction(backItem)
                tap.subscribe(onNext: {
                    callback.callDeprecatedFunction(name: success, param: [0] + (funcArgs ?? []), isWrappedParam: true)
                }).disposed(by: disposeBag)
            }
        }
    }

    func removeAction(_ item: UIBarButtonItem) -> ControlEvent<()> {
        item.target = nil
        item.action = nil
        var tap = item.rx.tap
        if let lkItem = item as? LKBarButtonItem {
            lkItem.button.removeTarget(nil, action: nil, for: .allEvents)
            tap = lkItem.button.rx.tap
        }
        return tap
    }
}
