//
//  ChatNavigationBarLeftItemSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/8.
//

import UIKit
import Foundation
import LarkUIKit
import LarkOpenChat
import EENavigator
import UniverseDesignIcon
import UniverseDesignColor
import LarkNavigation
import LarkTab
import RxSwift
import RxCocoa
import LarkContainer
import LarkSplitViewController
import LarkTraitCollection
import LarkTag

// ChatNavigationBarLeftItemSubModule.Store KV 存储 Key
public enum ChatNavigationBarLeftItemSubModuleStoreKey: String {
    case showUnread
    case backDismissTapped
}

public final class ChatNavigationBarLeftItemSubModule: BaseNavigationBarItemSubModule {

    private var metaModel: ChatNavigationBarMetaModel?
    private var badgeDriver: Driver<LarkTab.BadgeType>?
    private var unreadDisposeBag = DisposeBag()
    private var disposeBag = DisposeBag()

    private var showLeftStyle: Bool {
        return (try? self.userResolver.resolve(type: ChatNavigationBarConfigService.self).showLeftStyle) ?? false
    }

    private var dotCornerRadius: CGFloat {
        return self.showLeftStyle ? 6 : 10
    }

    private lazy var dismissButton: UIButton = {
        let dismissButton = UIButton()
        dismissButton.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: UDIcon.getIconByKey(.closeOutlined),
                                                                style: self.context.navigationBarDisplayStyle())
        dismissButton.setImage(image, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonClicked(sender:)), for: .touchUpInside)
        dismissButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        dismissButton.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        dismissButton.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.width.equalTo(28)
        }
        return dismissButton
    }()

    lazy var unreadContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addSubview(self.unreadLabel)
        view.addSubview(self.dotImageView)
        return view
    }()

    private lazy var unreadLabel: ChatUnreadLabel = {
        let unreadLabel = ChatUnreadLabel(frame: .zero)
        if let chat = self.metaModel?.chat {
            if chat.isCrypto {
                unreadLabel.textColor = UIColor.ud.textTitle.alwaysLight
                unreadLabel.color = UIColor.ud.N200.alwaysLight
            } else if chat.chatMode == .threadV2 {
                unreadLabel.color = UIColor.ud.N200
            } else {
                unreadLabel.color = UIColor.ud.staticBlack.withAlphaComponent(0.05) & UIColor.ud.staticWhite.withAlphaComponent(0.1)
            }
        }
        unreadLabel.lu.addTapGestureRecognizer(action: #selector(backButtonClicked), target: self)
        unreadLabel.isHidden = true
        unreadLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        if self.showLeftStyle {
            unreadLabel.paddingLeft = 4
            unreadLabel.paddingRight = 4
            unreadLabel.layer.cornerRadius = 6
        }
        return unreadLabel
    }()

    private lazy var dotImageView: UIImageView = {
        let dotImageView = UIImageView()
        dotImageView.image = UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
        dotImageView.contentMode = .center
        if let chat = self.metaModel?.chat {
            if chat.isCrypto {
                dotImageView.backgroundColor = UIColor.ud.N200
            } else if chat.chatMode == .threadV2 {
                dotImageView.backgroundColor = UIColor.ud.N200
            } else {
                dotImageView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.05) & UIColor.ud.staticWhite.withAlphaComponent(0.1)
            }
        }
        dotImageView.layer.cornerRadius = self.dotCornerRadius
        dotImageView.isHidden = true
        dotImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        dotImageView.setContentHuggingPriority(.required, for: .horizontal)
        return dotImageView
    }()

    lazy var backButton: UIButton = {
        let backButton = UIButton()
        backButton.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: LarkUIKit.Resources.navigation_back_light,
                                                                style: self.context.navigationBarDisplayStyle())

        backButton.setImage(image, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        backButton.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        backButton.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.width.equalTo(28)
        }
        return backButton
    }()

    private var needShowFullScreen: Bool = false {
        didSet {
            if oldValue != needShowFullScreen {
                refreshLeftItem()
            }
        }
    }
    private var fullScreenIsOn: Bool = false {
        didSet {
            if oldValue != fullScreenIsOn {
                updateFullButtonIcon(button: self.fullScreenButton)
            }
        }
    }

    private var returnItemType: NavigationBarRerurnType = .back {
        didSet {
            if oldValue != returnItemType {
                refreshLeftItem()
            }
        }
    }

    func refreshLeftItem() {
        self.buildItems()
        self.context.refreshLeftItems()
    }

    private lazy var fullScreenButton: UIButton = {
        let fullScreenButton = UIButton()
        fullScreenButton.addPointerStyle()
        fullScreenButton.addTarget(self, action: #selector(fullScreenButtonClicked(sender:)), for: .touchUpInside)
        fullScreenButton.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        self.updateFullButtonIcon(button: fullScreenButton)
        return fullScreenButton
    }()

    var _items: [ChatNavigationExtendItem] = []

    var showUnreadLabel: Bool? {
        didSet {
            /// 当值不一样的时候 需要修改约束
            guard oldValue != showUnreadLabel else {
                return
            }
            guard let showUnread = showUnreadLabel else {
                self.dotImageView.snp.removeConstraints()
                self.unreadLabel.snp.removeConstraints()
                return
            }
            if showUnread {
                self.unreadLabel.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                    make.height.equalTo(20)
                    make.width.greaterThanOrEqualTo(20)
                }
                self.dotImageView.snp.removeConstraints()
            } else {
                dotImageView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                    make.height.equalTo(20)
                    make.width.equalTo(26)
                }
                self.unreadLabel.snp.removeConstraints()
            }
        }
    }

    public override var items: [ChatNavigationExtendItem] {
        return _items
    }

    public override func viewWillAppear() {
        self.updateFullScreenItem()
        self.updateReturnItems()
    }

    public override func viewWillRealRenderSubView() {
        self.updateFullScreenItem()
        self.updateReturnItems()
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: self.context.chatVC().view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let vc = self.context.chatVC()
                self.checkShowBackAndDismiss(showBack: vc.hasBackPage,
                                             showDismiss: vc.presentingViewController != nil)
            }).disposed(by: disposeBag)

    }

    private func updateReturnItems() {
        let vc = self.context.chatVC()
        self.checkShowBackAndDismiss(showBack: vc.hasBackPage,
                                     showDismiss: vc.presentingViewController != nil)
    }

    public override func splitDisplayModeChange() {
        self.updateFullScreenItem()
    }

    public override func splitSplitModeChange() {
        self.updateFullScreenItem()
    }
    /// 更新全屏按钮 icon
    private func updateFullButtonIcon(button: UIButton) {
        let icon = self.fullScreenIsOn ?
            LarkSplitViewController.Resources.leaveFullScreen :
            LarkSplitViewController.Resources.enterFullScreen
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: icon,
                                                                style: self.context.navigationBarDisplayStyle())
        button.setImage(
            image,
            for: .normal
        )
    }

    fileprivate func updateFullScreenItem() {
        NavigationBarSubModuleTool.updateFullScreenItemFor(vc: self.context.chatVC()) { [weak self] (needShowFullScreen, isFullScreenOn) in
            self?.needShowFullScreen = needShowFullScreen
            if let isFullScreenOn = isFullScreenOn {
                self?.fullScreenIsOn = isFullScreenOn
            }
        }
    }

    func addBadgeObserver() {
        if self.badgeDriver != nil {
            return
        }

        let badgeDriver = try? self.context.resolver.resolve(assert: TabbarService.self).badgeDriver(for: .feed)
        badgeDriver?.drive(onNext: { [weak self] (badge) in
            guard let `self` = self else { return }
            var messageCount = 0
            switch badge {
            case .number(let num):
                messageCount = Int(num)
            default:
                messageCount = 0
            }
            switch messageCount {
                // 0 则隐藏
            case 0:
                self.unreadLabel.text = ""
                self.unreadLabel.isHidden = true
                self.dotImageView.isHidden = true
                self.unreadContainerView.isHidden = true
                self.showUnreadLabel = nil
                // [1, 99] 显示数字
            case 1...999:
                self.unreadLabel.text = "\(messageCount)"
                self.unreadLabel.isHidden = false
                self.dotImageView.isHidden = true
                self.unreadContainerView.isHidden = false
                self.showUnreadLabel = true
                // [100, +∞] 显示 “99+”
            default:
                self.unreadLabel.text = ""
                self.unreadLabel.isHidden = true
                self.dotImageView.isHidden = false
                self.unreadContainerView.isHidden = false
                self.showUnreadLabel = false
            }
        }).disposed(by: unreadDisposeBag)
        self.badgeDriver = badgeDriver
    }
    /// 不在监听Badge的变化
    func removeBadgeObserver() {
        if self.badgeDriver == nil {
            return
        }
        self.unreadDisposeBag = DisposeBag()
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.metaModel = model
    }

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        self.metaModel = metaModel
        self.buildItems()
    }

    func buildItems() {
        self._items = []
        switch self.returnItemType {
        case .back:
            self._items.append(ChatNavigationExtendItem(type: .back, view: self.backButton))
        case .close:
            self._items.append(ChatNavigationExtendItem(type: .close, view: self.dismissButton))
        case .none:
            break
        }
        let showUnread: Bool = context.store.getValue(for: ChatNavigationBarLeftItemSubModuleStoreKey.showUnread.rawValue) ?? true
        if self.returnItemType != .none,
            !needShowFullScreen, showUnread,
            UIDevice.current.userInterfaceIdiom == .phone {
            self._items.append(ChatNavigationExtendItem(type: .unread,
                                                        view: self.unreadContainerView))
            self.addBadgeObserver()

        } else {
            self.removeBadgeObserver()
        }
        if self.needShowFullScreen {
            self._items.append(ChatNavigationExtendItem(type: .fullScreen,
                                          view: self.fullScreenButton))
        }
    }

    public override func barStyleDidChange() {
        let buttons: [UIButton] = [dismissButton, backButton, fullScreenButton]
        buttons.forEach { button in
            if let image = button.imageView?.image {
                button.setImage(ChatNavigationBarItemTintColor.tintColorFor(image: image,
                                                                            style: self.context.navigationBarDisplayStyle()), for: .normal)
            }
        }
    }

    public func checkShowBackAndDismiss(showBack: Bool, showDismiss: Bool) {
        /// 返回 和 dismiss 按钮互斥
        if showBack {
            self.returnItemType = .back
            return
        }
        if showDismiss {
            self.returnItemType = .close
            return
        }
        self.returnItemType = .none
    }

    // MARK: Actions
    @objc
    private func backButtonClicked(sender: UIButton) {
        let backDismissTapped: (() -> Void)? = context.store.getValue(for: ChatNavigationBarLeftItemSubModuleStoreKey.backDismissTapped.rawValue)
        backDismissTapped?()
        let vc = self.context.chatVC()
        context.nav.pop(from: vc)
    }

    @objc
    private func fullScreenButtonClicked(sender: UIButton) {
        if self.fullScreenIsOn {
            NavigationBarSubModuleTool.leaveFullScreenItemFor(vc: self.context.chatVC())
        } else {
            NavigationBarSubModuleTool.enterFullScreenFor(vc: self.context.chatVC())
        }
    }

    @objc
    private func dismissButtonClicked(sender: UIButton) {
        let backDismissTapped: (() -> Void)? = context.store.getValue(for: ChatNavigationBarLeftItemSubModuleStoreKey.backDismissTapped.rawValue)
        backDismissTapped?()
        let vc = self.context.chatVC()
        switch vc.modalPresentationStyle {
        case .pageSheet, .formSheet, .popover:
            vc.dismiss(animated: true)
        default:
            vc.dismiss(animated: false)
        }
    }
}

private final class ChatUnreadLabel: PaddingUILabel {
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.paddingLeft = 6
        self.paddingRight = 6
        self.isUserInteractionEnabled = true
        self.textAlignment = .center
        self.textColor = UIColor.ud.textTitle
        self.font = UIFont.boldSystemFont(ofSize: 12)
        self.color = UIColor.ud.N200
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 11
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
