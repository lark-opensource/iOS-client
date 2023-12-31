//
//  MetaProtocol.swift
//  Timor
//  Meta 模块 协议定义，要求OC Swift两部分都可以用
//  Created by 武嘉晟 on 2020/5/16.
//

import Foundation
import LarkOPInterface

@objc public protocol AppMetaAdapterProtocol {
    var appMetaAdapter: AppMetaProtocol { get }
}

/// meta抽象
@objc public protocol AppMetaProtocol {

    /// 应用唯一标志符
    var uniqueID: BDPUniqueID { get }

    /// 版本
    var version: String { get }

    /// 应用名称
    var name: String { get }

    /// 应用图标地址
    var iconUrl: String { get }

    /// 包属性
    var packageData: AppMetaPackageProtocol { get }

    /// 权限属性
    var authData: AppMetaAuthProtocol { get }

    /// 业务数据，存放各应用形态独有的属性
    var businessData: AppMetaBusinessDataProtocol { get }

    /// metaModel转化为json字符串用于持久化（如果纯Swift可以用Codable，纯OC可以NSCoding，混编比较痛苦）
    func toJson() throws -> String
}

fileprivate var appMetaProtocolLastUpdateTimestamp: Void? = nil
extension AppMetaProtocol {
    // 上次更新时间,单位:毫秒
    public func setLastUpdateTimestamp(ts: NSNumber)  {
        objc_setAssociatedObject(self, &appMetaProtocolLastUpdateTimestamp, ts, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    // 上次更新时间,单位:毫秒
    public func getLastUpdateTimestamp() -> NSNumber? {
        return objc_getAssociatedObject(self, &appMetaProtocolLastUpdateTimestamp) as? NSNumber
    }
}

/// 目前只有小程序支持该协议
@objc public protocol AppMetaComponentsProtocol {
    /// 依赖的组件信息，做成 Dict，是为了方便将来扩展
    var components: [[String:Any]] { get }

    /// 返回组件列表
    func getComponentNames() -> [String]
}

/// meta中的包信息抽象
@objc public protocol AppMetaPackageProtocol {

    /// 代码包下载地址数组
    var urls: [URL] { get }

    /// 包校验码md5
    var md5: String { get }
    
    @objc optional var subPackages: [AppMetaSubPackageProtocol] { get }
}

// 数据结构: ["1.0.3" : ["path" : "https://xxx", "path_md5" : "xxxxx"]];
// 这里的"1.0.3"是包版本
public typealias MetaDiffPkgPathInfo = [String : [String : Any]]

@objc public protocol AppMetaDiffPackageProtocol {
    @objc optional var diffPkgPath: MetaDiffPkgPathInfo { get }
}

/// meta中的分包相关的信息抽象
@objc public protocol AppMetaSubPackageProtocol: AppMetaPackageProtocol {
    //分包的页面路径，如果是主包，则是 __APP__
    var path: String { get }
    //当前分包允许的分包页面
    var pages: [String] { get }
    //是否是独立分包
    var isIndependent: Bool { get }
    //是否是主包（path 是 __APP__）
    var isMainPackage: Bool { get }
}

/// meta中的权限信息抽象
@objc public protocol AppMetaAuthProtocol {
}

/// meta中的业务数据抽象，存放各应用形态独有的属性
@objc public protocol AppMetaBusinessDataProtocol {
}

@objc public protocol MetaTTCodeProtocol {
    /// 通过Meta上下文获取请求
    /// - Parameter context: Meta上下文
    func getMetaRequestAndTTCode(with context: MetaContext) throws -> MetaRequestAndTTCode
}

/// Meta 能力提供协议，例如组装meta请求和组装meta实体
@objc public protocol MetaProviderProtocol {
    /// 通过后端返回数据获取Meta实体
    /// - Parameters:
    ///   - data: 后端返回的二进制数据
    ///   - ttcode: ttcode校验对象
    ///   - context: Meta上下文
    func buildMetaModel(
        with data: Data,
        ttcode: BDPMetaTTCode,
        context: MetaContext
    ) throws -> AppMetaProtocol
    
    func buildMetaModelWithDict(
            _ dict: [String: Any],
            ttcode: BDPMetaTTCode,
            context: MetaContext
    ) throws -> AppMetaProtocol

    /// 通过数据库meta str转换为metamodel
    /// - Parameter metaJsonStr: meta json字符串
    func buildMetaModel(with metaJsonStr: String, context: MetaContext) throws -> AppMetaProtocol
}

@objc public protocol MetaFromStringProtocol {
    func buildMetaModel(with metaJsonStr: String) throws -> AppMetaProtocol
}

//  meta请求Request和校验参数的集合
@objcMembers
public class MetaRequestAndTTCode: NSObject {

    /// meta请求
    public let request: URLRequest

    /// 校验参数
    public let ttcode: BDPMetaTTCode

    public init(
        request: URLRequest,
        ttcode: BDPMetaTTCode
    ) {
        self.request = request
        self.ttcode = ttcode
        super.init()
    }
}
