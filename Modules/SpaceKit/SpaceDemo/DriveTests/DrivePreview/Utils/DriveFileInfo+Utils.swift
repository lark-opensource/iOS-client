//
//  DriveFileInfo+Utils.swift
//  DriveTests
//
//  Created by bupozhuang on 2020/1/4.
//  Copyright © 2020 Bytedance. All rights reserved.
//

import Foundation
@testable import SpaceKit

/// 不需要后台转码的fileInfo
let fileInfoNoServerTransfromJson = """
{
    "available_preview_type": [],
    "comment_flag": 1,
    "creator_tenant_id": "1",
    "data_version": "6719055589005068039",
    "mime_type": "image/gif",
    "mount_point": "explorer",
    "name": "15MB.gif",
    "num_blocks": 4,
    "preview_status": 4,
    "size": 15083640,
    "type": "gif",
    "version": "6770233712333293319"
}
"""

let videoFileInfoJson = """
{
    "available_preview_type": [3],
    "comment_flag": 0,
    "creator_tenant_id": "1",
    "data_version": "6771303413926856462",
    "mime_type": "video/mp4",
    "mount_point": "explorer",
    "name": "ttt.mp4",
    "num_blocks": 3,
    "preview_status": 1,
    "size": 8701192,
    "type": "mp4",
    "version": "6776041553069606660"
}
"""

let otherFileChangeToPDFJson = """
{
    "available_preview_type": [0, 9],
    "comment_flag": 1,
    "creator_tenant_id": "1",
    "data_version": "6765417363027265293",
    "mime_type": "application/pdf",
    "mount_point": "explorer",
    "name": "5b3af657N531ddcc8.pdf",
    "num_blocks": 1,
    "preview_status": 1,
    "size": 4030,
    "type": "pdf",
    "version": "6769126092730009355"
}
"""

let zipFileInfoJson = """
{
    "available_preview_type": [13],
    "comment_flag": 0,
    "creator_tenant_id": "1",
    "data_version": "6722253635918497547",
    "mime_type": "application/zip",
    "mount_point": "explorer",
    "name": "13.0.zip",
    "num_blocks": 4,
    "preview_status": 1,
    "size": 12753780,
    "type": "zip",
    "version": "6722253635918497547"
}
"""

let bigTxtFileInfo = """
{
    "available_preview_type": [0, 9, 14],
    "comment_flag": 1,
    "creator_tenant_id": "1",
    "data_version": "6758033100309006091",
    "mime_type": "text/plain; charset=utf-8",
    "mount_point": "explorer",
    "name": "txt_16m.txt",
    "num_blocks": 4,
    "preview_status": 1,
    "size": 15499290,
    "type": "txt",
    "version": "6759081581668730635"
}
"""

let linearImageFileInfo = """
{
    "available_preview_type": [11],
    "comment_flag": 1,
    "creator_tenant_id": "1",
    "data_version": "6773828754218157831",
    "mime_type": "image/jpeg",
    "mount_point": "explorer",
    "name": "Fronalpstock_big.jpg",
    "num_blocks": 4,
    "preview_status": 1,
    "size": 14679474,
    "type": "jpg",
    "version": "6773828754218157831"
}
"""

let zipFileInfo = """
{
    "available_preview_type": [13],
    "comment_flag": 0,
    "creator_tenant_id": "1",
    "data_version": "6722253635918497547",
    "mime_type": "application/zip",
    "mount_point": "explorer",
    "name": "13.0.zip",
    "num_blocks": 4,
    "preview_status": 1,
    "size": 12753780,
    "type": "zip",
    "version": "6722253635918497547"
}
"""

let unsupportFileInfo = """
{
    "available_preview_type": [],
    "comment_flag": 0,
    "creator_tenant_id": "1",
    "data_version": "6730580166646433550",
    "mime_type": "application/octet-stream",
    "mount_point": "explorer",
    "name": "icon_pop_quickaccess_nor.pd",
    "num_blocks": 1,
    "preview_status": 4,
    "size": 4215,
    "type": "pd",
    "version": "6730904330951460622"
}
"""
extension DriveFileInfo {
    static func fileInfo(with jsonStr: String,
                         fileToken: String = "defaultToken",
                         mountToken: String = "defaultToken",
                         mountPoint: String = "defaultPoint") -> DriveFileInfo? {
        guard let data = jsonStr.data(using: .utf8), let dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        return DriveFileInfo(data: dic, fileToken: fileToken, mountNodeToken: mountToken, mountPoint: mountPoint)
    }
}
