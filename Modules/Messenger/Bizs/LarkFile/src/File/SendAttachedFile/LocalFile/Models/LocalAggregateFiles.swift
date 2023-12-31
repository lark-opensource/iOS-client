//
//  LocalAggregateFiles.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/20.
//

import Foundation
import LarkMessengerInterface

struct LocalAggregateFiles: AggregateAttachedFiles {
    private(set) var files: [AttachedFile]
    let type: AttachedFileType

    init(type: AttachedFileType, files: [AttachedFile]) {
        self.type = type
        self.files = files
    }

    var filesCount: Int {
        return files.count
    }

    func fileAtIndex(_ index: Int) -> AttachedFile {
        return files[index]
    }

    @discardableResult
    mutating func removeFile(_ removeFile: AttachedFile) -> Bool {
        return files.removeAttachedFile(removeFile)
    }
}
