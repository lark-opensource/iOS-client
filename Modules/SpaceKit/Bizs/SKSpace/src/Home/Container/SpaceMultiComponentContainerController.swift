//
//  SpaceMultiComponentContainerController.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/1/31.
//

import Foundation
import SKUIKit
import SKFoundation
import SKCommon
import UniverseDesignColor
import SnapKit
import RxSwift
import RxRelay
import RxCocoa

struct SpaceListComponent {
    // TODO: 避免对 section 的直接依赖，改为 listToolProvider
    let subSection: SpaceListSubSection
    let controller: SpaceHomeViewController
    let title: String
    // TODO: 考虑抽成 UI config 配置类，提供拓展性
    // 是否允许 sortTool 展示在 switcher 旁，我的空间和共享空间需要区别处理
    let showSortToolOnSwitcher: Bool
}

// 多列表组合的容器，相比 multiSection 在更高层级上做切换
class SpaceMultiComponentContainerController: BaseViewController {

    private let bag = DisposeBag()

    private lazy var switchView = CloudDriveSwitchView()

    private let components: [SpaceListComponent]

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

    private var currentIndex: Int = 0

    init(components: [SpaceListComponent], title: String) {
        self.components = components
        super.init(nibName: nil, bundle: nil)
        navigationBar.title = title
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

    private func setupUI() {
        view.backgroundColor = UDColor.bgBody
        navigationController?.isNavigationBarHidden = true

        view.addSubview(switchView)
        switchView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }

        components.forEach { component in
            let childController = component.controller
            addChild(childController)
            view.addSubview(childController.view)
            childController.didMove(toParent: self)
            childController.view.snp.makeConstraints { (make) in
                make.top.equalTo(switchView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            childController.view.isHidden = true
        }

        switchView.sectionChangedSignal.emit(onNext: { [weak self] sectionIndex in
            guard let self else { return }
            guard sectionIndex != self.currentIndex else { return }
            self.switchSection(index: sectionIndex)
        })
        .disposed(by: bag)

        switchView.titles = components.map(\.title)
        switchSection(index: 0)
        components.forEach { component in
            component.subSection.didShowSubSection()
        }
    }

    private func switchSection(index: Int) {
        guard index < components.count else { return }
        if currentIndex < components.count {
            let component = components[currentIndex]
            component.controller.naviBarCoordinator.update(naviBarProvider: nil)
            component.controller.view.isHidden = true
            component.subSection.notifySectionWillDisappear()
        }
        currentIndex = index
        let component = components[index]
        component.controller.naviBarCoordinator.update(naviBarProvider: self)
        component.controller.reloadHomeLayout()
        component.controller.view.isHidden = false
        switchView.toolBar.allowSortTool = component.showSortToolOnSwitcher
        switchView.listToolConfigInput.accept(component.subSection.listTools)
        component.subSection.notifySectionDidAppear()
    }
}
