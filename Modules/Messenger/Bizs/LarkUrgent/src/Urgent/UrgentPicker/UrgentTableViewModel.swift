//
//  UrgentTableViewModel.swift
//  LarkUrgent
//
//  Created by 李勇 on 2019/6/7.
//

import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkTag
import LarkCore

final class UrgentTableViewModel {
    private let disposeBag = DisposeBag()
    private var _reloadData = PublishSubject<Void>()

    /// 提示信息
    var shouldShowTipView: Bool = false
    var bottomTipMessage: String?
    /// 某人被选中/取消选中
    var onSelected: ((UrgentChatterModel) -> Void)?
    var onDeSelected: ((UrgentChatterModel) -> Void)?
    /// 数据源
    var selectedItems: [UrgentChatterModel] = []
    var reloadData: Driver<Void> { return self._reloadData.asDriver(onErrorJustReturn: ()) }
    var datas: [UrgentChatterSectionData] = [] {
        didSet { self._reloadData.onNext(()) }
    }

    /// 某个人被选中
    func selected(_ item: UrgentChatterModel, isTableEvent: Bool = true) {
        self.selectedItems.append(item)

        if isTableEvent {
            self.onSelected?(item)
        } else {
            self._reloadData.onNext(())
        }
    }

    /// 某个人被取消选中
    func deselected(_ item: UrgentChatterModel, isTableEvent: Bool = true) {
        var hitDeselected: Bool = false
        self.selectedItems.removeAll(where: {
            if $0.chatter.id == item.chatter.id {
                hitDeselected = true
                return true
            }
            return false
        })
        guard hitDeselected else {
            return
        }
        if isTableEvent {
            self.onDeSelected?(item)
        } else {
            self._reloadData.onNext(())
        }
    }

    /// 某个人是否被选中
    func isItemSelected(_ item: UrgentChatterModel) -> Bool {
        return self.selectedItems.contains(
            where: { $0.chatter.id == item.chatter.id })
    }

    /// 设置默认哪些人被选中
    func setDefaultSelectedItems(_ items: [UrgentChatterModel]) {
        self.selectedItems = items
        self._reloadData.onNext(())
    }
}
