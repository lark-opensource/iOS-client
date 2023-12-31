//
//  Error+VideoEngineExtension.swift
//  OPPlugin
//
//  Created by zhujingcheng on 2/20/23.
//

import Foundation
import TTVideoEngine

extension Error {
    func isTTVideoEngineSrcInvalid() -> Bool {
        return [-9976, -9999, -9966, -9996].contains(_code)
    }
    
    func isTTVideoEngineRequestError() -> Bool {
        return (_code >= -499899 && _code <= -499890) || _code == -5
    }
    
    func isTTVideoEngineDNSError() -> Bool {
        return _domain == kTTVideoErrorDomainLocalDNS ||
        _domain == kTTVideoErrorDomainHTTPDNS ||
        _domain == kTTVideoErrorDomainCacheDNS
    }
    
    func isTTVideoEngineError() -> Bool {
        return _domain == kTTVideoErrorDomainOwnPlayer && needRestartPlayer()
    }
    
    private func needRestartPlayer() -> Bool {
        return _code == -499999 ||
        _code == -499997 ||
        _code == -499996 ||
        _code == -499992 ||
        _code == -499991 ||
        _code == -499990 ||
        _code == -499989 ||
        _code == -0x7f7f7f7f
    }
}
