//
//  UGBrowserBody.swift
//  LarkContact
//
//  Created by aslan on 2021/12/22.
//

import Foundation
import EENavigator

public typealias LoadFailFallback = () -> Void

public struct UGBrowserBody: PlainBody {
    public static let pattern = "//client/contact/UGBrowser"
    public var url: URL
    /// 针对注册流程的，没有就不传
    public var stepInfo: [String: Any]?
    public var fallback: LoadFailFallback?

    public init(url: URL, stepInfo: [String: Any]?, fallback: LoadFailFallback?) {
        self.url = url
        self.stepInfo = stepInfo
        self.fallback = fallback
    }
}
