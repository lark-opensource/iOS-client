//
//  NetDiagnoseCell.swift
//  LarkMine
//
//  Created by huanglx on 2021/12/16.
//

import Foundation
import LarkUIKit
import UIKit
import UniverseDesignIcon
import UniverseDesignLoading

/// 网络检测cell
final class NetDiagnoseCell: BaseTableViewCell {
    /// 标题
    private let titleLabel = UILabel()
    /// 描述
    private let descLabel = UILabel()
    /// 状态
    private let stateImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgBody
        /// 标题
        self.titleLabel.font = UIFont.ud.title4
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(2)
            make.left.equalTo(16)
            make.width.equalToSuperview().offset(-32)
        }
        /// 描述
        self.descLabel.font = UIFont.systemFont(ofSize: 14)
        self.descLabel.textAlignment = .left
        self.descLabel.numberOfLines = 0
        self.descLabel.textColor = UIColor.ud.textPlaceholder
        self.contentView.addSubview(self.descLabel)
        self.descLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-30)
            make.left.equalTo(16)
            make.width.equalToSuperview().offset(-32)
        }
        ///状态
        self.contentView.addSubview(self.stateImageView)
        self.stateImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.width.height.equalTo(19)
            make.right.equalTo(self.snp.right).offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, desc: String, status: NetDiagnoseStatus) {
        self.removeRotateAnimation(view: self.stateImageView)
        switch status {
        case .unStart:
            self.titleLabel.textColor = UIColor.ud.textTitle
            let icon = UDIcon.getIconByKey(.maybeFilled, size: CGSize(width: 18.3, height: 18.3)).ud.withTintColor(UIColor.ud.iconDisabled)
            self.stateImageView.image = icon
        case .running:
            self.titleLabel.textColor = UIColor.ud.textTitle
            let icon = UDIcon.chatLoadingOutlined.withRenderingMode(.alwaysTemplate)
            self.stateImageView.image = icon
            self.addRoateAnimation(view: self.stateImageView)
        case .normal:
            self.titleLabel.textColor = UIColor.ud.textTitle
            let icon = UDIcon.getIconByKey(.succeedColorful, size: CGSize(width: 18.3, height: 18.3))
            self.stateImageView.image = icon
        case .error:
            self.titleLabel.textColor = UIColor.ud.functionWarningContentDefault
            let icon = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 18.3, height: 18.3))
            self.stateImageView.image = icon
        }
        self.titleLabel.text = title
        self.descLabel.text = desc
    }

    private func removeRotateAnimation(view: UIView) {
        view.layer.removeAllAnimations()
    }

    private func addRoateAnimation(view: UIView) {
        if view.layer.animation(forKey: "rotate") != nil {
            return
        }
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.duration = 0.8
        animation.fillMode = .forwards
        animation.repeatCount = .infinity
        animation.values = [0, Double.pi * 2]
        animation.keyTimes = [NSNumber(value: 0.0), NSNumber(value: 1.0)]

        view.layer.add(animation, forKey: "rotate")
    }
}
