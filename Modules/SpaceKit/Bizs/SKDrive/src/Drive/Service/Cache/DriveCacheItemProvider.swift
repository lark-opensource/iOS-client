//
//  DriveCacheItemProvider.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/7/14.
//  

import UIKit
import SKCommon
import SKFoundation
import LinkPresentation
import SKUIKit
import LarkDocsIcon

protocol DriveCacheItem {
    var itemFileName: String { get }
    var itemFileURL: SKFilePath? { get }
}

extension DriveCache.Node: DriveCacheItem {
    var itemFileName: String {
        record.originName
    }

    var itemFileURL: SKFilePath? {
        fileURL
    }
}

class DriveCacheItemProvider: UIActivityItemProvider {

    private let file: DriveCacheItem
    private let fileURL: SKFilePath
    let isEncrypt: Bool //文件是否被加密
    init(file: DriveCacheItem, tmpURL: SKFilePath, isEncrypt: Bool) {
        self.file = file
        fileURL = tmpURL.appendingRelativePath(file.itemFileName)
        self.isEncrypt = isEncrypt
        super.init(placeholderItem: fileURL.pathURL)
    }

    public override var item: Any {
        guard let sourcePath = file.itemFileURL else {
            spaceAssertionFailure("Drive.Cache.3rdOpen --- no source file")
            return SKFilePath.globalSandboxWithLibrary
        }
        guard sourcePath.copyItem(to: fileURL, overwrite: true) else {
            DocsLogger.warning("Drive.Cache.3rdOpen --- Rename file failed when copying.")
            return sourcePath.pathURL
        }
        return fileURL.pathURL
    }

    @available(iOS 13.0, *)
    override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        if self.isEncrypt {
            //系统会自动解析文件metadata，解析加密后的视频会crash，所以如果文件被加密，则手动构造Metadata
            let metadata = LPLinkMetadata()
            metadata.title = self.file.itemFileName
            metadata.url = self.fileURL.pathURL
//            metadata.originalURL = self.fileURL
            return metadata
        } else {
            if #available(iOS 14, *) {
                return nil
            } else if isMultiMedia {
                // 原因： 经过尝试发现iOS13音视频文件，如果文件类型错误，有概率出现LPStreamingMediaMetadataProviderSpecialization crash
                // 解决：iOS13 并且为多媒体文件的情况下，提供默认的meta信息，避免系统拉取meta信息
                let metadata = LPLinkMetadata()
                metadata.title = self.file.itemFileName
                metadata.url = self.fileURL.pathURL
                if let icon = iconImage {
                    metadata.iconProvider = NSItemProvider(object: icon)
                }
                return metadata
            } else {
                return nil
            }
        }
    }
    
    private var isMultiMedia: Bool {
        guard let ext = SKFilePath.getFileExtension(from: file.itemFileName) else {
            DocsLogger.driveInfo("file has no extension")
            return false
        }
        let fileType = DriveFileType(fileExtension: ext)
        return fileType.isVideo || fileType.isAudio
    }
    
    private var iconImage: UIImage? {
        guard let ext = SKFilePath.getFileExtension(from: file.itemFileName) else {
            DocsLogger.driveInfo("file has no extension")
            return DriveFileType.unknown.roundImage
        }
        let fileType = DriveFileType(fileExtension: ext)
        return fileType.roundImage
    }
}
