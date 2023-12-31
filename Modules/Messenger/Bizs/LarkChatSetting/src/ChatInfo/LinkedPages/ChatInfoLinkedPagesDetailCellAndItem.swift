//
//  ChatInfoLinkedPagesDetailCellAndItem.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2023/10/18.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import TangramService
import RustPB
import LarkModel
import LarkSwipeCellKit

struct ChatInfoLinkedPagesDetailItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle = .none
    var verticalPadding: CGFloat = 8
    var titleNumberOfLines: Int = 1
    var linkedPageModel: ChatLinkedPageModel
    var longPressHandler: () -> Void
    var tapHandler: ChatInfoTapHandler
    weak var delegate: SwipeTableViewCellDelegate?
}

final class ChatInfoLinkedPagesDetailCell: SwipeTableViewCell, CommonCellProtocol {

    static var iconSize: CGFloat { 20 }

    private lazy var iconView: UIImageView = UIImageView()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    var item: CommonCellItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.clipsToBounds = true
        swipeView.backgroundColor = UIColor.clear
        swipeView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        swipeView.addSubview(iconView)
        swipeView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.top.bottom.equalToSuperview().inset(8)
            make.right.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(24)
        }
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.size.equalTo(Self.iconSize)
            make.top.equalTo(titleLabel.snp.top).offset(2)
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.swipeView.addGestureRecognizer(longPressGesture)
        setupBackgroundViews()
    }

    private func setupBackgroundViews() {
        backgroundView = DefaultBackgroundView()
        selectedBackgroundView = DefaultSelectedBackgroundView()
    }

    private func DefaultSelectedBackgroundView() -> UIView {
        let bgView = UIView()
        let hoverView = UIView()
        hoverView.backgroundColor = UIColor.ud.fillHover
        hoverView.layer.cornerRadius = 6
        bgView.addSubview(hoverView)
        hoverView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
        bgView.backgroundColor = UIColor.clear
        return bgView
    }

    private func DefaultBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAvailableMaxWidth(_ width: CGFloat) {}

    private func setCellInfo() {
        guard let item = item as? ChatInfoLinkedPagesDetailItem else {
            return
        }
        let verticalPadding = item.verticalPadding
        titleLabel.snp.updateConstraints { make in
            make.top.bottom.equalToSuperview().inset(verticalPadding)
        }
        iconView.bt.setLarkImage(.default(key: ""))
        iconView.image = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: Self.iconSize, height: Self.iconSize))
        if let inlineEntity = item.linkedPageModel.inlineEntity {
            ChatLinkedPagesdUtils.renderIconView(iconView, entity: inlineEntity)
        }
        titleLabel.numberOfLines = item.titleNumberOfLines
        titleLabel.text = item.linkedPageModel.title
        self.delegate = item.delegate
    }

    @objc
    private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        self.hideSwipe(animated: true)
        (self.item as? ChatInfoLinkedPagesDetailItem)?.longPressHandler()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = self.item as? ChatInfoLinkedPagesDetailItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
