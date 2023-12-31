//
//  SKMediaCommonDefines.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/11/26.
//

import SKFoundation
import LarkUIKit
import Photos

public enum SKPickContent {
    case asset(assets: [PHAsset], original: Bool)
    case takePhoto(photo: UIImage)
    case takeVideo(videoUrl: URL)
    case uploadCanvas(image: UIImage, pencilKitToken: String)
    case iCloudFiles(fileURLs: [URL])

    public static let pickContent = "pickContent"
}


public enum SKPickContentType: String {
    case image
    case video
    case file

    /// 存储路径
    public static func getUploadCacheUrl(uuid: String, pathExtension: String) -> SKFilePath {
        let lastPath = pathExtension.isEmpty ? uuid : "\(uuid).\(pathExtension)"
        return SKPickContentType.getUploadCacheUrl(lastComponent: lastPath)
    }

    public static func getUploadCacheUrl(lastComponent: String) -> SKFilePath {
        let path = SKFilePath.docsUploadCacheDir
        let resultPath = path.appendingRelativePath(lastComponent)
        return resultPath
    }

    public static let cacheUrlPrefix = DocSourceURLProtocolService.scheme + "://com.bytedance.net/file/f/"

}
