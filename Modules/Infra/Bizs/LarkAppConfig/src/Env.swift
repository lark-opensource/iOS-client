//
//  Env.swift
//  LarkAppConfig
//
//  Created by quyiming on 2020/5/28.
//
// doc: https://bytedance.feishu.cn/docs/doccnH3rtofqXlwYfwh9hTLtKRu#rBHTs5
import Foundation
import LarkEnv
import RustPB

//// swiftlint:disable missing_docs
extension Env.TypeEnum {
    public func transform() -> Basic_V1_InitSDKRequest.EnvV2.TypeEnum {
        switch self {
        case .release:
            return .release
        case .staging:
            return .staging
        case .preRelease:
            return .preRelease
        @unknown default:
            assertionFailure("should not come here")
            return .release
        }
    }
}
//
// extension Env {
//    public func transformToEnvV2() -> Basic_V1_InitSDKRequest.EnvV2 {
//        var env = Basic_V1_InitSDKRequest.EnvV2()
//        env.unit = unit
//        env.type = type.transform()
//        return env
//    }
//
//    static func transform(from envType: EnvType) -> Env {
//        switch envType {
//        case .online:
//            return .online
//        case .staging:
//            return .staging
//        case .preRelease:
//            return .preRelease
//        case .oversea:
//            return .oversea
//        case .overseaStaging:
//            return .overseaStaging
//        @unknown default:
//            assert(false, "new value")
//            return .online
//        }
//    }
//
//    @available(*, deprecated, message: "Will remove after envType not use.")
//    public func transformToEnvType(_ isStdLark: Bool) -> EnvType {
//        switch type {
//        case .release:
//            if isStdLark {
//                return .oversea
//            } else {
//                return .online
//            }
//        case .preRelease:
//            if isStdLark {
//                return .oversea
//            } else {
//                return .preRelease
//            }
//        case .staging:
//            if isStdLark {
//                return .overseaStaging
//            } else {
//                return .staging
//            }
//        @unknown default:
//            assertionFailure("should not come here")
//            return .online
//        }
//    }
//
// }

// swiftlint:enable missing_docs
