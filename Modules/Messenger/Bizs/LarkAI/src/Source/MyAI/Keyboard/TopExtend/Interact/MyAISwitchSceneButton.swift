//
//  MyAISwitchSceneButton.swift
//  LarkAI
//
//  Created by Zigeng on 2023/9/26.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignStyle

final class MyAISwitchSceneButton: UIButton {

    let tapAction: () -> Void

    lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.scenarioOutlined, iconColor: UIColor.ud.iconN1)
        return view
    }()

    lazy var titleView: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkAI.MyAI_Scenario_SelectScenario_Button
        return label
    }()

    public init(tapAction: @escaping () -> Void) {
        self.tapAction = tapAction
        super.init(frame: .zero)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTaped)))
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(Cons.newTopicIconSize)
            make.left.equalTo(Cons.sceneSwitchButtonHInset)
            make.centerY.equalToSuperview()
        }
        addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(4)
            make.right.equalTo(-Cons.sceneSwitchButtonHInset)
            make.centerY.equalToSuperview()
        }
        layer.masksToBounds = true
        layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        layer.cornerRadius = Cons.buttonCornerRadius
        setBackgroundImage(UIColor.ud.image(with: UIColor.ud.bgBody, size: CGSize(width: 1, height: 1), scale: 1), for: .normal)
        setBackgroundImage(UIColor.ud.image(with: UIColor.ud.udtokenBtnSeBgNeutralPressed, size: CGSize(width: 1, height: 1), scale: 1), for: .highlighted)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        }
    }

    @objc
    func didTaped() {
        tapAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private typealias Cons = MyAIInteractView.Cons
