//
//  TranslateMoreActionDrawer.swift
//  LarkMessageCore
//
//  Created by Patrick on 3/8/2022.
//

import Foundation
import UniverseDesignIcon
import LarkUIKit
import UIKit

public final class TranslateMoreActionDrawer: NSObject, UITableViewDataSource, UITableViewDelegate {
    public enum UI {
        public static let headerViewHeight: CGFloat = 48 + 20
        public static let cellHeight: CGFloat = 52
        public static let maxCellCountForExpend: Int = 2
        public static let dismissThresholdOffset: CGFloat = 120
        public static let footerHeight: CGFloat = 54
    }
    let translateActions: [TranslateMoreActionModel]

    public init(translateActions: [TranslateMoreActionModel]) {
        self.translateActions = translateActions
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return translateActions.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TranslateMoreActionCell.self)) as? TranslateMoreActionCell else {
            return UITableViewCell()
        }
        let action = translateActions[indexPath.row]
        var locationType: TranslateMoreActionCell.LocationType {
            if indexPath.row == 0 {
                return .first
            } else if indexPath.row == translateActions.count - 1 {
                return .last
            } else {
                return .middle
            }
        }
        cell.set(withAction: action, locationType: locationType)
        return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let action = translateActions[indexPath.row]
        action.tapHandler()
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UI.cellHeight
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

public final class TranslateMoreActionHeaderView: UIView {
    public var didTapCloseButton: (() -> Void)?
    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var headerTitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .ud.textTitle
        label.text = BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMTranslatedText_MoreOptions_MobileTitle
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault.withAlphaComponent(0.15)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .ud.bgFloatBase
        addSubview(container)
        container.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        container.addSubview(headerTitle)
        headerTitle.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        container.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        container.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    @objc
    private func closeButtonTapped() {
        didTapCloseButton?()
    }
}
