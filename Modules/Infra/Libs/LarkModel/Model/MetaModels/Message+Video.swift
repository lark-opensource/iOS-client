//
//  Message+Video.swift
//  LarkModel
//
//  Created by 李晨 on 2022/8/15.
//

import Foundation
import RustPB

public extension Message {

    /// PC 原画视频 消息转化
    func transformToFileMessageIfNeeded() -> Message {
        guard let content = self.content as? MediaContent else {
            return self
        }
        let fileContent = FileContent(
            key: content.key,
            name: content.name,
            size: content.size,
            mime: content.mime,
            filePath: content.filePath,
            cacheFilePath: "",
            fileSource: .unknown,
            namespace: "",
            isInMyNutStore: false,
            lanTransStatus: .pending,
            hangPoint: nil,
            fileAbility: .unknownSupportState,
            filePermission: .unknownCanState,
            fileLastUpdateUserId: 0,
            fileLastUpdateTimeMs: 0,
            filePreviewStage: .normal,
            isEncrypted: false
        )
        let copy = self.copy()
        copy.type = .file
        copy.content = fileContent
        return copy
    }
}
