//
//  OncallViewModel.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/27.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxRelay
import LarkSDKInterface
import LarkReleaseConfig
import LarkEnv
import LarkFeatureGating
import LarkContainer
import LarkAccountInterface
import LarkSetting

final class OnCallViewModel {

    enum Status {
        case initial, empty, loading, loadedMore, finish, error
    }

    enum Scene {
        case all, filter(tagId: String), search(text: String)

        var tagId: String? {
            switch self {
            case .filter(let tagId): return tagId
            default: return nil
            }
        }

        var text: String? {
            switch self {
            case .search(let text): return text
            default: return nil
            }
        }
    }

    private let statusVariable = BehaviorRelay<Status>(value: .initial)
    private let onCallsVariable = BehaviorRelay<[Oncall]>(value: [])
    private let onCallTagVariable = BehaviorRelay<[OnCallTag]>(value: [])
    private let userAPI: UserAPI
    private let searchAPI: SearchAPI
    let chatAPI: ChatAPI
    let oncallAPI: OncallAPI
    let fgService: FeatureGatingService

    lazy var statusObservable: Observable<Status> = self.statusVariable.asObservable()
    lazy var onCallObservable: Observable<[Oncall]> = self.onCallsVariable.asObservable()
    lazy var onCallTagObservable: Observable<[OnCallTag]> = self.onCallTagVariable.asObservable()

    private let disposeBag = DisposeBag()
    private let perPageDataCount: Int32 = 100
    private var scene: Scene = .all
    let userId: String
    private let userResolver: UserResolver
    private let passportService: PassportService

    lazy var isOversea: Bool = {
        // 海外版
        if ReleaseConfig.releaseChannel == "Oversea" { return true }
        // 国内动态环境是海外的
        if passportService.isOversea {
            return true
        }
        return false
    }()

    // 搜索翻页参数
    private var moreInfo: (hasMore: Bool, moreToken: Any?) = (true, nil)

    init(userAPI: UserAPI,
         userId: String,
         chatAPI: ChatAPI,
         oncallAPI: OncallAPI,
         searchAPI: SearchAPI,
         fgService: FeatureGatingService,
         resolver: UserResolver) throws {
        self.userAPI = userAPI
        self.userId = userId
        self.oncallAPI = oncallAPI
        self.chatAPI = chatAPI
        self.searchAPI = searchAPI
        self.fgService = fgService
        self.userResolver = resolver
        self.passportService = try resolver.resolve(assert: PassportService.self)
    }

    func isEmpty() -> Bool {
        return onCallsVariable.value.isEmpty
    }

    func loadOnCallTag() {
        self.userAPI.pullOncallTags()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (oncallTags) in
                guard let `self` = self else { return }
                self.onCallTagVariable.accept(oncallTags)
            }).disposed(by: self.disposeBag)
    }

    func loadOncalls() {
        self.scene = .all
        self.statusVariable.accept(.loading)
        self.pullOncalls(offset: 0)
    }

    func filter(by tagId: String) {
        self.scene = .filter(tagId: tagId)
        self.statusVariable.accept(.loading)
        self.pullOncalls(by: tagId, offset: 0)
    }

    func search(by text: String) {
        if text.isEmpty {
            loadOncalls()
            return
        }
        self.scene = .search(text: text)
        self.statusVariable.accept(.loading)
        self.searchOncalls(by: text, offset: 0)
    }

    func loadMore() {
        self.statusVariable.accept(.loading)
        switch self.scene {
        case .all:
            self.pullOncalls(offset: self.onCallsVariable.value.count)
        case .filter(let tagId):
            self.pullOncalls(by: tagId, offset: self.onCallsVariable.value.count)
        case .search(let text):
            self.searchOncalls(by: text, offset: self.onCallsVariable.value.count)
        }
    }

    private func pullOncalls(offset: Int) {
        let startTime = CACurrentMediaTime()
        self.userAPI
            .pullOncalls(offset: Int32(offset), count: perPageDataCount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (oncallsInfo) in
                guard let `self` = self else { return }
                OncallContactsApprecibleTrack.updateOncallContactsTrackData(sdkCost: CACurrentMediaTime() - startTime,
                                                                            memberCount: oncallsInfo.oncalls.count)
                OncallContactsApprecibleTrack.oncallContactsPageLoadingTimeEnd()
                self.addOncallsInfo(offset: offset, oncallsInfo: oncallsInfo)
            }, onError: { [weak self] (error) in
                if let apiError = error.underlyingError as? APIError {
                    OncallContactsApprecibleTrack.oncallContactsPageError(errorCode: Int(apiError.code),
                                                                          errorMessage: apiError.localizedDescription)
                } else {
                    OncallContactsApprecibleTrack.oncallContactsPageError(errorCode: (error as NSError).code,
                                                                          errorMessage: (error as NSError).localizedDescription)
                }
                self?.statusVariable.accept(.error)
            })
            .disposed(by: self.disposeBag)
    }

    private func pullOncalls(by tagId: String, offset: Int) {
        self.userAPI
            .pullOncallsByTag(tagIds: [tagId], offset: Int32(offset), count: perPageDataCount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (oncallsInfo) in
                guard let `self` = self, self.scene.tagId == tagId else { return }
                self.addOncallsInfo(offset: offset, oncallsInfo: oncallsInfo)
            }, onError: { [weak self] (_) in
                self?.statusVariable.accept(.error)
            })
            .disposed(by: self.disposeBag)
    }

    private func searchOncalls(by text: String, offset: Int) {
        let begin = Int32(offset)
        searchAPI.universalSearch(query: text,
                                  scene: .rustScene(.searchOncallScene),
                                  begin: begin,
                                  end: begin + perPageDataCount,
                                  moreToken: begin == 0 ? nil : moreInfo.moreToken,
                                  filter: nil,
                                  needSearchOuterTenant: false,
                                  authPermissions: [])
        .subscribe(onNext: { [weak self] (response) in
            guard let `self` = self, self.scene.text == text else { return }
            let oncalls = response.results.map({ (result) -> Oncall in
                var id: String = ""
                var name: String = ""
                var description: String = ""
                var chatId: String = ""
                var avatar = LarkModel.ImageSet()
                avatar.key = result.avatarKey
                name = result.title.string
                description = result.summary.string
                self.moreInfo = (response.hasMore, response.moreToken)
                switch result.meta {
                case .oncall(let meta):
                    id = meta.id
                    chatId = meta.chatID
                default:
                    break
                }
                return Oncall(id: id,
                              name: name,
                              description: description,
                              avatar: avatar,
                              chatId: chatId,
                              phoneNumber: "",
                              reportLocation: false)
            })
            if offset == 0 {
                self.onCallsVariable.accept(oncalls)
            } else {
                var temp = self.onCallsVariable.value
                temp += oncalls
                self.onCallsVariable.accept(temp)
            }
            if response.hasMore {
                self.statusVariable.accept(.loadedMore)
            } else {
                self.statusVariable.accept(self.onCallsVariable.value.isEmpty ? .empty : .finish)
            }
        }, onError: { [weak self] (_) in
            self?.statusVariable.accept(.error)
        })
        .disposed(by: self.disposeBag)
    }

    private func addOncallsInfo(offset: Int, oncallsInfo: (oncalls: [Oncall], hasMore: Bool)) {
        if offset == 0 {
            self.onCallsVariable.accept(oncallsInfo.oncalls)
        } else {
            var temp = self.onCallsVariable.value
            temp += oncallsInfo.oncalls
            self.onCallsVariable.accept(temp)
        }

        if oncallsInfo.hasMore, !oncallsInfo.oncalls.isEmpty {
            self.statusVariable.accept(.loadedMore)
        } else {
            self.statusVariable.accept(self.onCallsVariable.value.isEmpty ? .empty : .finish)
        }
    }
}
