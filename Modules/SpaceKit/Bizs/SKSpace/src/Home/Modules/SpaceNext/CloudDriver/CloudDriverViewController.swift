//
//  CloudDriverViewController.swift
//  SKSpace
//
//  Created by majie.7 on 2023/12/6.
//

import Foundation
import SKCommon
import SKResource
import RxSwift
import LarkContainer
import LarkUIKit
import SKUIKit
import UniverseDesignColor

class CloudDriverViewController: SpaceMultiTabContainerController {
    
    private lazy var pinFolderListView: CloudDriverPinFolderView = {
        let viewModel = QuickAccessViewModel(dataModel: QuickAccessDataModel(userID: userResolver.userID, apiType: .justFolder))
        return CloudDriverPinFolderView(viewModel: viewModel)
    }()
    
    private let userResolver: UserResolver
    
    private let disposeBag = DisposeBag()
    private var homeDisposeBag = DisposeBag()
    
    init(userResolver: UserResolver,
         components: [SpaceListComponent],
         title: String,
         initialIndex: Int = 0) {
        self.userResolver = userResolver
        super.init(components: components, title: title, initialIndex: initialIndex)
        self.bindAction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func setupUI() {
        view.backgroundColor = UDColor.bgBody
        navigationController?.isNavigationBarHidden = true
        
        view.addSubview(pinFolderListView)
        
        pinFolderListView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        
        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { make in
            make.top.equalTo(pinFolderListView.snp.bottom)
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
    
    override func switchSection(index: Int) {
        super.switchSection(index: index)
        bindSpaceHomeAction()
    }
    
    private func bindSpaceHomeAction() {
        let currentHomeVC = components[currentIndex].controller
        guard let homeVM = currentHomeVC.homeViewModel as? SpaceStandardHomeViewModel else {
            return
        }
        homeDisposeBag = DisposeBag()
        pinFolderListView.viewModel.actionSignal
            .map { action in
                return SpaceHomeAction.sectionAction(action)
            }
            .emit(to: homeVM.actionInput)
            .disposed(by: homeDisposeBag)
    }
    
    private func updateFolderListViewSizeIfNeed(show: Bool) {
        pinFolderListView.isHidden = !show
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else { return }
            if show {
                self.pinFolderListView.snp.updateConstraints { make in
                    make.height.equalTo(self.pinFolderListView.viewHeight)
                }
            } else {
                self.pinFolderListView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
            }
            self.view.layoutIfNeeded()
        }
    }
    
    private func bindAction() {
        pinFolderListView.viewAllButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] _ in
                guard let self, let vcFactory = try? self.userResolver.resolve(assert: SpaceVCFactory.self) else {
                    return
                }
                
                let pinFolderListVC = vcFactory.makePinFolderListViewController()
                userResolver.navigator.push(pinFolderListVC, from: self)
            })
            .disposed(by: disposeBag)
        
        pinFolderListView.updateShowStatusSignal
            .distinctUntilChanged()
            .emit(onNext: { [weak self] needShow in
                guard let self else { return }
                self.updateFolderListViewSizeIfNeed(show: needShow)
            })
            .disposed(by: disposeBag)
        
        pinFolderListView.prepare()
    }
}
