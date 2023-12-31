//
//  LynxTemplateProvider.swift
//  LarkSearch
//
//  Created by bytedance on 2021/7/19.
//

import Foundation
import Lynx
import LarkContainer
import LarkRustClient
import RustPB
import LarkSDKInterface

public final class SearchLynxTemplateProvider: NSObject, LynxTemplateProvider {

    //  测试用，加载本地模板时不会走这里
    public func loadTemplate(withUrl url: String!, onComplete callback: LynxTemplateLoadBlock!) {
        let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
        let requestUrl = URL(string: urlString) ?? .init(fileURLWithPath: "")
        let request = URLRequest(url: requestUrl)
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if error != nil {
                    callback(data, error)
                } else if data != nil {
                    callback(data, nil)
                }
            }
        }
        task.resume()
    }

}
