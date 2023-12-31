//
//  OpenAPIRustNetworkErrno.swift
//  OPPlugin
//
//  Created by 刘焱龙 on 2023/1/4.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPINetworkRustErrno {
    private let rustErrCode: Int
    private let rustErrString: String

    init?(errCode: Int, errString: String) {
        guard (errCode >= 100 && errCode < 200)
                || (errCode >= 300 && errCode < 400) else { return nil }
        rustErrCode = errCode
        rustErrString = errString
    }
}

extension OpenAPINetworkRustErrno: OpenAPIErrnoProtocol {
    public var bizDomain: Int {
        return 0
    }

    public var funcDomain: Int {
        return 0
    }

    public var rawValue: Int {
        return rustErrCode
    }

    public var errString: String {
        return rustErrString
    }

    public func errno() -> Int {
        return rustErrCode
    }
}
