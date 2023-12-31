//
//  FeedFlagDependency.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import RustPB
import LarkSDKInterface
import RxSwift
import SwiftProtobuf
import LarkMessengerInterface
import RxRelay
import LarkCore
import Swinject
import RxCocoa
import LarkContainer

public typealias CheckIsMe = (_ userId: String) -> Bool

public protocol FlagDataDependency: UserResolverWrapper {
    var checkIsMe: CheckIsMe { get }
    var isByteDancer: Bool { get }
    var audioPlayer: AudioPlayMediator? { get }
    var feedAPI: FeedAPI? { get }
    var flagAPI: FlagAPI? { get }
    var chatAPI: ChatAPI? { get }
    var pushFeedMessage: Observable<PushFeedMessage> { get }
    var pushFlagMessage: Observable<PushFlagMessage> { get }
    var pushFeedFilterMessage: Observable<PushFeedFilterMessage> { get }
    var refreshObserver: PublishSubject<Void> { get }
    var audioResourceService: AudioResourceService? { get }
    var is24HourTime: Driver<Bool> { get }
    var abbreviationEnable: Bool { get }
    var inlinePreviewVM: MessageInlineViewModel { get }
    // 先这么写，之后需要解耦
    var getResolver: UserResolver { get }
    // iPad选中态监听
    func observeSelect() -> Observable<String?>
    // 设置FlagItem选中
    func setSelected(flagId: String?)
    // 获取当前选中FlagItem的FlagId
    func getSelected() -> String?
    var iPadStatus: String? { get }
    // 团队相关
    var teamActionService: TeamActionService? { get }
    // feed清除未读
    func clearSingleBadge(feedID: String, feedEntityPBType: Basic_V1_FeedCard.EntityType) -> Observable<Void>
}
