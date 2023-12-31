//
//  OpenPluginNetwork+Download.swift
//  OPPlugin
//
//  Created by MJXin on 2022/1/14.
//
import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPFoundation

final class OpenPluginDownloadTask {
    
    typealias OpenPluginNetworkError = OpenPluginNetwork.OpenPluginNetworkError
    
    /// 将 filePath 转为 fileObject
    /// 内含写权限校验
    static func generateInputObject(context: FileSystem.Context, filePath: String) throws -> FileObject {
        let fileObject = try FileObject(rawValue: filePath)
        // 判断是否符合 ttfile:// 协议
        guard fileObject.isValidTTFile() else {
            throw OpenPluginNetworkError.invalidFilePath(filePath)
        }
        // 校验目标目录是否存在
        let destFolder = fileObject.deletingLastPathComponent;
        let floderExist = try FileSystem.fileExist(destFolder, context: context)
        guard floderExist else { throw OpenPluginNetworkError.fileNotExists(filePath) }
            
        // 校验是否有对目标目录的访问权限
        let hasWriteAccess = try (fileObject.isInTempDir || FileSystem.canWrite(
            fileObject,
            isRemove: false,
            context: context
        ))
        guard hasWriteAccess else { throw OpenPluginNetworkError.writePermissionDenied(filePath) }
        return fileObject
    }
    
    
    /// 生成下载文件用的临时路径
    /// 下载文件会先下到 Tmp 的临时路径中, 再下载完成后再移入正式路径(原因是考虑读写权限及加密, 以及下载中断临时文件处理等情况)
    static func generateTempDownloadPath(from uniqueID: OPAppUniqueID) throws -> String {
        let sandbox = try Self.getSandBox(with: uniqueID)
        // 创建沙箱中的临时路径
        guard let path = FileSystemUtils.generateRandomPrivateTmpPath(with: sandbox) else {
            throw OpenPluginNetworkError.getRandomTmpPathFail
        }
        return path
    }
    
    /// 在 private_tmp 路径下生成随机命名的文件夹，并返回对应路径
    static func generatePrivateTmpRandomInnerPath(from uniqueID: OPAppUniqueID) throws -> String {
        let sandbox = try Self.getSandBox(with: uniqueID)
        // 创建临时保存目录, 避免下载同名文件时覆盖
        guard let path = FileSystemUtils.generatePrivateTmpRandomInnerPath(with: sandbox) else {
            throw OpenPluginNetworkError.getRandomTmpPathFail
        }
        return path
    }
    
    static func getSandBox(with uniqueID: OPAppUniqueID) throws -> BDPMinimalSandboxProtocol {
        // 拿沙箱插件
        guard let storageModule = BDPModuleManager(of: uniqueID.appType).resolveModule(
            with: BDPStorageModuleProtocol.self
        ) as? BDPStorageModuleProtocol else {
            throw OpenPluginNetworkError.storageModuleNotFound
        }
        // 拿沙箱
        return storageModule.minimalSandbox(with: uniqueID)
    }
    
    /// 将文件移动到最终路径
    /// 下载中的文件存放在临时路径, 只有在下载完成后才向最终路径移动
    /// - Parameters:
    ///   - context: 文件系统的上下文
    ///   - source: 源路径
    ///   - filename: 建议的文件命名(在没有用户指定 filePath入参时使用)
    ///   - targetFileObj: 目标对象(通过用户指定的 filePath 入参生成)
    /// - Returns: 最终路径
    static func moveDownloadFile(context: FileSystem.Context, source: String, filename: String, targetFileObj: FileObject?) throws -> String {
        var destFileObj: FileObject
        if let fileObj = targetFileObj {
            destFileObj = fileObj
        } else {
            destFileObj = FileObject.generateSpecificTTFile(type: .temp, pathComponment: filename)
        }
        let fileExist = try FileSystem.fileExist(destFileObj, context: context)
        if fileExist { try FileSystem.removeFile(destFileObj, context: context) }
        try FileSystemCompatible.moveSystemFile(source, to: destFileObj, context: context)
        return destFileObj.rawValue
    }
}
