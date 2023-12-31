//
//  NewVotePinConfirmView.swift
//  LarkChat
//
//  Created by bytedance on 2022/4/26.
//

import Foundation
import UniverseDesignCheckBox
import UniverseDesignIcon
import UIKit
import LarkModel
import LarkMessageCore
import SnapKit

final class NewVotePinConfirmCell: UIView {
    let checkBox: UDCheckBox
    let cellLable: UILabel
    public var title: String {
        get {
            return self.cellLable.text ?? ""
        }
        set {
            self.cellLable.text = newValue
        }
    }
    override init(frame: CGRect) {
        self.checkBox = UDCheckBox()
        checkBox.isUserInteractionEnabled = false
        self.cellLable = UILabel()
        cellLable.font = UIFont.systemFont(ofSize: 16)
        cellLable.numberOfLines = 1
        cellLable.textColor = UIColor.ud.N900
        super.init(frame: frame)
        self.addSubview(checkBox)
        self.addSubview(cellLable)
        checkBox.snp.makeConstraints { make in
            make.width.height.equalTo(8)
            make.left.centerY.equalToSuperview()
        }
        cellLable.snp.makeConstraints { make in
            make.left.equalTo(checkBox.snp.right).offset(6)
            make.top.equalToSuperview()
        }
        self.snp.makeConstraints { make in
            make.bottom.equalTo(cellLable)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class NewVotePinConfirmView: PinConfirmContainerView {
    let icon: UIImageView
    let iconContainer: UIView
    let title: UILabel
    let contentView: UIStackView

    override init(frame: CGRect) {
        self.icon = UIImageView(frame: .zero)
        self.iconContainer = UIView(frame: .zero)
        iconContainer.backgroundColor = UIColor.ud.colorfulIndigo
        iconContainer.layer.cornerRadius = 12
        self.title = UILabel(frame: .zero)
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.textColor = UIColor.ud.N900
        title.numberOfLines = 1
        self.contentView = UIStackView(frame: .zero)
        contentView.axis = .vertical
        contentView.spacing = 4
        super.init(frame: frame)
        self.addSubview(iconContainer)
        iconContainer.addSubview(icon)
        self.addSubview(title)
        self.addSubview(contentView)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(14)
            make.center.equalToSuperview()
        }
        iconContainer.snp.makeConstraints { (make) in
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.width.height.equalTo(24)
        }
        title.snp.makeConstraints { (make) in
            make.top.equalTo(iconContainer).offset(2)
            make.left.equalTo(iconContainer.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
        }
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(title.snp.bottom).offset(9)
            make.left.equalTo(title)
            make.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)
        guard let voteContentVM = contentVM as? NewVotePinConfirmViewModel else {
            return
        }
        self.title.text = voteContentVM.title
        self.icon.image = voteContentVM.icon
        let maxLine = 4
        for (index, item) in voteContentVM.itemTitle.enumerated() {
            let cell = NewVotePinConfirmCell(frame: .zero)
            cell.title = index == (maxLine - 1) ? "..." : "\(item)"
            self.contentView.addArrangedSubview(cell)
            if index == (maxLine - 1) {
                break
            }
        }
    }
}

final class NewVotePinConfirmViewModel: PinAlertViewModel {
    var content: VoteContent
    var title: String = ""
    var icon: UIImage {
        return UDIcon.getIconByKey(.voteColorful, iconColor: UIColor.ud.primaryOnPrimaryFill)
    }
    var itemTitle: [String] = []
    init?(voteMessage: Message, getSenderName: @escaping (Chatter) -> String) {
        guard let content = voteMessage.content as? VoteContent else {
            return nil
        }
        self.content = content
        super.init(message: voteMessage, getSenderName: getSenderName)
        self.title = content.topic
        for item in content.options {
            itemTitle.append(item.content)
        }
    }
}
