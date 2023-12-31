//
//  Array+CommonItem.swift
//  LarkChatSetting
//
//  Created by Crazy凡 on 2020/6/28.
//

import Foundation

extension Array where Iterator.Element == CommonSectionModel {
    @inline(__always)
    var numberOfSections: Int { count }

    @inline(__always)
    func section(at index: Int) -> CommonSectionModel? {
        _fastPath(index < numberOfSections) ? self[index] : nil
    }

    @inline(__always)
    func sectionHeader(at index: Int) -> String? {
        section(at: index)?.title
    }

    @inline(__always)
    func sectionFooter(at index: Int) -> String? {
        section(at: index)?.description
    }

    @inline(__always)
    func numberOfRows(in section: Int) -> Int {
        self.section(at: section)?.numberOfRows ?? 0
    }

    func item(at indexPath: IndexPath) -> GroupSettingItemProtocol? {
        if let section = self.section(at: indexPath.section), var item = section.item(at: indexPath.row) {
            item.style = style(for: item, at: indexPath.row, total: section.numberOfRows)
            return item
        }

        return nil
    }
}

extension Array: CommonItemStyleFormat where Iterator.Element == CommonSectionModel {}
