//
//  FilterSelectionCell.swift
//  LarkSearchCore
//
//  Created by Patrick on 7/2/2023.
//

import UIKit
import Foundation
import LarkBizAvatar
import LarkUIKit
import UniverseDesignIcon
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface

final public class FilterSelectionCell: UITableViewCell {

    private let avatarView = LarkMedalAvatar()
    private let checkBox = LKCheckbox(boxType: .multiple)
    private let checkBoxSpace = UIView()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .ud.textTitle
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .ud.textPlaceholder
        return label
    }()

    private lazy var singleCheckView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.listCheckColorful).ud.withTintColor(.ud.primaryContentDefault)
        view.isHidden = true
        return view
    }()

    private lazy var labelStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        view.axis = .vertical
        view.spacing = 7
        view.alignment = .leading
        view.distribution = .fill
        return view
    }()

    private lazy var contentStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [checkBox, checkBoxSpace, avatarView, labelStack])
        view.axis = .horizontal
        view.spacing = 7
        view.alignment = .center
        view.distribution = .fill
        return view
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        view.isHidden = true
        return view
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(contentStack)
        contentView.addSubview(singleCheckView)
        contentView.addSubview(divider)
        singleCheckView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.trailing.equalToSuperview().inset(21)
            make.centerY.equalToSuperview()
        }

        contentStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            if singleCheckView.isHidden {
                make.trailing.equalToSuperview().inset(16)
            } else {
                make.trailing.equalTo(singleCheckView.snp.leading).offset(-16)
            }
        }

        divider.snp.makeConstraints { make in
            make.leading.equalTo(contentStack)
            make.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
        }
        /// not intercept the cell click event
        checkBox.isUserInteractionEnabled = false
        checkBox.isHidden = true
        checkBox.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: 20, height: 20))
        })

        checkBoxSpace.snp.makeConstraints {
            $0.width.equalTo(checkBox.isHidden ? 0 : 12).constraint
            $0.height.equalTo(0)
        }

        avatarView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 48, height: 48))
        }
    }

    private func setSingleSelected(_ selected: Bool) {
        if selected {
            titleLabel.textColor = .ud.primaryContentDefault
            subtitleLabel.textColor = .ud.primaryContentDefault
            singleCheckView.isHidden = false
        } else {
            titleLabel.textColor = .ud.textTitle
            subtitleLabel.textColor = .ud.textPlaceholder
            singleCheckView.isHidden = true
        }
    }

    private func setMultiSelected(selected: Bool, enabled: Bool) {
        checkBox.isSelected = selected
        checkBox.isEnabled = enabled
    }

    private func reset() {
        avatarView.image = nil
        avatarView.isHidden = false
        divider.isHidden = true
        singleCheckView.isHidden = true
        checkBox.isHidden = true
        checkBox.isSelected = false
        titleLabel.textColor = .ud.textTitle
        subtitleLabel.textColor = .ud.textPlaceholder
    }

    public func setContent(model: ForwardItem,
                           pickerType: UniversalPickerType,
                           currentTenantId: String,
                           hideCheckBox: Bool = false,
                           enabled: Bool,
                           isSelected: Bool = false) {
        guard case let .filter(info) = pickerType else { return }
        reset()
        if !model.avatarKey.isEmpty {
            avatarView.setAvatarByIdentifier(model.id,
                                             avatarKey: model.avatarKey,
                                             scene: .Search,
                                             avatarViewParams: .init(sizeType: .size(48)))
        } else if let imageURLStr = model.imageURLStr,
                  !imageURLStr.isEmpty,
                  let imageURL = URL(string: imageURLStr) {
            avatarView.avatar.bt.setImage(imageURL, completionHandler: { [weak self] imageResult in
                guard let self = self else { return }
                if case let .failure(error) = imageResult {
                    self.avatarView.isHidden = true
                }
            })
        } else {
            avatarView.isHidden = true
        }
        checkBox.isHidden = hideCheckBox
        switch info.optionMode {
        case .single:
            checkBox.isHidden = true
            setSingleSelected(isSelected)
        case .multiple:
            setMultiSelected(selected: isSelected, enabled: enabled)
        @unknown default: assertionFailure("unknown case")
        }
        titleLabel.attributedText = model.attributedTitle
        if model.subtitle.isEmpty {
            subtitleLabel.isHidden = true
            divider.isHidden = false
        } else {
            subtitleLabel.isHidden = false
            subtitleLabel.attributedText = model.attributedSubtitle
            divider.isHidden = true
        }
    }

    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }
    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    func updateCellStyle(animated: Bool) {
        let action: () -> Void = {
            switch (self.isHighlighted, self.isSelected) {
            case (_, true):
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillActive
            case (true, false):
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillFocus
            default:
                self.selectedBackgroundView?.backgroundColor = UIColor.ud.bgBody
            }
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: action)
        } else {
            action()
        }
    }
}
