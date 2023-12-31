//
//  Bar.swift
//  LarkAI
//
//  Created by Zigeng on 2023/10/19.
//

import Foundation
import UIKit
import UniverseDesignIcon

class SceneDetailNavBar: UIView {
    var confirmAction: (() -> Void)?
    var cancelAction: (() -> Void)?

    var confirmIsEnable: Bool = true {
        didSet {
            confirmButton.setTitleColor(confirmIsEnable ? .ud.colorfulBlue : .ud.textDisabled, for: .normal)
        }
    }

    init(title: String,
         confirmText: String,
         confirmAction: @escaping (() -> Void),
         cancelAction: @escaping (() -> Void)) {
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
        super.init(frame: .zero)
        titleView.text = title
        confirmButton.setTitle(confirmText, for: .normal)

        let lineView = UIView()
        lineView.layer.masksToBounds = true
        lineView.layer.cornerRadius = 2
        lineView.backgroundColor = UIColor.ud.lineBorderCard
        addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(4)
            make.centerX.equalTo(self)
            make.top.equalToSuperview().offset(8)
        }

        let container = UIView()
        addSubview(container)
        container.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(lineView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        container.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        container.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        container.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }

        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private lazy var closeButton: UIButton = {
        let icon = UIImageView(image: UDIcon.closeSmallOutlined)
        let button = UIButton()
        button.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        button.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        return button
    }()

    private lazy var titleView: UILabel = {
        let label = UILabel(frame: .zero)
        return label
    }()

    @objc
    func didTapConfirm(_ button: UIButton) {
        confirmAction?()
    }

    @objc
    func didTapClose(_ button: UIButton) {
        cancelAction?()
    }
}
