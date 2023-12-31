//
//  UniversaPickerSelectedTableViewCell.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/9/13.
//

import UIKit
import LarkCore
import Foundation
import LarkListItem
import LarkMessengerInterface

final class UniversaPickerSelectedTableViewCell: UITableViewCell {
    private var tapHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.addSubview(listInfoView)
        contentView.addSubview(deleteButton)
        listInfoView.snp.makeConstraints { (make) in
            make.top.bottom.left.equalToSuperview()
            make.right.lessThanOrEqualTo(deleteButton.snp.left)
        }
        deleteButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(10)
            make.right.equalToSuperview()
        }

        listInfoView.bottomSeperator.snp.remakeConstraints { (make) in
            make.leading.equalTo(listInfoView.nameLabel.snp.leading)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
//            make.trailing.equalTo(self.snp.trailing)
        }
        listInfoView.rightMarginConstraint.update(offset: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var listInfoView: ListItem = {
        let listInfoView = ListItem()
        listInfoView.checkStatus = .invalid
        listInfoView.nameTag.isHidden = true
        listInfoView.additionalIcon.isHidden = true
        listInfoView.statusLabel.isHidden = true
        listInfoView.bottomSeperator.backgroundColor = UIColor.ud.commonTableSeparatorColor
        listInfoView.textContentView.spacing = 4
        listInfoView.statusLabel.setUIConfig(StatusLabel.UIConfig(font: UIFont.systemFont(ofSize: 16)))
        listInfoView.statusLabel.descriptionView.setContentCompressionResistancePriority(.required, for: .horizontal)
        listInfoView.statusLabel.descriptionView.setContentHuggingPriority(.required, for: .horizontal)
        listInfoView.statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        listInfoView.statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        return listInfoView
    }()

    private lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.setImage(Resources.LarkSearchCore.Messenger.picker_selected_close.withRenderingMode(.alwaysTemplate), for: .normal)
        deleteButton.tintColor = UIColor.ud.iconN3
        deleteButton.adjustsImageWhenHighlighted = false
        deleteButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        deleteButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        return deleteButton
    }()

    @objc
    func tapped(_ button: UIButton) {
        self.tapHandler?()
    }

    public func setContent(model: ForwardItem, pickType: UniversalPickerType, tapHandler: @escaping (() -> Void)) {
        self.tapHandler = tapHandler
        listInfoView.avatarView.isHidden = false
        listInfoView.nameLabel.text = model.name
        switch pickType {
        case .folder:
            if let isShardFolder = model.isShardFolder, isShardFolder {
                listInfoView.avatarView.image = Resources.doc_sharefolder_circle
            } else {
                listInfoView.avatarView.image = LarkCoreUtils.docIcon(docType: .folder,
                                                                        fileName: "jpg")
            }
            listInfoView.infoLabel.text = model.description
        case .workspace:
            listInfoView.avatarView.image = Resources.wikibook_circle
            listInfoView.infoLabel.text = model.description
        case .filter:
            if model.avatarKey.isEmpty {
                listInfoView.avatarView.isHidden = true
            } else {
                listInfoView.avatarView.isHidden = false
                listInfoView.avatarView.setAvatarByIdentifier(model.id, avatarKey: model.avatarKey)
            }
        case .chat, .defaultType:
            break
        default: break
        }
    }
}
