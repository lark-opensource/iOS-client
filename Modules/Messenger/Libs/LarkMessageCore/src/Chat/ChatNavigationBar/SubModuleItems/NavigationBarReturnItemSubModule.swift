//
//  ChatNavigationBarCloseItemSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/8.
//

import UIKit
import Foundation
import LarkUIKit
import LarkOpenChat
import LarkModel
import UniverseDesignIcon
import LarkTraitCollection
import RxSwift
import EENavigator

enum NavigationBarRerurnType: Int {
    case none
    case back
    case close
}
class NavigationBarReturnItemSubModule: BaseNavigationBarItemSubModule {

    private var disposeBag = DisposeBag()

    private var _items: [ChatNavigationExtendItem] = []

    override var items: [ChatNavigationExtendItem] {
        return _items
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

    open var showSmallDismissButtom: Bool {
        return false
    }

    var chat: Chat?

    private lazy var backButton: UIButton = {
        let backButton = UIButton()
        backButton.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: LarkUIKit.Resources.navigation_back_light,
                                                                style: self.context.navigationBarDisplayStyle())
        backButton.setImage(image, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        backButton.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        return backButton
    }()

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

    private lazy var smallDismissButton: UIButton = {
        let smallDismissButton = UIButton()
        smallDismissButton.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: UDIcon.getIconByKey(.closeSmallOutlined),
                                                                style: self.context.navigationBarDisplayStyle())
        smallDismissButton.setImage(image, for: .normal)
        smallDismissButton.addTarget(self, action: #selector(dismissButtonClicked(sender:)), for: .touchUpInside)
        smallDismissButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        smallDismissButton.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        smallDismissButton.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.width.equalTo(28)
        }
        return smallDismissButton
    }()

    override func createItems(metaModel: ChatNavigationBarMetaModel) {
        self.buildItems()
    }

    func buildItems() {
        self._items = []
        switch self.returnItemType {
        case .none:
            break
        case .close:
            self._items.append(ChatNavigationExtendItem(type: .close,
                                                        view: showSmallDismissButtom ? self.smallDismissButton : self.dismissButton))
        case .back:
            self._items.append(ChatNavigationExtendItem(type: .back, view: self.backButton))

        }
    }

    override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.chat = model.chat
    }

    override func viewWillAppear() {
        self.updateReturnItem()
    }

    override func viewWillRealRenderSubView() {
        self.updateReturnItem()
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

    private func updateReturnItem() {
        let vc = self.context.chatVC()
        self.checkShowBackAndDismiss(showBack: vc.hasBackPage,
                                     showDismiss: vc.presentingViewController != nil)
    }
    private func checkShowBackAndDismiss(showBack: Bool, showDismiss: Bool) {
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
    open func backButtonClicked(sender: UIButton) {
        let vc = self.context.chatVC()
        self.context.nav.pop(from: vc)
    }

    @objc
    open func dismissButtonClicked(sender: UIButton) {
        self.context.chatVC().dismiss(animated: false)
    }
}
