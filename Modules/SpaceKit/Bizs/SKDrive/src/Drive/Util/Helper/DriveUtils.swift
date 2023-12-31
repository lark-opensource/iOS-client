//
//  DriveUtils.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2021/7/15.
//  

import Foundation
import CoreServices

struct DriveUtils {
    
    /// 将 MIMEType 转换为文件扩展名
    static func fileExtensionFromMIMEType(_ mime: String) -> String? {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mime as CFString, nil),
              let ext = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassFilenameExtension) else {
            // 用映射表兜底
            return MIMETypeToFileExt[mime]
        }
        return ext.takeRetainedValue() as String
    }
    
    /// MIMEType 映射为文件后缀
    static let MIMETypeToFileExt = [
        "video/ogg": "ogg",
        "audio/ogg": "ogg"
    ]

}
