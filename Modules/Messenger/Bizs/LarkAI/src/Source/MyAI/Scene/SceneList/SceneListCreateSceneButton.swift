//
//  SceneListCreateSceneButton.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/9.
//

import Foundation
import UniverseDesignIcon // UDIcon.
import UniverseDesignColor // UIColor.ud.
import EENavigator

protocol SceneListCreateButtonDelegate: AnyObject {
    func didClickCreate(button: UIButton)
}

/// 我的场景，底部创建场景按钮
final class SceneListCreateSceneButton: UIButton {
    weak var delegate: SceneListCreateButtonDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.addTarget(self, action: #selector(self.createScene(button:)), for: .touchUpInside)
        // 配置icon + title，居中展示
        let centerView = UIView()
        self.addSubview(centerView)
        centerView.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        let iconView = UIImageView()
        iconView.image = UDIcon.getIconByKey(UDIconType.moreAddFilled, iconColor: UIColor.ud.primaryContentDefault)
        centerView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.left.equalTo(centerView).offset(4)
            make.centerY.equalTo(centerView)
        }
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.primaryContentDefault
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.text = BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_CreateNew_Button
        centerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(4)
            make.right.equalTo(centerView).offset(-4)
            make.centerY.equalTo(centerView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func createScene(button: UIButton) {
        self.delegate?.didClickCreate(button: button)
    }

    func addTo(viewController: SceneListViewController) {
        viewController.view.addSubview(self)
        delegate = viewController
        self.snp.makeConstraints { make in
            make.left.equalTo(viewController.view).offset(16)
            make.right.equalTo(viewController.view).offset(-16)
            make.height.equalTo(46)
            make.bottom.equalTo(viewController.viewBottomConstraint).offset(-8)
        }
    }
}
