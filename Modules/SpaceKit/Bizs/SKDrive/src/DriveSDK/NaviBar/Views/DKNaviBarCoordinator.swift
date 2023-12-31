//
//  DKNaviBarCoordinator.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/16.
//

import UIKit
import SKUIKit
import RxSwift
import RxCocoa
import SKFoundation
import SpaceInterface

class DKNaviBarCoordinator {

    typealias ActionHandler = (DKNaviBarItemAction, UIView?, CGRect?) -> Void

    private let naviBar: SKNavigationBar
    private let viewModel: DKNaviBarViewModel
    private let subTitle: String?
    private let naviBarConfig: DriveSDKNaviBarConfig
    private let disposeBag = DisposeBag()

    private let itemsReloadSubject = PublishSubject<Void>()
    private var itemsReloadSignal: Signal<Void> {
        return itemsReloadSubject.asSignal(onErrorSignalWith: .never())
    }
    private var leftItems: [DKNaviBarItem] = []
    private var rightItems: [DKNaviBarItem] = []
    private var updateBag = DisposeBag()
    private var reloadLeftBag = DisposeBag()
    private var reloadRightBag = DisposeBag()
    private var title: String = ""
    
    /// The custom titleView of NavigationBar
    private(set) lazy var customTitleView: DriveSubTitleView = {
        let titleView = DriveSubTitleView()
        return titleView
    }()

    var actionHandler: ActionHandler?

    init(naviBar: SKNavigationBar,
         viewModel: DKNaviBarViewModel,
         subTitle: String? = nil,
         naviBarConfig: DriveSDKNaviBarConfig,
         actionHandler: ActionHandler? = nil) {
        self.naviBar = naviBar
        self.viewModel = viewModel
        self.actionHandler = actionHandler
        self.subTitle = subTitle
        self.naviBarConfig = naviBarConfig
        setup()
    }
    
    // showText: 是否显示title信息，目前groupTab不显示
    func updateTitle(title: String, subTitle: String?, showText: Bool) {
        guard title != self.title, subTitle != self.subTitle else {
            return
        }
        setupNavBar()
        self.updateTitle(title, subTitle: subTitle, showText: showText)
        self.title = title
    }

    private func setupNavBar() {
        removeCustomTitleViewIfNeed()
        naviBar.layoutAttributes.titleHorizontalAlignment = .leading
        naviBar.titleLabel.isHidden = true
        customTitleView.addTo(naviBar)
        naviBar.layoutAttributes.titleHorizontalAlignment = naviBarConfig.titleAlignment
        if SKDisplay.pad {
            // iPad下SKNavigationBar居中展示
            naviBar.layoutAttributes.titleVerticalAlignment = .center
        }
        naviBar.titleView.shouldShowTexts = viewModel.shouldShowTexts
    }
    private func setup() {
        setupNavBar()
        viewModel.fileDeleted.drive(onNext: {[weak self] isDelete in
            guard let self = self else { return }
            guard isDelete else { return }
            self.customTitleView.isHidden = true
            self.showTitleLabel(show: false)
            self.removeWikiTreeItem() // wiki目录树按钮需要单独处理
        }).disposed(by: disposeBag)

        viewModel.rightBarItemsUpdated
            .drive(onNext: { [weak self] items in
                self?.updateRight(items: items)
            })
            .disposed(by: disposeBag)
        viewModel.leftBarItemsUpdated
            .drive(onNext: { [weak self] items in
                self?.updateLeft(items: items)
            })
            .disposed(by: disposeBag)
        itemsReloadSignal.emit(onNext: { [weak self] in
                self?.reloadLeftItems()
                self?.reloadRightItems()
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            viewModel.titleUpdated.asObservable(),
            viewModel.sensitivityRelay.asObservable(),
            viewModel.titleVisableRelay.asObservable()
        ).observeOn(MainScheduler.instance).subscribe { [weak self] title, sensitivityName, visable in
            guard let self = self else { return }
            self.title = title
            self.viewModel.sensitivityName = sensitivityName
            if !sensitivityName.isEmpty {
                self.customTitleView.setSensitivityLabel(haveSubview: self.subTitle != nil)
            }
            self.updateTitle(self.title, subTitle: self.subTitle, showText: self.viewModel.shouldShowTexts)
            self.showTitleLabel(show: visable && !self.viewModel.shouldShowSensitivity)
        }.disposed(by: disposeBag)
    }

    private func updateLeft(items: [DKNaviBarItem]) {
        updateBag = DisposeBag()
        items.forEach { item in
            item.itemVisableChanged.map { _ -> Void in }.bind(to: itemsReloadSubject).disposed(by: updateBag)
        }
        self.leftItems = items
        reloadLeftItems()
    }
    
    private func updateRight(items: [DKNaviBarItem]) {
        updateBag = DisposeBag()
        items.forEach { item in
            item.itemVisableChanged.map { _ -> Void in }.bind(to: itemsReloadSubject).disposed(by: updateBag)
        }
        self.rightItems = items
        reloadRightItems()
    }

    private func reloadRightItems() {
        reloadRightBag = DisposeBag()
        let barItems = rightItems.filter { $0.itemVisable.value }
            .map { (item) -> SKBarButtonItem in
                let barItem = SKBarButtonItem(image: item.itemIcon, style: .plain, target: nil, action: nil)
                barItem.id = item.naviBarButtonID
                barItem.badgeStyle = item.badgeStyle
                barItem.isInSelection = item.isHighLighted
                barItem.useOriginRenderedImage = item.useOriginRenderedImage
                barItem.rx.tap.asDriver()
                    .drive(onNext: { [weak self, weak barItem] _ in
                        guard let barItem = barItem else { return }
                        self?.rightButtonDidClick(barItem, item: item)
                    })
                    .disposed(by: reloadRightBag)
                item.itemEnabledChanged.bind(to: barItem.rx.isEnabled).disposed(by: reloadRightBag)
                return barItem
            }
        naviBar.trailingBarButtonItems = barItems
    }

    private func reloadLeftItems() {
        reloadLeftBag = DisposeBag()
        //1.避免出现同一个按钮被重复添加 2.防止重置leftItems
        for barItem in leftItems {
            guard let index = naviBar.leadingBarButtonItems.firstIndex(where: {
                $0.id == barItem.naviBarButtonID
            }) else {
                continue
            }
            naviBar.leadingBarButtonItems.remove(at: index)
        }
        
        let barItems = leftItems.filter { $0.itemVisable.value }
            .map { (item) -> SKBarButtonItem in
                let barItem = SKBarButtonItem(image: item.itemIcon, style: .plain, target: nil, action: nil)
                barItem.id = item.naviBarButtonID
                barItem.badgeStyle = item.badgeStyle
                barItem.isInSelection = item.isHighLighted
                barItem.rx.tap.asDriver()
                    .drive(onNext: { [weak self, weak barItem] _ in
                        guard let barItem = barItem else { return }
                        self?.leftButtonDidClick(barItem, item: item)
                    })
                    .disposed(by: reloadLeftBag)
                item.itemEnabledChanged.bind(to: barItem.rx.isEnabled).disposed(by: reloadLeftBag)
                return barItem
            }
        naviBar.leadingBarButtonItems += barItems
    }
    
    private func rightButtonDidClick(_ button: SKBarButtonItem, item: DKNaviBarItem) {
        let action = item.itemDidClicked()
        guard case .present = action else {
            actionHandler?(action, nil, nil)
            return
        }
        guard let index = naviBar.trailingBarButtonItems.firstIndex(of: button) else {
            DocsLogger.error("Failed to locate right buttons location")
            actionHandler?(action, nil, nil)
            return
        }
        let rightButtons = naviBar.trailingButtons
        let buttonIndex = rightButtons.count - index - 1
        guard buttonIndex < rightButtons.count else {
            DocsLogger.error("Failed to locate right buttons location")
            actionHandler?(action, nil, nil)
            return
        }
        let button = rightButtons[buttonIndex]
        let frame = button.convert(button.bounds, to: naviBar)
        DocsLogger.driveInfo("frame for button popover: \(frame)")
        actionHandler?(action, naviBar, frame)
    }
    
    private func leftButtonDidClick(_ button: SKBarButtonItem, item: DKNaviBarItem) {
        let action = item.itemDidClicked()
        guard case .present = action else {
            actionHandler?(action, nil, nil)
            return
        }
        guard let index = naviBar.trailingBarButtonItems.firstIndex(of: button) else {
            DocsLogger.error("Failed to locate right buttons location")
            actionHandler?(action, nil, nil)
            return
        }
        let leftButtons = naviBar.leadingButtons
        let buttonIndex = leftButtons.count - index - 1
        guard buttonIndex < leftButtons.count else {
            DocsLogger.error("Failed to locate right buttons location")
            actionHandler?(action, nil, nil)
            return
        }
        let button = leftButtons[buttonIndex]
        let frame = button.convert(button.bounds, to: naviBar)
        DocsLogger.driveInfo("frame for button popover: \(frame)")
        actionHandler?(action, naviBar, frame)
    }
    
    private func updateTitle(_ title: String, subTitle: String?, showText: Bool) {
        if viewModel.shouldShowSensitivity, let name = viewModel.sensitivityName {
            showTitleLabel(show: false)
            customTitleView.isHidden = false
            if let subTitle = subTitle {
                customTitleView.setTitle(title, subTitle: subTitle)
            }
            customTitleView.setSensitivityTitile(title, sensitivityTitle: name)
            setCustomTitleViewOverrideNavigationBarDefaultBehavior()
        } else if let subTitle = subTitle {
            customTitleView.setTitle(title, subTitle: subTitle)
            customTitleView.isHidden = false
            showTitleLabel(show: false)
            setCustomTitleViewOverrideNavigationBarDefaultBehavior()
        } else {
            naviBar.title = title
            customTitleView.isHidden = true
            showTitleLabel(show: showText)
        }
    }
    private func showTitleLabel(show: Bool) {
        guard let titleView = naviBar.titleView as? SKNavigationBarTitle else {
            spaceAssertionFailure("navigation bar has no titleview")
            return
        }
        titleView.shouldShowTexts = show
    }

    private func setCustomTitleViewOverrideNavigationBarDefaultBehavior() {
        guard let titleView = naviBar.titleView as? SKNavigationBarTitle else {
            spaceAssertionFailure("navigation bar has no titleview")
            return
        }
        titleView.overridingCustomViewSizeProvider = { [self] maxAvailableSize in
            customTitleView.actualSizeThatFits(maxAvailableSize)
        }
    }
    
    private func removeCustomTitleViewIfNeed() {
        naviBar.titleView.subviews.forEach { (subView) in
            if subView is DriveSubTitleView {
                subView.removeFromSuperview()
            }
        }
    }
    
    private func removeWikiTreeItem() {
        let curItems = naviBar.leadingBarButtonItems.filter { item in
            return item.id != .tree
        }
        naviBar.leadingBarButtonItems = curItems
    }
}
