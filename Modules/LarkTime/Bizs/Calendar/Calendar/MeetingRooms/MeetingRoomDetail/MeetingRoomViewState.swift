//
//  MeetingRoomDetailViewState.swift
//  Calendar
//
//  Created by Lianghongbin on 2021/2/3.
//

import Foundation

enum MeetingRoomDetailViewState: Int {
    /// idle
    case idle
    /// 加载中
    case loading
    /// 加载完成
    case data
    /// 加载失败
    case failed
}
