//
//  DocsInterface+ImageHandoff.swift
//  SpaceInterface
//
//  Created by chenjiahao.gill on 2019/8/5.
//  

import EENavigator
import SwiftyJSON

/// Lark NoticePush 拿到推送，统一到这里处理后，重定向到其他路由
public final class SKNoticePushRouterBody: CodablePlainBody {
    public static let pattern = "//client/docs/noticePush"

    public let data: String
    public let fromNotice: Int?

    public init(data: String,
                fromNotice: Int?) {
        self.data = data
        self.fromNotice = fromNotice
    }
}
