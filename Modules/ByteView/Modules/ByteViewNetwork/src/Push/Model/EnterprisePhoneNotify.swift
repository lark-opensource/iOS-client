//
//  E.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - NOTIFY_ENTERPRISE_PHONE = 89452
/// - ServerPB_Videochat_EnterprisePhoneNotify
public struct EnterprisePhoneNotify {

    public var enterprisePhoneID: String

    public var action: Action

    public var callerUnreachedToastData: CallExceptionNotice

    public enum Action: Int, Hashable {
        case callerRinging // = 0
        case callExceptionToastCallerUnreached // = 1
        case callEnd // = 2
    }

    public struct CallExceptionNotice: Equatable {
        public var key: String
    }
}

extension EnterprisePhoneNotify: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = ServerPB_Videochat_EnterprisePhoneNotify
    init(pb: ServerPB_Videochat_EnterprisePhoneNotify) {
        self.enterprisePhoneID = pb.enterprisePhoneID
        self.action = .init(rawValue: pb.action.rawValue) ?? .callerRinging
        self.callerUnreachedToastData = CallExceptionNotice(key: pb.callerUnreachedToastData.key)
    }
}

extension EnterprisePhoneNotify: CustomStringConvertible {
    public var description: String {
        String(indent: "EnterprisePhoneNotify", "phoneId: \(enterprisePhoneID), action: \(action), unreachedToast: \(callerUnreachedToastData.key)")
    }
}
