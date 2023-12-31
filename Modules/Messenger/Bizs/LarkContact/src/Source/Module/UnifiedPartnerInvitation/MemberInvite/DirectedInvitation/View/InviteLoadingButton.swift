//
//  InviteLoadingButton.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/6/19.
//

import Foundation
import UIKit
import Lottie
import SnapKit

final class InviteLoadingButton: UIButton {
    static let enableColor = UIColor.ud.primaryContentDefault
    static let highlightedColor = UIColor.ud.primaryContentPressed
    static let disableColor = UIColor.ud.fillDisabled

    lazy private var containerVew: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()
    lazy private var animationView: LOTAnimationView = {
        let view = LOTAnimationView(filePath: BundleConfig.LarkContactBundle.path(forResource: "data", ofType: "json", inDirectory: "Lottie/button_loading") ?? "")
        view.loopAnimation = true
        return view
    }()
    lazy private var contentLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.backgroundColor = .clear
        label.text = BundleI18n.LarkContact.Lark_Invitation_AddMembersSendInvitation
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .left
        return label
    }()
    var title: String {
        return contentLabel.text ?? ""
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                contentLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            } else {
                contentLabel.textColor = UIColor.ud.udtokenBtnPriTextDisabled
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .clear
        setBackgroundImage(UIImage.lu.fromColor(InviteLoadingButton.enableColor), for: .normal)
        setBackgroundImage(UIImage.lu.fromColor(InviteLoadingButton.disableColor), for: .disabled)
        setBackgroundImage(UIImage.lu.fromColor(InviteLoadingButton.highlightedColor), for: .highlighted)
        layer.cornerRadius = IGLayer.commonButtonRadius
        layer.masksToBounds = true
        isEnabled = false
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLoading(_ loading: Bool) {
        if loading {
            animationView.play()
            isEnabled = false
            animationView.snp.updateConstraints { (make) in
                make.width.equalTo(20)
            }
            contentLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview()
                make.left.equalTo(animationView.snp.right).offset(8)
            }
        } else {
            animationView.stop()
            isEnabled = true
            animationView.snp.updateConstraints { (make) in
                make.width.equalTo(0)
            }
            contentLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.centerX.equalToSuperview()
                make.right.equalToSuperview()
            }
        }
    }

    private func layoutPageSubviews() {
        addSubview(containerVew)
        containerVew.addSubview(animationView)
        containerVew.addSubview(contentLabel)
        containerVew.snp.makeConstraints { (make) in
            make.centerX.centerY.height.equalToSuperview()
        }
        animationView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(0)
            make.height.equalTo(20)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
}
