//
//  TodoUpdateNoti.swift
//  Todo
//
//  Created by 张威 on 2020/11/23.
//

import RxSwift
import RustPB
import LarkRustClient
import LKCommonsLogging

/// Rust - Todo Update Noti

protocol TodoUpdateNoti: AnyObject {
    /// 全量（full）更新
    var rxFullUpdate: PublishSubject<Void> { get }

    /// 局部（diff）更新
    var rxDiffUpdate: PublishSubject<Rust.TodoChangeset> { get }

    /// 其他信息更新
    var rxExtraUpdate: PublishSubject<[Rust.TodoExtraInfo]> { get }

    var rxSectionUpdate: PublishSubject<[Rust.TaskSection]> { get }

    var rxRefsUpdate: PublishSubject<[Rust.ContainerTaskRef]> { get }
}

final class TodoUpdatePushHandler: TodoUpdateNoti {

    let rxFullUpdate: PublishSubject<Void> = .init()
    let rxDiffUpdate: PublishSubject<Rust.TodoChangeset> = .init()
    let rxExtraUpdate: PublishSubject<[Rust.TodoExtraInfo]> = .init()
    let rxSectionUpdate: PublishSubject<[Rust.TaskSection]> = .init()
    let rxRefsUpdate: PublishSubject<[Rust.ContainerTaskRef]> = .init()

    static let logger = Logger.log(TodoUpdatePushHandler.self, category: "Todo.UpdatePushHandler")

    init(client: RustService) {
        client.register(pushCmd: .pushTodosChangedNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let rustNotiBody = try RustPB.Todo_V1_PushTodosChangedNotification(serializedData: data)
                if rustNotiBody.hasRefreshAll, rustNotiBody.refreshAll {
                    self.rxFullUpdate.onNext(())
                    Self.logger.info("receive a fullRefresh push")
                    return
                }
                if rustNotiBody.hasChangedTodos && !rustNotiBody.changedTodos.isEmpty {
                    self.rxDiffUpdate.onNext(rustNotiBody.changedTodos)
                    Self.logger.info("receive a diffRefresh push. \(rustNotiBody.changedTodos.logInfo)")
                } else {
                    self.rxFullUpdate.onNext(())
                    V3Home.assertionFailure("fullRefresh payload should not be empty")
                }
            } catch {
                self.rxFullUpdate.onNext(())
                V3Home.assertionFailure("serialize update noti payload failed")
            }
        }
        client.register(pushCmd: .pushTodoExtraInfoNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let body = try RustPB.Todo_V1_PushTodoExtraInfoChangedNotification(serializedData: data)
                self.rxExtraUpdate.onNext(body.extraInfos)
                var logText = ""
                for (index, info) in body.extraInfos.enumerated() {
                    logText += "index: \(index), info: \(info.logInfo). "
                }
                Self.logger.info("receive a extra push, content: \(logText)")
            } catch {
                V3Home.assertionFailure("serialize extra noti payload failed")
            }
        }
        client.register(pushCmd: .pushTaskSectionNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let body = try RustPB.Todo_V1_PushTaskSectionNotification(serializedData: data)
                self.rxSectionUpdate.onNext(body.taskSections)
                Self.logger.info("receive a section push, infos: \(body.taskSections.map { $0.logInfo })")
            } catch {
                V3Home.assertionFailure("serialize section noti payload failed")
            }
        }
        client.register(pushCmd: .pushTaskContainerRefsNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let body = try RustPB.Todo_V1_PushTaskContainerRefsNotification(serializedData: data)
                self.rxRefsUpdate.onNext(body.taskContainerRefs)
                Self.logger.info("receive a refs push, info: \(body.taskContainerRefs.map { $0.logInfo })")
            } catch {
                V3Home.assertionFailure("serialize refs noti payload failed")
            }
        }
    }
}
