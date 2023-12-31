//
//  DriveFilePreview+Utils.swift
//  DriveTests
//
//  Created by bupozhuang on 2020/1/2.
//  Copyright © 2020 Bytedance. All rights reserved.
//

import Foundation
@testable import SpaceKit

let videoPreviewReadyJson = """
{
    "status": 0,
    "interval": 2000,
    "preview_url": "https://previewurl",
    "content": {
        "type": 3,
        "transcode_urls": {
            "480p": "https://previewurl/480",
            "360p": "https://previewurl/360",
            "720p": "https://previewurl/720"
        }
    }
}
"""

let videoPreviewGenerartingJson = """
{
    "status": 1,
    "interval": 2000,
    "preview_url": "https://previewurl",
    "content": {
        "type": 3,
        "transcode_urls": {
            "480p": "https://previewurl/480",
            "360p": "https://previewurl/360",
            "720p": "https://previewurl/720"
        }
    }
}
"""
let videoPreviewFailedJson = """
{
    "status": 3,
    "interval": 2000,
}
"""

let otherFileChangeToPDFPreviewJson = """
{
    "interval": 2000,
    "status": 8,
    "linearized": false
}
"""

let linearImagePreviewJson = """
    "preview_url": "https://internal-api.feishu.cn/space/api/box/stream/download/authcode/?code=493bcbd303f91275cf71a171e5a026d7_73fa675232bb2611_TM55V7D54E2BM_7HBSKEMKIBQHHC35076B7OS3MS",
    "interval": 2000,
    "status": 0,
    "extra": "",
    "linearized": true,
    "preview_file_size": 15250841
}
"""

let zipPreviewJson = """
{
    "interval": 2000,
    "status": 0,
    "extra": "zipinnfo",
    "linearized": false
}
"""


extension DriveFilePreview {
    static func preview(with jsonStr: String) -> DriveFilePreview? {
        guard let data = jsonStr.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(DriveFilePreview.self, from: data)
    }
}
