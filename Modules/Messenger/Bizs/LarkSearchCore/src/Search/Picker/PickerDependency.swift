//
//  PickerDependency.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/8/4.
//

import UIKit
import Foundation
import LarkSDKInterface
import RxSwift
import RxCocoa
import RustPB
import LarkModel
import LarkAccountInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkFeatureGating
import LarkRustClient
import Swinject

final class PickerServiceContainer {
    private let resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    // 先用单例服务。Picker依赖到的方法定义在下面，不要直接依赖外部大而全的服务。方便后续有需要时可以变成最小化依赖(到时候看需要可能需要进一步拆分)
    var searchAPI: SearchAPI? { try? resolver.resolve(assert: SearchAPI.self) }
    var chatterAPI: ChatterAPI? { try? resolver.resolve(assert: ChatterAPI.self) }
    var chatAPI: ChatAPI? { try? resolver.resolve(assert: ChatAPI.self) }
    var userService: PassportUserService? { try? resolver.resolve(assert: PassportUserService.self) }
    var serverNTPTimeService: ServerNTPTimeService? { try? resolver.resolve(assert: ServerNTPTimeService.self) }

    var feedSyncDispatchService: FeedSyncDispatchService? { try? resolver.resolve(assert: FeedSyncDispatchService.self) }
    var messageModelService: ModelService? { try? resolver.resolve(assert: ModelService.self) }
    var rustService: RustService? { try? resolver.resolve(assert: RustService.self) }
    var contactAPI: ContactAPI? { try? resolver.resolve(assert: ContactAPI.self) }

    // MARK: Dependency API
    func chatterDefaultView(picker: ChatterPicker) -> UIView? {
        try? resolver.resolve(assert: UIView.self, name: "LarkChatterPickerDefaultView", argument: picker)
    }

    func getChatter(id: String) -> Observable<Chatter?> {
        chatterAPI?.getChatter(id: id) ?? .never()
    }
    func getChatters(ids: [String]) -> Observable<[String: Chatter]> {
        chatterAPI?.getChatters(ids: ids) ?? .never()
    }

    func getChat(id: String) -> Observable<Chat?> {
        chatAPI?.fetchChat(by: id, forceRemote: false) ?? .never()
    }
    func getChats(by ids: [String]) -> Observable<[String: LarkModel.Chat]> {
        chatAPI?.fetchChats(by: ids, forceRemote: false) ?? .never()
    }
}
