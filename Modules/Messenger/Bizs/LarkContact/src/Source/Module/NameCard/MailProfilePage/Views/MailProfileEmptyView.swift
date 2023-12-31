//
//  MailProfileEmptyView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/29.
//

import UIKit
import Foundation
import UniverseDesignEmpty

final class MailEmptyStateView: UITableViewCell {

    enum State {
        case none
        case empty
        case reload(handler: () -> Void)
    }

    var state: State = .empty {
        didSet {
            updateState()
        }
    }

    private lazy var emptyView: UDEmpty = {
        return UDEmpty(config: UDEmptyConfig(type: .initial))
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(80)
            make.width.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    private func updateState() {
        switch state {
        case .none:
            emptyView.isHidden = true
        case .empty:
            emptyView.isHidden = false
            // TODO: MP
            let config = UDEmptyConfig(
                title: nil,
                description: .init(descriptionText: BundleI18n.LarkContact.Lark_NewContacts_ProfileNoInfo),
                type: .noData
            )
            emptyView.update(config: config)
        case .reload(let handler):
            emptyView.isHidden = false
            let config = UDEmptyConfig(
                title: nil,
                description: .init(
                    descriptionText: "加载失败，点击重试",
                    operableRange: .init(location: 5, length: 4)
                ),
                type: .loadingFailure,
                labelHandler: handler
            )
            emptyView.update(config: config)
        }
    }
}
