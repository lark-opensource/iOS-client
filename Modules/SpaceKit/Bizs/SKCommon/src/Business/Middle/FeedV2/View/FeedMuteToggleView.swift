//
//  FeedMuteToggleView.swift
//  SKCommon
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import SKResource

/// 文档通知免打扰按钮
class FeedMuteToggleView: UIView {

    enum Operation {
        /// 免打扰
        case mute
        /// 打开提醒
        case remind
    }

    var toggleAction: ((Operation) -> ())?

    private(set) var operation: Operation = .mute

    private lazy var icon: UIImageView = {
        return UIImageView()
    }()

    private lazy var button: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(UDColor.textTitle, for: .normal)
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(icon)
        icon.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(17)
        }

        addSubview(button)
        button.snp.makeConstraints {
            $0.leading.equalTo(icon.snp.trailing).offset(6)
            $0.trailing.top.bottom.equalToSuperview()
        }

        setOperation(self.operation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onClick() {
        toggleAction?(operation)
    }
}

extension FeedMuteToggleView {

    func setOperation(_ operation: Operation) {
        self.operation = operation
        switch operation {
        case .mute:
            icon.image = UDIcon.alertsOffOutlined.ud.withTintColor(UDColor.iconN1)
            let text = BundleI18n.SKResource.LarkCCM_Docs_Mute_Button
            button.setTitle(text, for: .normal)
        case .remind:
            icon.image = UDIcon.bellOutlined.ud.withTintColor(UDColor.iconN1)
            let text = BundleI18n.SKResource.LarkCCM_Docs_Unmute_Button
            button.setTitle(text, for: .normal)
        }
    }
}
