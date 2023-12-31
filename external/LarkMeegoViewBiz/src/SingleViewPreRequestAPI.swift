//
//  SingleViewPreRequestAPI.swift
//  LarkMeegoViewBiz
//
//  Created by shizhengyu on 2023/4/12.
//

import Foundation
import LarkMeegoStrategy
import LarkMeegoNetClient
import LarkContainer

struct SingleViewPreRequest: PreRequest {
    typealias ResponseType = PreRequestResponse

    let endpoint: String
    let parameters: [String: Any]

    let cacheKey: String

    init(cacheKey: String, endpoint: String, parameters: [String: Any]) {
        self.cacheKey = cacheKey
        self.endpoint = endpoint
        self.parameters = parameters
    }
}

final class SingleViewPreRequestAPI: PreRequestAPI {
    typealias T = SingleViewPreRequest

    private let dependency: ViewBizDependency
    private let userResolver: UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        dependency = try userResolver.resolve(assert: ViewBizDependency.self)
    }

    func create(by url: URL, context: PreRequestResponse?) -> SingleViewPreRequest? {
        let components = url.pathComponents
        guard components.count == 4 else {
            return nil
        }

        let simpleName = components[1]
        guard let projectKey = dependency.projectKey(by: simpleName) else {
            return nil
        }

        let viewId = components[3]
        guard !viewId.isEmpty else {
            return nil
        }

         // FG控制预请求接口
        let useNewViewApi = FeatureGating.get(by: FeatureGating.viewNewApiEnable, userResolver: userResolver)

        if useNewViewApi {
            return SingleViewPreRequest(
                cacheKey: "singleView_\(projectKey)_\(viewId)_v2",
                endpoint: "/goapi/mob/v5/search/view/filter",
                parameters: [
                    "project_key": projectKey,
                    "view_id": viewId
                ]
            )
        } else {
            return SingleViewPreRequest(
                cacheKey: "singleView_\(projectKey)_\(viewId)",
                endpoint: "/bff/v4/project/\(projectKey)/view/\(viewId)/filter",
                parameters: [:]
            )
        }
    }

    func check(with response: PreRequestResponse) -> Bool {
        return response.dataValue is [String: Any]
    }
}
