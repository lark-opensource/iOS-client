//
//  VirtualBackgroundInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_GetVcVirtualBackgroundResponse.VirtualBackgroundInfo
public struct VirtualBackgroundInfo {
    public init(key: String, name: String, url: String, path: String, isVideo: Bool, isCustom: Bool, isMiss: Bool,
                thumbnail: String, portraitPath: String, fileStatus: FileStatus, source: MaterialSource) {
        self.key = key
        self.name = name
        self.url = url
        self.path = path
        self.isVideo = isVideo
        self.isCustom = isCustom
        self.isMiss = isMiss
        self.thumbnail = thumbnail
        self.portraitPath = portraitPath
        self.fileStatus = fileStatus
        self.source = source
    }

    public var key: String

    public var name: String

    public var url: String

    public var path: String

    /// 是否为视频
    public var isVideo: Bool

    /// 是否为自定义背景
    public var isCustom: Bool

    /// 无法找到该图片/视频路径
    public var isMiss: Bool

    /// 如果是视频则返回帧路径
    public var thumbnail: String

    public var portraitPath: String

    /// 审核进度和结果
    public var fileStatus: FileStatus

    public var source: MaterialSource

    /// Videoconference_V1_FileStatus
    public enum FileStatus: Int, Hashable {

        /// 未同步到服务端
        case unSyncServer // = 0

        /// 图片大小超限制
        case fileSizeLimit // = 1

        /// 图片数量达到上限
        case fileCountLimit // = 2

        /// 审核中
        case reviewing // = 3

        /// 审核接口调用失败
        case serverErr // = 4

        /// 审核接口调用超时(图片上传完成后5s没收到推送返回超时)
        case timeOut // = 5

        /// 审核失败
        case failed // = 6

        /// 审核成功
        case ok // = 7
    }

    /// 虚拟背景来源
    /// - Videoconference_V1_MaterialSource
    public enum MaterialSource: Int, Hashable {
        case unknown // = 0

        /// 用于拉取全部数据
        case allSource // = 1

        /// 飞书app Windows上传
        case appWin // = 2

        /// 飞书app MacOS上传
        case appMac // = 3

        /// 飞书app Android上传
        case appAndroid // = 4

        /// 飞书app IOS上传
        case appIos // = 5

        /// 飞书app IPAD上传
        case appIpad // = 6

        /// 飞书app settings设置图片
        case appSettings // = 7

        /// 飞书app admin平台设置图片
        case appAdmin // = 8

        ///  People面试设置图片
        case appPeople // = 9

        /// 日程会议统一设置
        case appCalendar // = 10

        /// 用户通过ISV从本地添加上传
        case isvUpload = 21

        /// 从飞书同步到ISV的图，通过ISV编辑后上传
        case isvUploadFromVc // = 22

        /// 预置在ISV的图，通过ISV编辑后上传
        case isvUploadFromPreset // = 23
    }
}

extension VirtualBackgroundInfo {
    public init() {
        self.init(key: "", name: "", url: "", path: "", isVideo: false, isCustom: false, isMiss: false, thumbnail: "", portraitPath: "",
                  fileStatus: .unSyncServer, source: .unknown)
    }
}

extension VirtualBackgroundInfo: CustomStringConvertible {

    public var description: String {
        return String(indent: "VirtualBackgroundInfo",
                      "path: \(path)",
                      "name: \(name)",
                      "isVideo: \(isVideo)",
                      "fileStatus: \(fileStatus)",
                      "source: \(source)",
                      "isCustom: \(isCustom)"
        )
    }
}
