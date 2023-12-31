//
//  OpenPluginUploadTask.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/9/15.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPFoundation

final class OpenPluginUploadTask {
    
    typealias OpenPluginNetworkError = OpenPluginNetwork.OpenPluginNetworkError
    
    /// ttfilePath 转为 file 路径, 带权限校验
    /// - Parameters:
    ///   - context: api 上下文
    ///   - ttFilePath: 入参传入的 ttFilePath
    ///   - tag: 标签
    /// - Returns: 真实路径
    static func getRealFilePath(context: OpenAPIContext, ttFilePath: String, tag: String, needCheckPageFile: Bool = true) throws -> (FileObject, String) {
        let uniqueID = try OpenPluginNetwork.getUniqueID(context: context)
        let fsContext = FileSystem.Context(
            uniqueId: uniqueID,
            trace: context.apiTrace,
            tag: tag,
            isAuxiliary: false
        )
        let fileObj = try FileObject(rawValue: ttFilePath)
        guard fileObj.isValidTTFile() || (needCheckPageFile && fileObj.isValidPackageFile()) else {
            throw OpenPluginNetworkError.invalidFilePath(ttFilePath)
        }
        if try FileSystem.canRead(fileObj, context: fsContext) {
            let realFilePath = try FileSystemCompatible.getSystemFile(from: fileObj, context: fsContext)
            return (fileObj, realFilePath)
        } else {
            throw OpenPluginNetworkError.readPermissionDenied(ttFilePath)
        }
    }
}
