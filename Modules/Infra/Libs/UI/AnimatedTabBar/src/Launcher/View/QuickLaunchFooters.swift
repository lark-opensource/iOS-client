//
//  QuickLaunchFooters.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2023/5/11.
//

import UIKit
import UniverseDesignColor

/// 启动页面底部的 “编辑” 按钮
final class TabEditFooterView: UICollectionReusableView {
    static var identifier: String = "TabEditFooter"

    var editHandler: (() -> Void)?

    private lazy var editButtons: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Legacy_Edit, for: .normal)
        button.titleLabel?.font = UIFont.ud.body1
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.backgroundColor = UIColor.ud.bgFloatOverlay
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.layer.cornerRadius = 15
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addSubview(editButtons)
        editButtons.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(30)
        }
        editButtons.addTarget(self, action: #selector(didTapEditButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapEditButton() {
        editHandler?()
    }
}

/// 启动页面中间的分割线
final class TabDividerFooterView: UICollectionReusableView {
    static var identifier: String = "TabDividerFooterView"

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
