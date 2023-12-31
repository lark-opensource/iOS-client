//
//  DocsImageDownloader.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/11/14.
// swiftlint:disable function_parameter_count

import Foundation
public final class DocsImageDownloader {
    public enum FromSource: String {
        case unknown = ""
        case spaceList = "space_list"  // docs tab中的所有列表页
        case spaceListIcon = "space_list_icon"
        case chat // 会话
        case template // 新建文件--自定义模板的图片
        case announcement // lark会话中的群公告
        case vcfollow // 视频会议
    }
}
