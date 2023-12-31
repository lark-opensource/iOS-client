//
//  SecurityReviewManager+drive.swift
//  SKCommon
//
//  Created by huangzhkai on 2023/11/27.
//

import Foundation
import LarkSecurityAudit
import LarkDocsIcon

extension SecurityReviewManager {
    //抽取drive埋点上报的参数，后续不建议放这里面，放到drive模块
    public class func getDriveSecurityEventitem(driveType: DriveFileType) -> [SecurityEvent_RenderItem] {
        var itemList = [SecurityEvent_RenderItem]()
        var item = SecurityEvent_RenderItem()
        item.key = RenderItemKey.ccmDownloadType.rawValue
        if driveType.isVideo {
            item.value = "video"
        } else if driveType.isImage {
            item.value = "image"
        } else {
            item.value = "file"
        }
        itemList.append(item)
        return itemList
    }
}
