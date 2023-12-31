//
//  CustomFieldsTagsPanelViewModel.swift
//  Todo
//
//  Created by baiyantao on 2023/4/23.
//

import Foundation
import RxSwift
import RxCocoa

final class CustomFieldsTagsPanelViewModel {

    var updateHandler: ((CustomFieldsTagsPanelViewModel.Selection) -> Void)?
    var dismissHandler: (() -> Void)?

    private let initSelection: Selection

    // view drivers
    let reloadNoti = PublishRelay<Void>()
    private var cellDatas = [CustomFieldsTagsPanelContentCellData]()

    // const
    private let sectionCount = 1

    init(tagOptions: [Rust.SelectFieldOption], selection: Selection) {
        self.initSelection = selection
        cellDatas = options2CellDatas(tagOptions, selection)
    }

    func getContentHeight() -> CGFloat {
        let topAndBottomOffset: CGFloat = 96
        if cellDatas.isEmpty {
            let emptyHeight: CGFloat = 258
            return emptyHeight + topAndBottomOffset
        } else {
            let cellsHeight = CGFloat(numberOfItems()) * DetailCustomFields.tagsPanelCellHeight
            return min(cellsHeight + topAndBottomOffset, DetailCustomFields.tagsPanelMaxHeight)
        }
    }

    private func options2CellDatas(
        _ tagOptions: [Rust.SelectFieldOption],
        _ selection: Selection
    ) -> [CustomFieldsTagsPanelContentCellData] {
        let selectIdSet: Set<String>
        switch selection {
        case .single(let selectGuid):
            if let selectGuid = selectGuid {
                selectIdSet = Set([selectGuid])
            } else {
                selectIdSet = Set()
            }
        case .multi(let selectGuids):
            selectIdSet = Set(selectGuids)
        }
        return tagOptions
            .filter { !$0.isHidden }
            .sorted { $0.rank < $1.rank }
            .map {
                return CustomFieldsTagsPanelContentCellData(
                    tagText: $0.name,
                    colorToken: DetailCustomFields.index2ColorToken($0.colorIndex),
                    isChecked: selectIdSet.contains($0.guid),
                    option: $0
                )
            }
    }
}

// MARK: - View Action

extension CustomFieldsTagsPanelViewModel {

    func doToggle(at indexPath: IndexPath) {
        guard safeCheck(indexPath: indexPath) else { return }
        switch initSelection {
        case .single:
            var cellDatas = self.cellDatas
            var oldCheckedIndex: Int?
            cellDatas.indices.forEach {
                if cellDatas[$0].isChecked {
                    oldCheckedIndex = $0
                }
                cellDatas[$0].isChecked = false
            }
            if indexPath.row != oldCheckedIndex {
                cellDatas[indexPath.row].isChecked = true
            }
            self.cellDatas = cellDatas
        case .multi:
            cellDatas[indexPath.row].isChecked = !cellDatas[indexPath.row].isChecked
        }
        doUpdate()
        reloadNoti.accept(void)
        if case .single = initSelection {
            // 先等 UI 刷新一下再退出
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.dismissHandler?()
            }
        }
    }

    private func doUpdate() {
        let result: Selection
        switch initSelection {
        case .single:
            let first = cellDatas.first(where: { $0.isChecked })
            result = .single(selectGuid: first?.option.guid)
        case .multi:
            let guids = cellDatas.filter { $0.isChecked }.map { $0.option.guid }
            result = .multi(selectGuids: guids)
        }
        updateHandler?(result)
    }

}

// MARK: - UITableView

extension CustomFieldsTagsPanelViewModel {
    func numberOfSections() -> Int {
        sectionCount
    }

    func numberOfItems() -> Int {
        cellDatas.count
    }

    func cellInfo(indexPath: IndexPath) -> CustomFieldsTagsPanelContentCellData? {
        guard safeCheck(indexPath: indexPath) else { return nil }
        return cellDatas[indexPath.row]
    }

    private func safeCheck(indexPath: IndexPath) -> Bool {
        let (section, row) = (indexPath.section, indexPath.row)
        guard section >= 0
                && section < sectionCount
                && row >= 0
                && row < cellDatas.count
        else {
            var text = "check indexPath failed. indexPath: \(indexPath)"
            text += " sectionCount: \(sectionCount)"
            if section >= 0 && section < sectionCount {
                text += " itemCount: \(cellDatas.count)"
            }
            assertionFailure(text)
            return false
        }
        return true
    }
}

// MARK: - Other

extension CustomFieldsTagsPanelViewModel {
    enum Selection {
        case single(selectGuid: String?)
        case multi(selectGuids: [String])
    }
}

extension CustomFieldsTagsPanelViewModel.Selection: LogConvertible {
    var logInfo: String {
        switch self {
        case .single(let guid):
            return guid ?? ""
        case .multi(let guids):
            return guids.description
        }
    }
}
