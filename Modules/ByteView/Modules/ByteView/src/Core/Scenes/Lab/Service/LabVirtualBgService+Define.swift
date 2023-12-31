//
//  LabVirtualBgService+Define.swift
//  ByteView
//
//  Created by wangpeiran on 2021/11/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon

internal let virtualBackgroundCatalogue: String = "virtualBackground/"   // lark存储虚拟背景部分路径

struct CalendarMeetingVirtual {
    var meetingId: String?
    var uniqueId: String?
    var isWebinar: Bool?

    var hasExtraBg: Bool = false
    var bgModel: VirtualBgModel? //日程会议统一设置虚拟背景
    var hasShowedExtraBgToast: Bool = false
    var hasShowedExtraBgTipInLabVC: Bool = false

    init( meetingId: String?, uniqueId: String?, isWebinar: Bool?) {
        self.meetingId = meetingId
        self.uniqueId = uniqueId
        self.isWebinar = isWebinar
    }
}

// 会议虚拟背景类型
enum MeetingVirtualBgType {
    case normal       // 普通
    case people       // 面试
    case calendar(res: (Result<GetExtraMeetingVirtualBackgroundResponse, Error>)?) // 日程统一虚拟背景

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }
    static func != (lhs: Self, rhs: Self) -> Bool {
        return lhs.value != rhs.value
    }

    var value: String? {
        return String(describing: self).components(separatedBy: "(").first
    }

    var isCalendar: Bool {
        switch self {
        case .calendar:
            return true
        default:
            return false
        }
    }
}

// 虚拟背景设置类型
enum VirtualBgType {
    case setNone       // 不设置背景
    case blur       // 背景虚化
    case virtual    // 虚拟背景
    case add        // 增加虚拟背景
}

// 特效加载状态
enum EffectLoadingStatus {
    case unStart
    case loading
    case failed
    case done
}

// 额外特效加载状态
enum ExtraBgDownLoadStatus {
    case unStart
    case checking
    case download
    case failed
    case done
}

enum VirtualBgStatus {
    case normal // 图片可正常使用
    case uploading // 上传中
    case uploadError // 上传接口报错
    case sizeLimit // 上传失败（图片大小超过限制）
    case countLimit // 上传失败（图片数量超过限制）
    case reviewing // 审核中
    case reviewError // 审核接口报错
    case reviewTimeout // 审核超时，目前5s
    case reviewFailed // 审核不通过

    var isError: Bool {
        switch self {
        case .uploadError, .sizeLimit, .countLimit, .reviewError, .reviewTimeout, .reviewFailed:
            return true
        default:
            return false
        }
    }

    var isLoading: Bool {
        switch self {
        case .uploading, .reviewing:
            return true
        default:
            return false
        }
    }
}

struct AllowVirtualBgRelayInfo: Equatable {
    var allow: Bool
    var hasUsedBgInAllow: Bool?
}

extension VirtualBackgroundInfo {

    func convertToBgModel(storage: UserStorage) -> VirtualBgModel {
        let fileName = (path as NSString).lastPathComponent  // xxx.jpg
        let fileNameWithoutExtension = (fileName as NSString).deletingPathExtension  // xxx

        // Space-User_123/Domain-ByteView/virtualBackground/xxx_thumbnail.png
        let rtcPath = storage.getIsoPath(root: .document, relativePath: virtualBackgroundCatalogue + fileNameWithoutExtension + ".png")
        let localThumbnailPath = storage.getIsoPath(root: .document, relativePath: virtualBackgroundCatalogue + fileNameWithoutExtension + "_thumbnail.png")
        let localPortraitPath = storage.getIsoPath(root: .document, relativePath: virtualBackgroundCatalogue + fileNameWithoutExtension + "_portrait.png")
        let localLandscapePath = storage.getIsoPath(root: .document, relativePath: virtualBackgroundCatalogue + fileNameWithoutExtension + "_landscape.png")

        return VirtualBgModel(name: name,
                              key: key,
                              bgType: .virtual,
                              isFromSettings: !path.isEmpty && !portraitPath.isEmpty,
                              thumbnailIsoPath: localThumbnailPath,
                              landscapeIsoPath: localLandscapePath,
                              portraitIsoPath: localPortraitPath,
                              originPath: path,
                              originPortraitPath: portraitPath,
                              rtcPath: rtcPath.absoluteString,
                              status: fileStatus.virtualBgStatus,
                              imageSource: source)
    }
}

extension FileStatus {
    var virtualBgStatus: VirtualBgStatus {
        switch self {
        case .unSyncServer:
            return .uploadError
        case .reviewing:
            return .reviewing
        case .fileSizeLimit:
            return .sizeLimit
        case .fileCountLimit:
            return .countLimit
        case .serverErr:
            return .reviewError
        case .timeOut:
            return .reviewTimeout
        case .failed:
            return .reviewFailed
        default:
            return .normal
        }
    }
}

class VirtualBgModel {
    let name: String
    let key: String
    let bgType: VirtualBgType
    let isVideo: Bool
    let isFromSettings: Bool
    let thumbnailIsoPath: IsoFilePath
    let landscapeIsoPath: IsoFilePath
    let portraitIsoPath: IsoFilePath
    let originPath: String
    let originPortraitPath: String
    let rtcPath: String
    var isSelected: Bool
    var isShowDelete: Bool
    var status: VirtualBgStatus
    var imageSource: VirtualBgMaterialSource?

    init(name: String,
         key: String = "",
         bgType: VirtualBgType,
         isVideo: Bool = false,
         isFromSettings: Bool = false,
         thumbnailIsoPath: IsoFilePath,
         landscapeIsoPath: IsoFilePath,
         portraitIsoPath: IsoFilePath,
         originPath: String = "",
         originPortraitPath: String = "",
         rtcPath: String = "",
         isSelected: Bool = false,
         isShowDelete: Bool = false,
         status: VirtualBgStatus = .normal,
         imageSource: VirtualBgMaterialSource? = .unknown) {
        self.name = name
        self.key = key
        self.bgType = bgType
        self.isVideo = isVideo
        self.isFromSettings = isFromSettings
        self.thumbnailIsoPath = thumbnailIsoPath
        self.landscapeIsoPath = landscapeIsoPath
        self.portraitIsoPath = portraitIsoPath
        self.originPath = originPath
        self.originPortraitPath = originPortraitPath
        self.rtcPath = rtcPath
        self.isSelected = isSelected
        self.isShowDelete = isShowDelete
        self.status = status
        self.imageSource = imageSource
    }

    var thumbnailPath: String {
        thumbnailIsoPath.absoluteString
    }

    var landscapePath: String {
        landscapeIsoPath.absoluteString
    }

    var portraitPath: String {
        portraitIsoPath.absoluteString
    }

    func isClientUpload() -> Bool {
        switch self.imageSource {
        case .appWin, .appMac, .appAndroid, .appIos, .appIpad:
            return true
        default:
            return false
        }
    }

    func isSettingModel() -> Bool {
        if bgType == .add || bgType == .setNone {
            return true
        }
        return false
    }

    func isDeleteEnable() -> Bool {
        if !(isSettingModel() || bgType == .blur) && status == .normal && imageSource != .appPeople && imageSource != .appCalendar {
            return true
        }
        return false
    }

    func hasCropThumbnail() -> Bool {
        if FileManager.default.fileExists(atPath: thumbnailPath) {
            return true
        }
        return false
    }

    func hasCropLandscape() -> Bool {
        if FileManager.default.fileExists(atPath: landscapePath) {
            return true
        }
        Logger.lab.info("landscapePath false: \(landscapePath)")
        return false
    }

    func hasCropPortrait() -> Bool {
        if FileManager.default.fileExists(atPath: portraitPath) {
            return true
        }
        Logger.lab.info("portraitPath false: \(portraitPath)")
        return false
    }
}
