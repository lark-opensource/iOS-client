//
//  BanningSettingChattersCellItem.swift
//  LarkChatSetting
//
//  Created by yuhaixin.2000 on 2020/7/6.
//

import UIKit
import Foundation
import RxCocoa
import LarkUIKit

struct BanningSettingChattersItem: BanningSettingItem {
    var identifier: String
    var chatters: [BanningSettingItem]
    var cellWidth: CGFloat
    var onItemSelected: (BanningSettingItem) -> Void
}

final class BanningSettingChattersCell: BaseSettingCell, BanningSettingCell {
    private(set) var item: BanningSettingItem?

    private var chatterCellWrapper = UIView()
    private var chatterCells: [UIControl] = []
    private let leftSpacing: CGFloat = 50.0 // 跟上边对齐 间距16 + 按钮18 + 间距16
    private var totalRows: Int {
        return (self.chatterCells.count - 1 + cellsInOneLine) / cellsInOneLine
    }
    private var cellsInOneLine: Int {
        guard let item = item as? BanningSettingChattersItem else { return 0 }
        return Int((item.cellWidth - leftSpacing) / 44)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(chatterCellWrapper)
        chatterCellWrapper.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(item: BanningSettingItem) {
        guard let item = item as? BanningSettingChattersItem else {
            assert(false, "item type error")
            return
        }

        self.item = item

        generateChatterCells(chatters: item.chatters)
        chatterCellWrapper.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(totalRows * 40 + 16)
        }
        layoutChatterCells()
    }

    func generateChatterCells(chatters: [BanningSettingItem]) {
        // Remove all previous cells
        chatterCells.forEach { $0.removeFromSuperview() }
        chatterCells = []
        // Generate new cells
        for (index, item) in chatters.enumerated() {
            if let cell = self.generateNewCell(item: item, index: index) {
                chatterCellWrapper.addSubview(cell)
                chatterCells.append(cell)
            }
        }
    }

    func generateNewCell(item: BanningSettingItem, index: Int) -> UIControl? {
        let frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        var newCell: (UIControl & BanningSettingCell)?

        if item is BanningSettingAvatarItem {
            newCell = BanningSettingAvatarCell(frame: frame)
        } else if item is BanningSettingEditItem {
            newCell = BanningSettingEditCell(frame: frame)
        }

        newCell?.set(item: item)
        newCell?.tag = index
        newCell?.addTarget(self, action: #selector(itemSelected), for: .touchUpInside)
        return newCell
    }

    func layoutChatterCells() {
        var column = 0
        var row = 0
        for button in chatterCells {
            button.frame.origin = CGPoint(x: column * 44 + Int(leftSpacing), y: row * 40 + 12)
            if column == cellsInOneLine - 1 {
                column = 0
                row += 1
            } else {
                column += 1
            }
        }
    }

    @objc
    func itemSelected(_ cell: UIControl) {
        guard let cell = cell as? BanningSettingCell, let cellItem = cell.item else { return }
        guard let item = item as? BanningSettingChattersItem else { return }
        item.onItemSelected(cellItem)
    }
}
