//
//  AllProvider.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/13.
//

import Foundation
import RxSwift
import LarkContainer

enum MentionType {
    case all
    case chatter
    case document
}


class AllProvider: MentionProviderType {
    private var disposeBag = DisposeBag()
    var context: IMMentionContext
    var chatterProvider: ChatterProvider
    var docProvider: DocumentProvider
    
    var currentSearchText: String?
    let processor = AllProviderProcessor()
    
    var items = [IMMentionOptionType]()

    let userResolver: LarkContainer.UserResolver
    init(resolver: LarkContainer.UserResolver, context: IMMentionContext, parameters: IMMentionSearchParameters) {
        self.userResolver = resolver
        self.context = context
        self.chatterProvider = ChatterProvider(context: context)
        self.docProvider = DocumentProvider(resolver: resolver, context: context, parameters: parameters)
    }
    
    func search(query: String?) -> [Observable<ProviderEvent>] {
        currentSearchText = query
        let chatterSignal = chatterProvider.search(query: query)
        let docSignal = docProvider.search(query: query)
        let allSignal = Observable.combineLatest([
            chatterSignal,
            docSignal.startWith(ProviderEvent.success(.empty(query: query, hasMore: true)))
        ])
            .map { (events: [ProviderEvent]) in
                return AllProviderProcessor.reduce(query: query, events: events)
            }
        return [allSignal, chatterSignal, docSignal]
    }
    
    func loadMore() -> [Observable<ProviderEvent>] {
        let docSignal = docProvider.loadMore()
        return [.never(), .never(), docSignal]
    }
}
