//
//  EdgeTabBar+TableViewHeader.swift
//  LarkNavigation
//
//  Created by yaoqihao on 2023/7/3.
//

import Foundation
import AnimatedTabBar
import LarkTab
import UniverseDesignButton
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor

final class EdgeTabBarTableViewHeaderView: UIView {
    enum Layout {
        static var VerticalHeaderViewHeightHasRefresh: CGFloat = 50
        static var VerticalHeaderViewHeightNoRefresh: CGFloat = 10
        static var HorizontalHeaderViewHeightHasRefresh: CGFloat = 59
        static var HorizontalHeaderViewHeightNoRefresh: CGFloat = 23
        static var closeButtonRightMargin: CGFloat = 8
        static var closeButtonHeight: CGFloat = 20
        static var bottomBorderHeight: CGFloat = 1
        static var bottomBorderBottomMarigin: CGFloat = 5
        static var bottomLeftMarigin: CGFloat = 14
        static var bottomVerticalRightMarigin: CGFloat = 14
        static var bottomHorizontalRightMarigin: CGFloat = 4

        static let closeTagIcon = UDIcon.getIconByKey(.spaceDownOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(Self.closeButtonTitleColor)

        static var closeButtonTitleColor: UIColor = UIColor.ud.staticBlack.withAlphaComponent(0.5) & UIColor.ud.staticWhite.withAlphaComponent(0.8)
    }

    static func getHeight(_ tabbarLayoutStyle: EdgeTabBarLayoutStyle = .vertical, showRefreshTabIcon: Bool) -> CGFloat {
        switch tabbarLayoutStyle {
        case .vertical:
            return showRefreshTabIcon ? Self.Layout.VerticalHeaderViewHeightHasRefresh : Self.Layout.VerticalHeaderViewHeightNoRefresh
        case .horizontal:
            return showRefreshTabIcon ? Self.Layout.HorizontalHeaderViewHeightHasRefresh : Self.Layout.HorizontalHeaderViewHeightNoRefresh
        @unknown default:
            fatalError("new value")
        }
    }

    var refreshCallBack: (() -> Void)?
    var closeTagCallBack: (() -> Void)?
    let showClearTemporaryTabs: Bool

    var refreshTabItem: UIView? {
        return self.refreshView
    }

    var showRefreshTabIcon: Bool = false {
        didSet {
            updateUI()
        }
    }

    var tabbarLayoutStyle: EdgeTabBarLayoutStyle = .vertical {
        didSet {
            updateUI()
        }
    }

    var showBottomBorder: Bool = true {
        didSet {
            bottomBorder.isHidden = !showBottomBorder
            guard self.showClearTemporaryTabs, tabbarLayoutStyle == .horizontal else {
                return
            }
            closeButton.isHidden = !showBottomBorder
        }
    }

    private var bottomBorder: UIView = {
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = UIColor.ud.lineDividerDefault
        return bottomBorder
    }()

    lazy var edgeRefreshItem: TabBarItem = {
        let item = TabBarItem(
            tab: Tab(url: "", appType: .native, key: ""),
            title: BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdates_Hover,
            stateConfig: ItemStateConfig(
                defaultIcon: Resources.LarkNavigation.EdgeTab.refresh_icon,
                selectedIcon: Resources.LarkNavigation.EdgeTab.refresh_icon,
                quickBarIcon: nil
            )
        )
        item.itemState = DefaultTabState()
        return item
    }()

    lazy var refreshView: NewEdgeTabView = {
        let view = NewEdgeTabView()
        view.titleLabel.isHidden = true
        view.item = edgeRefreshItem
        return view
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(Self.Layout.closeButtonTitleColor, for: .normal)
        button.setTitle(BundleI18n.LarkNavigation.Lark_Navbar_CloseTabs_Button, for: .normal)
        button.titleLabel?.font = UIFont.ud.caption1
        button.setImage(Self.Layout.closeTagIcon, for: .normal)
        button.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        button.hitTestEdgeInsets = .init(top: -5, left: -10, bottom: -5, right: -10)
        return button
    }()

    init(frame: CGRect, showClearTemporaryTabs: Bool) {
        self.showClearTemporaryTabs = showClearTemporaryTabs
        super.init(frame: frame)

        self.addSubview(bottomBorder)
        self.addSubview(refreshView)
        refreshView.lu.addTapGestureRecognizer(action: #selector(handleTapRefreshButton), target: self)
        refreshView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if self.showClearTemporaryTabs {
            self.addSubview(closeButton)
            closeButton.sizeToFit()
            let closeButtonWith = closeButton.frame.size.width
            closeButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-Self.Layout.closeButtonRightMargin)
                make.bottom.equalToSuperview()
                make.width.equalTo(closeButtonWith)
                make.height.equalTo(Self.Layout.closeButtonHeight)
            }
            bottomBorder.snp.remakeConstraints { make in
                make.height.equalTo(Self.Layout.bottomBorderHeight)
                make.centerY.equalTo(self.closeButton.snp.centerY)
                make.leading.equalToSuperview().offset(Self.Layout.bottomLeftMarigin)
                make.trailing.equalTo(self.closeButton.snp.leading).offset(-Self.Layout.bottomHorizontalRightMarigin)
            }
        } else {
            bottomBorder.snp.remakeConstraints { make in
                make.height.equalTo(Self.Layout.bottomBorderHeight)
                make.leading.equalToSuperview().offset(Self.Layout.bottomLeftMarigin)
                make.trailing.equalToSuperview().offset(-Self.Layout.bottomLeftMarigin)
                make.bottom.equalTo(-Self.Layout.bottomBorderBottomMarigin)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.refreshView.layoutProgress = max(0, min(1, (self.frame.width - 56) / 188))
    }

    private func updateUI() {
        if self.showClearTemporaryTabs {
            if tabbarLayoutStyle == .vertical {
                closeButton.isHidden = true
                bottomBorder.snp.remakeConstraints { make in
                    make.height.equalTo(Self.Layout.bottomBorderHeight)
                    make.bottom.equalTo(-Self.Layout.bottomBorderBottomMarigin)
                    make.leading.equalToSuperview().offset(Self.Layout.bottomLeftMarigin)
                    make.trailing.equalToSuperview().offset(-Self.Layout.bottomLeftMarigin)
                }
            } else {
                closeButton.isHidden = false
                bottomBorder.snp.remakeConstraints { make in
                    make.height.equalTo(Self.Layout.bottomBorderHeight)
                    make.centerY.equalTo(self.closeButton.snp.centerY)
                    make.leading.equalToSuperview().offset(Self.Layout.bottomLeftMarigin)
                    make.trailing.equalTo(self.closeButton.snp.leading).offset(-Self.Layout.bottomHorizontalRightMarigin)
                }
            }
        }
        refreshView.isHidden = !showRefreshTabIcon
        if !showRefreshTabIcon {
            refreshView.snp.removeConstraints()
            return
        }
        refreshView.layoutProgress = tabbarLayoutStyle == .horizontal ? 1 : 0
        refreshView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc
    func closeBtnTapped() {
        closeTagCallBack?()
    }

    @objc private func handleTapRefreshButton() {
        refreshCallBack?()
    }
}
