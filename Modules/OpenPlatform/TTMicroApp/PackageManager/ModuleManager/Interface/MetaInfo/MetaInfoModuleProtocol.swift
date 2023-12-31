//
//  MetaInfoModuleProtocol..swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/16.
//

import Foundation
import LarkOPInterface

/// Meta 管理模块协议
/// 功能：从网络下载Meta，获取本地Meta，清除Meta
@objc public protocol MetaInfoModuleProtocol: BDPModuleProtocol {

    /// 应用元数据 数据库管理对象
    var metaInfoAccessor: BDPMetaInfoAccessorProtocol { get }

    /// 尝试获取meta磁盘缓存
    /// - Parameter context: meta请求上下文
    func getLocalMeta(with context: MetaContext) -> AppMetaProtocol?

    /// 从网络拉取meta信息
    /// - Parameters:
    ///   - context: meta请求上下文
    ///   - shouldSaveMeta: 是否需要持久化Meta
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func requestRemoteMeta(
        with context: MetaContext,
        shouldSaveMeta: Bool,
        success: ((AppMetaProtocol, (() -> Void)?) -> Void)?,
        failure: ((OPError) -> Void)?
    )
    
    /// 通过外部传入meta的String，构建一个appMetaProtocol对象
    /// - Parameters:
    ///   - str: 原始meta json
    ///   - context: meta的上下文
    /// - Returns:appMeta 对象
    func buildMeta(with str:String, context: MetaContext) -> AppMetaProtocol?
    /// 删除本地meta
    /// - Parameter contexts: meta请求上下文
    func removeMetas(with contexts: [MetaContext])

    /// 清除本地所有meta
    func removeAllMetas()

    /// 清除所有meta请求
    func clearAllMetaRequests()

    /// 获取meta复合接口 会走 local+asyncUpdate 或者只走 remote
    /// - Parameters:
    ///   - context: meta请求上下文
    ///   - local: 本地回调
    ///   - asyncUpdate: 异步更新回调 内部不持久化，包下载结束外界进行持久化 第三个参数是持久化Meta的Block
    ///   - remote: 无缓存时网络请求meta的回调 下载完毕会直接持久化
    func launchGetMeta(
        with context: MetaContext,
        local: ((AppMetaProtocol) -> Void)?,
        asyncUpdate: ((AppMetaProtocol?, OPError?, (() -> Void)?) -> Void)?,
        remote: ((AppMetaProtocol?, OPError?) -> Void)?
    )

    /// 清理数据库实例，用于退出登录/切换租户｜用户时
    func closeDBQueue()
}
