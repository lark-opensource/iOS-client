//
//  WorkflowPreRequestAPI.swift
//  LarkMeegoWorkItemBiz
//
//  Created by shizhengyu on 2023/4/12.
//

import Foundation
import LarkMeegoStrategy
import LarkMeegoNetClient
import LarkContainer
import LarkLocalizations

struct WorkflowPreRequest: PreRequest {
    typealias ResponseType = PreRequestResponse

    let endpoint: String
    let parameters: [String: Any]

    let cacheKey: String

    var method: RequestMethod {
        return .put
    }

    init(cacheKey: String, endpoint: String, parameters: [String: Any]) {
        self.cacheKey = cacheKey
        self.endpoint = endpoint
        self.parameters = parameters
    }
}

final class WorkflowPreRequestAPI: PreRequestAPI {
    typealias T = WorkflowPreRequest

    private let dependency: WorkItemBizDependency

    init(userResolver: UserResolver) throws {
        dependency = try userResolver.resolve(assert: WorkItemBizDependency.self)
    }

    func shouldTriggle(with url: URL) -> Bool {
        let components = url.pathComponents
        guard components.count == 5 else {
            return false
        }

        let workItemType = components[2]
        // 仅需求类型需要额外发起流程图的预请求
        return workItemType == "story"
    }

    func create(by url: URL, context: PreRequestResponse?) -> WorkflowPreRequest? {
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

        let delayPadding = LanguageManager.currentLanguage == .zh_CN ? 48 : 52
        return WorkflowPreRequest(
            cacheKey: "detail_\(projectKey)_\(workItemType)_\(workItemId)_workflow",
            endpoint: "/bff/v2/project/\(projectKey)/work_item/\(workItemType)/\(workItemId)/workflow",
            parameters: [
                "layout_config": [
                    "container_width": 0,
                    "container_height": 0,
                    "centered_in_graph": false,
                    "node_style": [
                        "node_height": 32,
                        "max_width": 200,
                        "font_size": 14,
                        "padding": [
                            "left": 30,
                            "right": 20
                        ]
                    ],
                    "gap": [
                        "horizontal": 32,
                        "vertical": 16
                    ]
                ],
                "delay_padding": delayPadding,
                "need_calculate": true
            ]
        )
    }

    func check(with response: PreRequestResponse) -> Bool {
        return response.dataValue is [String: Any]
    }
}
