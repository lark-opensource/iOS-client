//
//  NfcNDDFTagAdapterImp.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/10/8.
//

import CoreNFC
import Foundation
import LKCommonsLogging
/// NFC connect & close 的通用实现
@available(iOS 13.0, *)
extension NfcTagConnect where Session == NFCTagReaderSession, Tag == NFCTag {
    func connect(handler: @escaping ((Error?) -> Void)) {
        guard let session = session, session.isReady else {
            logger.error("connect tag failed. session is not ready. session\(session)")
            handler(NFCAdapterError.serviceDead)
            return
        }
        guard !tag.isAvailable else {
            logger.warn("tag already connected")
            handler(nil)
            return
        }
        session.connect(to: tag) { error in
            if let error = error {
                logger.error("connected failed. error\(error)")
            } else {
                logger.info("connected success")
            }
            handler(error)
        }
    }
    
    func close() {
        logger.info("tag close success")
    }
}
/// NDEF的通用实现
private let logger = Logger.oplog(NfcNDDFTagAdapter.self, category: "NfcTagAdapter")
@available(iOS 13.0, *)
extension NfcNDDFTagAdapter {
    func writeNDEF(records: [NFCNDEFPayload],
                   success successHandler: @escaping () -> Void,
                   failure failureHandler: @escaping (Error) -> Void) {
        guard let tag = ndefTag else {
            logger.error("writeNDEF failed: error: ndefTag is nil")
            failureHandler(NFCAdapterError.techNotSupport)
            return
        }
        guard tag.isAvailable else {
            logger.error("writeNDEF failed: error: techNotConnected")
            failureHandler(NFCAdapterError.techNotConnected)
            return
        }
        let message = NFCNDEFMessage(records: records)
        tag.writeNDEF(message) { error in
            if let error = error {
                logger.error("writeNDEF failed: error: \(error)")
                failureHandler(error)
                return
            }
            logger.info("writeNDEF success")
            successHandler()
        }
    }

    func readNDEF(success successHandler: @escaping ([NFCNDEFPayload]) -> Void,
                  failure failureHandler: @escaping (Error) -> Void) {
        guard let tag = ndefTag else {
            logger.error("writeNDEF failed: error: ndefTag is nil")
            failureHandler(NFCAdapterError.techNotSupport)
            return
        }
        guard tag.isAvailable else {
            logger.error("writeNDEF failed: error: techNotConnected")
            failureHandler(NFCAdapterError.techNotConnected)
            return
        }
        tag.readNDEF { message, error in
            if let error = error {
                logger.error("readNDEF failed: error: \(error)")
                failureHandler(error)
                return
            }
            let results = message?.records ?? []
            logger.info("readNDEF success!")
            successHandler(results)
        }
    }

    func isNDEFWritable(success successHandler: @escaping (Bool) -> Void,
                        failure failureHandler: @escaping (Error) -> Void) {
        guard let tag = ndefTag else {
            logger.error("writeNDEF failed: error: ndefTag is nil")
            failureHandler(NFCAdapterError.techNotSupport)
            return
        }
        guard tag.isAvailable else {
            logger.error("isNDEFWritable failed: error: techNotConnected")
            failureHandler(NFCAdapterError.techNotConnected)
            return
        }

        tag.queryNDEFStatus { status, _, error in
            if let error = error {
                logger.error("isNDEFWritable failed: error: \(error)")
                failureHandler(error)
                return
            }
            let result = status == .readWrite
            logger.info("isNDEFWritable success!")
            successHandler(result)
        }
    }

    func makeNDEFReadOnly(success successHandler: @escaping () -> Void,
                          failure failureHandler: @escaping (Error) -> Void) {
        guard let tag = ndefTag else {
            logger.error("writeNDEF failed: error: ndefTag is nil")
            failureHandler(NFCAdapterError.techNotSupport)
            return
        }
        guard tag.isAvailable else {
            logger.error("makeNDEFReadOnly failed: error: techNotConnected")
            failureHandler(NFCAdapterError.techNotConnected)
            return
        }
        tag.writeLock { error in
            if let error = error {
                logger.error("makeNDEFReadOnly failed: error: \(error)")
                failureHandler(error)
                return
            }
            logger.info("makeNDEFReadOnly success")
            successHandler()
        }
    }
}
