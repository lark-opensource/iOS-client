//
//  ParticipantSearchHeaderView.swift
//  ByteView
//
//  Created by huangshun on 2019/8/3.
//

import Foundation
import SnapKit
import UIKit
import UniverseDesignIcon

class ParticipantSearchHeaderView: UIView {

    lazy var warningImageView: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKey(.vcWarningColorful, size: CGSize(width: 16, height: 16)))
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    lazy var backGroundImageView: UIImageView = {
        let imageView = UIImageView(image: BundleResources.ByteView.Participants.PartcioantSearchTopLayer)
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let lable = UILabel(frame: .zero)
        lable.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lable.textColor = UIColor.ud.textTitle
        lable.text = I18n.View_MV_MeetingLocked_Toast
        return lable
    }()

    lazy var contentStatck: UIStackView = {
        let s = UIStackView(arrangedSubviews: [warningImageView, titleLabel])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 8
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.O100
        addSubview(backGroundImageView)
        addSubview(contentStatck)

        backGroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentStatck.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(12)
        }

        warningImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        titleLabel.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(44)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
