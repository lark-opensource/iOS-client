//
//  SpaceNetWorkAPI.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/19.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra


public enum SpaceNetworkAPI {}

extension SpaceNetworkAPI {
    // TODO: 考虑是否可以和 rename 合并
    @available(*, deprecated, message: "Space opt: Space do not specialize the logic for the sheet, you need the sheet to implement it yourself")
    public static func renameSheet(objToken: String, with newName: String) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.renameSheet,
                                        params: ["token": objToken, "title": newName])
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                throw error
            }
            return .empty()
        }
    }

    @available(*, deprecated, message: "Space opt: Space do not specialize the logic for the bitable, you need the bitable to implement it yourself")
    public static func renameBitable(objToken: String, with newName: String) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.renameBitable,
                                        params: ["token": objToken, "title": newName])
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                throw error
            }
            return .empty()
        }
    }
    
    public static func renameSlides(objToken: String, with newName: String) -> Completable {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.renameSlides,
                                        params: ["token": objToken, "title": newName, "type": DocsType.slides.rawValue])
        return request.rxStart().flatMapCompletable { json in
            let code = json?["code"].int
            if let error = DocsNetworkError(code) {
                throw error
            }
            return .empty()
        }
    }
    
}
