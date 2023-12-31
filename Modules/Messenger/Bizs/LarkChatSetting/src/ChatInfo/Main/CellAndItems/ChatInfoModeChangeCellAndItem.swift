//
//  ChatInfoModeChangeCellAndItem.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2022/10/8.
//

import UIKit
import Foundation
import UniverseDesignCheckBox
import LarkMessageCore

enum ChatModeSelected {
    case normal
    case thread
}

// MARK: - 群模式切换 - item
struct ChatInfoModeChangeModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var selectedMode: ChatModeSelected
    var modeChange: (ChatModeSelected) -> Void
    //不可选时也会有回调，可以弹提示等操作
    var disableModeChangeClick: (ChatModeSelected) -> Void
    var disableSelect: Bool
    init(type: CommonCellItemType,
         cellIdentifier: String,
         style: SeparaterStyle,
         selectedMode: ChatModeSelected,
         disableSelect: Bool,
         modeChange: @escaping (ChatModeSelected) -> Void,
         disableModeChangeClick: @escaping (ChatModeSelected) -> Void) {
        self.type = type
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.selectedMode = selectedMode
        self.modeChange = modeChange
        self.disableSelect = disableSelect
        self.disableModeChangeClick = disableModeChangeClick
    }
}

// MARK: - 分享群 - cell
final class ChatInfoModeChangeCell: ChatInfoCell {
    private let normalView = ModeSketch(modeNameText: BundleI18n.LarkChatSetting.Lark_IM_GroupTypeSettings_ChatMode_Option, table: NormalChatModeTable(frame: .zero))
    private let threadView = ModeSketch(modeNameText: BundleI18n.LarkChatSetting.Lark_IM_GroupTypeSettings_TopicMode_Option, table: ThreadChatModeTable(frame: .zero))
    private let modeViewWidth: CGFloat = 154
    private var viewModel: ChatInfoModeChangeModel?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.addSubview(normalView)
        normalView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(modeViewWidth)
        }
        self.contentView.addSubview(threadView)
        threadView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(modeViewWidth)
        }
        self.arrow.isHidden = true
        normalView.tapCallBack = { [weak self] in
            if self?.normalView.isSelected ?? false == false {
                self?.normalView.isSelected = true
                self?.threadView.isSelected = false
                self?.viewModel?.modeChange(.normal)
            }
        }
        normalView.disableSelectTapCallBack = { [weak self] in
            self?.viewModel?.disableModeChangeClick(.normal)
        }
        threadView.tapCallBack = { [weak self] in
            if self?.threadView.isSelected ?? false == false {
                self?.threadView.isSelected = true
                self?.normalView.isSelected = false
                self?.viewModel?.modeChange(.thread)
            }
        }
        threadView.disableSelectTapCallBack = { [weak self] in
            self?.viewModel?.disableModeChangeClick(.thread)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatInfoModeChangeModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.viewModel = item
        switch item.selectedMode {
        case .normal:
            normalView.isSelected = true
            threadView.isSelected = false
            normalView.disableSelect = false
            threadView.disableSelect = item.disableSelect
        case .thread:
            normalView.isSelected = false
            threadView.isSelected = true
            threadView.disableSelect = false
            normalView.disableSelect = item.disableSelect
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.bounds.width
        let padding = (width - modeViewWidth * 2) / 3
        normalView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(padding)
        }
        threadView.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(-padding)
        }
    }
}

private class ModeSketch: UIView {
    private let checkbox = UDCheckBox()
    var isSelected: Bool = false {
        didSet {
            checkbox.isSelected = isSelected
        }
    }

    var disableSelect: Bool = false {
        didSet {
            checkbox.isEnabled = !disableSelect
        }
    }

    var tapCallBack: (() -> Void)?
    var disableSelectTapCallBack: (() -> Void)?

    init(modeNameText: String, table: UIView) {
        super.init(frame: .zero)

        table.backgroundColor = UIColor.ud.bgFloat
        table.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        table.layer.borderWidth = 1
        table.layer.cornerRadius = 10
        table.layer.masksToBounds = true
        self.addSubview(table)
        table.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
        }

        let modeName: UILabel = UILabel(frame: .zero)
        modeName.numberOfLines = 1
        modeName.text = modeNameText
        modeName.textColor = UIColor.ud.textTitle
        modeName.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(modeName)
        modeName.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(table.snp.bottom).offset(16)
        }
        checkbox.respondsToUserInteractionWhenDisabled = true
        self.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(20)
            make.top.equalTo(modeName.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
        }
        checkbox.tapCallBack = { [weak self] box in
            if box.isEnabled {
                self?.tapCallBack?()
            } else {
                self?.disableSelectTapCallBack?()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ThreadChatModeTable: UIView {
    private let cellInfos: [ThreadChatModeCellInfo] = [ThreadChatModeCellInfo(root: (Resources.fakeUser1, BundleI18n.LarkChatSetting.Lark_IM_Sketch_GiftIsGreat_Text),
                                                                              replies: [(Resources.fakeUser2, BundleI18n.LarkChatSetting.Lark_IM_Sketch_FamilyLikeItToo_Text),
                                                                                        (Resources.fakeUser3, BundleI18n.LarkChatSetting.Lark_IM_Sketch_True_Text)]),
                                                       ThreadChatModeCellInfo(root: (Resources.fakeUser4, BundleI18n.LarkChatSetting.Lark_IM_Sketch_HelloImLeo_Text),
                                                                              replies: [(Resources.fakeUser1, BundleI18n.LarkChatSetting.Lark_IM_Sketch_Leo_Text),
                                                                                        (Resources.fakeUser2, BundleI18n.LarkChatSetting.Lark_IM_Sketch_WelcomeAboard_Text)])]
    override init(frame: CGRect) {
        super.init(frame: frame)
        var recentCell: ThreadChatModeCell?
        for i in 0..<cellInfos.count {
            let cell = ThreadChatModeCell(info: cellInfos[i])
            self.addSubview(cell)
            cell.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(10)
                make.right.lessThanOrEqualToSuperview().offset(-10)
                if let recentCell = recentCell {
                    make.top.equalTo(recentCell.snp.bottom).offset(12)
                } else {
                    make.top.equalToSuperview().offset(12)
                }
                if i == cellInfos.count - 1 {
                    make.bottom.equalToSuperview().offset(-12)
                }
            }
            recentCell = cell
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct ThreadChatModeCellInfo {
    let root: (avatar: UIImage?, content: String)
    let replies: [(avatar: UIImage?, content: String)]
}

private class ThreadChatModeCell: UIView {
    init(info: ThreadChatModeCellInfo) {
        super.init(frame: .zero)
        let rootAvatar = UIImageView(frame: .zero)
        rootAvatar.layer.cornerRadius = 8
        rootAvatar.layer.masksToBounds = true
        rootAvatar.image = info.root.avatar
        self.addSubview(rootAvatar)
        rootAvatar.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(6)
            make.width.height.equalTo(16)
        }

        let rightContainer = UIView(frame: .zero)
        rightContainer.layer.cornerRadius = 8
        rightContainer.layer.masksToBounds = true
        rightContainer.layer.cornerRadius = 10
        rightContainer.layer.borderWidth = 1
        rightContainer.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        self.addSubview(rightContainer)
        rightContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(rootAvatar.snp.right).offset(4)
            make.bottom.equalToSuperview()
            make.width.equalTo(114)
            make.right.equalToSuperview()
        }
        let rootContent: UILabel = UILabel(frame: .zero)
        rootContent.font = UIFont.systemFont(ofSize: 10)
        rootContent.textColor = UIColor.ud.textTitle
        rootContent.setContentHuggingPriority(.defaultHigh, for: .vertical)
        rootContent.numberOfLines = 1
        rootContent.text = info.root.content
        rightContainer.addSubview(rootContent)
        rootContent.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.left.equalToSuperview().offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-8)
        }
        let line: UIView = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        rightContainer.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalTo(rootContent.snp.bottom).offset(4)
        }
        var recentReply: UIView?
        for i in 0 ..< info.replies.count {
            let reply = info.replies[i]
            let replyView = UIView(frame: .zero)
            rightContainer.addSubview(replyView)
            replyView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(8)
                make.right.lessThanOrEqualToSuperview().offset(-8)
                if let recentReply = recentReply {
                    make.top.equalTo(recentReply.snp.bottom).offset(4)
                } else {
                    make.top.equalTo(line.snp.bottom).offset(4)
                }
                if i == info.replies.count - 1 {
                    make.bottom.equalToSuperview().offset(-6)
                }
            }
            recentReply = replyView
            let replyAvatar = UIImageView(frame: .zero)
            replyAvatar.layer.cornerRadius = 6
            replyAvatar.layer.masksToBounds = true
            replyAvatar.image = reply.avatar
            replyView.addSubview(replyAvatar)
            replyAvatar.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalTo(12)
            }
            let replyContent: UILabel = UILabel(frame: .zero)
            replyContent.font = UIFont.systemFont(ofSize: 8)
            replyContent.textColor = UIColor.ud.textTitle
            replyContent.numberOfLines = 1
            replyContent.text = reply.content
            replyContent.setContentHuggingPriority(.defaultHigh, for: .vertical)
            replyView.addSubview(replyContent)
            replyContent.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(replyAvatar.snp.right).offset(4)
                make.right.lessThanOrEqualToSuperview()
                make.height.equalTo(13)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class NormalChatModeTable: UIView {
    private let cellInfos: [(String, UIImage?, UIColor)] = [(BundleI18n.LarkChatSetting.Lark_IM_Sketch_GiftIsGreat_Text, Resources.fakeUser1, UDMessageColorTheme.imMessageBgBubblesGrey),
                                                            (BundleI18n.LarkChatSetting.Lark_IM_Sketch_True_Text, Resources.fakeUser3, UDMessageColorTheme.imMessageBgBubblesBlue),
                                                            (BundleI18n.LarkChatSetting.Lark_IM_Sketch_HelloImLeo_Text, Resources.fakeUser4, UDMessageColorTheme.imMessageBgBubblesGrey),
                                                            (BundleI18n.LarkChatSetting.Lark_IM_Sketch_Leo_Text, Resources.fakeUser1, UDMessageColorTheme.imMessageBgBubblesGrey)]
    override init(frame: CGRect) {
        super.init(frame: frame)
        var recentCell: NormalChatModeCell?
        for i in 0..<cellInfos.count {
            let cell = NormalChatModeCell(contentText: cellInfos[i].0,
                                          avatarImage: cellInfos[i].1,
                                          bubbleColor: cellInfos[i].2)
            self.addSubview(cell)
            cell.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(10)
                make.right.lessThanOrEqualToSuperview().offset(-10)
                if let recentCell = recentCell {
                    make.top.equalTo(recentCell.snp.bottom).offset(12)
                } else {
                    make.top.equalToSuperview().offset(12)
                }
                if i == cellInfos.count - 1 {
                    make.bottom.equalToSuperview().offset(-15)
                }
            }
            recentCell = cell
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class NormalChatModeCell: UIView {
    init(contentText: String, avatarImage: UIImage?, bubbleColor: UIColor) {
        super.init(frame: .zero)
        let avatar = UIImageView(frame: .zero)
        avatar.layer.cornerRadius = 8
        avatar.layer.masksToBounds = true
        avatar.image = avatarImage
        self.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
        }

        let bubble = UIView(frame: .zero)
        bubble.backgroundColor = bubbleColor
        bubble.layer.cornerRadius = 6
        bubble.layer.masksToBounds = true
        self.addSubview(bubble)
        bubble.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(avatar.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }

        let content = UILabel(frame: .zero)
        content.text = contentText
        content.font = UIFont.systemFont(ofSize: 10)
        content.numberOfLines = 1
        content.textColor = UIColor.ud.textTitle
        bubble.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
