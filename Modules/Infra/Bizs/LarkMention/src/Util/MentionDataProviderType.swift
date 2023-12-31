//
//  MentionDataProviderType.swift
//  LarkMention
//
//  Created by Yuri on 2022/6/2.
//

import Foundation
import RxSwift

public protocol MentionSearchable {
    func search(text: String)
}

public enum MentionLoadEvent {
    public struct MentionResult {
        var items = [PickerOptionType]()
        var hasMore = false
    }
    case empty
    case reloading(String)
    case load(MentionResult)
    case loadingMore(MentionResult)
    case fail(Error)
}

public protocol MentionDataProviderType: MentionSearchable {
    var items: PublishSubject<[PickerOptionType]> { get set }
    var didEventHandler: ((MentionLoadEvent) -> Void)? { get set }
    func loadMore()
}
