//
//  Header.swift
//  FileCryptoDemo
//
//  Created by qingchun on 2023/2/22.
//

import Foundation

public struct AESHeader {

    public static let size: UInt64 = 96

    public enum Section: Int, CaseIterable {
        case magic1
        case dataOffset
        case nonce
        case keyHasher // key, uid, did, nonce
        case gapZero
        case magic2
        case uid
        case did
        case version
        case reserved
    }

    public struct KeyHasher {
        let value: [UInt8]
        let uid, did, nonce: [UInt8]
        let key: Data

        public init(key: Data, uid: [UInt8], did: [UInt8], nonce: [UInt8]) {
            self.key = key
            self.uid = uid
            self.did = did
            self.nonce = nonce

            var targetData = [UInt8]() // key, uid, did, nonce
            targetData.append(contentsOf: key.bytes)
            targetData.append(contentsOf: uid)
            targetData.append(contentsOf: did)
            targetData.append(contentsOf: nonce)
            self.value = Array(targetData.sha256().prefix(upTo: 16))
        }
    }

    public private(set) var values: [Section: Data] = [:]
    
    /// 根据HeaderData解析出Header，以供解密使用
    public init(data: Data) throws {
        let count = Section.allCases.reduce(0, { $0 + $1.count })
        guard data.count >= count else { throw AESError.isNotCrypto }
        var offset = 0
        Section.allCases.forEach { type in
            let start = offset
            let end = offset + type.count
            let itemData = data.subdata(in: start ..< end)
            values[type] = itemData
            offset += type.count
        }
    }

    /// 通过key+uid+did构造出header，以供加密使用
    public init(key: Data, uid: Int64, did: Int64) {
        values[.magic1] = AESFileKind.v1.magic.data
        values[.dataOffset] = withUnsafeBytes(of: UInt32(Self.size), { Data($0) })
        values[.magic2] = AESFileKind.v2.magic.data
        let nonce = Self.randomNonce()
        values[.nonce] = nonce.data
        let uidData = withUnsafeBytes(of: uid.littleEndian) { Data($0) }
        let didData = withUnsafeBytes(of: did.littleEndian) { Data($0) }
        let keyHasher = KeyHasher(key: key, uid: uidData.bytes, did: didData.bytes, nonce: nonce)
        values[.uid] = uidData
        values[.did] = didData
        values[.keyHasher] = keyHasher.value.data
        values[.version] = [AESFileKind.v2.rawValue].data
        values[.gapZero] = Array(repeating: UInt8(0), count: 12).data
        values[.reserved] = Array(repeating: UInt8(0), count: 15).data
    }
}

extension AESHeader {
    func calculateKeyHasher(_ deviceKey: Data) -> [UInt8] {
        let hasher = KeyHasher(key: deviceKey,
                               uid: values[.uid]?.bytes ?? [],
                               did: values[.did]?.bytes ?? [],
                               nonce: values[.nonce]?.bytes ?? [])
        return hasher.value
    }

    var data: Data {
        let count = Section.allCases
        var result = Data()
        count.forEach {
            guard let data = values[$0] else { return }
            result.append(data.bytes, count: $0.count)
        }
        return result
    }
}

extension AESHeader.Section {
    var count: Int {
        switch self {
        case .magic1: return 8
        case .dataOffset: return 4 // MemoryLayout<UInt32>.size
        case .nonce: return 16
        case .keyHasher: return 16
        case .gapZero: return 12
        case .magic2: return 8
        case .uid: return 8 // MemoryLayout<UInt64>.size
        case .did: return 8 // MemoryLayout<UInt64>.size
        case .version: return 1
        case .reserved: return 15
        }
    }
}

extension AESHeader {
    static func randomNonce() -> [UInt8] {
        var result: [UInt8] = Array(repeating: 0, count: 16)
        result.enumerated().forEach { each in
            result[each.offset] = UInt8.random(in: 0 ..< UInt8.max)
        }
        return result
    }
}

extension AESHeader {
    
    enum CheckError: Error {
        case didNotMatched(did: Int64)
        case magicNotMatch
        case uidNotMatch
        case keyHasherNotMatch
        case nonceNotMatch
        case notV2Cryptor
    }
    /// 根据文件路径，解析出来header信息
    /// - Parameter filePath: 文件路径
    init(filePath: String) throws {
        let fileHandle = try SCFileHandle(path: filePath, option: .read)
        guard let headerData = try fileHandle.read(upToCount: Int(AESHeader.size)) else {
            try fileHandle.close()
            throw AESError.isNotCrypto
        }
        try fileHandle.close()
        try self.init(data: headerData)
    }
    
    func checkV2Header(did: String, uid: String, deviceKey: Data) throws {
        let magicChecked = values[.magic1]?.bytes == AESFileKind.v1.magic
        && values[.magic2]?.bytes == AESFileKind.v2.magic
        if !magicChecked {
            throw CheckError.magicNotMatch
        }
        if let headerUid: Int64 = values[.uid]?.convertToInteger(), "\(headerUid)" != uid {
            throw CheckError.uidNotMatch
        }
        
        guard let nonceBytes = values[.nonce]?.bytes else {
            throw CheckError.nonceNotMatch
        }
        
        let uidInt = Int64(uid) ?? 0
        let didInt = Int64(did) ?? 0
        let uidData = withUnsafeBytes(of: uidInt) { Data($0) }
        let didData = withUnsafeBytes(of: didInt) { Data($0) }
        let keyHasher = KeyHasher(key: deviceKey, uid: uidData.bytes, did: didData.bytes, nonce: nonceBytes)
       
        if keyHasher.value != values[.keyHasher]?.bytes {
            throw CheckError.keyHasherNotMatch
        }
        
        if let ver: UInt8 = values[.version]?.convertToInteger(), ver != AESFileKind.v2.rawValue {
            throw CheckError.notV2Cryptor
        }
        
        if let headerDid: Int64 = values[.did]?.convertToInteger(), "\(headerDid)" != did {
            throw CheckError.didNotMatched(did: headerDid)
        }
    }
}

extension AESHeader {
    public func checkEncrypted() -> Bool {
        return encryptVersion() != .regular
    }
    
    public func encryptVersion() -> AESFileKind {
        let magicChecked = values[.magic1]?.bytes == AESFileKind.v1.magic
        && values[.magic2]?.bytes == AESFileKind.v2.magic
        if magicChecked, let versionD = values[.version] {
            let version: UInt8 = versionD.convertToInteger()
            return AESFileKind(rawValue: version) ?? .regular
        }
        return .regular
    }
}
