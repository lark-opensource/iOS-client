//
//  WikiSpaceDetailViewModel.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/23.
//  

import Foundation
import RxSwift
import RxCocoa
import SKWorkspace

class WikiSpaceDetailViewModel: NSObject {
    // MARK: - Rx Input
    let refreshData = PublishSubject<String>()

    // MARK: - Rx Output
    private(set) lazy var spaceInfoUpdated: Observable<Event<WikiSpaceInfo>> = {
        return refreshData
            .asObservable()
            .flatMap { (spaceID) -> Observable<Event<WikiSpaceInfo>> in
                return WikiNetworkManager.shared
                    .getSpaceInfo(spaceID: spaceID)
                    .do(onSuccess: { [weak self] (spaceInfo) in
                        guard let self = self else { return }
                        self.spaceInfo = spaceInfo
                    })
                    .asObservable()
                    .materialize()
            }
            .share()
    }()

    var memberListUpdated: Observable<Event<[WikiMember]>> {
        return spaceInfoUpdated
            .map { spaceEvent in
                switch spaceEvent {
                case let .next(spaceInfo):
                    let sortedMembers = spaceInfo.members.sorted(by: WikiMember.isRoleGreater)
                    return .next(sortedMembers)
                case let .error(error):
                    return .error(error)
                case .completed:
                    return .completed
                }
            }
    }

    var spaceDescriptionUpdated: Driver<String> {
        return spaceInfoUpdated
            .flatMap { (event) -> Observable<String> in
                switch event {
                case let .next(spaceInfo):
                    return .just(spaceInfo.spaceDescription)
                case let .error(error):
                    return .error(error)
                case .completed:
                    return .never()
                }
            }
            .asDriver(onErrorJustReturn: spaceDescription)
            .distinctUntilChanged()
    }

    var memberTableUpdated: Driver<Event<[WikiMember]>> {
        return memberListUpdated
            .map { memberEvent -> Event<[WikiMember]> in
                switch memberEvent {
                case let .error(error):
                    return .error(error)
                case let .next(members):
                    return .next(members)
                default:
                    return .completed
                }
            }
            .asDriver(onErrorJustReturn: .next([]))
    }

    let space: WikiSpace
    var spaceInfo: WikiSpaceInfo?

    var spaceDescription: String {
        return spaceInfo?.spaceDescription ?? space.wikiDescription
    }

    init(space: WikiSpace) {
        self.space = space
        super.init()
    }

    func refresh() {
        refreshData.onNext(space.spaceID)
    }
}
