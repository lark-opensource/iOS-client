//
//  AccountService+Privacy.swift
//  LarkAccountInterface
//
//  Created by bytedance on 2022/4/19.
//

import Foundation

public enum AgreementType {
    //隐私政策
    case privacy
    //服务协议
    case term
}

/// 对外提供的协议链接
public protocol AccountServiceAgreement { // user:checked

    /// 根据 type 获取一个协议 URL
    /// - Returns: 协议URL
    func getAgreementURLWithPackageDomain(type: AgreementType) -> URL?
}
