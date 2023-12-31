//
//  ChatInfoSearchDetailCellAndItem.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/2/3.
//

import UIKit
import Foundation

// MARK: - 搜索聊天细节 - item
struct ChatInfoSearchDetailItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var listViewModel: ChatSettingItemListViewModel
}

// MARK: - 搜索聊天细节 - cell
final class ChatInfoSearchDetailCell: ChatInfoCell {
    private var listView: ChatSettingItemListView?
    private var maxWidth: CGFloat = UIScreen.main.bounds.width

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        arrow.isHidden = true
        self.selectionStyle = .none
    }

    override func updateAvailableMaxWidth(_ width: CGFloat) {
        maxWidth = width
    }

    func update(viewModel: ChatInfoSearchDetailItem) {
        self.layout(viewModel: viewModel)
    }

    private func layout(viewModel: ChatInfoSearchDetailItem) {
        self.listView?.removeFromSuperview()
        let listView = ChatSettingItemListView(viewModel: viewModel.listViewModel, maxWidth: maxWidth)
        self.listView = listView
        contentView.addSubview(listView)
        listView.snp.makeConstraints({ (make) in
            make.top.equalTo(16)
            make.left.equalTo(6)
            make.right.lessThanOrEqualTo(-6)
            make.bottom.equalToSuperview().offset(-16)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let vm = item as? ChatInfoSearchDetailItem else {
            assert(false, "\(self):vm.Type error")
            return
        }
        self.update(viewModel: vm)
        layoutSeparater(vm.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
