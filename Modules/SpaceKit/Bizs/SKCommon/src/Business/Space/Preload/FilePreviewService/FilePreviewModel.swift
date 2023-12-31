//
//  FilePreviewModel.swift
//  SpaceKit
//
//  Created by bytedance on 2018/9/29.
//

import SKFoundation

public struct FilePreviewModel {
    public enum FileType: String {
        case doc        = "application/msword"
        case docx       = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case ppt        = "application/vnd.ms-powerpoint"
        case pptx       = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case xls        = "application/vnd.ms-excel"
        case xlsx       = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

        case numbers    = "application/x-iwork-numbers-sffnumbers"
        case keynote    = "application/x-iwork-keynote-sffkey"
        case pages      = "application/x-iwork-pages-sffpages"

        case pdf        = "application/pdf"

        case mp4        = "video/mp4"
        case mp3        = "audio/mp3"
        case mov        = "video/quicktime"

        case txt        = "text/plain"

        case zip        = "application/zip"

        case apk        = "application/vnd.android.package-archive"

        case png        = "image/png"
        case jpeg       = "image/jpeg"

        case unKnown    = "unKnown"
    }

    public enum MountType: Int {
        case jianguoyun = 0
        case tos = 1
        case unKnown = 999
    }

    public let id: String
    public let name: String
    public let driveKey: String
    public let type: FileType
    public let size: Int64

    public let previewFrom: String
    public let mountNodeToken: String
    public let mountPoint: String
    public let mountType: MountType

    public let cacheName: String // 拼接 id 和 name 作为本地唯一标识

    public var url: String?

    enum CodingKeys: String, CodingKey {
        case id = "file_id"
        case name = "file_name"
        case driveKey = "drive_file_key"
        case type = "file_mime_type"
        case size = "file_size"
        case previewFrom = "preview_from"
        case mountNodeToken = "mount_node_token"
        case mountPoint = "mount_point"
        case mountType = "type"
    }

    public mutating func setUrl(_ customUrl: String) {
        url = customUrl
    }

    // 判断类型是否已经支持了
    func isSupport2OpenNow() -> Bool {
        return type != .zip
            && type != .apk
            && type != .unKnown
    }

    func isVideoType() -> Bool {
        return type == .mp4
            || type == .mov
            || type == .mp3
    }

    func isImageType() -> Bool {
        return type == .png || type == .jpeg
    }
}

extension FilePreviewModel: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        driveKey = try values.decode(String.self, forKey: .driveKey)
        size = try values.decode(Int64.self, forKey: .size)

        if let t = FilePreviewModel.FileType(rawValue: try values.decode(String.self, forKey: .type)) {
            type = t
        } else {
            type = .unKnown
        }

        if let fromKey = try? values.decode(String.self, forKey: .previewFrom),
           let from = DrivePreviewFrom(rawValue: fromKey) {
            previewFrom = from.rawValue
        } else {
            previewFrom = DrivePreviewFrom.docsAttach.rawValue
        }

        var tmpCacheName = name
        if let range = name.range(of: ".") {
            tmpCacheName.insert(contentsOf: "[" + id + "]", at: range.lowerBound)
        } else {
            DocsLogger.info("找不到小数点，无法识别文件")
        }
        cacheName = tmpCacheName

        mountNodeToken = try values.decode(String.self, forKey: .mountNodeToken)

        if let mt = FilePreviewModel.MountType(rawValue: try values.decode(Int.self, forKey: .mountType)) {
            mountType = mt
        } else {
            mountType = .unKnown
        }

        mountPoint = try values.decode(String.self, forKey: .mountPoint)
    }
}
