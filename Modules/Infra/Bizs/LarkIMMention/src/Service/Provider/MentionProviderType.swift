//
//  IMMentionDataProviderType.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/25.
//

import Foundation
import RxSwift

protocol MentionProviderType {
    func search(query: String?) -> [Observable<ProviderEvent>]
    func loadMore() -> [Observable<ProviderEvent>]
}
