//
//  ChatSettingLabelCell.swift
//  LarkFeedPlugin
//
//  Created by aslan on 2022/4/19.
//

import Foundation
import LarkOpenChat
import LarkUIKit
import UIKit
import LarkTag
import UniverseDesignTag

final class ChatSettingLabelCell: BaseSettingCell, ChatSettingCellProtocol {
    func updateAvailableMaxWidth(_ width: CGFloat) {}

    fileprivate(set) var separater: UIView = .init()
    fileprivate(set) var arrow: UIImageView = .init(image: nil)

    private var titleLabel: UILabel
    private let tagsView: TagsView

    var item: ChatSettingCellVMProtocol? {
        didSet {
            setCellInfo()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel()
        tagsView = TagsView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        separater = UIView()
        separater.backgroundColor = UIColor.ud.lineDividerDefault
        separater.isHidden = true
        contentView.addSubview(separater)

        arrow = UIImageView(image: Resources.LarkFeedPlugin.right_arrow)
        contentView.addSubview(arrow)
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }

        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        // 不可被压缩和拉伸
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.top.equalToSuperview().offset(13)
            maker.bottom.equalToSuperview().offset(-13)
            maker.centerY.equalToSuperview()
        }

        contentView.addSubview(tagsView)
        tagsView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(12).priority(.required)
            make.centerY.equalToSuperview()
            make.right.equalTo(arrow.snp.left).offset(-4)
            make.height.equalTo(18)
        }
        tagsView.setContentHuggingPriority(.required, for: .horizontal)
        tagsView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCellInfo() {
        guard let labelItem = item as? ChatSettingLabelModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = labelItem.title
        tagsView.isHidden = labelItem.labels.isEmpty
        tagsView.update(titles: labelItem.labels)
        layoutSeparater(labelItem.style)
    }

    func layoutSeparater(_ style: ChatSettingSeparaterStyle) {
        if style == .none {
            separater.isHidden = true
        } else {
            separater.isHidden = false
            separater.snp.remakeConstraints { (maker) in
                maker.bottom.right.equalToSuperview()
                maker.height.equalTo(0.5)
                maker.left.equalToSuperview().offset(style == .half ? 16 : 0)
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let addItem = self.item as? ChatSettingLabelModel {
            addItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

final class TagsView: UIView {
    let config: UDTagConfig.TextConfig
    let font = UIFont.systemFont(ofSize: 12, weight: .medium)
    let padding: CGFloat = 8
    let tagSpace: CGFloat = 8
    private var maxWidth: CGFloat = 0
    private var titles: [String] = []
    private var reuseTags: [TagView] = []

    init() {
        self.config = UDTagConfig.TextConfig(
            padding: UIEdgeInsets(top: 0, left: padding / 2, bottom: 0, right: padding / 2),
            font: font,
            textColor: UIColor.ud.T700,
            backgroundColor: UIColor.ud.udtokenTagBgTurquoise)
        super.init(frame: .zero)
        self.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if maxWidth != self.bounds.size.width {
            self.maxWidth = self.bounds.size.width
            self.update(titles: titles)
        }
    }

    func update(titles: [String]) {
        self.titles = titles
        clear()
        var tagsLength: CGFloat = 0
        var isExtraCreat = true
        let maxWidth = maxWidth + self.tagSpace
        titles.forEach { title in
            let tagWidth = getTagWidth(title: title, font: font, padding: self.padding)
            tagsLength += (tagWidth + tagSpace)
            if tagsLength < maxWidth || isExtraCreat {
                if tagsLength >= maxWidth {
                    isExtraCreat = false
                }
                let tag = getTag(title: title)
                self.addSubview(tag)
            } else {
                return
            }
        }

        var trailing = self.snp.trailing
        var offset: CGFloat = 0
        subviews.reversed().forEach { view in
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            view.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.trailing.equalTo(trailing).offset(offset)
            }
            offset = -self.padding
            trailing = view.snp.leading
        }
        subviews.first?.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualToSuperview()
        }
        // 最后一个tag可以被压缩
        subviews.last?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func getTag(title: String) -> TagView {
        if let tag = reuseTags.popLast() {
            tag.text = title
            return tag
        } else {
            let label = TagView(config: config)
            label.text = title
            return label
        }
    }

    func clear() {
        self.subviews.forEach({ view in
            guard let view = view as? TagView else { return }
            view.snp.removeConstraints()
            reuseTags.append(view)
            view.removeFromSuperview()
        })
    }

    func getTagWidth(title: String, font: UIFont, padding: CGFloat) -> CGFloat {
        let size = title.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: self.bounds.size.height), options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size
        return size.width + padding
    }
}

final class TagView: UIView {
    let config: UDTagConfig.TextConfig
    var text: String? {
        didSet {
            label.text = text
        }
    }
    let label = UILabel()
    init(config: UDTagConfig.TextConfig) {
        self.config = config
        super.init(frame: .zero)
        self.clipsToBounds = true
        label.font = config.font
        label.textColor = config.textColor
        self.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(config.padding.top)
            make.leading.equalToSuperview().offset(config.padding.left)
            make.bottom.equalToSuperview().offset(-config.padding.bottom)
            make.trailing.equalToSuperview().offset(-config.padding.right)
        }
        self.layer.cornerRadius = config.cornerRadius
        self.backgroundColor = config.backgroundColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setContentHuggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
        super.setContentHuggingPriority(priority, for: axis)
        subviews.forEach {
            $0.setContentHuggingPriority(priority, for: axis)
        }
    }

    override func setContentCompressionResistancePriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
        super.setContentCompressionResistancePriority(priority, for: axis)
        subviews.forEach {
            $0.setContentCompressionResistancePriority(priority, for: axis)
        }
    }
}
