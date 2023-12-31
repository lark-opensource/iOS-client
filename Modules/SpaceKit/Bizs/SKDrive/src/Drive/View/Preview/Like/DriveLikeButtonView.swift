//
//  DriveLikeButtonView.swift
//  SpaceKit
//
//  Created by liweiye on 2019/6/3.
//

import UIKit
import SnapKit
import SKCommon
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon

class DriveLikeButtonView: UIView {

    let likeButton: UIButton = {
        let bigButton = DocsButton()
        bigButton.heightInset = -14
        bigButton.widthInset = -14
        bigButton.setImage(UDIcon.thumbsupOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        return bigButton
    }()

    private let likeNumberLabel: UILabel = {
        let likeLabel = UILabel()
        likeLabel.textColor = UDColor.textCaption
        likeLabel.font = UIFont.ct.system(ofSize: 14)
        return likeLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 4
        backgroundColor = UDColor.bgBody
        addSubview(likeButton)
        addSubview(likeNumberLabel)

        likeButton.snp.makeConstraints { (make) in
            make.height.width.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }

        likeNumberLabel.snp.makeConstraints { (make) in
            make.left.equalTo(likeButton.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.height.equalTo(16)
            make.right.equalToSuperview()
        }

        likeButton.docs.addHighlight(with: UIEdgeInsets(top: -6, left: -8, bottom: -6, right: -8),
                                     radius: 8)
    }

    func reload(likeStatus: DriveLikeStatus, likeCount: UInt) {
        likeButton.docs.removeAllPointer()
        switch likeStatus {
        // 当前用户已点赞
        case .hasLiked:
            // 更新点赞按钮
            likeButton.isEnabled = true
            likeButton.setImage(UDIcon.thumbsupFilled.ud.withTintColor(UDColor.primaryContentDefault), for: .normal)
            likeButton.snp.updateConstraints { (make) in
                make.height.width.equalTo(20)
            }

            likeButton.docs.addStandardLift()
            // 更新点赞数
            reloadLikeNumberLabel(likeCount: likeCount)
            likeNumberLabel.isHidden = false
            likeNumberLabel.textColor = UDColor.primaryContentDefault

            backgroundColor = UDColor.primaryContentDefault.withAlphaComponent(0.12)
        case .notLiked:
            // 当前用户未点赞且点赞数为0
            if likeCount == 0 {
                // 更新点赞按钮
                likeButton.isEnabled = true
                likeButton.setImage(UDIcon.thumbsupOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
                likeNumberLabel.textColor = UDColor.textCaption
                likeButton.snp.updateConstraints { (make) in
                    make.height.width.equalTo(24)
                }
                likeButton.docs.addHighlight(with: UIEdgeInsets(top: -6, left: -8, bottom: -6, right: -8),
                                             radius: 8)
                // 更新点赞数
                likeNumberLabel.isHidden = true

                backgroundColor = UDColor.bgBody
            } else {
                // 当前用户未点赞且点赞数大于0
                // 更新点赞按钮
                likeButton.isEnabled = true
                likeButton.setImage(UDIcon.thumbsupOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)

                // 更新点赞数
                reloadLikeNumberLabel(likeCount: likeCount)
                likeNumberLabel.textColor = UDColor.textCaption
                likeNumberLabel.isHidden = false

                backgroundColor = UDColor.bgBody
                likeButton.docs.addHighlight(with: UIEdgeInsets(top: -6, left: -8, bottom: -6, right: -8),
                                             radius: 8)
            }
        default:
            likeButton.isEnabled = false
            likeButton.setImage(UDIcon.thumbsupOutlined.ud.withTintColor(UDColor.iconN1).change(alpha: 0.3), for: .normal)
            likeNumberLabel.isHidden = true
        }
    }

    private func reloadLikeNumberLabel(likeCount: UInt) {
        var numberLabelText = ""
        if likeCount > 99 {
            numberLabelText = "99+"
        } else if likeCount > 0 {
            numberLabelText = "\(likeCount)"
        }
        likeNumberLabel.text = numberLabelText
    }
}
