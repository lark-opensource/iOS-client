//
//  CardTemplateProvider.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/7.
//

import Foundation
import Lynx

private let TemplateProviderErrorDomain = "CardTemplateProvider"
private let TemplateProviderErrorcode = -1

/// 加载远程的卡片url会使用这个对象 A helper class for load template
@objcMembers
class CardTemplateProvider: NSObject, LynxTemplateProvider {

    /// 加载 url远程卡片使用该方法进行卡片的下载
    /// - Parameters:
    ///   - url: 远程卡片地址
    ///   - callback: 结果回调（需要在主线程回调，Lynx潜规则）
    func loadTemplate(withUrl url: String!, onComplete callback: LynxTemplateLoadBlock!) {
        guard let callback = callback else {
            //  如果没有回调，下载卡片数据也没用
            let msg = "loadTemplate has no callback, please contact Lynx team"
            assertionFailure(msg)
            BDPLogError(tag: .cardRequestTemplate, msg)
            return
        }
        guard let url = url,
            !url.isEmpty else {
                //  url为空也不需要进行下载了
                let msg = "url for card template.js is empty, please check it"
                assertionFailure(msg)
                BDPLogError(tag: .cardRequestTemplate, msg)
                callback(nil, cardTemplateError(with: msg))
                return
        }
        guard let urlObject = URL(string: url) else {
            //  url字符串不合法，无法转换成url对象
            let msg = "url for card template.js is invaild, cannot init urlobj, \(url)"
            assertionFailure(msg)
            BDPLogError(tag: .cardRequestTemplate, msg)
            callback(nil, cardTemplateError(with: msg))
            return
        }
        //  下载卡片
        let session = BDPNetworking.sharedSession()
        let task = session.dataTask(with: urlObject) { (data, _, error) in
            if let error = error {
                //  网络请求失败
                DispatchQueue.main.async {
                    callback(nil, error)
                    BDPLogError(tag: .cardRequestTemplate, error.localizedDescription)
                }
                return
            }
            guard let data = data else {
                //  没有回包数据
                DispatchQueue.main.async {
                    let msg = "response for card template.js is nil"
                    callback(nil, cardTemplateError(with: msg))
                    BDPLogError(tag: .cardRequestTemplate, msg)
                }
                return
            }
            //  成功回调
            DispatchQueue.main.async {
                callback(data, nil)
            }
        }
        task.resume()
    }
}

/// 组装远程URL下载卡片的错误对象
/// - Parameter msg: 错误信息
private func cardTemplateError(with msg: String) -> Error {
    NSError(
        domain: TemplateProviderErrorDomain,
        code: TemplateProviderErrorcode,
        userInfo: [
            NSLocalizedDescriptionKey: msg
        ]
    )
}
