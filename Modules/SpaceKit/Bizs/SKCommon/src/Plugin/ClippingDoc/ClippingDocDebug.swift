//
//  ClippingDocDebug.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/28.
//  


import Foundation
import SKFoundation
import SKInfra

#if DEBUG
class ClippingDocDebug {

    static let key = "clipping.doc.js.locol.file"
    
    static func save(_ url: URL) {
        CCMKeyValue.globalUserDefault.set(url.absoluteString, forKey: key)
    }
    
    static var url: URL? {
        guard CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.localFileValue) else {
            return nil
        }
        guard let urlString = CCMKeyValue.globalUserDefault.string(forKey: key),
              let fileUrl = URL(string: urlString) else {
            return nil
        }
        return fileUrl
    }
}
#endif
