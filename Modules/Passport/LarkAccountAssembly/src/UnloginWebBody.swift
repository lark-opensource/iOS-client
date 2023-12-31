//
//  UnloginWebBody.swift
//  LarkAccountAssembly
//
//  Created by 张威 on 2022/2/23.
//

#if GadgetMod

import Foundation
import EENavigator
import WebBrowser
import LarkWebViewContainer

public struct UnloginWebBody: PlainBody {
    public static let pattern: String = "//client/web/unlogin"

    public let url: URL
    /// 使用的 JsAPI Method 范围
    public let jsApiMethodScope: JsAPIMethodScope
    public let showMore: Bool
    public let showLoadingFirstLoad: Bool = false
    public let customUserAgent: String?
    public let webBizType: LarkWebViewBizType?

    public init(
        url: URL,
        jsApiMethodScope: JsAPIMethodScope = .all,
        showMore: Bool = true,
        showLoadingFirstLoad: Bool = true,
        customUserAgent: String? = nil,
        webBizType: LarkWebViewBizType? = nil
    ) {
        self.url = url
        self.showMore = showMore
        self.jsApiMethodScope = jsApiMethodScope
        self.customUserAgent = customUserAgent
        self.webBizType = webBizType
    }
}

#endif
