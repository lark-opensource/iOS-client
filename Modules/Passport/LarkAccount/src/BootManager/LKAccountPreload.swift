//
//  LKAccountPreLoad.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2022/12/6.
//

import Foundation


@objc
public final class LKAccountPreload: NSObject {
    @objc
    public static func preload() {
        _ = RangersAppLogDeviceServiceImpl.shared
    }
}
