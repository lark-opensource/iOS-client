//
//  SKRxNaviBarCoordinator.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/12/9.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation

public protocol SKNaviBarProvider: AnyObject {
    var skNaviBar: SKNaviBarCompatible? { get }
}

public protocol SKNaviBarCompatible {
    func update(trailingBarButtons: [SKBarButtonItem])
    func update(title: String)
    func sourceView(for: SKBarButtonItem) -> UIView?
}

extension SKNavigationBar: SKNaviBarCompatible {
    public func update(trailingBarButtons: [SKBarButtonItem]) {
        trailingBarButtonItems = trailingBarButtons
    }

    public func update(title: String) {
        self.title = title
    }

    public func sourceView(for item: SKBarButtonItem) -> UIView? {
        guard let itemIndex = trailingBarButtonItems.firstIndex(of: item) else {
            DocsLogger.error("space.list.container --- index for navi bar item not found!")
            return nil
        }
        return trailingButtons[itemIndex]
    }
}

public final class SKRxNaviBarCoordinator {

    private(set) public weak var naviBarProvider: SKNaviBarProvider?
    private var providerBag = DisposeBag()

    private var items: [SKRxNaviBarItem] = []
    private let disposeBag = DisposeBag()
    // 导航栏按钮配置变化时，会重置
    private var updateBag = DisposeBag()

    private let itemReloadInput = PublishRelay<Void>()
    private var itemReloadSignal: Signal<Void> { itemReloadInput.asSignal() }
    // 任意导航栏按钮状态变化触发重新布局时，会重置，如按钮可见性发生变化
    private var reloadBag = DisposeBag()

    public init() {
        setup()
    }

    private func setup() {
        itemReloadSignal.emit(onNext: { [weak self] in
            self?.reload()
        })
        .disposed(by: disposeBag)
    }

    public func update(naviBarProvider: SKNaviBarProvider?) {
        providerBag = DisposeBag()
        self.naviBarProvider = naviBarProvider
        if naviBarProvider != nil {
            // 更新 provider 后，主动 reload 一下，让导航栏刷新一下
            itemReloadInput.accept(())
        }
    }

    public func update(items: [SKRxNaviBarItem]) {
        updateBag = DisposeBag()
        items.forEach { item in
            item.itemVisableChanged.map { _ -> Void in }.bind(to: itemReloadInput).disposed(by: updateBag)
        }
        self.items = items
        itemReloadInput.accept(())
    }

    public func update(title: String) {
        // set barItems to naviBar
        guard let naviBar = naviBarProvider?.skNaviBar else {
            DocsLogger.error("space.naviBar.coordinator --- failed to retrive navi bar when reload items")
            return
        }
        naviBar.update(title: title)
    }

    private func reload() {
        reloadBag = DisposeBag()
        let visableItems = items.filter(\.itemVisable.value)
        let barItems = visableItems.map { item -> SKBarButtonItem in
            let barItem = SKBarButtonItem(image: item.itemIcon.value, style: .plain, target: nil, action: nil)
            barItem.id = item.naviBarButtonID
            item.itemIcon.asDriver().skip(1).drive(onNext: { [weak barItem] newImage in
                barItem?.image = newImage
            })
            .disposed(by: reloadBag)
            barItem.rx.tap.asSignal().emit(onNext: { [weak self, weak barItem] _ in
                guard let barItem = barItem else { return }
                self?.didClick(barButton: barItem, item: item)
            }).disposed(by: reloadBag)
            item.itemEnabled.asDriver().drive(barItem.rx.isEnabled).disposed(by: reloadBag)
            return barItem
        }
        // set barItems to naviBar
        guard let naviBar = naviBarProvider?.skNaviBar else {
            DocsLogger.error("space.naviBar.coordinator --- failed to retrive navi bar when reload items")
            return
        }
        naviBar.update(trailingBarButtons: barItems)
    }

    private func didClick(barButton: SKBarButtonItem, item: SKRxNaviBarItem) {
        // get sourceView from naviBar
        guard let naviBar = naviBarProvider?.skNaviBar,
              let sourceView = naviBar.sourceView(for: barButton) else {
            assertionFailure("failed to get sourceView when handle bar button clicked")
            DocsLogger.error("space.naviBar.coordinator --- failed to get sourceView")
            return
        }
        item.itemDidClicked(sourceView: sourceView)
    }
}
