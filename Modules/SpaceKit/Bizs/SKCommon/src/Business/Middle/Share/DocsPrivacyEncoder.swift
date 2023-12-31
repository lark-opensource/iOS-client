//
//  DocsPrivacyEncryptor.swift
//  SKCommon
//
//  Created by huayufan on 2021/2/8.
//  


import Foundation
import SKFoundation
import SKInfra

public enum EncodeType {
    case shareUrl
}

public final class DocsAccountService {
    public init() {}
}

public final class DocsPrivacyEncoder {
     
    public typealias DocsPrivacyEncoderResult = (String) -> Void
    
    var resolver = DocsContainer.shared
    
    var type: EncodeType
    
    public init(_ type: EncodeType) {
        self.type = type
    }
}

extension DocsPrivacyEncoder {
    
    public func generate(origin: String, callback: @escaping DocsPrivacyEncoderResult) {
        switch type {
        case .shareUrl:
            generateUrl(urlString: origin, callback: callback)
        }
    }
}

extension DocsPrivacyEncoder {
    
    func generateUrl(urlString: String, callback: @escaping DocsPrivacyEncoderResult) {
        guard let service = HostAppBridge.shared.call(DocsAccountService()) as? DocsManagerDelegate else {
            DocsLogger.error("iPad share service is empty")
            callback(urlString)
            return
        }
        service.generatePasswordFreeLink(urlString: urlString, completion: { (result) in
            callback(result)
        })
    }
    
}
