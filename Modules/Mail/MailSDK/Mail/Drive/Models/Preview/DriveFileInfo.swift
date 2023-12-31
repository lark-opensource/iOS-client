//
//  DriveFileInfo.swift
//  DocsSDK
//
//  Created by Wenjian Wu on 2019/3/14.
//

import Foundation

// 后端转码后的文件类型: https://bytedance.feishu.cn/space/doc/tSrvZGGj5N8WUT08s0vLlg#j83gMl

// swiftlint:disable identifier_name
enum DrivePreviewFileType: Int {
    case pdf = 0
    case png = 1
    case pages = 2
    case mp4 = 3
    case jpg = 7
    case linerizedPDF = 9
}

/// 文件信息
struct DriveFileInfo: DriveFileCacheable {

    let size: UInt64                    /** 大小 */
    var name: String                    /** 名字 */
    let type: String                    /** 类型 */
    let numBlocks: Int?                  /** 分片数量 */

    let fileToken: String               /** 文件token */
    let mountNodeToken: String          /** 父节点token */
    let mountPoint: String

    // 后端转码
    var downloadPreviewURL: String?            /** 预览下载链接 */
    private(set) var previewFileType: DrivePreviewFileType?  /** 预览文件类型 */
    private let availableTypes: [Int]?  /** 后端对于当前文件支持的转码类型 */
    var canTransformPDF: Bool {
        if fileType == .pdf {
            return true
        }
        return availableTypes?.contains(DrivePreviewFileType.pdf.rawValue) ?? false
    }

    var version: String?
    var dataVersion: String?

    init?(data: [String: Any],
          fileToken: String,
          mountNodeToken: String,
          mountPoint: String) {
        guard let name = data["name"] as? String,
            let size = data["size"] as? UInt64,
            let type = data["type"] as? String else {
                return nil
        }

        let numBlocks = data["num_blocks"] as? Int
        let version = data["version"] as? String
        let dataVersion = data["data_version"] as? String

        self.availableTypes = data["available_preview_type"] as? [Int]
        self.size = size
        self.type = type
        self.name = name
        self.numBlocks = numBlocks
        self.version = version
        self.dataVersion = dataVersion
        self.fileToken = fileToken
        self.mountNodeToken = mountNodeToken
        self.mountPoint = mountPoint

        if let types = availableTypes, !types.isEmpty {
            // 优先使用线性化PDF
            if true, // TODO: 确定下这里是很么判断？ DrivePDFKit
                types.contains(DrivePreviewFileType.linerizedPDF.rawValue) {
                self.previewFileType = .linerizedPDF
            } else {
                self.previewFileType = DrivePreviewFileType(rawValue: types[0])
            }
        }
    }
}
