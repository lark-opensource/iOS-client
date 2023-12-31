//
//  GroupSettingChooseLimitViewModel.swift
//  LarkChatSetting
//
//  Created by bytedance on 2021/10/18.
//

import Foundation
import RxSwift
import RxCocoa

final class GroupSettingChooseLimitViewModel {
    private var currentOption: Int32
    let options: [Int32]
    var callback: ((Int32) -> Void)?

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()
    init(options: [Int32], currentOption: Int32) {
        self.options = options
        self.currentOption = currentOption
    }
    func isIndexSelected(indexPath: IndexPath) -> Bool {
        return options[indexPath.row] == currentOption
    }

    func indexText(indexPath: IndexPath) -> String {
        return "\(options[indexPath.row])"
    }

    func setIndex(indexPath: IndexPath) {
        currentOption = options[indexPath.row]
        _reloadData.onNext(())
    }

    func confirmOption() {
        callback?(currentOption)
    }
}
