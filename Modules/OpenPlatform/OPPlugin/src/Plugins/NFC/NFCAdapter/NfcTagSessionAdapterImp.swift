//
//  NfcTagSessionAdapterImp.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/29.
//

import CoreNFC
import LKCommonsLogging
///检测到的Tag 实现
struct DetectedTagImp: DetectedTag {
    var techs: [NfcTechnology] { Array(tagAdapters.keys) }
    fileprivate(set) var identifier: Data?
    fileprivate(set) var tagAdapters: [NfcTechnology: any NfcTagAdapter]
}
/// NFCTagReaderSession 的 NfcTagSessionAdapter 实现。 
@available(iOS 13.0, *)
final class NfcTagSessionAdapter: NSObject, NfcSessionAdapter, NFCTagReaderSessionDelegate {
    private static let logger = Logger.oplog(NfcTagSessionAdapter.self, category: "NfcTagAdapter")
   
    weak var delegate: NfcSessionAdapterDelegate?
    /// 为什么设置为weak 经过测试
    var readerSession: NFCTagReaderSession?
    private var detectedTag: DetectedTagImp?
    func startPolling() throws {
        Self.logger.info("startPolling hasOldSession:\(readerSession != nil), isReady:\(readerSession?.isReady)")
        /// session 存在意味着 session 还可用
        if readerSession != nil {
            throw NFCAdapterError.isDiscovering
        }
        readerSession?.invalidate()
        readerSession = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: DispatchQueue.main)
        readerSession?.begin()
    }
    
    func stopPolling() throws {
        Self.logger.info("stopPolling")
        readerSession?.invalidate()
    }
    
    func getTag(tech: NfcTechnology) throws -> any NfcTagAdapter {
        Self.logger.info("getTag techType:\(tech) ")
        guard readerSession?.isReady == true else {
            throw NFCAdapterError.serviceDead
        }
        guard let tag = detectedTag?.tagAdapters[tech] else {
            throw NFCAdapterError.techNotDiscovered
        }
        return tag
    
    }

    // MARK: - NFCTagReaderSessionDelegate
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        Self.logger.info("tagReaderSession, become active")
        if let currentSession = readerSession, session === currentSession {
            delegate?.nfcSeessionAdapterDidBecomeActive(self)
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Self.logger.warn("tagReaderSession did invalidate error:\(error)")
        if let currentSession = readerSession, session === currentSession {
            readerSession = nil
            delegate?.nfcSessionAdapter(self, didInvalidateWithError: error)
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Self.logger.info("tagReaderSession, detect tags:\(tags)")
        let detectedTag = tags.reduce(into: DetectedTagImp(identifier: nil, tagAdapters: [:])) { partialResult, tag in
            switch tag {
            case .feliCa(let aTag):
                break
            case .iso15693(let aTag):
                partialResult.identifier = aTag.identifier
                break
            case .miFare(let aTag):
                partialResult.identifier = aTag.identifier
                switch aTag.mifareFamily {
                case .unknown:
                    break
                case .ultralight:
                    let adapter = NfcATagMiFareAdapter(session: session, tag: tag)
                    partialResult.tagAdapters[.nfcA] = adapter
//                    partialResult.tagAdapters[.ndef] = adapter
                
                case .plus:
                    let adapter = NfcATagMiFareAdapter(session: session, tag: tag)
                    partialResult.tagAdapters[.nfcA] = adapter
//                    partialResult.tagAdapters[.ndef] = adapter
                case .desfire:
                    let adapter = NfcATagMiFareAdapter(session: session, tag: tag)
                    partialResult.tagAdapters[.nfcA] = adapter
//                    partialResult.tagAdapters[.ndef] = adapter
                }
            case .iso7816(let aTag):
                partialResult.identifier = aTag.identifier
                let adapter = NfcATagMiFareAdapter(session: session, tag: tag)
                partialResult.tagAdapters[.nfcA] = adapter
//                partialResult.tagAdapters[.ndef] = adapter
            }
        }
        self.detectedTag = detectedTag
        Self.logger.info("tagReaderSession detect tags:\(tags) transform to \(detectedTag)")
        delegate?.nfcSessionAdapter(self, didDetectTag: detectedTag)
    }

    
    deinit {
        readerSession?.invalidate()
    }
}
