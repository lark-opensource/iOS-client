//
//  GroupSettingApproversCellAndItem.swift
//  LarkChatSetting
//
//  Created by bytedance on 2021/10/15.
//

import UIKit
import Foundation
import LarkBizAvatar
import AvatarComponent

// MARK: - 审批经办人（申请群上限） - item
struct GroupSettingApproversItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var approvers: [ApproverItem]
    var onItemTapped: ((ApproverItem) -> Void)?
    var heightChange: (() -> Void)?
}
// MARK: - 审批经办人（申请群上限） - cell
final class GroupSettingApproversCell: GroupSettingCell {
    private var onItemTapped: ((ApproverItem) -> Void)?
    private let containerPadding: CGFloat = 16
    private lazy var approverInfoContainerView: ApproverInfoContainerView = {
        let view = ApproverInfoContainerView(frame: .zero, onItemTapped: { [weak self] item in
            guard let onItemTapped = self?.onItemTapped else {
                return
            }
            onItemTapped(item)
        })
        return view
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(approverInfoContainerView)
        approverInfoContainerView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(containerPadding)
            make.height.equalTo(24)
            make.right.bottom.equalToSuperview().offset(-containerPadding)
        }
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingApproversItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        onItemTapped = item.onItemTapped
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let item = item as? GroupSettingApproversItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        let currentHeight = approverInfoContainerView.bounds.height
        // approverInfoContainerView计算依赖最大宽度，cell在未添加到视图时bounds只返回默认值（比如从未复用过），所以需要在layoutSubviews中获取
        let newHeight = approverInfoContainerView.update(data: item.approvers, maxWidth: self.bounds.width - containerPadding * 2)
        self.approverInfoContainerView.snp.updateConstraints { make in
            make.height.equalTo(newHeight)
        }
        // 这个时机table已完成布局，如果高度变化，需要让table刷新下
        if currentHeight != newHeight {
            item.heightChange?()
        }
    }
}

struct ApproverItem {
    var id: String
    var avatarKey: String
    var name: String
}
private final class ApproverInfoContainerView: UIView {
    private let onItemTapped: ((ApproverItem) -> Void)?
    static fileprivate let lineHeight: CGFloat = 24
    private let lineSpace: CGFloat = 8
    private let itemSpace: CGFloat = 8

    private var approverInfoViews = [ApproverInfoView]()

    init(frame: CGRect, onItemTapped: ((ApproverItem) -> Void)?) {
        self.onItemTapped = onItemTapped
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(data: [ApproverItem]?, maxWidth: CGFloat) -> CGFloat {
        return updateUI(data: data, maxWidth: maxWidth)
    }

    //更新ui并返回总高度
    private func updateUI(data: [ApproverItem]?, maxWidth: CGFloat) -> CGFloat {
        for view in approverInfoViews where view.superview != nil {
            view.removeFromSuperview()
        }
        approverInfoViews.removeAll()
        guard let data = data else {
            return 0
        }
        for item in data {
            let view = ApproverInfoView(frame: .zero, onTapped: onItemTapped)
            view.item = item
            approverInfoViews.append(view)
            addSubview(view)
        }

        var lines: CGFloat = 0
        //当前布局的行 已经占用的宽度
        var currentTotalWidth: CGFloat = 0
        for view in approverInfoViews {
            if currentTotalWidth + view.suggestedWidth > maxWidth {
                currentTotalWidth = 0
                lines += 1
            }
            view.frame = CGRect(x: currentTotalWidth, y: (Self.lineHeight + lineSpace) * lines, width: min(view.suggestedWidth, maxWidth), height: Self.lineHeight)
            currentTotalWidth += view.suggestedWidth + itemSpace
        }
        return Self.lineHeight * (lines + 1) + lineSpace * lines
    }
}

private final class ApproverInfoView: UIView {
    private let onTapped: ((ApproverItem) -> Void)?
    init(frame: CGRect, onTapped: ((ApproverItem) -> Void)?) {
        self.onTapped = onTapped
        super.init(frame: frame)
        setupView()
    }
    private(set) var suggestedWidth: CGFloat = 0
    var item: ApproverItem? {
        didSet {
            updateUI()
        }
    }
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.backgroundColor = .clear
        return label
    }()
    private lazy var avatar: BizAvatar = {
        let view = BizAvatar()
        let config = AvatarComponentUIConfig(style: .circle)
        view.setAvatarUIConfig(config)
        return view
    }()
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupView() {
        backgroundColor = .ud.udtokenTagNeutralBgNormal
        layer.cornerRadius = ApproverInfoContainerView.lineHeight / 2
        addSubview(avatar)
        addSubview(titleLabel)
        avatar.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().offset(2)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatar.snp.right).offset(4)
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandler)))
    }

    @objc
    private func tapHandler() {
        guard let item = self.item else {
            return
        }
        onTapped?(item)
    }

    private func updateUI() {
        guard let item = item else {
            return
        }
        titleLabel.text = item.name
        self.avatar.setAvatarByIdentifier(item.id, avatarKey: item.avatarKey)
        calculateWidth()
    }

    private func calculateWidth() {
        guard let item = item else {
            return
        }
        let labelWidth = widthForString(item.name, font: titleLabel.font)
        suggestedWidth = labelWidth + 20 + 14
    }

    func widthForString(_ string: String, font: UIFont) -> CGFloat {
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: font.pointSize + 10),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }
}
