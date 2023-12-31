//
//  AudioSelectCell.swift
//  ByteView
//
//  Created by wangpeiran on 2022/3/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewUI
import UniverseDesignIcon
import ByteViewNetwork

private extension ParticipantSettings.AudioMode {
    var icon: UIImage? {
        switch self {
        case .internet: return UDIcon.getIconByKey(.systemaudioFilled, iconColor: .ud.iconN2, size: AudioSelectCell.Layout.iconSize)
        case .pstn: return UDIcon.getIconByKey(.callFilled, iconColor: .ud.iconN2, size: AudioSelectCell.Layout.iconSize)
        case .noConnect: return UDIcon.getIconByKey(.disconnectAudioFilled, iconColor: .ud.iconN2, size: AudioSelectCell.Layout.iconSize)
        default: return nil
        }
    }

    var selectedIcon: UIImage? {
        switch self {
        case .internet: return UDIcon.getIconByKey(.systemaudioFilled, iconColor: .ud.primaryContentDefault, size: AudioSelectCell.Layout.iconSize)
        case .pstn: return UDIcon.getIconByKey(.callFilled, iconColor: .ud.primaryContentDefault, size: AudioSelectCell.Layout.iconSize)
        case .noConnect: return UDIcon.getIconByKey(.disconnectAudioFilled, iconColor: .ud.primaryContentDefault, size: AudioSelectCell.Layout.iconSize)
        default: return nil
        }
    }


    var title: String {
        switch self {
        case .internet: return I18n.View_MV_SelectDeviceAudio
        case .pstn: return I18n.View_MV_SelectPhoneAudio
        case .noConnect: return I18n.View_G_DontUseAudioCheck
        default: return ""
        }
    }
}

class AudioSelectCell: UITableViewCell {

    enum Layout {
        static let imageSize: CGSize = CGSize(width: 40, height: 40)
        static let iconSize: CGSize = .init(width: 20, height: 20)
    }

    let titleImageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFit
        return img
    }()

    lazy var iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgFiller
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.addSubview(titleImageView)
        titleImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 16.0)
        return label
    }()

    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = .systemFont(ofSize: 14.0)
        return label
    }()

    let callingLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.text = I18n.View_G_CallingEllipsis
        label.font = .systemFont(ofSize: 14.0)
        label.isHidden = true
        return label
    }()

    let checkImageView: UIImageView = {
        let image = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: .ud.primaryContentDefault, size: Layout.imageSize)
        let img = UIImageView(image: image)
        return img
    }()

    let containerView: UIView = {
        let view = UIView()
        return view
    }()

    let highlightedView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.fillPressed
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    private var audioMode: ParticipantSettings.AudioMode?

    var isCustomSelected: Bool = false {
        didSet {
            titleLabel.textColor = isCustomSelected ? .ud.primaryContentDefault : .ud.textTitle
            titleLabel.font = .systemFont(ofSize: 16, weight: isCustomSelected ? .medium : .regular)
            iconView.backgroundColor = isCustomSelected ? (isHighlighted ? VCScene.isRegular ? .ud.bgFloat : .ud.bgBody : .ud.primaryFillTransparent02) : .ud.bgFiller
            if let mode = audioMode {
                titleImageView.image = isCustomSelected ? mode.selectedIcon : mode.icon
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            highlightedView.isHidden = !isHighlighted
            iconView.backgroundColor = isHighlighted ? VCScene.isRegular ? .ud.bgFloat : .ud.bgBody : isCustomSelected ? .ud.primaryFillTransparent02 : .ud.bgFiller
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // disable-lint: duplicated code
    private func setupSubviews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(containerView)

        containerView.addSubview(highlightedView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subTitleLabel)
        containerView.addSubview(checkImageView)
        containerView.addSubview(callingLabel)

        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        highlightedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.imageSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.top.bottom.equalToSuperview().inset(17)
            make.right.lessThanOrEqualTo(checkImageView.snp.left).offset(-12)
            make.height.equalTo(22)
        }

        checkImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(20)
        }

        callingLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
            make.height.equalTo(20)
        }
    }
    // enable-lint: duplicated code

    func setModel(model: AudioSelectCellItem) {
        self.audioMode = model.audioMode
        titleImageView.image = model.audioMode.icon
        titleLabel.text = model.audioMode.title
        checkImageView.isHidden = !model.isSelect
        callingLabel.isHidden = true
        isCustomSelected = model.isSelect

        if model.isCalling {
            callingLabel.isHidden = false
            checkImageView.isHidden = true
        }

        if let subTitle = model.subTitle, !subTitle.isEmpty {
            subTitleLabel.text = subTitle
            titleLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(8)
                make.left.equalTo(iconView.snp.right).offset(12)
                make.right.lessThanOrEqualTo(checkImageView.snp.left).offset(-12)
                make.height.equalTo(22)
                make.bottom.equalTo(subTitleLabel.snp.top).offset(-2)
            }
            subTitleLabel.snp.remakeConstraints { make in
                make.left.equalTo(titleLabel.snp.left)
                make.right.lessThanOrEqualTo(checkImageView.snp.left).offset(-12)
                make.height.equalTo(20)
                make.bottom.equalToSuperview().inset(8)
            }
        } else {
            subTitleLabel.text = ""
            titleLabel.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview().inset(17)
                make.left.equalTo(iconView.snp.right).offset(12)
                make.right.lessThanOrEqualTo(checkImageView.snp.left).offset(-12)
                make.height.equalTo(22)
            }
        }
    }
}
