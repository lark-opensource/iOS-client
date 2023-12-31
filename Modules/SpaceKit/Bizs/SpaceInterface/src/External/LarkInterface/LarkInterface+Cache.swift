//
//  LarkInterface+Cache.swift
//  SpaceInterface
//
//  Created by liweiye on 2019/12/24.
//

import Foundation
import RxSwift

public protocol DocsUserCacheServiceProtocol {
    func calculateCacheSize() -> Observable<Float>
    func clearCache() -> Observable<Void>
}

public protocol SpaceDownloadCacheProtocol: AnyObject {
    func data(key: String, type: DocCommonDownloadType) -> Data?
    func dataWithVersion(key: String, type: DocCommonDownloadType, dataVersion: String?) -> Data?
    func save(request: DocCommonDownloadRequestContext, completion: ((_ success: Bool) -> Void)?)

    func addImagesToManualCache(infos: [(String, DocCommonDownloadType)])
    func removeImagesFromManualCache(infos: [(String, DocCommonDownloadType)])
}
