//
//  ChatSettingSearchDetailViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/2/4.
//

import UIKit
import Foundation
import RxSwift
import LarkCore
import LarkContainer
import RxCocoa
import LarkModel
import LarkOpenChat
import LarkMessengerInterface
import LarkAccountInterface
import LKCommonsLogging
import EENavigator

final class ChatSettingSearchDetailViewModel {
    static let logger = Logger.log(ChatSettingSearchDetailViewModel.self, category: "IM.ChatSetting")
    //共UI使用的刷新信号
    lazy var reload: Driver<Void> = {
        return reloadPublish.asDriver(onErrorJustReturn: ())
    }()
    //共UI使用的数据源
    private(set) var items: [ChatSettingSearchDetailItem] = [] {
        didSet {
            reloadPublish.onNext(())
        }
    }

    private var reloadPublish: PublishSubject<Void> = PublishSubject<Void>()
    private var factorys: [ChatSettingSerachDetailItemsFactory]
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver,
         chat: Chat,
         factoryTypes: [ChatSettingSerachDetailItemsFactory.Type]) {
        self.factorys = factoryTypes.map({ (factoryType) -> ChatSettingSerachDetailItemsFactory in
            return factoryType.init(userResolver: userResolver)
        })
        var subFunctionsObservables: [Observable<[ChatSettingSearchDetailItem]>] = []
        for factory in factorys {
            //收集各业务线子功能（信号）
            subFunctionsObservables.append(factory.createItems(chat: chat))
        }
        let layout = LarkOpenChat.settingSearchDetailLayout
        //监听各业务线子功能变更
        Observable.combineLatest(subFunctionsObservables)
            .map { (subFunctions) -> [ChatSettingSearchDetailItem] in
                return subFunctions.flatMap { return $0 }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (items) in
                let layoutedItems = layout.items.compactMap { identify in
                    return items.first(where: { $0.type.rawValue == identify })
                }
                self?.items = layoutedItems
            }, onError: { (error) in
                ChatExtensionFunctionsViewModel.logger.error("subFunctionsObservables error \(chat.id)", error: error)
            }).disposed(by: self.disposeBag)
    }
}

final class MessengerChatSettingSerachDetailItemsFactory: NSObject, ChatSettingSerachDetailItemsFactory {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public var currentChatterId: String {
        return userResolver.userID
    }

    func createItems(chat: Chat) -> Observable<[ChatSettingSearchDetailItem]> {
        let items = [
            createItemForMessage(chat: chat),
            createItemForDocs(chat: chat),
            createItemForFile(chat: chat),
            createItemForImage(chat: chat),
            createItemForLink(chat: chat)
        ]
        return .just(items)
    }

    private func createItemForMessage(chat: Chat) -> ChatSettingSearchDetailItem {
        let image = Resources.search_detail_message.ud.withTintColor(UIColor.ud.iconN2)
        let isOwner = currentChatterId == chat.ownerId
        let item = ChatSettingSearchDetailItem(type: .message,
                                               title: BundleI18n.LarkChatSetting.Lark_Feed_Messages,
                                               badgePath: nil,
                                               imageInfo: .image(image)) { [weak self] (vc) in
            guard let vc = vc else { return }
            NewChatSettingTracker.imChatSettingClickMessage(chat: chat)
            self?.jumpToSearchVCBytype(.message, chat: chat, vc: vc)
        }
        return item
    }

    private func createItemForDocs(chat: Chat) -> ChatSettingSearchDetailItem {
        let image = Resources.search_detail_docs.ud.withTintColor(UIColor.ud.iconN2)
        let isOwner = currentChatterId == chat.ownerId
        let item = ChatSettingSearchDetailItem(type: .docs,
                                               title: BundleI18n.LarkChatSetting.Lark_Legacy_DocFragmentTitle,
                                               badgePath: nil,
                                               imageInfo: .image(image)) { [weak self] (vc) in
            guard let vc = vc else { return }
            NewChatSettingTracker.imChatSettingClickMessageDoc(chat: chat)
            self?.jumpToSearchVCBytype(.doc, chat: chat, vc: vc)
        }
        return item
    }

    private func createItemForFile(chat: Chat) -> ChatSettingSearchDetailItem {
        let image = Resources.search_detail_file.ud.withTintColor(UIColor.ud.iconN2)
        let isOwner = currentChatterId == chat.ownerId
        let item = ChatSettingSearchDetailItem(type: .file,
                                               title: BundleI18n.LarkChatSetting.Lark_Legacy_FileFragmentTitle,
                                               badgePath: nil,
                                               imageInfo: .image(image)) { [weak self] (vc) in
            guard let vc = vc else { return }
            NewChatSettingTracker.imChatSettingClickMessageFile(chat: chat)
            self?.jumpToSearchVCBytype(.file, chat: chat, vc: vc)
        }
        return item
    }

    private func createItemForImage(chat: Chat) -> ChatSettingSearchDetailItem {
        let image = Resources.search_detail_image.ud.withTintColor(UIColor.ud.iconN2)
        let isOwner = currentChatterId == chat.ownerId
        let item = ChatSettingSearchDetailItem(type: .image,
                                               title: BundleI18n.LarkChatSetting.Lark_Search_Media,
                                               badgePath: nil,
                                               imageInfo: .image(image)) { [weak self] (vc) in
            guard let vc = vc else { return }
            NewChatSettingTracker.imChatSettingClickMessageImage(chat: chat)
            self?.jumpToSearchVCBytype(.image, chat: chat, vc: vc)
        }
        return item
    }

    private func createItemForLink(chat: Chat) -> ChatSettingSearchDetailItem {
        let image = Resources.search_detail_link.ud.withTintColor(UIColor.ud.iconN2)
        let isOwner = currentChatterId == chat.ownerId
        let item = ChatSettingSearchDetailItem(type: .link,
                                               title: BundleI18n.LarkChatSetting.Lark_Search_Link,
                                               badgePath: nil,
                                               imageInfo: .image(image)) { [weak self] (vc) in
            guard let vc = vc else { return }
            NewChatSettingTracker.imChatSettingClickMessageLink(chat: chat)
            self?.jumpToSearchVCBytype(.url, chat: chat, vc: vc)
        }
        return item
    }

    private func jumpToSearchVCBytype(_ type: MessengerSearchInChatType, chat: Chat, vc: UIViewController) {
        let body = SearchInChatBody(chatId: chat.id, type: type, chatType: chat.type, isMeetingChat: chat.isMeeting)
        userResolver.navigator.push(body: body, from: vc)
    }
}
