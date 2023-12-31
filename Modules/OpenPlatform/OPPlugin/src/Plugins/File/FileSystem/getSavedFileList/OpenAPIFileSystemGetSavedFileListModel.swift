//
//  OpenAPIFileSystemGetSavedFileListModel.swift
//  OPPlugin
//
//  Created by Meng on 2021/7/21.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIFileSystemGetSavedFileListResult: OpenAPIBaseResult {
    struct FileItem {
        let filePath: String
        let size: UInt64?
        let createTime: TimeInterval?

        init(filePath: String, size: UInt64?, createTime: TimeInterval?) {
            self.filePath = filePath
            self.size = size
            self.createTime = createTime
        }
    }

    let fileList: [FileItem]

    init(fileList: [FileItem]) {
        self.fileList = fileList
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        let fileListValue = self.fileList.map({ fileItem -> [AnyHashable: Any] in
            var result: [AnyHashable: Any] = [:]
            result["filePath"] = fileItem.filePath
            if let size = fileItem.size {
                result["size"] = size
            }
            if let createTime = fileItem.createTime {
                result["createTime"] = createTime
            }
            return result
        })
        return ["fileList": fileListValue]
    }
}
