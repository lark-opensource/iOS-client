//
//  UtilTaskAssigneeService.swift
//  SKBrowser
//
//  Created by liujinwei on 2023/3/22.
//  


import Foundation
import SKFoundation
import SKCommon
import SpaceInterface
import SKResource
import EENavigator
import LarkUIKit

public final class UtilTaskAssigneeService: BaseJSService {}

extension UtilTaskAssigneeService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.searchAssignee, .showTaskAssignee, .showCreateTask]
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("\(serviceName)", component: LogComponents.assignee)
        var body: PlainBody?
        let callback = params["callback"] as? String
        switch serviceName {
        case DocsJSService.searchAssignee.rawValue:
            guard let callback else {
                DocsLogger.error("\(serviceName) fail,callback requird", component: LogComponents.assignee)
                return
            }
            body = LarkSearchAssigneePickerBody(title: BundleI18n.SKResource.CreationDoc_Tasks_AddAssignee_PageTitle) { [weak self] items in
                guard let self = self else { return }
                let params = [
                    "data": [
                        "result_list": items.map { ["id": $0.id, "name": $0.name] }
                    ]
                ]
                self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
                DocsLogger.info("searchTaskAssignee callback", component: LogComponents.assignee)
            }
        case DocsJSService.showTaskAssignee.rawValue:
            guard let callback else {
                DocsLogger.error("\(serviceName) fail,callback requird", component: LogComponents.assignee)
                return
            }
            body = LarkShowTaskAssigneeBody(params: params) { [weak self] items in
                guard let self = self else { return }
                let params = [
                    "data": [
                        "result_list": items
                    ]
                ]
                self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
                DocsLogger.info("showTaskAssignee callback", component: LogComponents.assignee)
            }
        case DocsJSService.showCreateTask.rawValue:
            DocsLogger.info("showCreateTask", component: LogComponents.assignee)
            body = LarkShowCreateTaskBody(params: params) { [weak self] data in
                guard let self = self else { return }
                DocsLogger.info("showCreateTask callback, \(data.count)", component: LogComponents.assignee)
                if let callback = callback {
                    self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: data, completion: nil)
                }
            }
        default:
            return
        }
        guard let body, let currentVc = self.navigator?.currentBrowserVC else {
            DocsLogger.error("\(serviceName) can't find currentBrowserVC", component: LogComponents.assignee)
            return
        }
        model?.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: currentVc, prepare: { $0.modalPresentationStyle = .formSheet })
    }
}
