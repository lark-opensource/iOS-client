//
//  SpaceMultiTabContainerController.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/6/20.
//

import SnapKit
import SKCommon
import SKFoundation
import UIKit
import UniverseDesignTabs
import UniverseDesignColor
import RxSwift
import SKUIKit

// 与 SpaceMultiComponentContainerController 逻辑类似，但是 UI 布局有差异
class SpaceMultiTabContainerController: BaseViewController {
    private let bag = DisposeBag()
    private(set) lazy var tabsView: UDTabsTitleView = {
        let view = UDTabsTitleView()
        view.backgroundColor = UDColor.bgBody
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        view.indicators = [indicator]
        view.delegate = self
        let config = view.getConfig()
        config.layoutStyle = .average
        config.itemSpacing = 0
        config.isItemSpacingAverageEnabled = false
        view.setConfig(config: config)
        return view
    }()

    private(set) lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private(set) var components: [SpaceListComponent]

    override var commonTrackParams: [String: String] {
        guard currentIndex < components.count else {
            return [
                "module": "null",
                "sub_module": "none"
            ]
        }
        let bizParams = components[currentIndex].controller.homeViewModel.commonTrackParams
        return [
            "module": bizParams["module"] ?? "null",
            "sub_module": bizParams["sub_module"] ?? "none"
        ]
    }

    private(set) var currentIndex: Int = 0

    init(components: [SpaceListComponent], title: String, initialIndex: Int = 0) {
        self.components = components
        self.currentIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        navigationBar.title = title
        self.bindSubTabChangeSyncAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard currentIndex < components.count else {
            spaceAssertionFailure("current index out of bounds")
            return
        }
        let currentController = components[currentIndex].controller
        currentController.reloadHomeLayout()
    }

    func setupUI() {
        view.backgroundColor = UDColor.bgBody
        navigationController?.isNavigationBarHidden = true

        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
        }

        view.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.bottom.equalTo(tabsView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        components.forEach { component in
            let childController = component.controller
            addChild(childController)
            view.addSubview(childController.view)
            childController.didMove(toParent: self)
            childController.view.snp.makeConstraints { (make) in
                make.top.equalTo(tabsView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
            childController.view.isHidden = true
        }

        tabsView.titles = components.map(\.title)
        tabsView.defaultSelectedIndex = currentIndex
        switchSection(index: currentIndex)
        components.forEach { component in
            component.subSection.didShowSubSection()
        }
    }

    func switchSection(index: Int) {
        guard index < components.count else { return }
        if currentIndex < components.count {
            let component = components[currentIndex]
            component.controller.naviBarCoordinator.update(naviBarProvider: nil)
            component.controller.view.isHidden = true
            component.subSection.notifySectionWillDisappear()
        }
        let previousIndex = currentIndex
        currentIndex = index
        let component = components[index]
        component.controller.naviBarCoordinator.update(naviBarProvider: self)
        component.controller.reloadHomeLayout()
        component.controller.view.isHidden = false
        component.subSection.notifySectionDidAppear()

        if previousIndex != currentIndex {
            component.subSection.reportClick(
                fromSubSectionId: components[previousIndex].subSection.subSectionIdentifier)
        }
    }
    
    private func bindSubTabChangeSyncAction() {
        // 非pad场景下不会有两个列表需要同步tab的场景
        guard SKDisplay.pad else { return }
        NotificationCenter.default.rx.notification(.Docs.notifySelectedListChange)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let userInfo = notification.userInfo as? [String: Any],
                      let index = userInfo["index"] as? Int,
                      let isPad = userInfo["isPad"] as? Bool else {
                    return
                }
                // 仅处理pad列表发送的信号
                guard isPad else { return }
                self?.switchSection(index: index)
                self?.tabsView.defaultSelectedIndex = index
            })
            .disposed(by: bag)
    }
}

extension SpaceMultiTabContainerController: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        guard index != currentIndex else { return }
        switchSection(index: index)
        
        if SKDisplay.pad {
            // 同步相同的pad列表切换相同的tab
            let userInfo: [String: Any] = ["index": index, "isPad": false]
            NotificationCenter.default.post(name: .Docs.notifySelectedListChange, object: nil, userInfo: userInfo)
        }
    }
}

