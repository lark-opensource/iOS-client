//
//  ApplyCollaborationDetailTableView.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/8/14.
//

import UIKit
import Foundation
import LarkUIKit
import LarkBizAvatar
import LarkMessengerInterface

final class ApplyCollaborationDetailViewModel {
    var contacts: [AddExternalContactModel] = []

    init(contacts: [AddExternalContactModel]) {
        self.contacts = contacts
    }
}

final class ApplyCollaborationDetailTableView: UITableView {
    static let cellIndentifier = String(describing: ApplyCollaborationDetailTableViewCell.self)

    private let viewModel: ApplyCollaborationDetailViewModel

    init(viewModel: ApplyCollaborationDetailViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero, style: .plain)

        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.delegate = self
        self.dataSource = self
        self.separatorStyle = .none
        self.bounces = false
        self.backgroundColor = UIColor.ud.N200
        self.lu.register(cellSelf: ApplyCollaborationDetailTableViewCell.self)
    }
}

private final class ApplyCollaborationDetailTableViewCell: UITableViewCell {
    private let avatarView = BizAvatar()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.contentView.backgroundColor = UIColor.ud.N200

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.height.equalTo(40)
            maker.width.equalTo(40)
            maker.left.equalToSuperview().inset(16)
        }

        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarView.snp.right).offset(12)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(22)
            maker.width.equalTo(90)
        }

        nameLabel.font = .systemFont(ofSize: 16)
    }

    func setContent(
        id: String,
        avatarKey: String,
        name: String
    ) {
        self.avatarView.setAvatarByIdentifier(id, avatarKey: avatarKey, scene: .Contact)
        self.nameLabel.text = name
    }
}

extension ApplyCollaborationDetailTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ApplyCollaborationDetailTableView.cellIndentifier)

        if let cell = cell as? ApplyCollaborationDetailTableViewCell {
            let contact = viewModel.contacts[indexPath.row]
            cell.setContent(id: contact.ID, avatarKey: contact.avatarKey, name: contact.name)
        }

        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}
