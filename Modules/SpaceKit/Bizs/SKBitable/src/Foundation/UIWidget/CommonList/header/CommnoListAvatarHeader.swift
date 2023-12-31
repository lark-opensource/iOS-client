//
//  CommnoListAvatarHeader.swift
//  SKUIKit
//
//  Created by zoujie on 2023/7/26.
//  

import Foundation
import SKUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon

final public class CommnoListAvatarHeader: CommonListBaseHeaderView {
    
    private lazy var iconImageView = UIImageView()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UDColor.textTitle
        return label
    }()
    
    private lazy var templateTag = TemplateTag()
    
    private lazy var closeButton: UIButton = {
        let button = SKHighlightButton()
        button.imageEdgeInsets = UIEdgeInsets(edges: 5)
        button.setImage(UDIcon.closeBoldOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.normalBackgroundColor = UDColor.udtokenTagNeutralBgNormal
        button.highlightBackgroundColor = UDColor.udtokenTagNeutralBgNormalPressed
        return button
    }()
    
    public lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    override func update(headerModel: BTPanelItemActionParams) {
        self.model = headerModel
        nameLabel.text = headerModel.leftAction?.leftText ?? ""
        if let headerIcon = headerModel.leftAction?.headerIconImage {
            iconImageView.image = headerIcon
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }
    }
    
    override func setUpView() {
        super.setUpView()
        containerView.addSubview(iconImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(bottomLine)
        
        iconImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(40)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(10)
        }
        
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-22)
        }
        closeButton.layer.cornerRadius = 12
        closeButton.clipsToBounds = true
        closeButton.hitTestEdgeInsets = UIEdgeInsets(edges: -8)
        closeButton.addTarget(self, action: #selector(didClickClose), for: .touchUpInside)
        
        bottomLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.left.right.bottom.equalToSuperview()
        }
        
        update(headerModel: model)
    }
    
    override func setCloseButtonHidden(isHidden: Bool) {
        closeButton.isHidden = isHidden
    }
    
    override func getHeight() -> CGFloat {
        return 72
    }
    
    @objc
    private func didClickClose() {
        onclick(id: "exit")
    }
    
    func onclick(id: String) {
        clickCallback?(id)
    }
}
