//
//  BrowseFile.swift
//  LarkFile
//
//  Created by SuPeng on 12/12/18.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkFoundation
import LarkCore
import LarkMessengerInterface
import LarkAccountInterface
import LarkContainer
import LarkSDKInterface
import LarkStorage
import RustPB

private typealias Path = LarkSDKInterface.PathWrapper

final class FileMessageInfoProtocolImpl: FileMessageInfoService {
    init(userID: String) {
        self.userID = userID
    }

    let userID: String

    func getFileMessageInfo(message: Message, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> FileMessageInfoProtocol {
        var extra: [String: Any] = [:]
        if let downloadFileScene = downloadFileScene {
            extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
        }
        return FileMessageInfo(userID: userID, message: message, browseFromWhere: .file(extra: extra))
    }
}

extension FileContent: FileContentBasicInfo {
    public var authFileKey: String {
        return key
    }
}

struct FileFromFolderBasicInfo: FileContentBasicInfo {
    let key: String
    let authToken: String?
    let authFileKey: String
    let size: Int64
    let name: String
    let cacheFilePath: String
    let filePreviewStage: RustPB.Basic_V1_FilePreviewStage
}

/// 文件信息 + message信息
/// 如果是文件夹里面的文件，message 指的是文件夹消息
final class FileMessageInfo: FileMessageInfoProtocol {
    let userID: String
    private var message: Message /// 文件对应的消息或者上层文件夹对应的消息
    private var content: FileContentBasicInfo
    let downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    let browseFromWhere: FileBrowseFromWhere
    var riskObjectKeys: [String] {
        return message.riskObjectKeys
    }

    init(userID: String,
         message: Message,
         fileInfo: FileContentBasicInfo? = nil,
         browseFromWhere: FileBrowseFromWhere) {
        self.userID = userID
        self.message = message
        self.browseFromWhere = browseFromWhere
        switch browseFromWhere {
        case .file(let extra):
            if let content = message.content as? FileContent {
                self.content = content
            } else {
                assertionFailure("init parameters is wrong")
                self.content = FileFromFolderBasicInfo(key: "", authToken: nil, authFileKey: "", size: 0, name: "", cacheFilePath: "", filePreviewStage: .normal)
            }
            self.downloadFileScene = extra[FileBrowseFromWhere.DownloadFileSceneKey] as? RustPB.Media_V1_DownloadFileScene
        case .folder(let extra):
            if let fileInfo = fileInfo {
                self.content = fileInfo
            } else {
                assertionFailure("init parameters is wrong")
                self.content = FileFromFolderBasicInfo(key: "", authToken: nil, authFileKey: "", size: 0, name: "", cacheFilePath: "", filePreviewStage: .normal)
            }
            self.downloadFileScene = extra[FileBrowseFromWhere.DownloadFileSceneKey] as? RustPB.Media_V1_DownloadFileScene
        }
    }

    var messageId: String { return message.id }

    var channelId: String { return message.channel.id }

    var senderUserId: String { return message.fromId }

    var senderTenantId: String { return message.fromChatter?.tenantId ?? "" }

    var messageSourceType: RustPB.Basic_V1_Message.SourceType { return message.sourceType }

    var messageSourceId: String { return message.sourceID }

    var isCrptoMessage: Bool { return message.isCryptoMessage }

    var fileKey: String { return content.key }

    var authToken: String? { return content.authToken }

    var authFileKey: String { return content.authFileKey }

    var fileSize: Int64 { return content.size }

    var fileName: String { return content.name }

    var filePreviewStage: Basic_V1_FilePreviewStage { return content.filePreviewStage }

    var isEncrypted: Bool { return (message.content as? FileContent)?.isEncrypted ?? false }

    var dlpDownloadState: RustPB.Basic_V1_MessageDLPState { return message.dlpState }

    var isRisk: Bool { !message.riskObjectKeys.isEmpty }
    var disabledAction: MessageDisabledAction {
        return message.disabledAction
    }

    lazy var fileFormat: FileFormat = {
        func fileData() -> Data? {
            if isFileExist {
                // 只需读取文件header信息，而Data读取q超大文件会导致内存不够从而Crash
                // 使用InputStream，只读取2048字节data，可以取到全部的HeaderData足以判断FileFormat
                let inputStream = Path(fileLocalPath).inputStream()
                inputStream?.open()

                // 创建指针
                let bufferSize = 2048
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

                defer {
                    // 释放指针，关闭InputStream
                    buffer.deallocate()
                    inputStream?.close()
                }

                // 使用InputStream读取数据并写入Data
                guard let read = inputStream?.read(buffer, maxLength: bufferSize), read > 0 else {
                    return nil
                }
                var data = Data()
                data.append(buffer, count: read)

                return data
            }
            return nil
        }

        if let fileData = fileData() {
            var fileFormat = fileData.lf.fileFormat()
            // officeX格式和zip格式是一样的，所以不能用data来判断,用文件名字判断
            // 同样如果通过data判断不出来格式，也用文件名字判断
            if fileFormat == FileFormat.office(.officeX) || fileFormat == FileFormat.unknown {
                fileFormat = fileName.lf.fileFormat()
            } else if fileFormat == .pdf {
                // PDF 特殊判断一下，因为pdf，ai,FDF的data格式是一样的，所以还需要加上文件 名字判断
                if fileName.lf.fileFormat() != .pdf {
                    fileFormat = .unknown
                }
            }
            return fileFormat
        }
        return fileName.lf.fileFormat()
    }()

    var isFileExist: Bool {
        return Path(fileLocalPath).exists
    }

    var fileLocalURL: URL {
        return URL(fileURLWithPath: fileLocalPath)
    }

    var fileRelativePath: String {
        fileKey.kf.md5
            .appending("/" + fileName)
    }
    var fileLocalPath: String {
        if message.isCryptoMessage {
            return content.cacheFilePath
        } else {
            return fileDownloadCache(userID).filePath(forKey: fileRelativePath)
        }
    }

    var fileOriginPath: String {
        if message.isCryptoMessage {
            return content.cacheFilePath
        } else {
            return fileDownloadCache(userID).originFilePath(forKey: fileRelativePath)
        }
    }

    var fileIcon: UIImage {
        return LarkCoreUtils.fileIcon(with: fileName)
    }

    var fileLadderIcon: UIImage {
        return LarkCoreUtils.fileLadderIcon(with: fileName)
    }

    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .binary)
    }

    var pathExtension: String {
        return (fileName as NSString).pathExtension
    }

    var canSaveToAlbum: Bool {
        if isFileExist {
            switch fileFormat {
            case .video:
                // 有一些音频文件也可以保存到相册，但是不可以播放。
                // 所以这里保存的时候判断一下，只保存视频文件
                return UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(fileLocalPath)
            case .image:
                return UIImage.read_(from: fileLocalPath) != nil
            default:
                return false
            }
        }
        return false
    }

    func updateMessage(_ message: Message) {
        self.message = message
        if let fileContent = message.content as? FileContent {
            self.content = fileContent
        }
    }
}
