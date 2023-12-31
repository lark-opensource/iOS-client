//
//  WorkDescriptionViewModel.swift
//  LarkMine
//
//  Created by liuwanlin on 2018/8/2.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkStorage
import TangramService
import LarkMessengerInterface
import LarkContainer

final class WorkDescriptionViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    let chatterAPI: ChatterAPI

    private var allHistoryItems: [Chatter.Description] = [] {
        didSet {
            self.historyItems = self.allHistoryItems.filter({ (des) -> Bool in
                return !des.text.isEmpty
            })
            self.hasHistory = !self.allHistoryItems.isEmpty
        }
    }
    private(set) var historyItems: [Chatter.Description] = []

    public var userID: String { return self.userResolver.userID }
    public let urlPreviewAPI: URLPreviewAPI
    public let inlineService: TextToInlineService
    private lazy var userStore = KVStores.Setting.build(forUser: self.userID)

    var hasMoreHistory: Bool = true
    var hasHistory: Bool = false
    var loadingHistory: Bool = false

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        self.urlPreviewAPI = try userResolver.resolve(assert: URLPreviewAPI.self)
        self.inlineService = try userResolver.resolve(assert: TextToInlineService.self)
    }

    /// 本地缓存
    func localCacheStoresDescription(text: String, type: Int) {
        self.userStore[KVKeys.Mine.description] = text
        self.userStore[KVKeys.Mine.descriptionType] = type
    }

    func saveWorkDescription(_ description: Chatter.Description) -> Observable<Bool> {
        return self.chatterAPI.updateChatter(description: description)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                MineTracker.trackPersonalStatusEdit(type: description.type)
                self.localCacheStoresDescription(text: description.text, type: description.type.rawValue)
            })
    }

    func loadLocalDescription() -> Chatter.Description? {
        let descriptionTypeValue = self.userStore[KVKeys.Mine.descriptionType]
        if let description = self.userStore[KVKeys.Mine.description],
            let descriptionType = Chatter.DescriptionType(rawValue: descriptionTypeValue) {
            var current = Chatter.Description()
            current.text = description
            current.type = descriptionType
            return current
        }
        return nil
    }

    func loadCurrent(userID: String) -> Observable<Chatter.Description> {
        return self.chatterAPI.fetchUserProfileInfomation(userId: userID)
            .observeOn(MainScheduler.instance)
            .map({ [weak self] (profile) -> Chatter.Description in
                var current = Chatter.Description()
                current.text = profile.description
                current.type = profile.status
                //增加本地缓存时机
                self?.localCacheStoresDescription(text: current.text, type: current.type.rawValue)
                return current
            })
    }

    func loadHistory() -> Observable<Void> {
        self.loadingHistory = true
        return self.chatterAPI.fetchChatterDescriptions(count: 20, offset: Int32(self.allHistoryItems.count))
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] descriptionsEntity in
                guard let `self` = self else { return }
                self.allHistoryItems += descriptionsEntity.descriptions
                self.hasMoreHistory = descriptionsEntity.hasMore
                self.loadingHistory = false
            }, onError: { [weak self] _ in
                self?.loadingHistory = false
            })
            .map { _ in }
    }

    func delete(item: Chatter.Description) -> Observable<Void> {
        self.allHistoryItems = self.allHistoryItems.filter({ (historyItem) -> Bool in
            return !(historyItem.type == item.type &&
                historyItem.text == item.text)
        })

        return self.chatterAPI.deleteChatterDescription(item: item)
            .observeOn(MainScheduler.instance)
    }
}
