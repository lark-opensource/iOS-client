//
//  SCDebugViewCell.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/16.
//

import UIKit
import SnapKit
import LarkSecurityComplianceInfra

// 自定义单元格类
public final class SCDebugViewCell: UITableViewCell {
    static let cellTableIdentifier = "SCDebugViewCell"

    private var model: SCDebugModel?

    private weak var uiSwitch: UISwitch?
    private weak var subtitleLabel: UILabel?
    private weak var arrowImageView: UIImageView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalTo(-70)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 根据type更新单元格
    public func configModel(model: SCDebugModel) {
        self.model = model

        uiSwitch?.removeFromSuperview()
        subtitleLabel?.removeFromSuperview()
        arrowImageView?.removeFromSuperview()
        textLabel?.text = model.cellTitle
        switch model.cellType {
        case .switchButton:
            let switchButton = UISwitch()
            switchButton.isOn = model.isSwitchButtonOn
            switchButton.addTarget(self, action: #selector(switchChangedHandler(_:)), for: .valueChanged)
            switchButton.isOn = model.isSwitchButtonOn
            self.contentView.addSubview(switchButton)
            switchButton.snp.makeConstraints { (make) in
                make.trailing.equalTo(-16)
                make.centerY.equalToSuperview()
            }
            self.uiSwitch = switchButton
        case .normal:
            let imageArrow = UIImageView()
            if #available(iOS 13.0, *) {
                imageArrow.image = UIImage(systemName: "chevron.right")
            } else {
                // Fallback on earlier versions
                imageArrow.image = UIImage(named: "arrow.right")
            }
            self.addSubview(imageArrow)
            imageArrow.snp.makeConstraints { (make) in
                make.trailing.equalTo(-16)
                make.centerY.equalToSuperview()
            }
            self.arrowImageView = imageArrow
        default:
            let subtitleLabel = UILabel()
            subtitleLabel.textColor = .gray
            subtitleLabel.text = model.cellSubtitle
            self.addSubview(subtitleLabel)
            subtitleLabel.snp.makeConstraints { (make) in
                make.trailing.equalTo(-16)
                make.centerY.equalToSuperview()
            }
            self.subtitleLabel = subtitleLabel
        }
    }

    @objc
    private func switchChangedHandler(_ uiSwitch: UISwitch) {
        model?.switchHandler?(uiSwitch.isOn)
    }
}
