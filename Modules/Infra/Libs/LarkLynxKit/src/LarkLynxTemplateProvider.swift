//
//  LarkLynxTemplateProvider.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/10/27.
//

import Foundation
import Lynx

public final class LarkLynxTemplateProvider: NSObject, LynxTemplateProvider {

    // MARK: - LynxTemplateProvider

    /// 这个方法只有在使用 `loadTemplateFromURL:data` 时才会调用，目前这个交给了 loader 去实现，但是 LynxView 在初始化时又必须要提供一个 provider，🤷‍♂️
    /// - Parameters:
    ///   - url: 要加载的 URL
    ///   - callback: 下载结束后的回调
    public func loadTemplate(withUrl url: String!, onComplete callback: LynxTemplateLoadBlock!) {
        guard let url = URL(string: url) else {
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async { callback(data, error) }
        }
        task.resume()
    }
}
