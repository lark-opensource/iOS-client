//
//  FolderMessageInfo.swift
//  LarkFile
//
//  Created by 赵家琛 on 2021/4/7.
//

import Foundation
import LarkSDKInterface
import RustPB
import LarkModel

struct FolderMessageInfo {
    let message: Message
    let isFromZip: Bool //是否是压缩包在线预览 所拿到的文件夹
    let downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    let extra: [AnyHashable: Any]

    init(message: Message, isFromZip: Bool, downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil, extra: [AnyHashable: Any]) {
        self.message = message
        self.isFromZip = isFromZip
        self.downloadFileScene = downloadFileScene
        self.extra = extra
    }
}

struct FolderManagementMenuOptions: OptionSet {
    let rawValue: UInt

    static let forward = FolderManagementMenuOptions(rawValue: 1 << 0)
    static let viewInChat = FolderManagementMenuOptions(rawValue: 1 << 1)
    static let openWithOtherApp = FolderManagementMenuOptions(rawValue: 1 << 2)
}

struct FolderManagementConfiguration {
    var menuOptions: FolderManagementMenuOptions
    let supportSearch: Bool
    let disableAction: MessageDisabledAction
}
