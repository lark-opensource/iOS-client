//
//  SNSShareHelper.swift
//  LarkMicroApp
//
//  Created by yi on 2021/4/7.
//

import Foundation

// code from LarkOpenPlatform SNSShareHelper.swift, but divide a file into two
public protocol SNSShareHelper {
    // 分享处理方法
    func snsShare(_ controller: UIViewController, appID: String, channel: String, contentType: String, traceId: String, title: String, url: String, desc: String, imageData: Data, successHandler: (() -> Void)?, failedHandler: ((Error?) -> Void)?)
}
