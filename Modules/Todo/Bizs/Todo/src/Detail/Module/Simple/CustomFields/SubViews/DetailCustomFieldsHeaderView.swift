//
//  DetailCustomFieldsHeaderView.swift
//  Todo
//
//  Created by baiyantao on 2023/4/18.
//

import Foundation
import UniverseDesignFont
import UniverseDesignIcon

struct DetailCustomFieldsHeaderViewData {
    var isCollapsed: Bool = false
}

final class DetailCustomFieldsHeaderView: UIView {

    var viewData: DetailCustomFieldsHeaderViewData? {
        didSet {
            guard let data = viewData else { return }
            let image = data.isCollapsed ? UDIcon.expandRightFilled : UDIcon.expandDownFilled
            iconView.image = image.ud.withTintColor(UIColor.ud.iconN2)
        }
    }

    var clickHandler: (() -> Void)?

    private lazy var containerView = UIView()
    private lazy var iconView = UIImageView()
    private lazy var titleLabel = initTitleLabel()

    init() {
        super.init(frame: .zero)

        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-4)
        }

        containerView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.width.height.equalTo(12)
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(2)
        }
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(iconView.snp.right).offset(8)
            $0.right.equalToSuperview().offset(-2)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.boldSystemFont(ofSize: 14)
        label.text = I18N.Todo_TaskList_ListField_Title
        return label
    }

    @objc
    private func onClick() {
        clickHandler?()
    }
}
