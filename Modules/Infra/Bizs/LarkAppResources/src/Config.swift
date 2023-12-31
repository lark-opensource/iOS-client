//
//  Resources.swift
//  Module
//
//  Created by Kongkaikai on 2018/12/23.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name

let SelfBundle: Bundle = {
    if let url = Bundle.main.url(forResource: "Frameworks/LarkAppResources", withExtension: "framework") {
        return Bundle(url: url)!
    } else {
        return Bundle.main
    }
}()
let LarkAppResourcesBundle = Bundle(url: SelfBundle.url(forResource: "LarkAppResources", withExtension: "bundle")!)!
// swiftlint:enable identifier_name

final class Config {}
