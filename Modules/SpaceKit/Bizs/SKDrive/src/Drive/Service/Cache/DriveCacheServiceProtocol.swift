//
//  DriveCacheServiceProtocol.swift
//  SKECM
//
//  Created by Weston Wu on 2020/9/1.
//

import Foundation
import SKFoundation
import class SKCommon.SpaceEntry

protocol DriveCacheServiceProtocol {

    /// 拼接drive文件的下载路径，e.g: XXX/$type_$encryptToken_$version.$fileExtension
    /// - Parameters:
    ///   - cacheType: 缓存的类型（原始文件、转码文件、视频信息等）
    ///   - fileExtension: 文件拓展名
    func driveFileDownloadURL(cacheType: DriveCacheType, fileToken: String, dataVersion: String, fileExtension: String) -> SKFilePath

    /// 判断drive文件是否存在
    /// - Attention: 无网时，存在可离线打开的缓存, 才返回true
    /// - Attention: 同步接口，注意避免主线程调用
    func isDriveFileExist(token: String, dataVersion: String?, fileExtension: String?) -> Bool
    /// 判断drive文件是否存在
    /// - Attention: 无网时，存在可离线打开的缓存, 才返回true
    /// - Attention: 同步接口，注意避免主线程调用
    /// - Parameters:
    ///   - type: 缓存的类型（原始文件、转码文件、视频信息等）
    func isDriveFileExist(type: DriveCacheType, token: String, dataVersion: String?, fileExtension: String?) -> Bool

    // MARK: - Check file existence
    /// 获取缓存的drive文件，若缓存中不存在对应文件，返回nil
    /// - Attention: 此接口没有指定缓存的类型，若存在多个匹配的文件，会随机选择一个返回
    /// - Attention: 同步接口，注意避免主线程调用
    func getDriveFile(token: String, dataVersion: String?, fileExtension: String?) -> Result<DriveCache.Node, Error>
    /// 获取特定类型的drive文件缓存，若缓存中不存在对应文件，返回nil
    /// - Attention: 同步接口，注意避免主线程调用
    /// - Parameters:
    ///   - type: 缓存的类型（原始文件、转码文件、视频信息等）
    func getDriveFile(type: DriveCacheType, token: String, dataVersion: String?, fileExtension: String?) -> Result<DriveCache.Node, Error>
    /// 获取特定类型的drive文件数据，若缓存中不存在对应文件，返回nil
    /// - Attention: 此接口从本地文件读取并转换为 Data，应注意控制存入的 Data 的大小
    /// - Attention: 同步接口，注意避免主线程调用
    func getDriveData(type: DriveCacheType, token: String, dataVersion: String?, fileExtension: String?) -> Result<(DriveCache.Node, Data), Error>

    // MARK: - Save operation
    
    /// 存入 drive 文件
    /// - Attention: 默认情况下会移动文件，调用此接口后 filePath 将失效
    /// - Attention: 异步接口，可通过回调闭包确认保存结果
    func saveDriveFile(context: SaveFileContext, completion: ((Result<SKFilePath, Error>) -> Void)?)
    
    /// 存入 drive 数据
    /// - Attention: Data 会被写入到磁盘，若需要加密，需在调用此接口前完成
    /// - Attention: 异步接口，可通过回调闭包确认保存结果
    func saveDriveData(context: SaveDataContext, completion: ((Result<SKFilePath, Error>) -> Void)?)

    // MARK: - Deletion
    /// 删除 drive 缓存
    /// - Attention: 会删除所有匹配的文件，如同一个token的多种缓存文件，或多个版本的多种缓存文件
    /// - Attention: 异步接口，可通过回调闭包确认保存结果
    /// - Parameters:
    ///   - dataVersion: 需要删除的版本，为 nil 表示删除所有版本的文件
    ///   - completion: 删除完成后的回调，若没有可删除的文件，则删除失败
    func deleteDriveFile(token: String, dataVersion: String?, completion: ((_ success: Bool) -> Void)?)

    /// 清空缓存中的所有文件（包括手动离线文件）
    /// - Attention: 异步接口，可通过回调闭包确认保存结果
    func deleteAll(completion: (() -> Void)?)

    /// 将 drive 缓存标记为手动离线，避免被自动清理
    /// - Parameter files: token 和对应的原始文件后缀，缓存中记录的原始文件后缀不匹配的文件不会被标记
    func moveToManualOffline(files: [(token: String, dataVersion: String?, fileExtension: String?)],
                             complete: (() -> Void)?)
    /// 移除手动离线的标记，使缓存可被自动清理
    func moveOutManualOffline(tokens: [String], complete: (() -> Void)?)
}

extension DriveCacheServiceProtocol {
    func deleteDriveFile(token: String, dataVersion: String?) {
        deleteDriveFile(token: token, dataVersion: dataVersion, completion: nil)
    }
}

/// 存入 DriveCacheService 的基础文件信息
/// - Parameters:
///   - cacheType: 缓存类型
///   - source: 请求的来源，用于判断文件是否可被自动清理
///   - token: 文件token
///   - fileName: 适合在UI上展示的文件名，不需要和磁盘文件名一致
///   - fileType: 文件类型
///   - dataVersion: 文件版本
///   - originFileSize: 原始文件的大小，不一定和存入的文件大小相等
struct DriveCacheServiceBasicInfo {
    let cacheType: DriveCacheType
    let source: DriveCacheService.Source
    let token: String
    let fileName: String
    let fileType: String?
    let dataVersion: String?
    let originFileSize: UInt64?
}

/// 存入 drive 文件的配置信息
/// - Parameters:
/// - Attention: 默认情况下会移动文件，调用此接口后 filePath 将失效
/// - Attention: 异步接口，可通过回调闭包确认保存结果
///   - source: 请求的来源，用于判断文件是否可被自动清理
///   - moveInsteadOfCopy: 移动文件或复制文件
///   - completion: 保存结束的回调
///   - rewriteFileName: 在文件名中新增fileID相关信息
struct SaveFileContext {
    let filePath: SKFilePath
    let moveInsteadOfCopy: Bool
    let basicInfo: DriveCacheServiceBasicInfo
    let rewriteFileName: Bool
}

/// 存入 drive 数据的配置信息
struct SaveDataContext {
    let data: Data
    let basicInfo: DriveCacheServiceBasicInfo
}
