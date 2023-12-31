//
//  DKFileProtocol.swift
//  SKECM
//
//  Created by bupozhuang on 2021/5/27.
//

import Foundation
import SKCommon
import RxSwift
import RxCocoa
import SKFoundation
import LarkDocsIcon

protocol DKFileProtocol: CustomStringConvertible {
    var name: String { get }
    var size: UInt64 { get }
    var fileID: String { get }
    var type: String { get }
    var mimeType: String? { get }
    var realMimeType: String? { get }
    var fileExtension: String? { get }
    var version: String? { get }
    var dataVersion: String? { get }
    var previewStatus: Int? { get }
    var fileType: DriveFileType { get }
    var videoCacheKey: String { get }
    var webOffice: Bool { get }
    var wpsInfo: DriveWPSPreviewInfo { get }
    var wpsEnable: Bool { get }
    var previewMetas: [DrivePreviewFileType: DriveFilePreview] { get }
    var mountPoint: String { get }
    var authExtra: String? { get } // 第三方附件接入业务可以通过authExtra透传参数给业务后方进行鉴权，根据业务需要可选
    var isIMFile: Bool { get }
    /// 根据预览场景，获取优先预览的方式
    func getPreferPreviewType(isInVCFollow: Bool?) -> DrivePreviewFileType?
    func getPreviewDownloadURLString(previewType: DrivePreviewFileType) -> String?
    func getMeta() -> DriveFileMeta?
}

extension DKFileProtocol {
    /// 通过比对后端返回的 mimeType 和文件后缀判断文件是否为真实类型，返回 nil 表明无法判断
    var isRealFileType: Bool? {
        guard let mimeType = self.mimeType,
              let realMimeType = self.realMimeType else { return nil }
        // 先判断后端返回的两个 mimeType 信息是否一致，若不一致则转换为文件后缀名进行二次判断
        if mimeType == realMimeType {
            return true
        } else {
            let originFileExt = DriveUtils.fileExtensionFromMIMEType(realMimeType)
            return originFileExt == type
        }
    }
    var version: String? {
        return nil
    }
}

extension DKFileProtocol {
    public var description: String {
        return "size: \(size), fileId: \(DocsTracker.encrypt(id: fileID)), type: \(type), mimeType: \(String(describing: mimeType)), fileExtension: \(String(describing: fileExtension)), version: \(String(describing: version)), dataVersion: \(String(describing: dataVersion)), previewStatus: \(String(describing: previewStatus)), fileType: \(fileType), webOffice: \(webOffice), previewMetas: \(previewMetas), mountPoint: \(mountPoint), authExtra: \(String(describing: authExtra))"
    }
}
