//
//  File.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/18.
//

import Foundation
import Photos
import LarkMessengerInterface

extension AttachedFile {
    var videoDuration: TimeInterval? { return nil }
}

extension Array where Element == AttachedFile {
    func classify() -> [AttachedFileType: [AttachedFile]] {
        var dic: [AttachedFileType: [AttachedFile]] = [:]
        forEach { (attachedFile) in
            if dic.keys.contains(attachedFile.type) {
                dic[attachedFile.type]?.append(attachedFile)
            } else {
                dic[attachedFile.type] = [attachedFile]
            }
        }
        return dic
    }

    var aggregateAttachedFiles: [LocalAggregateFiles] {
        var aggregateAttachedFiles: [LocalAggregateFiles] = []
        classify().forEach { (type, attachFiles) in
            guard !attachFiles.isEmpty else { return }
            let aggregateFile = LocalAggregateFiles(type: type, files: attachFiles)
            aggregateAttachedFiles.append(aggregateFile)
        }
        return aggregateAttachedFiles
    }

    @discardableResult
    mutating func removeAttachedFile(_ attachedFile: AttachedFile) -> Bool {
        var result: [AttachedFile] = []
        forEach { (file) in
            if file.id != attachedFile.id {
                result.append(file)
            }
        }
        let isChanged = (self.count != result.count)
        self = result
        return isChanged
    }
}
