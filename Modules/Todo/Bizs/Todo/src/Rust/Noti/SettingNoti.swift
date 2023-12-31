//
//  SettingNoti.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/24.
//

import RustPB
import RxSwift
import LarkRustClient
import LKCommonsLogging

protocol SettingNoti: AnyObject {
    var rxSetting: PublishSubject<Todo_V1_PushTodoSettingChangeNotification> { get }
}

final class SettingPushHandler: SettingNoti {

    static let logger = Logger.log(SettingPushHandler.self, category: "Todo.SettingPushHandler")

    let rxSetting: PublishSubject<Todo_V1_PushTodoSettingChangeNotification> = .init()

    init(client: RustService) {
        client.register(pushCmd: .pushTodoSettingChangeNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let rustBody = try RustPB.Todo_V1_PushTodoSettingChangeNotification(serializedData: data)
                self.rxSetting.onNext(rustBody)
                Self.logger.info("receive a setting push")
            } catch {
                V3Home.assertionFailure(("serialize update noti payload failed"))
            }
        }
    }
}
