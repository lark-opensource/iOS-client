//   
//  KVMigration+Crypto.swift
//  LarkStorage
//
//  Created by 李昊哲 on 2023/2/28.
//  

import Foundation

extension KVStore {
    
    private func findComponents() -> (KVStoreBase, KVStoreRekeyProxy, KVStoreCryptoProxy)? {
        var rekeyProxy: KVStoreRekeyProxy?
        var cryptoProxy: KVStoreCryptoProxy?

        let (base, proxies) = allComponents()

        for proxy in proxies {
            if let proxy = proxy as? KVStoreRekeyProxy {
                rekeyProxy = proxy
            } else if let proxy = proxy as? KVStoreCryptoProxy {
                cryptoProxy = proxy
            }
        }

        if let base, let rekeyProxy, let cryptoProxy {
            return (base, rekeyProxy, cryptoProxy)
        }

        return nil
    }

    // 直接写入未经加密的原始数据，用于迁移加密数据时平移 Data
    internal func setRaw(data: Data, forKey key: String, oldCipher: KVCipher) {
        guard let (base, rekeyProxy, cryptoProxy) = findComponents() else {
            KVStores.assert(false, "", event: .migration)
            return
        }
        let encodedKey = rekeyProxy.encodedKey(from: key)
        let hashedKey = cryptoProxy.cipher.hashed(forKey: encodedKey)
        // Compare cipher with pointer.
        if oldCipher === cryptoProxy.cipher {
            // Previous execution path.
            base.set(data, forKey: hashedKey)
        } else {
            var newData: Data? = nil
            do {
                newData = try cryptoProxy.cipher.encrypt(oldCipher.decrypt(data))
            } catch {
                KVStores.assert(false, "Migrate data failed. Error: \(error)", event: .migration)
            }

            if let newData {
                base.set(newData, forKey: hashedKey)
            }
        }
    }

    // 直接读取未经加密的原始数据，用于回写 Data 到加密迁移源中
    internal func rawData(forKey key: String, oldCipher: KVCipher) -> Data? {
        guard let (base, rekeyProxy, cryptoProxy) = findComponents() else {
            return nil
        }
        let encodedKey = rekeyProxy.encodedKey(from: key)
        let hashedKey = cryptoProxy.cipher.hashed(forKey: encodedKey)
        let data = base.data(forKey: hashedKey)
        // Compare cipher with pointer.
        // Decryption and encryption process will happen when the new storage raw data is not empty.
        if cryptoProxy.cipher !== oldCipher, let data {
            var newData: Data? = nil
            do {
                newData = try oldCipher.encrypt(cryptoProxy.cipher.decrypt(data))
            } catch {
                KVStores.assert(false, "Double write data failed. Error: \(error)", event: .migration)
            }

            return newData
        } else {
            // Previous execution path.
            return data
        }
    }

}
