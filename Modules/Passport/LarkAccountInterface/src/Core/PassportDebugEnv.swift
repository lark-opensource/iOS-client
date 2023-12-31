//
//  PassportDebugEnv.swift
//  LarkAccountInterface
//
//  Created by qihongye on 2023/11/9.
//

import Foundation

public struct PassportDebugEnv {
    private static let featureEnvKey = "x-tt-env"
    public static var xttEnv = UserDefaults.standard.string(forKey: featureEnvKey) ?? "" {
        didSet { UserDefaults.standard.set(xttEnv, forKey: featureEnvKey) }
    }

    /// 实际看应该没用了，这里直接返回 "" 了，不去UserDefault记录了。
    private static let BOEFdKey = "BOEFdKey"
    public static var BOEFd = ""

    private static let stressKey = "stress-tag"
    public static var stressTag = UserDefaults.standard.string(forKey: stressKey) ?? "" {
        didSet { UserDefaults.standard.set(stressTag, forKey: stressKey) }
    }

    private static let fdKey = "pre_rpc_persist_dyecp_fd_mock_value"
    public static var preReleaseFd = UserDefaults.standard.string(forKey: fdKey) ?? "" {
        didSet { UserDefaults.standard.set(preReleaseFd, forKey: fdKey) }
    }

    private static let mockTagKey = "pre_rpc_persist_mock_tag_value"
    public static var mockTag = UserDefaults.standard.string(forKey: mockTagKey) ?? "" {
        didSet { UserDefaults.standard.set(mockTag, forKey: mockTagKey) }
    }

    /// 切换机房的信息
    // lint:disable lark_storage_check
    private static let idcFlowControlValueKey = "IdcFlowControlValueKey"
    public static var idcFlowControlValue: String {
        get {
            return UserDefaults.standard.string(forKey: idcFlowControlValueKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: idcFlowControlValueKey)
        }
    }
    // lint:enable lark_storage_check
}
