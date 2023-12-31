//
//  TopicGroupPushWrapper.swift
//  LarkThread
//
//  Created by lizhiqiang on 2020/1/6.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer
import LarkSDKInterface

public protocol TopicGroupPushWrapper {
    var topicGroupObservable: BehaviorRelay<TopicGroup> { get }
}

public final class TopicGroupPushWrapperImp: TopicGroupPushWrapper {
    public let topicGroupObservable: BehaviorRelay<TopicGroup>

    private let disposeBag = DisposeBag()

    public init(topicGroup: TopicGroup, pushCenter: PushNotificationCenter) {
        self.topicGroupObservable = BehaviorRelay<TopicGroup>(value: topicGroup)
        pushCenter.observable(for: PushTopicGroups.self).filter { (pushTopicGroups) -> Bool in
            return pushTopicGroups.topicGroups.contains { (pushTopicGroup) -> Bool in
                return pushTopicGroup.id == topicGroup.id
            }
        }.flatMap({ (pushTopicGroups) -> Observable<TopicGroup> in
            if let topicGroup = pushTopicGroups.topicGroups.first(where: { (pushTopicGroup) -> Bool in
                return pushTopicGroup.id == topicGroup.id
            }) {
                return .just(topicGroup)
            } else {
                return .never()
            }
        }).subscribe(onNext: { [weak self] (topicGroup) in
            self?.topicGroupObservable.accept(topicGroup)
        }).disposed(by: self.disposeBag)
    }
}
