//
//  DetailPreRequestAPI.swift
//  LarkMeegoWorkItemBiz
//
//  Created by shizhengyu on 2023/4/12.
//

import Foundation
import LarkMeegoStrategy
import LarkMeegoNetClient
import LarkContainer

struct DetailPreRequest: PreRequest {
    typealias ResponseType = PreRequestResponse

    let endpoint: String
    let parameters: [String: Any] = [:]

    let cacheKey: String

    init(cacheKey: String, endpoint: String) {
        self.cacheKey = cacheKey
        self.endpoint = endpoint
    }
}

final class DetailPreRequestAPI: PreRequestAPI {
    typealias T = DetailPreRequest

    private let dependency: WorkItemBizDependency

    init(userResolver: UserResolver) throws {
        dependency = try userResolver.resolve(assert: WorkItemBizDependency.self)
    }

    func create(by url: URL, context: PreRequestResponse?) -> DetailPreRequest? {
        let components = url.pathComponents
        guard components.count == 5 else {
            return nil
        }

        let simpleName = components[1]
        guard let projectKey = dependency.projectKey(by: simpleName) else {
            return nil
        }

        let workItemType = components[2]
        let workItemId = components[4]
        guard !workItemType.isEmpty && !workItemId.isEmpty else {
            return nil
        }

        return DetailPreRequest(
            cacheKey: "detail_\(projectKey)_\(workItemType)_\(workItemId)_detail",
            endpoint: "/bff/v4/project/\(projectKey)/work_item_type/\(workItemType)/work_item/\(workItemId)"
        )
    }

    func check(with response: PreRequestResponse) -> Bool {
        return response.dataValue is [String: Any]
    }
}
