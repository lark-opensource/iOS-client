//
//  OPMonitorCodeBase.swift
//  ECOProbeMeta
//
//  Created by Crazy凡 on 2023/3/24.
//

import Foundation

let kOPMonitorCodeVersion = 1
let kOPMonitorCodeDefaultDomain = "global"

@objc
open class OPMonitorCodeBase: NSObject, OPMonitorCodeProtocol {
    /// 业务域，参与ID计算
    public private(set) var domain: String

    /// 业务域内唯一编码 code，参与ID计算
    public private(set) var code: Int

    /// 唯一识别ID，格式为：{version}-{domain}-{code}
    @objc(ID)
    public private(set) var id: String

    /// 建议级别（不代表最终级别），不参与ID计算
    public private(set) var level: OPMonitorLevel

    /// 相关信息，不参与ID计算
    public private(set) var message: String

    /**
     * @param domain 业务域，参与ID计算
     * @param code 业务域内唯一编码 code，参与ID计算
     * @param level 建议级别（不代表最终级别），不参与ID计算
     * @param message 相关信息，不参与ID计算
     */
    public init(domain: String? = nil, code: Int, level: OPMonitorLevel, message: String? = nil) {
        precondition(domain != nil || message != nil)
        self.domain = domain ?? ""
        self.code = code
        self.level = level
        self.message = message ?? ""
        self.id = "\(kOPMonitorCodeVersion)-\(domain ?? "")-\(code)"
    }
}

public extension OPMonitorCodeBase {
    override var description: String {
        "\(id)-\(message)"
    }

    static func == (lhs: OPMonitorCodeBase, rhs: OPMonitorCodeBase) -> Bool {
        lhs.id == rhs.id
    }

    override var hash: Int {
        id.hashValue
    }
}
