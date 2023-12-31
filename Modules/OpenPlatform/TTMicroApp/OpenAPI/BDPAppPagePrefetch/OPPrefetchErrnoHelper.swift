//
//  OPPrefetchErrnoHelper.swift
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/8/29.
//

import Foundation
import LarkOpenAPIModel

@objc public final class OPPrefetchErrnoWrapper: NSObject {
    public let errno: OpenAPIErrnoProtocol

    @objc
    public var errnoValue: Int {
        return errno.errno()
    }

    @objc
    public var errString: String {
        return errno.errString
    }

    init(_ errno: OpenAPIErrnoProtocol) {
        self.errno = errno
    }
}

@objcMembers
public final class OPPrefetchErrnoHelper: NSObject {
    @objc public static func max(errnoWapper: OPPrefetchErrnoWrapper, otherErrnoWrapper: OPPrefetchErrnoWrapper) -> OPPrefetchErrnoWrapper {
        if errnoWapper.errno.rawValue >= otherErrnoWrapper.errno.rawValue {
            return errnoWapper
        }
        return otherErrnoWrapper
    }

    @objc public static func noPrefetch() -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.noPrefetch)
    }

    @objc public static func hostMismatch(url: String, cacheUrlList: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.hostMismatch(url: url, cacheUrlList: cacheUrlList))
    }

    @objc public static func pathMismatch(url: String, cacheUrlList: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.pathMismatch(url: url, cacheUrlList: cacheUrlList))
    }

    @objc public static func queryMismatch(url: String, cacheUrlList: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.queryMismatch(url: url, cacheUrlList: cacheUrlList))
    }

    @objc public static func urlNormalMismatch(url: String, cacheUrlList: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.urlNormalMismatch(url: url, cacheUrlList: cacheUrlList))
    }

    @objc public static func methodMismatch(method: String, cacheMethod: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.methodMismatch(method: method, cacheMethod: cacheMethod))
    }

    @objc public static func headerMismatch(header: String, cacheHeader: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.headerMismatch(header: header, cacheHeader: cacheHeader))
    }

    @objc public static func responseTypeMismatch(responseType: String, cacheResponseType: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.responseTypeMismatch(responseType: responseType, cacheResponseType: cacheResponseType))
    }

    @objc public static func dataMismatch(data: String, cacheData: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.dataMismatch(data: data, cacheData: cacheData))
    }

    @objc public static func prefetchRequestFailed() -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.prefetchRequestFailed)
    }

    @objc public static func prefetchExceedLimit(limit: Int) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.prefetchExceedLimit(limit: "\(limit)"))
    }

    @objc public static func prefetchUnknown() -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPICommonErrno.unknown)
    }

    @objc public static func prefetchSuccess() -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPICommonErrno.ok)
    }

    @objc public static func prefetchNoSend(keyName: String) -> OPPrefetchErrnoWrapper {
        return OPPrefetchErrnoWrapper(OpenAPINetworkPrefetchErrno.prefetchNoSend(keyName: keyName))
    }
}
