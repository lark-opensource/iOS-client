//
//  DocsInfoDetailUpdater.swift
//  SKCommon
//
//  Created by Weston Wu on 2020/9/20.
//

import Foundation
import RxSwift
import SKFoundation
import SwiftyJSON

public protocol DocsInfoDetailUpdater {
    var isRequesting: Bool { get }
    func updateDetail(for: DocsInfo, headers: [String: String]) -> Single<Void>
}

public extension DocsInfoDetailUpdater {
    func updateDetail(for docsInfo: DocsInfo) -> Single<Void> {
        updateDetail(for: docsInfo, headers: SpaceHttpHeaders.common)
    }
}

public final class DefaultDocsInfoDetailUpdater: DocsInfoDetailUpdater {

    private(set) public var isRequesting: Bool = false

    public init() {
    }

    public func updateDetail(for docsInfo: DocsInfo, headers: [String: String] = SpaceHttpHeaders.common) -> Single<Void> {
        guard !isRequesting else {
            spaceAssertionFailure("another update request is in progress, check isRequesting flag before calling this method")
            return .error(DocsInfoDetailError.redundantRequest)
        }
        isRequesting = true
        let fetchDetail = DocsInfoDetailHelper.fetchDetail(token: docsInfo.urlToken, type: docsInfo.urlType, headers: headers)
            .map { (type, detailData) -> Void in
                guard !type.isUnknownType else {
                    throw DocsInfoDetailError.typeUnsupport
                }
                DocsInfoDetailHelper.update(docsInfo: docsInfo, detailInfo: detailData, needUpdateStar: true)
            }

        let updateOwnerType = DocsInfoDetailHelper.fetchEntityInfo(objToken: docsInfo.objToken, objType: docsInfo.type)
        return Single.zip(fetchDetail, updateOwnerType)
            .do(onDispose: { [weak self] in
                self?.isRequesting = false
            })
                .map { (_, ownerType) -> Void in
                    docsInfo.ownerType = ownerType
                }
    }
}
