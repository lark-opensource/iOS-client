//
//  EdgeTabBar+TableViewCell.swift
//  LarkNavigation
//
//  Created by yaoqihao on 2023/7/2.
//

import Foundation
import AnimatedTabBar
import LarkBadge
import LarkUIKit
import LKCommonsLogging
import LarkSwipeCellKit
import UniverseDesignIcon
import UniverseDesignColor

final class EdgeTabBarTableViewCell: SwipeTableViewCell {
    static let logger = Logger.log(EdgeTabBarTableViewCell.self, category: "LarkNavigation.EdgeTabBarTableViewCell")

    static let selectedBGColor = UIColor.ud.staticWhite70 & UIColor.ud.N90010

    weak var edgeTabBar: NewEdgeTabBar?

    var item: AbstractTabBarItem?

    var itemView: NewEdgeTabView?

    var closeCallback: ((AbstractTabBarItem?) -> Void)?

    var canclose: Bool = false {
        didSet {
            self.itemView?.canclose = canclose
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.swipeView.frame = CGRect(x: self.contentView.bounds.minX, y: self.contentView.bounds.minY + 4,
                                      width: self.contentView.bounds.width, height: self.contentView.bounds.height - 8)
        self.swipeView.backgroundColor = .clear
        self.swipeView.layer.cornerRadius = 10
        self.layer.cornerRadius = 10
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.masksToBounds = true
        self.contentView.clipsToBounds = true
        self.backgroundColor = .clear
        self.selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let layoutProgress = max(0, min(1, (self.frame.width - 58) / 166))
        self.itemView?.layoutProgress = layoutProgress
        if self.isActive {
            self.swipeView.frame = CGRect(x: self.swipeView.frame.minX, y: self.contentView.bounds.minY + 4 * (1 - layoutProgress),
                                          width: self.swipeView.frame.width, height: self.contentView.bounds.height - 8 * (1 - layoutProgress))
        } else {
            self.swipeView.frame = CGRect(x: self.contentView.bounds.minX, y: self.contentView.bounds.minY + 4 * (1 - layoutProgress),
                                          width: self.swipeView.frame.width, height: self.contentView.bounds.height - 8 * (1 - layoutProgress))
        }
    }

    func update(item: AbstractTabBarItem,
                style: EdgeTabBarLayoutStyle) {
        self.swipeView.backgroundColor = item.isSelected ? Self.selectedBGColor : .clear
        Self.logger.info("Update, item:\(item.tab.key)")
        self.itemView?.removeFromSuperview()
        self.item = item
        let itemView = NewEdgeTabView()
        itemView.delegate = self
        itemView.closeCallback = closeCallback
        self.itemView = itemView
        self.swipeView.addSubview(itemView)
        itemView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
        }
        self.itemView?.item = item
        self.itemView?.canclose = canclose
        self.itemView?.layoutProgress = style == .horizontal ? 1 : 0
    }

    func refreshCustomView() {
        itemView?.refreshCustomView()
    }

    override func prepareForReuse() {
        guard let item = item else { return }
        Self.logger.info("Prepare For Reuse, item:\(item.tab.key)")
        self.swipeView.backgroundColor = .clear
        self.itemView?.removeFromSuperview()
        self.item = nil
        self.itemView = nil
        super.prepareForReuse()
    }
}

extension EdgeTabBarTableViewCell: TabBarItemDelegate {
    func tabBarItemDidUpdateBadge(type: BadgeType, style: BadgeStyle) {

    }

    func tabBarItemDidAddCustomView(_ item: AnimatedTabBar.AbstractTabBarItem) {

    }

    func tabBarItemDidChangeAppearance(_ item: AnimatedTabBar.AbstractTabBarItem) {

    }

    func selectedState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {
        guard (self.item?.tab.key ?? "") == item.tab.key else { return }
        self.swipeView.backgroundColor = Self.selectedBGColor
        Self.logger.info("selected State, item:\(item.tab.key)")
    }

    func deselectState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {
        guard (self.item?.tab.key ?? "") == item.tab.key else { return }
        self.swipeView.backgroundColor = .clear
        Self.logger.info("deselect State, item:\(item.tab.key)")
    }
}

final class EdgeTabBarTableViewMoreCell: UITableViewCell {

    var tabbarLayoutStyle: EdgeTabBarLayoutStyle = .vertical {
        didSet{
            moreView.layoutProgress = tabbarLayoutStyle == .horizontal ? 1 : 0
        }
    }

    var moreItem: AbstractTabBarItem? {
        get { moreView.item }
        set { moreView.item = newValue }
    }

    lazy var moreView: NewEdgeTabView = NewEdgeTabView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(moreView)
        moreView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
        }
        self.backgroundColor  = .clear
        self.layer.cornerRadius = 10
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.masksToBounds = true
        self.contentView.clipsToBounds = true
        self.selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.moreView.layoutProgress = max(0, min(1, (self.frame.width - 58) / 166))
    }
}
