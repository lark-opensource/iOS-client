//
//  ChatInfoChatBoxCellAndItem.swift
//  LarkChatSetting
//
//  Created by liuxianyu on 2022/3/30.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import RxSwift

// MARK: - 添加到会话盒子 - item
struct ChatInfoChatBoxModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var descriptionText: String
    var status: Bool
    var cellEnable: Bool
    var switchHandler: ChatInfoSwitchHandler
    var helpButtonHandler: ChatInfoHelpButtonHandler?

    init(
        type: CommonCellItemType,
        cellIdentifier: String,
        style: SeparaterStyle,
        title: String,
        descriptionText: String,
        status: Bool,
        cellEnable: Bool,
        helpButtonHandler: ChatInfoHelpButtonHandler? = nil,
        switchHandler: @escaping ChatInfoSwitchHandler
    ) {
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.title = title
        self.type = type
        self.descriptionText = descriptionText
        self.status = status
        self.cellEnable = cellEnable
        self.switchHandler = switchHandler
        self.helpButtonHandler = helpButtonHandler
    }
}

// MARK: - 置顶 - cell
final class ChatInfoChatBoxCell: ChatInfoCell {
    private let disposeBag = DisposeBag()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var switchButton: LoadingSwitch = {
        let button = LoadingSwitch(behaviourType: .normal)
        button.onTintColor = UIColor.ud.primaryContentDefault
        return button
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        return label
    }()

    lazy var helpButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.setImage(Resources.helpButton, for: .normal)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        return button
    }()

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.iconDisabled
        view.layer.cornerRadius = 0.65
        view.layer.masksToBounds = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(13)
            maker.left.equalToSuperview().offset(36)
            maker.height.equalTo(22).priority(.high)
        }

        contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(self.titleLabel)
            maker.left.equalToSuperview().offset(18)
            maker.width.equalTo(12)
            maker.height.equalTo(1.3)
        }

        helpButton.addTarget(self, action: #selector(helpButtonClicked), for: .touchUpInside)
        contentView.addSubview(helpButton)
        helpButton.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(16)
            make.trailing.lessThanOrEqualToSuperview()
        }

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.left.equalTo(titleLabel.snp.left)
            maker.right.equalToSuperview().offset(-79)
            maker.bottom.equalToSuperview().offset(-13)
        }

        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { (maker) in
            maker.right.centerY.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12))
        }

        switchButton
            .rx.isOn
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (isOn) in
                if let self = self, self.canHandleEvent {
                    (self.item as? ChatInfoChatBoxModel)?.switchHandler(self.switchButton, isOn)
                }
            }).disposed(by: disposeBag)

        arrow.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let chatBox = item as? ChatInfoChatBoxModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        helpButton.isHidden = (chatBox.helpButtonHandler == nil)
        titleLabel.text = chatBox.title
        switchButton.isOn = chatBox.status
        layoutSeparater(chatBox.style)
        setCell(enable: chatBox.cellEnable, descriptionText: chatBox.descriptionText)
    }

    private func setCell(enable: Bool, descriptionText: String = "") {
        switchButton.isEnabled = enable
        let alpha: CGFloat = enable ? 1 : 0.4
        switchButton.alpha = alpha
        titleLabel.alpha = alpha
        descriptionLabel.text = descriptionText
        if descriptionText.isEmpty {
            descriptionLabel.isHidden = true
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                    .inset(UIEdgeInsets(top: 15, left: 36, bottom: 0, right: 75))
                maker.height.equalTo(22.5).priority(.high)
            }
            descriptionLabel.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-12.5)
            }
        } else {
            descriptionLabel.isHidden = false
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.equalToSuperview().offset(12.5)
                maker.left.equalToSuperview().offset(36)
                maker.height.equalTo(22.5).priority(.high)
            }
            descriptionLabel.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-11.5)
            }
        }
    }

    @objc
    private func helpButtonClicked() {
        (self.item as? ChatInfoChatBoxModel)?.helpButtonHandler?()
    }
}
