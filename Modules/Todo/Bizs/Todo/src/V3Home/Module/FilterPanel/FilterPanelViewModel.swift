//
//  FilterPanelViewModel.swift
//  Todo
//
//  Created by baiyantao on 2022/8/23.
//

import Foundation

final class FilterPanelViewModel {
    enum Input {
        case status(list: [FilterTab.StatusField], seleted: FilterTab.StatusField)
        case group(list: [FilterTab.GroupField], seleted: FilterTab.GroupField)
        case sorting(list: [FilterTab.SortingCollection], seleted: FilterTab.SortingCollection)
    }
    enum Field {
        case status(FilterTab.StatusField)
        case group(FilterTab.GroupField)
        case sorting(FilterTab.SortingCollection)
    }

    // 内部状态
    private var cellDatas: [FilterPanelCellData] = []
    private let sectionCount = 1

    init(input: Input) {
        switch input {
        case .status(let list, let seleted):
            let listInfo = list.map { String($0.rawValue) }.joined(separator: ";")
            FilterTab.logger.info("init panel, status, l: \(listInfo), s: \(seleted.rawValue)")
            var datas: [FilterPanelCellData] = list.map {
                FilterPanelCellData(title: $0.title(), state: .normal, field: .status($0))
            }
            if let index = datas.firstIndex(where: {
                if case .status(let field) = $0.field {
                    return field == seleted
                }
                return false
            }) {
                datas[index].state = .seleted
            }
            cellDatas = datas
        case .group(let list, let seleted):
            let listInfo = list.map { String($0.rawValue) }.joined(separator: ";")
            FilterTab.logger.info("init panel, group, l: \(listInfo), s: \(seleted.rawValue)")
            var datas: [FilterPanelCellData] = list.map {
                FilterPanelCellData(title: $0.title(), state: .normal, field: .group($0))
            }
            if let index = datas.firstIndex(where: {
                if case .group(let field) = $0.field {
                    return field == seleted
                }
                return false
            }) {
                datas[index].state = .seleted
            }
            cellDatas = datas
        case .sorting(let list, let seleted):
            let listInfo = list.map { String($0.logInfo) }.joined(separator: ";")
            FilterTab.logger.info("init panel, sorting, l: \(listInfo), s: \(seleted.logInfo)")
            var datas: [FilterPanelCellData] = list.map {
                FilterPanelCellData(title: $0.field.title(), state: .normal, field: .sorting($0))
            }
            if let index = datas.firstIndex(where: {
                if case .sorting(let collection) = $0.field {
                    return collection.field == seleted.field
                }
                return false
            }) {
                datas[index].field = .sorting(seleted)
                switch seleted.indicator {
                case .sorting(let isAscending):
                    datas[index].state = .seletedWithSorting(isAscending: isAscending)
                case .check:
                    datas[index].state = .seleted
                }
            }
            cellDatas = datas
        }
    }

    func contentHeight() -> CGFloat {
        CGFloat(cellDatas.count * 48)
    }
}

// MARK: - UITableView

extension FilterPanelViewModel {
    func numberOfSections() -> Int {
        sectionCount
    }

    func numberOfItems() -> Int {
        cellDatas.count
    }

    func cellInfo(indexPath: IndexPath) -> FilterPanelCellData? {
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

extension FilterPanelViewModel.Field: LogConvertible {
    var logInfo: String {
        switch self {
        case .status(let field):
            return "status: \(field.rawValue)"
        case .group(let field):
            return "group: \(field.rawValue)"
        case .sorting(let collection):
            return "collection: \(collection.logInfo)"
        }
    }
}
