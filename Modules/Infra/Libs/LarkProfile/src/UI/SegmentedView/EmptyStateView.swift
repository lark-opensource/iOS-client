//
//  EmptyStateView.swift
//  LarkProfile
//
//  Created by Hayden Wang on 2021/7/15.
//

import Foundation
import UIKit
import UniverseDesignEmpty

final class EmptyStateView: UITableViewCell {

    enum State {
        case none
        case empty
        case privacy
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
        contentView.backgroundColor = UIColor.ud.bgBase
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    private func updateState() {
        switch state {
        case .none:
            emptyView.isHidden = true
        case .empty:
            emptyView.isHidden = false
            let config = UDEmptyConfig(
                title: nil,
                description: .init(descriptionText: BundleI18n.LarkProfile.Lark_NewContacts_ProfileNoInfo),
                type: .noContent
            )
            emptyView.update(config: config)
        case .privacy:
            emptyView.isHidden = false
            let config = UDEmptyConfig(
                title: nil,
                description: .init(descriptionText: BundleI18n.LarkProfile.Lark_Profile_PrivacySettings),
                type: .noAuthority
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
