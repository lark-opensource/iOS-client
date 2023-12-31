//
//  NFCAdapter.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/28.
//

import CoreNFC
/// NfcSessionAdapter 工厂
struct NfcSessionAdapterFactory {
    static var defaultSessionAdapter: NfcSessionAdapter {
        let result: NfcSessionAdapter
        if #available(iOS 13.0, *), NFCReaderSession.readingAvailable {
            result = NfcTagSessionAdapter()
        } else {
            result = NfcSessionUnavailableAdapter()
        }
        return result
    }
}



