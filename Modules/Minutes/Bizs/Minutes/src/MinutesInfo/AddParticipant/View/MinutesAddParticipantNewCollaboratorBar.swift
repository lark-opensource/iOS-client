//
//  MinutesAddParticipantNewCollaboratorBar.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/22.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import Kingfisher
import UniverseDesignIcon

@objc protocol AddParticipantNewCollaboratorBarDelegate: UIScrollViewDelegate {
    @objc
    optional func newAvatarBar(_ bar: AddParticipantNewCollaboratorBar, didAddNew: String)
}

// MARK: - Collaborator TableView
class AddParticipantNewCollaboratorBar: UIView {

    weak var delegate: AddParticipantNewCollaboratorBarDelegate?

    var name: String?

    private lazy var barImageView: UIImageView = {
        let contentView = UIImageView(image: UDIcon.getIconByKey(.memberAddOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)))

        return contentView
    }()

    private lazy var barTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var bottomSeparatorLineView: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        contentView.backgroundColor = UIColor.ud.lineDividerDefault
        return contentView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody

        addSubview(barImageView)
        addSubview(barTextLabel)
        addSubview(bottomSeparatorLineView)

        createConstraints()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundViewTapped(gesture:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    func createConstraints() {
        barImageView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.height.equalTo(20)
            $0.width.equalTo(20)
            $0.centerY.equalToSuperview()
        }

        barTextLabel.snp.makeConstraints {
            $0.left.equalTo(barImageView.snp.right).offset(9)
            $0.right.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        bottomSeparatorLineView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateNewAvatarName(_ text: String) {
        var newText = BundleI18n.Minutes.MMWeb_G_AddNameAsParticipant_Desc("\"\(text)\"")
        newText.removeAllAt()
        barTextLabel.text = newText
        name = text
    }

    @objc
    private func backgroundViewTapped(gesture: UITapGestureRecognizer) {
        if let name = name {
            (self.delegate as? AddParticipantNewCollaboratorBarDelegate)?.newAvatarBar?(self, didAddNew: name)
        }
    }
}
