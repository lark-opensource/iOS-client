//
//  TeamConfigCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/4.
//

import Foundation
import SnapKit
import LarkCore
import LarkUIKit
import UIKit

typealias TeamSwitchHandler = (_ switchControl: LoadingSwitch, _ status: Bool) -> Void

struct TeamConfigCellViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle
    var title: String
    var descContent: String?
    var status: Bool
    var cellEnable: Bool
    var switchHandler: TeamSwitchHandler
    var switchunUseHandler: (() -> Void)?

    init(type: TeamCellType,
         cellIdentifier: String,
         style: TeamCellSeparaterStyle,
         title: String,
         descContent: String?,
         status: Bool,
         cellEnable: Bool,
         switchHandler: @escaping TeamSwitchHandler,
         switchunUseHandler: (() -> Void)? = nil) {
        self.type = type
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.title = title
        self.descContent = descContent
        self.status = status
        self.cellEnable = cellEnable
        self.switchHandler = switchHandler
        self.switchunUseHandler = switchunUseHandler
    }
}

// MARK: - 开关 - cell
final class TeamConfigCell: TeamBaseCell {
    fileprivate let contentBackView: UIView
    fileprivate let titleLabel: UILabel
    fileprivate let descLabel: UILabel
    fileprivate let switchButton: LoadingSwitch
    fileprivate let switchMaskView: UIView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.contentBackView = UIView()
        self.titleLabel = UILabel()
        self.descLabel = UILabel()
        self.switchMaskView = UIView()
        self.switchButton = LoadingSwitch(behaviourType: .normal)
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        contentView.addSubview(contentBackView)
        contentBackView.snp.makeConstraints { (maker) in
            maker.top.equalTo(16)
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-79)
            maker.bottom.equalTo(-14)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        contentBackView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.leading.trailing.top.equalToSuperview()
        }

        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.textColor = UIColor.ud.textPlaceholder
        descLabel.numberOfLines = 0
        contentBackView.addSubview(descLabel)
        descLabel.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(2)
        }

        switchButton.onTintColor = UIColor.ud.primaryContentDefault
        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { (maker) in
            maker.right.equalTo(-12)
            maker.centerY.equalToSuperview()
        }
        contentView.addSubview(switchMaskView)
        switchMaskView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(switchButton)
        }

        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tap))
        switchMaskView.addGestureRecognizer(tapGes)
        switchMaskView.backgroundColor = .clear

        switchButton.valueChanged = { [weak self] status in
            if let self = self {
                (self.item as? TeamConfigCellViewModel)?.switchHandler(self.switchButton, status)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? TeamConfigCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        descLabel.text = item.descContent
        switchButton.isOn = item.status
        layoutSeparater(item.style)
        setCell(enable: item.cellEnable)
    }

    private func setCell(enable: Bool) {
        switchButton.isEnabled = enable
        switchMaskView.isHidden = enable
        let alpha: CGFloat = enable ? 1 : 0.4
        switchButton.alpha = alpha
        titleLabel.textColor = enable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
    }

    @objc
    func tap() {
        guard let item = item as? TeamConfigCellViewModel else { return }
        item.switchunUseHandler?()
    }
}
