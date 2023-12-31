//
//  SceneListNavigationBar.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/9.
//

import Foundation
import UniverseDesignIcon // UDIcon.

protocol SceneListNavigationBarDelegate: AnyObject {
    func didClickExit(button: UIButton)
}

/// 我的场景，导航栏
final class SceneListNavigationBar: UIView {
    weak var delegate: SceneListNavigationBarDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 用户反馈不好点：这个包一层[48, 48]的按钮，扩大点击热区
        let exitIcon = UIImageView(image: UDIcon.closeSmallOutlined)
        self.addSubview(exitIcon)
        exitIcon.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.left.equalTo(self).offset(16)
            make.centerY.equalTo(self)
        }
        let exitButton = UIButton(frame: .zero)
        exitButton.addTarget(self, action: #selector(self.exit(button:)), for: .touchUpInside)
        self.addSubview(exitButton)
        exitButton.snp.makeConstraints { make in
            make.center.equalTo(exitIcon)
            make.size.equalTo(CGSize(width: 48, height: 48))
        }
        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func exit(button: UIButton) {
        self.delegate?.didClickExit(button: button)
    }

    func addTo(viewController: SceneListViewController) {
        viewController.view.addSubview(self)
        self.delegate = viewController
        self.snp.makeConstraints { make in
            make.top.equalTo(viewController.viewTopConstraint).offset(12)
            make.left.right.equalTo(viewController.view)
            make.height.equalTo(48)
        }
    }
}
