//
//  FeedFeatureGatingImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/9/15.
//

import Foundation
import LarkFeatureGating
import LarkContainer

//func feedGetFgValue(key: UnsafePointer<Int8>?) -> Int32 {
//    guard let k = key else {
//        FeedContext.log.error("feedlog/feature/fg/toRust/error")
//        return Int32(0)
//    }
//    let str = String(cString: k)
//    let enable = userResolver.fg.staticFeatureGatingValue(with: str)
//    FeedContext.log.info("feedlog/feature/fg/toRust/success. \(str): \(enable)")
//    return enable ? Int32(1) : Int32(0)
//}

func feedGetFgValue(key: UnsafePointer<Int8>?) -> Int32 {
    guard let k = key else {
        let info = FeedBaseErrorInfo(type: .error(), errorMsg: "fg toRust error")
        FeedExceptionTracker.Setting.fg(node: .fgToRust, info: info)
        return Int32(0)
    }
    let str = String(cString: k)
    var value = false
    var userResolver: UserResolver { Container.shared.getCurrentUserResolver() }
    if str == "lark.feed.add_mute_group_ios" {
        value = Feed.Feature(userResolver).addMuteGroupEnable
    } else if str == "lark.core.feed.groupsettings" {
        value = Feed.Feature(userResolver).groupSettingEnable
    } else if str == "lark.feed.groupsettings.optimization" {
        value = Feed.Feature(userResolver).groupSettingOptEnable
    }
    FeedContext.log.info("feedlog/feature/fg/toRust/success. \(str): \(value)")
    return value ? Int32(1) : Int32(0)
}

final class FeedFeatureGatingImpl {

    @discardableResult
    init() {
        getFgValueOfSwiftImpl = feedGetFgValue(key:)
    }
}
