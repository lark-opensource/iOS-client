//
//  ContactSelect+SelectionSource.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/5.
//

import Foundation
import LarkSearchCore
import RxSwift
import LarkModel
import LarkMessengerInterface
import LarkSDKInterface

/// 这里是默认实现，实现类可能需要修改部分实现
extension ContactSelect where Self: SelectionDataSource {
    /// 默认单选，开启后显示多选样式。可动态切换
    var isMultiple: Bool { !isSingleStatus }
    /// 当前的选中项，单选时只会有0-1个
    var selected: [Option] { dataSource.selectedContactItems() }

    // observable shouldn't emit inital value when subscribe, only changes
    // var isMultipleChangeObservable: Observable<Bool> { }
    // selected can be lazy get
    var selectedChangeObservable: Observable<SelectionDataSource> {
        return dataSource.getSelectedObservable.compactMap { [weak self] _ in self }
    }

    func state(for option: Option, from: Any?) -> SelectState {
        return state(for: option, from: from, category: .unknown)
    }

    func state(for option: Option, from: Any?, category: PickerItemCategory) -> SelectState {
        let dataSource = self.dataSource
        // NOTE: 如果要进行强类型的判断，需要动态转换
        let option = option.optionIdentifier
        if option.type == OptionIdentifier.Types.chatter.rawValue, dataSource.forceSelectedChatterIds.contains(option.id) {
            return .forceSelected
        }
        if dataSource.selectedContactItems().firstIndex(where: { $0.optionIdentifier == option }) != nil {
            return .selected
        }
        return .normal
    }
}

extension SelectedContactItem: Option {
    var optionIdentifier: OptionIdentifier {
        switch self {
        case .unknown:
            return .init(type: OptionIdentifier.Types.unknown.rawValue, id: "")
        case .chatter(let info):
            return .init(type: OptionIdentifier.Types.chatter.rawValue, id: info.ID)
        case .meetingGroup(let id), .chat(let id):
            return .init(type: OptionIdentifier.Types.chat.rawValue, id: id)
        case .mail(let id):
            return .init(type: OptionIdentifier.Types.mailContact.rawValue, id: id)
        case .bot(let info):
            return .init(type: OptionIdentifier.Types.bot.rawValue, id: info.id)
        }
    }
}

extension SelectState {
    var asContactCheckBoxStaus: ContactCheckBoxStaus {
        switch (self.selected, self.disabled) {
        case (false, false):
            return .unselected
        case (true, false):
            return .selected
        case (false, true):
            return .disableToSelect
        case (true, true):
            return .defaultSelected
        }
    }
}
