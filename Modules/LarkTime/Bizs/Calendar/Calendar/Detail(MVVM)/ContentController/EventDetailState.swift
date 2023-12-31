//
//  EventDetailObservableContext.swift
//  Calendar
//
//  Created by Rico on 2021/3/19.
//

import UIKit
import Foundation
import LarkCombine

/*
 这里存放详情页页面需要全局知晓的页面状态数据
 如无必要，不要随意增加字段，加字段请务必写注释
 */
final class EventDetailState: OpenCombine.ObservableObject {

    // 头部视图高度，因需要动态计算，所以确定高度之后，外部ScrollView约束要随之更新
    @OpenCombine.Published
    var headerHeight: CGFloat

    // 头部透明度
    @OpenCombine.Published
    var headerViewOpaque: CGFloat

    // 头部标题透明度
    @OpenCombine.Published
    var navigationTitleAlpha: CGFloat

    // getEvent 接口 中的 event.webinarInfo 并不可靠，这里用于缓存 getServerEvent 中的 webinarInfo
    var webinarContext: EventDetailWebinarContext?

    // 会议是否在进行中
    var isVideoMeetingLiving: Bool

    init() {
        headerHeight = 0
        headerViewOpaque = 0
        navigationTitleAlpha = 1
        isVideoMeetingLiving = false
    }

}
