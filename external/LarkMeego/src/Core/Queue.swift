//
//  Queue.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/4/3.
//

import Foundation

/// meego 路由执行队列
let routerQueue = DispatchQueue(label: "lark.meego.router.queue", qos: .userInteractive)

/// meego 用户行为分析执行队列
let userTrackQueue = DispatchQueue(label: "lark.meego.user.track.queue", qos: .background)
