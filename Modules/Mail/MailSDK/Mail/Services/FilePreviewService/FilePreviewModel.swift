//
//  FilePreviewModel.swift
//  MailSDK
//
//  Created by bytedance on 2018/9/29.
//

import Foundation

struct FilePreviewModel {
    enum MountType: Int {
        case jianguoyun = 0
        case tos = 1
        case unKnown = 999
    }

    enum FileType: String {
        case doc
        case docx
        case ppt
        case pptx
        case xls
        case xlsx

        case numbers
        case keynote
        case pages

        case pdf

        case mp4
        case mp3
        case mov

        case txt

        case zip

        case apk

        case png
        case jpeg

        case unKnown
    }

    let id: String
    let name: String
    let driveKey: String
    let type: FileType
    let size: Int64

    let mountNodeToken: String
    let mountPoint: String
    let mountType: MountType

    let cacheName: String // 拼接 id 和 name 作为本地唯一标识
    var url: String?

    enum CodingKeys: String, CodingKey {
        case mountNodeToken = "mount_node_token"
        case mountPoint = "mount_point"
        case mountType = "type"

        case id = "file_id"
        case name = "file_name"
        case driveKey = "drive_file_key"
        case type = "file_mime_type"
        case size = "file_size"
    }

    // 判断类型是否已经支持了
    func isSupport2OpenNow() -> Bool {
        return type != .zip
            && type != .apk
            && type != .unKnown
    }

    func isImageType() -> Bool {
        return type == .png || type == .jpeg
    }

    func isVideoType() -> Bool {
        return type == .mp4
            || type == .mov
            || type == .mp3
    }
}

extension FilePreviewModel: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        size = try values.decode(Int64.self, forKey: .size)
        driveKey = try values.decode(String.self, forKey: .driveKey)

        if let fType = FilePreviewModel.FileType(rawValue: try values.decode(String.self, forKey: .type)) {
            type = fType
        } else {
            type = .unKnown
        }

        var tempCacheName = name
        if let range = name.range(of: ".") {
            tempCacheName.insert(contentsOf: "[" + id + "]", at: range.lowerBound)
        } else {
            MailLogger.info("找不到小数点，无法识别文件")
        }

        cacheName = tempCacheName
        mountNodeToken = try values.decode(String.self, forKey: .mountNodeToken)

        if let mType = FilePreviewModel.MountType(rawValue: try values.decode(Int.self, forKey: .mountType)) {
            mountType = mType
        } else {
            mountType = .unKnown
        }

        mountPoint = try values.decode(String.self, forKey: .mountPoint)
    }
}
