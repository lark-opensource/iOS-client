//
//  ChatInfoToTopCellAndItem.swift
//  Lark
//
//  Created by K3 on 2018/8/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import RxSwift

// MARK: - 置顶 - item
struct ChatInfoToTopModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var descriptionText: String
    var status: Bool
    var switchHandler: ChatInfoSwitchHandler
    var helpButtonHandler: ChatInfoHelpButtonHandler?

    init(
        type: CommonCellItemType,
        cellIdentifier: String,
        style: SeparaterStyle,
        title: String,
        descriptionText: String,
        status: Bool,
        helpButtonHandler: ChatInfoHelpButtonHandler? = nil,
        switchHandler: @escaping ChatInfoSwitchHandler
    ) {
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.title = title
        self.type = type
        self.descriptionText = descriptionText
        self.status = status
        self.switchHandler = switchHandler
        self.helpButtonHandler = helpButtonHandler
    }
}

// MARK: - 置顶 - cell
final class ChatInfoToTopCell: ChatInfoCell {
    fileprivate var titleLabel: UILabel = .init()
    fileprivate var switchButton: LoadingSwitch = .init()
    fileprivate var descriptionLabel: UILabel = .init()
    fileprivate var helpButton: UIButton!
    private let disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(13)
            maker.left.equalToSuperview().offset(16)
            maker.height.equalTo(22).priority(.high)
        }

        helpButton = UIButton()
        helpButton.isHidden = true
        helpButton.setImage(Resources.helpButton, for: .normal)
        helpButton.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        helpButton.addTarget(self, action: #selector(helpButtonClicked), for: .touchUpInside)
        contentView.addSubview(helpButton)
        helpButton.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(16)
            make.trailing.lessThanOrEqualToSuperview()
        }

        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.ud.textPlaceholder
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.left.equalTo(titleLabel.snp.left)
            maker.right.equalToSuperview().offset(-79)
            maker.bottom.equalToSuperview().offset(-13)
        }

        switchButton = LoadingSwitch(behaviourType: .normal)
        switchButton.onTintColor = UIColor.ud.primaryContentDefault
        contentView.addSubview(switchButton)
        switchButton.snp.makeConstraints { (maker) in
            maker.right.centerY.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12))
        }

        switchButton
            .rx.isOn
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (isOn) in
                if let strongSelf = self, strongSelf.canHandleEvent {
                    (strongSelf.item as? ChatInfoToTopModel)?.switchHandler(strongSelf.switchButton, isOn)
                }
            }).disposed(by: disposeBag)
        arrow.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let toTop = item as? ChatInfoToTopModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        helpButton.isHidden = (toTop.helpButtonHandler == nil)
        titleLabel.text = toTop.title
        switchButton.isOn = toTop.status
        layoutSeparater(toTop.style)
        setCell(descriptionText: toTop.descriptionText)
    }

    private func setCell(descriptionText: String = "") {
        descriptionLabel.text = descriptionText
        if descriptionText.isEmpty {
            descriptionLabel.isHidden = true
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                    .inset(UIEdgeInsets(top: 15, left: 16, bottom: 0, right: 75))
                maker.height.equalTo(22.5).priority(.high)
            }
            descriptionLabel.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-12.5)
            }
        } else {
            descriptionLabel.isHidden = false
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.equalToSuperview().offset(12.5)
                maker.left.equalToSuperview().offset(16)
                maker.height.equalTo(22.5).priority(.high)
            }
            descriptionLabel.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-11.5)
            }
        }
    }

    @objc
    private func helpButtonClicked() {
        (self.item as? ChatInfoToTopModel)?.helpButtonHandler?()
    }
}

// MARK: - 消息提醒 - item
typealias ChatInfoNotificationModel = ChatInfoToTopModel
// MARK: - 消息提醒 - cell
typealias ChatInfoNotificationCell = ChatInfoToTopCell

// MARK: - 自动翻译 - item
typealias ChatInfoAutoTranslateModel = ChatInfoToTopModel
// MARK: - 自动翻译 - cell
typealias ChatInfoAutoTranslateCell = ChatInfoToTopCell

// MARK: - 标记 - item
typealias ChatInfoMarkForFlagModel = ChatInfoToTopModel
// MARK: - 标记 - cell
typealias ChatInfoMarkForFlagCell = ChatInfoToTopCell

// MARK: - @所有人不提醒 - item
typealias ChatInfoAtAllSilentModel = ChatInfoToTopModel
// MARK: - @所有人不提醒 - cell
typealias ChatInfoAtAllSilentCell = ChatInfoToTopCell

// MARK: - 免打扰 - cell
typealias ChatInfoMuteCell = ChatInfoToTopCell

// MARK: - 屏蔽机器人消息 - cell
typealias ChatInfoBotForbiddenCell = ChatInfoToTopCell
// MARK: - 屏蔽机器人消息 - item
typealias ChatInfoBotForbiddenModel = ChatInfoToTopModel
