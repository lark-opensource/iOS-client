//
//  NfcSessionUnavailableAdapter.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/29.
//

import CoreNFC
import LKCommonsLogging
/// 不支持NFC 设备的默认实现
final class NfcSessionUnavailableAdapter: NfcSessionAdapter {
    private static let logger = Logger.oplog(NfcSessionUnavailableAdapter.self, category: "NfcTagAdapter")

    weak var delegate: NfcSessionAdapterDelegate?
    func startPolling() throws {
        throw NFCAdapterError.notAvailable
    }
    
    func stopPolling() throws {
        throw NFCAdapterError.notAvailable
    }
    
    func getTag(tech: NfcTechnology) throws -> any NfcTagAdapter {
        throw NFCAdapterError.notAvailable
    }
    
}
