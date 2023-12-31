//
//  BlockSyncMessageRustAPI.swift
//  Blockit
//
//  Created by ChenMengqi on 2021/11/10.
//

import LarkRustClient
import LarkContainer
import RustPB
import RxSwift
import SwiftyJSON

///订阅主题
typealias RustSubscribeTopicRequest = RustPB.Sync_V1_SubscribeTopicRequest
typealias RustSubscribeTopicResponse = RustPB.Sync_V1_SubscribeTopicResponse

typealias RustSyncHeader = RustPB.Sync_V1_SyncHeader

///取消订阅
typealias RustUnsubscribeSyncTopicRequest = RustPB.Sync_V1_UnsubscribeSyncTopicRequest
typealias RustUnsubscribeSyncTopicResponse = RustPB.Sync_V1_UnsubscribeSyncTopicResponse


typealias OnSubscribeTopicRustResponseCallback = ( RustSubscribeTopicResponse) -> Void
typealias OnUnsubscribeSyncTopicRustResponseCallback = (RustUnsubscribeSyncTopicResponse) -> Void


protocol BlockSyncMessageRustAPI {
    func subscribeTopic(request: RustSubscribeTopicRequest, listener: OnSubscribeTopicRustResponseCallback?)
    func unsubscribeSyncTopic(request: RustUnsubscribeSyncTopicRequest, listener: OnUnsubscribeSyncTopicRustResponseCallback?)
}


class BlockSyncMessageRustAPIImpl: BlockSyncMessageRustAPI {
    private let rustService: RustService

    let disposeBag = DisposeBag()

    init(rustService: RustService) {
        self.rustService = rustService
    }

    func subscribeTopic(request: RustSubscribeTopicRequest, listener: OnSubscribeTopicRustResponseCallback?) {
        (rustService.sendAsyncRequest(request) { (response: RustSubscribeTopicResponse) -> Void in
            Blockit.log.info("subscribeTopic with response:\(response)")
            listener?(response)
        }).subscribe().disposed(by: self.disposeBag)
    }
    
    func unsubscribeSyncTopic(request: RustUnsubscribeSyncTopicRequest, listener: OnUnsubscribeSyncTopicRustResponseCallback?) {
        (rustService.sendAsyncRequest(request) { (response: RustUnsubscribeSyncTopicResponse) -> Void in
            Blockit.log.info("unsubscribeSyncTopic with response:\(response)")
            listener?(response)
        }).subscribe().disposed(by: self.disposeBag)
    }
    
}
    
