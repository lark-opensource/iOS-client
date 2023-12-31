//
//  E2EEKeyParameter.swift
//  ByteViewNetwork
//
//  Created by ZhangJi on 2023/4/13.
//

import Foundation
import RustPB
import ServerPB

typealias PBE2EEKeyParameter = Videoconference_V1_E2EEKeyParameter
typealias ServerPBE2EEKeyParameter = ServerPB_Videochat_E2EEKeyParameter

// Videoconference_V1_E2EEKeyParameter
public struct E2EEKeyParameter {
    // 公钥
    public var pk: Data?
    // 临时公钥
    public var epk: Data?
}

extension E2EEKeyParameter {
    var pbType: PBE2EEKeyParameter {
        var keyParameter = PBE2EEKeyParameter()
        keyParameter.pk = pk ?? Data()
        keyParameter.epk = epk ?? Data()
        return keyParameter
    }
}

extension PBE2EEKeyParameter {
    var vcType: E2EEKeyParameter {
        return E2EEKeyParameter(pk: hasPk ? pk : nil,
                                epk: hasEpk ? epk : nil)
    }
}

extension ServerPBE2EEKeyParameter {
    var vcType: E2EEKeyParameter {
        return E2EEKeyParameter(pk: hasPk ? pk : nil,
                                epk: hasEpk ? epk : nil)
    }
}
