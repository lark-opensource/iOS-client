//
//  DynamicDomainInterface.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/12.
//

import Foundation
import RxSwift

/// 异步请求域名配置状态
enum AsynGetDynamicDomainStatus {
    /// 未触发
    case notTriger

    /// 加载中...
    case loading

    /// 加载成功
    case success

    /// 加载失败
    case failure(Error)
}

protocol DynamicDomainService {
    /// 拉取动态域名结果
    var result: Observable<AsynGetDynamicDomainStatus> { get }

    /// 拉取动态域名
    func asyncGetDynamicDomain()
}
