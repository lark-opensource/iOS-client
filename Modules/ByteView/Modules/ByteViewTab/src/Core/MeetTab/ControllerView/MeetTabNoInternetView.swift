//
//  MeetTabNoInternetView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Foundation
import UniverseDesignIcon

class MeetTabNoInternetView: UIView {

    lazy var errorIconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.closeFilled, iconColor: .ud.colorfulRed, size: CGSize(width: 16, height: 16))
        return view
    }()

    lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        label.attributedText = .init(string: I18n.View_G_NoConnection, config: .bodyAssist)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.R100.dynamicColor
        clipsToBounds = true

        addSubview(errorIconView)
        addSubview(errorLabel)

        errorIconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        errorLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.errorIconView.snp.right).offset(8)
            make.centerY.equalTo(self.errorIconView)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
