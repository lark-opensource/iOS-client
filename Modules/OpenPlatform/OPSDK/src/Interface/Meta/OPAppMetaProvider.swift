//
//  OPAppMetaProvider.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/10/29.
//

// 应用meta信息提供者协议：包含远端meta和本地meta
import Foundation
import LarkOPInterface
import OPFoundation

public typealias requestProgress = (_ current: Float, _ total: Float) -> Void
public typealias requestCompletion = (_ success: Bool, _ meta: OPBizMetaProtocol?, _ error: OPError?) -> Void

/// 本地meta provider
public protocol OPAppMetaLocalAccessor: NSObjectProtocol {

    /// 获取本地meta db json
    /// - Parameter uniqueID: 需要获取的uniqueID
    func getLocalMeta(with uniqueID: OPAppUniqueID) throws -> OPBizMetaProtocol



    /// 保存/更新本地meta
    /// - Parameters:
    ///   - uniqueID: 需要更新的uniqueID
    ///   - meta: 待保存的meta
    func saveMetaToLocal(with uniqueID: OPAppUniqueID, meta: OPBizMetaProtocol) throws


    /// 删除本地meta
    /// - Parameter uniqueID: 需要删除的uniqueID
    func deleteLocalMeta(with uniqueID: OPAppUniqueID)

}

/// 远端meta provider
public protocol OPAppMetaRemoteAccessor: NSObjectProtocol {

    /// 从远端拉取meta
    /// - Parameters:
    ///   - uniqueID: 拉取meta的ID
    ///   - previewToken: 预览token
    ///   - progress: 拉取进度：current：当前接收， total: 总共需接收
    ///   - completion: 拉取完成：success: 是否成功，meta: 请求成功时的meta，error：请求失败时的错误信息
    func fetchRemoteMeta(with uniqueID: OPAppUniqueID, previewToken: String, progress: requestProgress?, completion: requestCompletion?)

    /// 取消拉取meta
    /// - Parameters:
    ///   - uniqueID: 拉取meta的ID
    ///   - previewToken: 预览token
    func cancelFetchMeta(with uniqueID: OPAppUniqueID, previewToken: String)

}
