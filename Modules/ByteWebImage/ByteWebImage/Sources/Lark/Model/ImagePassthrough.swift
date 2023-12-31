//
//  ImagePassthrough.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/8/2.
//

import Foundation
import LarkCache
import RustPB
import ServerPB

// swiftlint:disable identifier_name

public struct ImagePassThrough {

    public struct SerCrypto {

        public enum TypeEnum: Int {
        case UNKNOWN = 0
        case AES_256_GCM = 1
        case AES_CTR = 2
        case CRYPTO_SDK_UNIFIED = 3
        case CRYPTO_SDK_DOWNGRADE = 4
        case CRYPTO_SDK_THIRDPARTY = 5
        case SM4_128 = 6
        }

        public struct Cipher {
            public var secret: Data?
            public var nonce: Data?
            public var additionalData: Data?

            public init() { }
        }

        public var type: TypeEnum?
        public var cipher: Cipher?

        public init() { }
    }

    public enum FileType: Int {
        case profileTopImage = 1
        case urlPreviewInlineIcon = 2
    }

    public var key: String?
    public var fsUnit: String?
    public var crypto: SerCrypto?
    public var fileType: FileType?

    public init() { }
}

public extension ImagePassThrough {
    static func transform(passthrough: RustPB.Basic_V1_ImageSetPassThrough) -> ImagePassThrough {
        var pass = ImagePassThrough()
        if passthrough.hasFsUnit {
            pass.fsUnit = passthrough.fsUnit
        }
        if passthrough.hasKey {
            pass.key = passthrough.key
        }
        if passthrough.hasCrypto {
            var crypto = ImagePassThrough.SerCrypto()
            if passthrough.crypto.hasType {
                crypto.type = SerCrypto.TypeEnum(rawValue: passthrough.crypto.type.rawValue)
            }
            if passthrough.crypto.hasCipher {
                var cipher = SerCrypto.Cipher()
                let originCipher = passthrough.crypto.cipher
                if originCipher.hasSecret { cipher.secret = originCipher.secret }
                if originCipher.hasNonce { cipher.nonce = originCipher.nonce }
                if originCipher.hasAdditionalData { cipher.additionalData = originCipher.additionalData }
                crypto.cipher = cipher
            }
            pass.crypto = crypto
        }
        return pass
    }
}


public extension RustPB.Basic_V1_ImageSetPassThrough {
    static func transform(pass: ImagePassThrough) -> RustPB.Basic_V1_ImageSetPassThrough {
        var passThrough = Basic_V1_ImageSetPassThrough()
        if let key = pass.key {
            passThrough.key = key
        }
        if let fsUnit = pass.fsUnit {
            passThrough.fsUnit = fsUnit
        }
        if let passCrypto = pass.crypto {
            var crypto = Basic_V1_SerCrypto()
            if let passCryptoType = passCrypto.type,
               let cryptoType = Basic_V1_SerCrypto.TypeEnum(rawValue: passCryptoType.rawValue) {
                crypto.type = cryptoType
            }
            if let passCryptoCipher = passCrypto.cipher {
                var cipher = Basic_V1_Cipher()
                if let secret = passCryptoCipher.secret { cipher.secret = secret }
                if let nonce = passCryptoCipher.nonce { cipher.nonce = nonce }
                if let additionalData = passCryptoCipher.additionalData { cipher.additionalData = additionalData }
                crypto.cipher = cipher
            }
            passThrough.crypto = crypto
        }
        if let passFileType = pass.fileType,
           let fileType = Basic_V1_ImageSetPassThrough.FileType(rawValue: passFileType.rawValue) {
            passThrough.fileType = fileType
        }
        return passThrough
    }
}

public extension ImagePassThrough {
    static func transform(passthrough: ServerPB_Entities_ImageSetPassThrough) -> ImagePassThrough {
            var pass = ImagePassThrough()
            if passthrough.hasFsUnit {
                pass.fsUnit = passthrough.fsUnit
            }
            if passthrough.hasKey {
                pass.key = passthrough.key
            }
            if passthrough.hasCrypto {
                var crypto = ImagePassThrough.SerCrypto()
                if passthrough.crypto.hasType {
                    crypto.type = SerCrypto.TypeEnum(rawValue: passthrough.crypto.type.rawValue)
                }
                if passthrough.crypto.hasCipher {
                    var cipher = SerCrypto.Cipher()
                    let originCipher = passthrough.crypto.cipher
                    if originCipher.hasSecret { cipher.secret = originCipher.secret }
                    if originCipher.hasNonce { cipher.nonce = originCipher.nonce }
                    if originCipher.hasAdditionalData { cipher.additionalData = originCipher.additionalData }
                    crypto.cipher = cipher
                }
                pass.crypto = crypto
            }
            return pass
        }
}
