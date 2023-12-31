//
//  NewTopicButton.swift
//  LarkAI
//
//  Created by Hayden on 10/7/2023.
//

import UIKit
import FigmaKit
import ServerPB
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignToast
import LarkMessengerInterface

class NewTopicButton: UIButton {
    lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.newtopicOutlined, iconColor: UIColor.ud.iconN1)
        return view
    }()

    /// 新话题title
    lazy var titleView: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkAI.Lark_MyAI_IM_Server_StartNewTopic_Text
        return label
    }()

    enum Status {
        case disable
        case normal
        case loading
    }

    func changeNewTopicButtonStatus(_ status: Status) {
        switch status {
        case .disable:
            self.changeNewTopicButtonToDisable()
        case .normal:
            self.changeNewTopicButtonToNormal()
        case .loading:
            self.changeNewTopicButtonToLoading()
        }
    }

    func changeNewTopicButtonToLoading() {
        isEnabled = false
        titleView.textColor = UIColor.ud.textTitle
        iconView.image = UDIcon.getIconByKey(.loadingOutlined, iconColor: UIColor.ud.primaryContentDefault)
        iconView.lu.addRotateAnimation()
    }

    func changeNewTopicButtonToNormal() {
        isEnabled = true
        titleView.textColor = UIColor.ud.textTitle
        iconView.image = UDIcon.getIconByKey(.newtopicOutlined, iconColor: UIColor.ud.iconN1)
        iconView.lu.removeRotateAnimation()
    }

    func changeNewTopicButtonToDisable() {
        isEnabled = false
        titleView.textColor = UIColor.ud.textDisabled
        iconView.image = UDIcon.getIconByKey(.newtopicOutlined, iconColor: UIColor.ud.iconDisabled)
        iconView.lu.removeRotateAnimation()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconView)
        iconView.snp.makeConstraints { maker in
            maker.size.equalTo(Cons.newTopicIconSize)
            maker.left.equalTo(Cons.quickActionButtonHInset)
            maker.centerY.equalToSuperview()
        }
        addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.left.equalTo(iconView.snp.right).offset(4)
            maker.right.equalTo(-Cons.quickActionButtonHInset)
            maker.centerY.equalToSuperview()
        }
        layer.masksToBounds = true
        // layer.borderWidth = 1
        layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        layer.cornerRadius = Cons.buttonCornerRadius
        setBackgroundImage(UIColor.ud.image(with: UIColor.ud.bgBody, size: CGSize(width: 1, height: 1), scale: 1), for: .normal)
        setBackgroundImage(UIColor.ud.image(with: UIColor.ud.udtokenBtnSeBgNeutralPressed, size: CGSize(width: 1, height: 1), scale: 1), for: .highlighted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        }
    }
}

private typealias Cons = MyAIInteractView.Cons
