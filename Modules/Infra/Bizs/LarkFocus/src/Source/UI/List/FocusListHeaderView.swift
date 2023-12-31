//
//  FocusListHeaderView.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/26.
//

import Foundation
import UIKit
import SnapKit
import LarkInteraction
import UniverseDesignIcon

final class FocusListHeaderView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var buttonWrapper = UIView()

    lazy var addButton: UIButton = {
        let button = ExtendedButton()
        button.extendInsets = UIEdgeInsets(edges: 10)
        button.setImage(UDIcon.addOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN1
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(titleLabel)
        addSubview(buttonWrapper)
        buttonWrapper.addSubview(addButton)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(32)
            make.trailing.lessThanOrEqualTo(addButton.snp.leading).offset(-10)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
        addButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.center.equalToSuperview()
        }
        buttonWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(36)
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-20).priority(999)
        }
    }

    private func setupAppearance() {
        titleLabel.text = BundleI18n.LarkFocus.Lark_Profile_MyStatus
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .highlight))
            buttonWrapper.addLKInteraction(action)
        }
    }
}

extension UITableView {

    /// Set table header view & add Auto layout.
    func setTableHeaderView(headerView: UIView) {
        headerView.translatesAutoresizingMaskIntoConstraints = false

        // Set first.
        self.tableHeaderView = headerView

        // Then setup AutoLayout.
        headerView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        headerView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    }

    /// Update header view's frame.
    func updateHeaderViewFrame() {
        guard let headerView = self.tableHeaderView else { return }

        // Update the size of the header based on its internal content.
        headerView.layoutIfNeeded()

        // ***Trigger table view to know that header should be updated.
        let header = self.tableHeaderView
        self.tableHeaderView = header
    }
}
