//
//  SetLeftHandler.swift
//  LarkWeb
//
//  Created by yuanping on 2019/4/19.
//

import LKCommonsLogging
import LarkUIKit
import RxSwift
import RxCocoa
import WebBrowser
import OPFoundation

class SetLeftHandler: JsAPIHandler {
    static let logger = Logger.log(SetLeftHandler.self, category: "Module.JSSDK")

    private var disposeBag = DisposeBag()

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let text = args["text"] as? String
        let control = args["control"] as? Bool
        let isShowIcon = args["isShowIcon"] as? Bool

        // 隐藏左侧导航栏
        if (text ?? "").isEmpty, let showIcon = isShowIcon, !showIcon {
            let leftBarItem = LKBarButtonItem(image: nil, title: nil)
            api.setLeftBarButtonItems([leftBarItem], animated: false)
            return
        }
        let back_icon = UIImage.bdp_imageNamed("back_icon") ?? UIImage()
        if text != nil {
            let image = (isShowIcon ?? true) ? back_icon : nil
            let leftBarItem = LKBarButtonItem(image: image, title: text?.trimmingCharacters(in: .whitespaces))
            if control ?? false {
                leftBarItem.button.rx.tap.subscribe(onNext: {
                    callback.callbackSuccess(param: [String: Any]())
                }).disposed(by: disposeBag)
            } else {
                leftBarItem.button.rx.tap.subscribe(onNext: { [weak api] in
                    api?.closeVC()
                }).disposed(by: disposeBag)
            }
            api.setLeftBarButtonItems([leftBarItem], animated: false)
            return
        }
        // 自定义点击事件
        let leftBarItem = LKBarButtonItem(image: back_icon, title: text?.trimmingCharacters(in: .whitespaces))
        if control ?? false {
            leftBarItem.button.rx.tap.subscribe(onNext: {
                callback.callbackSuccess(param: [String: Any]())

            }).disposed(by: disposeBag)
        } else {
            leftBarItem.button.rx.tap.subscribe(onNext: { [weak api] in
                api?.closeVC()
            }).disposed(by: disposeBag)
        }
        api.setLeftBarButtonItems([leftBarItem], animated: false)
    }
}
