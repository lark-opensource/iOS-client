//
//  AtViewModelDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/10.
//

import Foundation
import RxSwift
import RxCocoa

protocol AtViewModelDependency {
    var pushFeedFilterSettings: Observable<FiltersModel> { get }
    func getAtFilterSetting() -> Observable<Bool>
}
