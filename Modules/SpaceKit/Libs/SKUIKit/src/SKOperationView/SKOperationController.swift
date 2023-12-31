//
//  SKOperationController.swift
//  SKUIKit
//
//  Created by yinyuan on 2023/4/12.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor

public struct SKOperationControllerConfig {
    let items: [[SKOperationBaseItem]]
    let background: UIColor?
    
    public init(items: [[SKOperationBaseItem]], background: UIColor? = nil) {
        self.items = items
        self.background = background
    }
}

public class SKOperationController: SKPanelController, SKOperationViewDelegate, UIPopoverPresentationControllerDelegate {
    
    var config: SKOperationControllerConfig
    
    private var currentOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation

    //列表距离底部的边距
    private var bottom: CGFloat = 0

    public var isInPopover: Bool {
        self.modalPresentationStyle == .popover
    }
    
    private lazy var operationList = SKOperationView(frame: .zero,
                                                     displayIcon: true).construct { it in
        it.delegate = self
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }

    public init(config: SKOperationControllerConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)

        self.dismissalStrategy = []
        self.automaticallyAdjustsPreferredContentSize = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func setupUI() {
        super.setupUI()
        containerView.addSubview(operationList)
        
        if !isInPopover {
            bottom = 34
        }

        operationList.snp.makeConstraints { make in
            make.left.right.equalTo(containerView.safeAreaLayoutGuide)
            make.height.equalTo(0)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottom)
        }

        self.navigationController?.navigationBar.isHidden = true
    }
    
    public override func transitionToRegularSize() {
        super.transitionToRegularSize()
        if let background = config.background {
            containerView.backgroundColor = background
        }
    }
    
    public override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        if let background = config.background {
            containerView.backgroundColor = background
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentOrientation = UIApplication.shared.statusBarOrientation
        navigationController?.setNavigationBarHidden(true, animated: false) // 从外部网页退回到描述页面时要把导航栏隐藏
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            if UIApplication.shared.statusBarOrientation != self?.currentOrientation {
                //转屏后刷新页面布局高度
                self?.currentOrientation = UIApplication.shared.statusBarOrientation
                self?.updateUI()
            }
        }
    }

    func updateUI() {
        let groupItem = config.items
        let preferredHeight = countOperationListPreferredContentHeight()
        operationList.snp.updateConstraints { make in
            make.height.equalTo(preferredHeight)
        }
        operationList.refresh(infos: groupItem)
        if isInPopover {
            preferredContentSize = CGSize(width: 375, height: preferredHeight + bottom)
        } else {
            operationList.setCollectionViewScrollEnable(enable: false)
        }
    }

    func countOperationListPreferredContentHeight() -> CGFloat {
        
        var operationListViewHeight: CGFloat = 0
        
        operationListViewHeight += SKOperationView.Const.contentInset.top
        
        config.items.forEach { items in
            operationListViewHeight += SKOperationView.Const.sectionInset.top
            items.forEach { item in
                operationListViewHeight += (item.customViewHeight ?? SKOperationView.Const.itemHeight)
            }
            operationListViewHeight += SKOperationView.Const.sectionInset.bottom
        }
        
        operationListViewHeight += SKOperationView.Const.contentInset.bottom
        return operationListViewHeight
    }

    public func didClickItem(identifier: String, finishGuide: Bool, itemIsEnable: Bool, disableReason: OperationItemDisableReason, at view: SKOperationView) {
        if self.navigationController != nil {
            self.navigationController?.dismiss(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    public func shouldDisplayBadge(identifier: String, at view: SKOperationView) -> Bool {
        return false
    }
}
