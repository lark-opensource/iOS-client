//
//  LoadMore.swift
//  Calendar
//
//  Created by Rico on 2021/5/23.
//

import Foundation

enum LoadMoreState {

    typealias RetryAction = () -> Void

    case initial
    case loading
    case noMore
    case failed(_ retry: RetryAction?)
}
