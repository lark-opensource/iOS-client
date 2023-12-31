//
//  SelectMenuViewModel.swift
//  LarkUIKit
//
//  Created by Songwen Ding on 2019/7/18.
//

import Foundation
import UIKit
import LarkExtensions

public final class SelectMenuViewModel: NSObject {
    enum MenuMode {
        case compact
        case fullScreen
    }

    public struct Icon {
        public var imgKey: String?
        public var udToken: String?
        public var color: UIColor?
        public init(imgKey: String?, udToken: String?, color: UIColor?) {
            self.imgKey = imgKey
            self.udToken = udToken
            self.color = color
        }
    }

    public struct Item: Equatable {
        public var name: String
        public var value: String
        public var icon: Icon?
        public init(name: String, value: String, icon: Icon?) {
            self.name = name
            self.value = value
            self.icon = icon
        }
        
        public static func == (lhs: SelectMenuViewModel.Item, rhs: SelectMenuViewModel.Item) -> Bool {
            return lhs.value == rhs.value
        }
    }
    
    public var firstSelectIndexPath: IndexPath? {
        guard !selectedItems.isEmpty else {
            return nil
        }
        var index = 0
        for item in allItems {
            if selectedItems.contains(item) {
                return IndexPath(row: index, section: 0)
            }
            index += 1
        }
        return nil
    }
    /// 选中样式
    public var selectionStyle: UITableViewCell.SelectionStyle
    private(set) var allItems: [Item]
    private let preSelectedValues: [String]?
    private var filteredItems: [Item]
    private(set) var selectedItems: [Item] = []
    private let mode: MenuMode
    private(set) var isMulti: Bool
    private(set) var singlePreSelectIndex: IndexPath?
    
    init(items: [Item],
     selectedValues: [String]? = nil,
     selectionStyle: UITableViewCell.SelectionStyle = .default,
     mode: MenuMode = .fullScreen,
     isMulti: Bool = false) {
        self.allItems = items
        self.preSelectedValues = selectedValues
        self.filteredItems = items
        self.selectionStyle = selectionStyle
        self.mode = mode
        self.isMulti = isMulti
        super.init()
        initSelectedItems()
    }

    func filter(keyWord: String, complete: (_ isEmpty: Bool) -> Void) {
        self.filteredItems = keyWord.isEmpty ? self.allItems : self.allItems.filter {
            return $0.name.contains(keyWord)
        }
        complete(self.filteredItems.isEmpty)
    }

    func selectItem(select: Bool, item: Item) {
        if select {
            selectedItems.lf_appendIfNotContains(item)
        } else {
            selectedItems.lf_remove(object: item)
        }
    }
    
    func item(index: Int) -> Item? {
        switch index {
        case 0..<self.filteredItems.count:
            return self.filteredItems[index]
        default:
            return nil
        }
    }
    
    private func initSelectedItems() {
        guard let preSelectedValues = preSelectedValues, !preSelectedValues.isEmpty else {
            return
        }
        
        for item in allItems {
            if preSelectedValues.contains(item.value) {
                selectedItems.lf_appendIfNotContains(item)
            }
        }
    }
}

extension SelectMenuViewModel: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = selectionStyle
        if let cell = cell as? SelectMenuTableViewCell {
            cell.bgColor = UIColor.ud.bgBody
            cell.title = self.filteredItems[indexPath.row].name
            cell.icon = self.filteredItems[indexPath.row].icon
            cell.isChosen = selectedItems.contains(filteredItems[indexPath.row])
            cell.isMulti = isMulti
            cell.isLastCell = (indexPath.row == self.filteredItems.count - 1)
            cell.titleAlignment = (self.mode == .compact && !isMulti) ? .center : .left
            if cell.isChosen && !isMulti {
                singlePreSelectIndex = indexPath
            }
        }
        return cell
    }
}
