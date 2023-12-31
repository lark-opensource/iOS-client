//
//  SettingLabelViewModel.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/20.
//

import Foundation
import LarkSDKInterface
import RxSwift

protocol SettingLabelViewModel {
    var title: String { get }
    var textFieldText: String { get set }
    var errorTip: String { get }
    var rightItemTitle: String { get }
    var targetVC: SettingLabelViewController? { get set }
    var resultObservable: Observable<(String?, Error?)> { get }
    var needShowResultToast: Bool { get }

    func leftItemClick()
    func rightItemClick(label: String)
    func viewDidLoad()
}
