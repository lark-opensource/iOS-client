//
//  OpenAPIErrno.swift
//  LarkOpenAPIModel
//
//  Created by 王飞 on 2022/5/30.
//

import Foundation

/// errno 逻辑，在 API 发生异常时返回
/// errno 由三部分组成 {业务域}_{功能域}_{具体的 API 错误码}
/// 业务域两位，比如媒体，导航，网络等
/// 功能域两位，比如图片，视频，上传，下载等
/// 具体的 API 错误域，比如 openSchema API 中打开一个非法的 schema 行为
/// 相关设计文档 https://bytedance.feishu.cn/wiki/wikcn8J3NhYLRudpEnT07cYvuSe
public protocol OpenAPIErrnoProtocol {
    
    /// 业务域
    var bizDomain: Int { get }
    
    /// 功能域
    var funcDomain: Int { get }
    
    /// API 错误码，这个名字用在 RawRepresentable enum 上会比较舒服
    var rawValue: Int { get }
    
    /// 具体的错误信息
    var errString: String { get }
    
    /// 由上述组合成的错误码
    /// 比如 login 的业务域 10，功能域 00，发生了请求服务失败的情况错误码 001
    /// 那么 errno 就是 10_00_001
    func errno() -> Int
}
public extension OpenAPIErrnoProtocol {
    func errno() -> Int {
        return (bizDomain * 100 + funcDomain) * 1000 + rawValue
    }
}

