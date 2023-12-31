//
//  FeedFilterSelectionService.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/16.
//

import Foundation
import RxSwift

protocol FeedFilterSelectionService {
    var currentSelection: FeedFilterSelection { get }
    var dataObservable: Observable<FeedFilterSelection> { get }
    func updateFilterSelection(_ selection: FeedFilterSelection)
}
