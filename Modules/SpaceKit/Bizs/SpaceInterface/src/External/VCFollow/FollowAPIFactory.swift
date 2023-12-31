//
//  FollowAPIFactory.swift
//  SpaceInterface
//
//  Created by lijuyou on 2020/4/2.
//  


import Foundation
import RxSwift

/// 创建FollowAPI的Factory，通过依赖注入获得
public protocol FollowAPIFactory {


    /// 开始会议
    func startMeeting()

    /// 结束会议
    func stopMeeting()

    /// 打开Lark文档
    /// - Parameters:
    ///   - urlString: url
    ///   - events: 注册的事件
    /// - returns: 返回实现FollowAPI的实例
    ///     以下情况会返回失败 1.非法URL
    func open(url urlString: String, events: [FollowEvent]) -> FollowAPI?

    /// 打开GoogleDrive的文档
       /// - Parameters:
       ///   - urlString: url
    ///
       /// - returns: 返回实现FollowAPI的实例
       ///     有两种情况会返回失败 1.非法URL  2.调用此方法频率过高(500ms)


    /// 打开GoogleDrive的文档
    /// - Parameters:
    ///   - urlString: url
    ///   - events: 注册的事件
    ///   - injectScript: 注入的JS
    /// - returns: 返回实现FollowAPI的实例
    ///     以下情况会返回失败 1.非法URL
    func openGoogleDrive(url urlString: String, events: [FollowEvent], injectScript: String?) -> FollowAPI?


    /// 判断是否属于Docs的链接
    static func isDocsURL(_ urlString: String) -> Bool

    /// 下载Space文档缩略图
    /// - Parameters:
    ///   - url: 图片 url
    ///   - thumbnailInfo: ["nonce":"随机数", "secret":"秘钥","type" :"解密方式"]
    ///   - imageSize: 目标图片大小, nil 表示不调整，直接返回原图
    static func getThumbnail(url: String,
                             thumbnailInfo: [String: Any],
                             imageSize: CGSize?) -> Observable<UIImage>
}
