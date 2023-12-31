//
//  DocThumbnailSyncer.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/12/14.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SKInfra

public final class DocThumbnailSyncer {
    public enum DocThumbnailSyncerError: Error, Equatable {
        case announcementLLegal
        case networkError
        case other
    }
    private let fileToken: String
    private let fileType: Int?
    private var thumbnailRequest: DocsRequest<JSON>?

    private static var modelsDelayToDealloc = Set<DocThumbnailSyncer>()

    init(fileToken: String, fileType: Int? = nil) {
        self.fileToken = fileToken
        self.fileType = fileType
    }

    func requestServerGenerateThumbnail(completion: @escaping (DocThumbnailSyncerError?) -> Void) {
        spaceAssert(Thread.isMainThread)
        thumbnailRequest?.cancel()
        DocThumbnailSyncer.modelsDelayToDealloc.insert(self)
        var params: [String: Any] = ["token": fileToken]
        if let objType = fileType {
            params["obj_type"] = objType
        }
        thumbnailRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.thumbnailSync, params: params)

        thumbnailRequest?.start(result: { [weak self] (json, error) in
            guard let `self` = self else { return }
            // 去掉引用
            defer {
                self.thumbnailRequest = nil
                DocThumbnailSyncer.modelsDelayToDealloc.remove(self)
            }
            guard let result = json?["code"].int, result == 0 else {
                let info: [String: Any] = ["token": self.fileToken.encryptToken, "result": json?.rawString() ?? "null"]
                DocsLogger.error("sync thumbnail fail", extraInfo: info, error: error, component: nil)
                if let jsonResult = json?["code"].int, jsonResult == 10009 {
                    completion(.announcementLLegal)
                } else {
                    completion(.other)
                }
                return
            }
            // 群公告如果是不合规保存，则不算报错
            if error != nil {
                completion(.networkError)
            } else {
                completion(nil)
            }
            DocsLogger.info("sync thumbnail success")
        })
    }

    public class func syncDocThumbnail(objToken: String, objType: Int? = nil, completion: @escaping (Error?) -> Void) {
        spaceAssert(Thread.isMainThread)
        let model = DocThumbnailSyncer(fileToken: objToken, fileType: objType)
        model.requestServerGenerateThumbnail(completion: completion)
    }
}

extension DocThumbnailSyncer: Hashable, Equatable {
    public static func == (lhs: DocThumbnailSyncer, rhs: DocThumbnailSyncer) -> Bool {
        return lhs.fileToken == rhs.fileToken && lhs.fileType == rhs.fileType
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileToken)
    }
}
