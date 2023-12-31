//
//  AppDelegate.swift
//  LarkFoundation
//
//  Created by Yuguo on 2017/12/13.
//  Copyright © 2017年 com.bytedance.lark. All rights reserved.
//

import Foundation
import UIKit
import LarkFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                             didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Utils.addSkipBackupAttributeToAllUserFile()

//        var url = URL(string: "http://baidu.com")!
//        var newUrl = url.lf.appendPercentEncodedQuery(["from": "http://toutiao.com"])
//        assert(newUrl.absoluteString == "http://baidu.com?from=http%3A%2F%2Ftoutiao.com")
//
//        url = URL(string: "http://baidu.com?test=a")!
//        newUrl = url.lf.appendPercentEncodedQuery(["from": "http://toutiao.com"])
//        assert(newUrl.absoluteString == "http://baidu.com?test=a&from=http%3A%2F%2Ftoutiao.com")
//
//        url = URL(string: "http://baidu.com?from=aaa")!
//        newUrl = url.lf.appendPercentEncodedQuery(["from": "http://toutiao.com"])
//        assert(newUrl.absoluteString == "http://baidu.com?from=http%3A%2F%2Ftoutiao.com")
//
//        url = URL(string: "http://baidu.com?from=http%3A%2F%2Ftoutiao.com")!
//        newUrl = url.lf.appendPercentEncodedQuery(["abc": "aaa"])
//        assert(newUrl.absoluteString == "http://baidu.com?from=http%3A%2F%2Ftoutiao.com&abc=aaa")

        return true
    }
}
