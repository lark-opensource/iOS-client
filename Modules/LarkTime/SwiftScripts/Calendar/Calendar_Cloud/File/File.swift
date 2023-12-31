//
//  File.swift
//  Calendar_Cloud
//
//  Created by Rico on 2021/4/20.
//

import Foundation
import PathKit

/// 相对于srcRootPath
let REL_LarkTimePath = "../.."

/// 相对于LarkTimePath
let REL_WorkspacePath = "SwiftScripts"

/// 相对于workspacePath
let REL_RecordFilePath = "compile.txt"
let REL_ExecutablePath = "Calendar_Cloud"

struct FileManager {

    let srcRootPath: String

    func write(_ content: String) {

        makeRecordFileIfNeeded()
        let handle = FileHandle(forWritingAtPath: recordFilePath.string)!
        handle.write(content.data(using: .utf8)!)
    }

    func read() -> String {

        makeRecordFileIfNeeded()
        let handle = FileHandle(forReadingAtPath: recordFilePath.string)!
        return String(data: handle.readDataToEndOfFile(), encoding: .utf8)!
    }

    private func makeRecordFileIfNeeded() {
        guard !recordFilePath.exists else {
            return
        }
        Foundation.FileManager.default.createFile(atPath: recordFilePath.string, contents: nil, attributes: nil)
    }
}

extension FileManager {

    var larkTimePath: Path {
        let path = Path(srcRootPath) + REL_LarkTimePath
        print("larkTimePath: \(path)")
        return path
    }

    var workspacePath: Path {
        let path = larkTimePath + REL_WorkspacePath
        print("workspacePath: \(path)")
        return path
    }

    var recordFilePath: Path {
        let path = workspacePath + REL_RecordFilePath
        print("recordFilePath: \(path)")
        return path
    }

    var executablePath: Path {
        let path = workspacePath + REL_ExecutablePath
        print("executablePath: \(path)")
        return path
    }
}
