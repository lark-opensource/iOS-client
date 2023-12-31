//
//  UGBrowserBody.swift
//  LarkContact
//
//  Created by aslan on 2021/12/22.
//

import Foundation
import EENavigator

public typealias UGOverseaLoadFailFallback = (String) -> Void

public struct UGOverseaBrowserBody: PlainBody {
    public static let pattern = "//client/contact/UGOverseaBrowser"
    public var url: URL
    /// 针对注册流程的，没有就不传
    public var stepInfo: [String: Any]?
    public var fallback: UGOverseaLoadFailFallback?

    public init(url: URL, stepInfo: [String: Any]?, fallback: UGOverseaLoadFailFallback?) {
        self.url = url
        self.stepInfo = stepInfo
        self.fallback = fallback
    }
}
