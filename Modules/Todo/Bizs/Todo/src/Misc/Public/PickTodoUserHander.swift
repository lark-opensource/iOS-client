//
//  PickTodoUserHander.swift
//  Todo
//
//  Created by wangwanxin on 2021/11/8.
//

import TodoInterface
import EENavigator
import Swinject
import UniverseDesignActionPanel
import LarkNavigator
import LarkUIKit
import LKCommonsLogging
import SwiftProtobuf

final class PickTodoUserHander: UserTypedRouterHandler {

    func handle(_ body: TodoUserBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let viewModel = PickTodoUserViewModel(resolver: userResolver, body: body)
        let vc = PickTodoUserController(resolver: userResolver, viewModel: viewModel)
        res.end(resource: vc)
    }
}

final class CreateTaskFromDocHandler: UserTypedRouterHandler {

    static let logger = Logger.log(CreateTaskFromDocHandler.self, category: "CreateTaskFromDocHandler")

    func handle(_ body: CreateTaskFromDocBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let callbacks = TodoCreateCallbacks(
            createHandler: { res in
                var value = [String: Any]()
                var options = JSONEncodingOptions()
                options.alwaysPrintEnumsAsInts = true
                if let data = try? res.jsonUTF8Data(options: options), let dataMap = try? JSONSerialization.jsonObject(with: data) {
                    value[CreateTaskFromDocBody.CallbackKey] = dataMap
                }
                body.callback(value)
            }
        )

        var task: Rust.Todo?, sectionContainer: Rust.ContainerSection?
        var options = JSONDecodingOptions()
        options.ignoreUnknownFields = true
        if let taskMap = body.param[CreateTaskFromDocBody.TaskKey] as? [String: Any] {
            if let data = try? JSONSerialization.data(withJSONObject: taskMap) {
                task = try? Rust.Todo(jsonUTF8Data: data, options: options)
            } else {
                Self.logger.error("init todo struct failed.")
            }
        }

        if let sectionsMap = body.param[CreateTaskFromDocBody.SectionKey] as? [Any] {
            if let data = try? JSONSerialization.data(withJSONObject: sectionsMap) {
                let sections = try? Rust.ContainerSection.array(fromJSONUTF8Data: data, options: options)
                sectionContainer = sections?.first
            } else {
                Self.logger.error("init section struct failed.")
            }
        }
        let vc = DetailViewController(
            resolver: userResolver,
            input: .create(
                source: .list(container: sectionContainer, task: task),
                callbacks: callbacks
            )
        )
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

}
