//
//  SetMenuHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import LarkUIKit
import LKCommonsLogging
import WebBrowser

class SetMenuHandler: JsAPIHandler {
    static let logger = Logger.log(SetMenuHandler.self, category: "Module.JSSDK")
    fileprivate var disposeBag = DisposeBag()

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let items = args["items"] as? [[String: Any]] else {
            SetMenuHandler.logger.error("参数有误")
            return
        }

        var rightItems: [UIBarButtonItem] = []
        items.forEach { (item) in
            guard let id = item["id"] as? String else {
                SetMenuHandler.logger.error("item参数有误")
                return
            }
            let text = item["text"] as? String
            let base64 = item["imageBase64"] as? String
            if text == nil && base64 == nil {
                SetMenuHandler.logger.error("item参数有误")
                return
            }
            var image: UIImage?

            if base64 != nil, let imageData = Data(base64Encoded: base64!) {
                if let scale = item["imageScale"] as? CGFloat {
                    image = UIImage(data: imageData, scale: scale)
                } else {
                    image = UIImage(data: imageData)
                }
            }

            let item: LKBarButtonItem = LKBarButtonItem(image: image, title: text)

            item.button.rx.tap.subscribe(onNext: {
                callback.callbackSuccess(param: ["id": id])
            }).disposed(by: disposeBag)

            rightItems.append(item)
        }

        api.setRightBarButtonItems(rightItems.reversed(), animated: false)
    }
}
