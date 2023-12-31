//
//  Utils.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import Foundation
import LKCommonsLogging
import CryptoSwift

extension String {
    func appendPath(_ path: String, addLastSlant: Bool = false) -> String {
        var result: String
        if !path.isEmpty {
            if self.hasSuffix(Const.slant), path.hasPrefix(Const.slant) {
                result = self + path.dropFirst()
            } else if self.hasSuffix(Const.slant) {
                result = self + path
            } else if path.hasPrefix(Const.slant) {
                result = self + path
            } else {
                result = self + Const.slant + path
            }
        } else {
            result = self
        }
        if addLastSlant, !result.hasSuffix(Const.slant) {
            result += Const.slant
        }
        return result
    }
}

extension String {
    func subString(firstIndex: Int, length: Int) -> String? {
        guard firstIndex >= 0, length > 0, firstIndex + length <= self.count else {
            return nil
        }
        let firstIndex = self.index(startIndex, offsetBy: firstIndex)
        let lastIndex = self.index(firstIndex, offsetBy: length - 1)
        return String(self[firstIndex...lastIndex])
    }
}

final class Utils {

    static let logger = Logger.log(Utils.self, category: "SecurityAudit.Utils")

    enum AESOP {
        case encrypt
        case decrypt
    }

    enum AESError: Error {
        case wrongKey
    }

    static func aes(key: String, op: AESOP, data: Data, padding: CryptoSwift.Padding) throws -> Data {
        let uniqueString = key.sha256()
        let key16: String = uniqueString.subString(firstIndex: 0, length: 16) ?? ""
        guard let keyData = key16.data(using: String.Encoding.utf8) else {
            throw AESError.wrongKey
        }
        do {
            let aes = try AES(key: [UInt8](keyData), blockMode: ECB(), padding: padding)
            let bytes: [UInt8]
            switch op {
            case .encrypt:
                bytes = try aes.encrypt([UInt8](data))
            case .decrypt:
                bytes = try aes.decrypt([UInt8](data))
            }
            let outData = Data(bytes)
            return outData
        } catch {
            switch op {
            case .encrypt:
                Self.logger.error("encrypt fail len: \(data.count)", error: error)
            case .decrypt:
                Self.logger.error("decrypt fail len: \(data.count)", error: error)
            }
            throw error
        }
    }

    @inline(__always)
    static func merge(_ event: SecurityEvent_Event, _ commonEvent: SecurityEvent_Event?) throws -> SecurityEvent_Event {
        let mergedEvent: SecurityEvent_Event
        if var toMergeEvent = commonEvent {
            do {
                let partialData = try event.serializedData(partial: true)
                try toMergeEvent.merge(serializedData: partialData)
                mergedEvent = toMergeEvent
            } catch {
                assert(true, "missing required field")
                Self.logger.error("partial serializedData failed", error: error)
                throw SecurityAuditError.mergeDataFail
            }
        } else {
            mergedEvent = event
        }
        return mergedEvent
    }

#if DEBUG || ALPHA
    @inline(__always)
    static func verify(
        _ event: SecurityEvent_Event,
        _ commonEvent: SecurityEvent_Event?
    ) throws -> SecurityEvent_Event {
        let mergedEvent: SecurityEvent_Event
        if var toMergeEvent = commonEvent {
            do {
                let partialData = try event.serializedData(partial: true)
                try toMergeEvent.merge(serializedData: partialData, partial: true)
                mergedEvent = toMergeEvent
            } catch {
                assert(true, "missing required field")
                Self.logger.error("partial serializedData failed", error: error)
                throw SecurityAuditError.mergeDataFail
            }
        } else {
            mergedEvent = event
        }
        let result = mergedEvent.verify()
        switch result {
        case .success:
            if !mergedEvent.isInitialized {
                throw SecurityEvent_Event.FieldMissError.missUnknown
            }
        case .failure(let error):
            throw error
        }
        return mergedEvent
    }
#endif
}

#if DEBUG || ALPHA
extension SecurityEvent_Event {
    enum FieldMissError: Error {
        case missModule
        case missOperation
        case missTimestamp
        case missOperator
        case operatorContentMissField
        case recipientContentMiss(index: Int)
        case objectsContentMiss(index: Int)
        case missObjects
        case missUnknown
    }

    func verify() -> Result<Void, FieldMissError> {
        if !self.hasModule {
            return .failure(.missModule)
        }
        if !self.hasOperation {
            return .failure(.missOperation)
        }
        if !self.hasTimeStamp {
            return .failure(.missTimestamp)
        }
        //  客户端必须要有operator
        if !self.hasOperator {
            return .failure(.missOperator)
        } else if !self.operator.isInitialized {
            return .failure(.operatorContentMissField)
        }
        if !self.recipients.isEmpty {
            for args in self.recipients.enumerated() where !args.element.isInitialized {
                return .failure(.recipientContentMiss(index: args.offset))
            }
        }
        if !self.objects.isEmpty {
            for args in self.objects.enumerated() where !args.element.isInitialized {
                return .failure(.objectsContentMiss(index: args.offset))
            }
        } else {
            // 至少需要一个objects
            return .failure(.missObjects)
        }
        return .success(())
    }
}
#endif
