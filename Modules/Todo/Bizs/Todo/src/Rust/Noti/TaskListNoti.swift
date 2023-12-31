//
//  TaskListNoti.swift
//  Todo
//
//  Created by wangwanxin on 2022/11/18.
//

import RxSwift
import RustPB
import LarkRustClient
import LKCommonsLogging

/// Home - TaskList

protocol TaskListNoti: AnyObject {
    // 任务清单更新
    var rxTaskListUpdate: PublishSubject<([Rust.TaskContainer], Bool)> { get }

    // 任务清单中更新
    var rxTasksUpdate: PublishSubject<[Rust.TaskRefInfo]> { get }

    var rxTaskListSectionUpdate: PublishSubject<[Rust.TaskListSection]> { get }

    var rxTaskListSectionRefUpdate: PublishSubject<[Rust.TaskListSectionItem]> { get }
}

final class TaskListPushHandler: TaskListNoti {

    let rxTaskListUpdate: PublishSubject<([Rust.TaskContainer], Bool)> = .init()
    let rxTasksUpdate: PublishSubject<[Rust.TaskRefInfo]> = .init()
    let rxTaskListSectionUpdate: PublishSubject<[Rust.TaskListSection]> = .init()
    let rxTaskListSectionRefUpdate: PublishSubject<[Rust.TaskListSectionItem]> = .init()

    static let logger = Logger.log(TaskListPushHandler.self, category: "Todo.TaskListPushHandler")

    init(client: RustService) {
        client.register(pushCmd: .pushTaskListsChangedNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let body = try RustPB.Todo_V1_PushTaskListsChangedNotification(serializedData: data)
                self.rxTaskListUpdate.onNext((body.taskLists, body.refreshAll))
                Self.logger.info("received task list push, info: \(body.taskLists.map { $0.logInfo }), refreshAll: \(body.refreshAll)")
            } catch {
                V3Home.assertionFailure("serialize task list noti payload failed")
            }

        }
        client.register(pushCmd: .pushListTasksChangedNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let body = try RustPB.Todo_V1_PushListTasksChangedNotification(serializedData: data)
                self.rxTasksUpdate.onNext(body.taskInfos)
                Self.logger.info("received tasks push, info: \(body.taskInfos.map { $0.logInfo })")
            } catch {
                V3Home.assertionFailure("serialize tasks noti payload failed")
            }
        }
        client.register(pushCmd: .pushContainerSectionsChangedNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let body = try RustPB.Todo_V1_PushContainerSectionsChangedNotification(serializedData: data)
                self.rxTaskListSectionUpdate.onNext(body.taskContainerSections)
                Self.logger.info("received tasklist section push. \(body.taskContainerSections.map(\.logInfo))")
            } catch {
                V3Home.assertionFailure("serialize tasklist section payload failed")
            }
        }
        client.register(pushCmd: .pushContainerSectionRefsChangedNotification) { [weak self] data in
            do {
                let body = try RustPB.Todo_V1_PushContainerSectionItemsChangedNotification(serializedData: data)
                self?.rxTaskListSectionRefUpdate.onNext(body.taskContainerSectionItems)
                Self.logger.info("received tasklist seciton ref push. \(body.taskContainerSectionItems.map(\.logInfo))")
            } catch {
                V3Home.assertionFailure("serialize tasklist section ref payload failed")
            }
        }
    }
}
