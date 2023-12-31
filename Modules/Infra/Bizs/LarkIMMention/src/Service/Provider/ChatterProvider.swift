//
//  ChatterProvider.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/8.
//

import Foundation
import RxSwift
import LarkContainer
import LarkSDKInterface
import RustPB

class ChatterProvider {
    
    @Injected private var chatterAPI: ChatterAPI
    private var context: IMMentionContext
    private var processor: ChatterProviderProcessor
    
    var event = PublishSubject<ProviderEvent>()
    private var disposeBag = DisposeBag()
    private var recommendDisposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()
    
    init(context: IMMentionContext) {
        self.context = context
        self.processor = ChatterProviderProcessor(context: context)
    }
    
    func search(query: String?) -> Observable<ProviderEvent> {
        return request(query: query)
    }
    
    func request(query: String? = nil) -> Observable<ProviderEvent> {
        let logger = IMMentionLogger.shared
        logger.info(module: .provider, event: "chatter start search", parameters: "query = \(query ?? "")")
        return chatterAPI.fetchAtListWithLocalOrRemote(chatId: context.currentChatId, query: query)
            .do(onNext: { (data, isRemote) in
                let data = """
wantedIds=\(data.wantedMentionIds.count)&inChatIds=\(data.inChatChatterIds.count)&outChatIds=\(data.outChatChatterIds.count)&isShowPrivacy=\(data.showSearch)
"""
                logger.info(module: .provider, event: "chatter request success", parameters: "isRemote=\(isRemote)&" + data)
            }, onError: { error in
                logger.error(module: .provider, event: "chatter request failed", parameters: error.localizedDescription)
            })
            .map { [weak self] (data, isRemote) in
                guard let self = self else { return ProviderEvent.fail(.none) }
                let res = {
                    if query.isEmpty {
                        return self.processor.processRecommendResult(data, isRemote: isRemote)
                    } else {
                        return self.processor.processSearchResult(data, isRemote: isRemote)
                    }
                }()
                let isShowPrivacy = data.showSearch && query.isEmpty
                let result = ProviderEvent.Response(query: query, res: res, isShowPrivacy: isShowPrivacy)
                return ProviderEvent.success(result)
            }
            .catchError {
                .just(ProviderEvent.fail(.request($0)))
            }
    }
}
