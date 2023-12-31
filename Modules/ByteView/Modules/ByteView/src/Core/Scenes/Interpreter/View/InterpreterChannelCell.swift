//
//  InterpreterChannelCell.swift
//  ByteView
//
//  Created by wulv on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxDataSources
import UniverseDesignIcon
import UIKit

enum InterpreterChannelCellType {
    case cellTypeChannel
    case cellTypeMute
    case cellTypeManage
}

struct InterpreterChannelCellSectionModel {
    var items: [InterpreterChannelCellViewModel]
}

extension InterpreterChannelCellSectionModel: SectionModelType {
    init(original: InterpreterChannelCellSectionModel, items: [InterpreterChannelCellViewModel]) {
        self = original
        self.items = items
    }
}

class InterpreterChannelCellViewModel {

    let id: String
    let model: LanguageType
    var channelTitle: NSAttributedString?
    var isSelected: Bool
    var cellType: InterpreterChannelCellType
    var isEnableMute: Bool
    var isSwitchOn: Bool
    var isRetractBottomLine: Bool
    var isMeetingOpenInterpretation: Bool

    init(with id: String, model: LanguageType, channelTitle: NSAttributedString?, isSelected: Bool = false, cellType: InterpreterChannelCellType = .cellTypeChannel, isEnableMute: Bool = false, isSwitchOn: Bool = false, isRetractBottomLine: Bool = false, isMeetingOpenInterpretation: Bool = false) {
        self.id = id
        self.model = model
        self.channelTitle = channelTitle
        self.isSelected = isSelected
        self.cellType = cellType
        self.isEnableMute = isEnableMute
        self.isSwitchOn = isSwitchOn
        self.isRetractBottomLine = isRetractBottomLine
        self.isMeetingOpenInterpretation = isMeetingOpenInterpretation
    }
}

class InterpreterChannelCell: UITableViewCell {

    lazy var channelLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    lazy var selectIcon: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKey(.doneOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 20, height: 20)))
        return imageView
    }()

    lazy var bottomLine: UIView = {
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    lazy var muteSwitch: UISwitch = {
        let muteSwitch = UISwitch()
        return muteSwitch
    }()

    lazy var rightArrow: UIImageView = {
       let image = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: .ud.iconN3, size: CGSize(width: 12, height: 12))
        return UIImageView(image: image)
    }()

    private var hightLightColor: UIColor = UIColor.ud.fillPressed

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgFloat
        self.backgroundColor = .clear
        loadSubView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadSubView() {
        let marginRight = (safeAreaInsets.right > 0) ? 0 : 20
        let marginLeft = (safeAreaInsets.left > 0) ? 0 : 16

        contentView.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { (maker) in
            maker.bottom.right.equalToSuperview()
            maker.left.equalTo(marginLeft)
            maker.height.equalTo(0.5)
        }

        contentView.addSubview(channelLabel)
        channelLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(marginLeft)
            maker.centerY.equalToSuperview()
        }

        contentView.addSubview(selectIcon)
        selectIcon.snp.makeConstraints { (maker) in
            maker.right.equalTo(-marginRight)
            maker.centerY.equalToSuperview()
        }
        selectIcon.isHidden = true

        contentView.addSubview(muteSwitch)
        muteSwitch.snp.makeConstraints { (maker) in
            maker.right.equalTo(-marginRight)
            maker.centerY.equalToSuperview()
        }
        muteSwitch.isHidden = true

        contentView.addSubview(rightArrow)
        rightArrow.snp.makeConstraints { make in
            make.right.equalTo(-18)
            make.centerY.equalToSuperview()
        }
        rightArrow.isHidden = true
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if isHighlighted {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                    self.contentView.backgroundColor = UIColor.ud.fillPressed
            }, completion: nil)
        } else {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    self.contentView.backgroundColor = UIColor.ud.bgFloat
            }, completion: nil)
        }
    }
}

extension InterpreterChannelCell {
    func config(with viewModel: InterpreterChannelCellViewModel) {
        channelLabel.attributedText = viewModel.channelTitle

        if viewModel.cellType == .cellTypeChannel {
            selectionStyle = .default
            channelLabel.textColor = UIColor.ud.textTitle
            selectIcon.isHidden = !viewModel.isSelected
            muteSwitch.isHidden = true
            rightArrow.isHidden = true
        } else if viewModel.cellType == .cellTypeMute {
            selectionStyle = .none
            channelLabel.textColor = UIColor.ud.textTitle
            selectIcon.isHidden = true
            muteSwitch.isHidden = false
            rightArrow.isHidden = true

            muteSwitch.isOn = viewModel.isSwitchOn
            muteSwitch.isEnabled = viewModel.isEnableMute
            refreshMuteViewStyle(data: (isEnable: viewModel.isEnableMute, isOn: viewModel.isSwitchOn))
        } else if viewModel.cellType == .cellTypeManage {
            selectionStyle = .default
            channelLabel.textColor = UIColor.ud.primaryContentDefault
            selectIcon.isHidden = true
            muteSwitch.isHidden = true
            rightArrow.isHidden = false
        }

        let marginLeft = (safeAreaInsets.left > 0 || viewModel.isRetractBottomLine) ? 0 : 16
        bottomLine.snp.updateConstraints { (maker) in
            maker.left.equalTo(marginLeft)
        }
    }

    func refreshMuteViewStyle(data: (isEnable: Bool, isOn: Bool)) {
        switch data {
        case (true, _):
            muteSwitch.onTintColor = UIColor.ud.primaryContentDefault
            muteSwitch.tintColor = UIColor.ud.lineBorderComponent
            channelLabel.textColor = UIColor.ud.textTitle
        case (false, _):
            muteSwitch.onTintColor = UIColor.ud.primaryFillSolid03
            muteSwitch.tintColor = UIColor.ud.lineBorderCard
            channelLabel.textColor = UIColor.ud.textPlaceholder
        }
    }
}
