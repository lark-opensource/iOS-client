//
//  ChatInfoTeamItemCellAndItem.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2022/2/14.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import LarkModel
import LarkBizAvatar
import LarkOpenChat
import LarkMessengerInterface

final class ChatInfoTeamHeaderCell: BaseSettingCell, ChatSettingCellProtocol {

    private let titleLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.titleLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .none
        self.selectionStyle = .none
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(8)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAvailableMaxWidth(_ width: CGFloat) {}

    var item: ChatSettingCellVMProtocol? {
        didSet {
            setCellInfo()
        }
    }

    private func setCellInfo() {
        guard let item = item as? ChatInfoTeamHeaderCellModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
    }
}

final class ChatInfoTeamItemCollection: BaseSettingCell, ChatSettingCellProtocol {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .none
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAvailableMaxWidth(_ width: CGFloat) {}

    var item: ChatSettingCellVMProtocol? {
        didSet {
            setCellInfo()
        }
    }

    private func setCellInfo() {
        contentView.btd_removeAllSubviews()
        guard let item = item as? ChatInfoTeamItemsCellModel else { return }
        for i in 0 ..< item.teamCells.count {
            let cell = ChatInfoTeamItemCellView(frame: .zero)
            cell.setCellInfo(item: item.teamCells[i])
            contentView.addSubview(cell)
            if i == 0 {
                cell.snp.makeConstraints { make in
                    make.top.equalToSuperview()
                    make.left.right.equalToSuperview()
                    if i == item.teamCells.count - 1 {
                        make.bottom.equalToSuperview().inset(8)
                    }
                }
            } else if i == item.teamCells.count - 1 {
                cell.snp.makeConstraints { make in
                    make.top.equalTo(contentView.subviews[i - 1].snp.bottom)
                    make.bottom.equalToSuperview().inset(8)
                    make.left.right.equalToSuperview()
                }
            } else {
                cell.snp.makeConstraints { make in
                    make.top.equalTo(contentView.subviews[i - 1].snp.bottom)
                    make.left.right.equalToSuperview()
                }
            }
        }
    }

    @objc
    private func click(_ sender: UIButton) {
        guard let sender = sender as? EnlargeButton, let item = sender.item else { return }
        if item.showMore {
            item.tapHandler(item, self)
        }
    }
}

final class EnlargeButton: UIButton {
    var largeEdge: UIEdgeInsets = .zero
    var item: ChatInfoTeamItem?
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largeFrame = bounds.inset(by: largeEdge)
        return largeFrame.contains(point)
    }
}
