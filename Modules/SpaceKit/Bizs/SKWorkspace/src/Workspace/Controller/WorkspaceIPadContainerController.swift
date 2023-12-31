//
//  WorkspaceIPadContainerController.swift
//  SKWorkspace
//
//  Created by Weston Wu on 2023/9/22.
//

import Foundation
import RxSwift
import LarkTraitCollection
import LarkSplitViewController

// iPad 场景负责 iPad 和 iPhone 样式的切换
open class WorkspaceIPadContainerController: UIViewController {
    public let compactController: UIViewController
    public let regularController: UIViewController

    public let disposeBag = DisposeBag()

    public init(compactController: UIViewController, regularController: UIViewController) {
        self.compactController = compactController
        self.regularController = regularController
        super.init(nibName: nil, bundle: nil)
        supportSecondaryOnly = true
        supportSecondaryPanGesture = true
        keyCommandToFullScreen = true
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupChildControllers()
        setupTraitCollection()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateForTraitCollectionChanged()
    }

    private func setupChildControllers() {
        setup(childController: regularController)
        setup(childController: compactController)
    }

    private func setup(childController: UIViewController) {
        addChild(childController)
        childController.beginAppearanceTransition(true, animated: false)
        view.addSubview(childController.view)
        childController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        childController.didMove(toParent: self)
        childController.endAppearanceTransition()
    }

    private func setupTraitCollection() {
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: view)
            .observeOn(MainScheduler.instance)
            .filter { change in
                change.old.horizontalSizeClass != change.new.horizontalSizeClass
            }
            .subscribe(onNext: { [weak self] _ in
                self?.updateForTraitCollectionChanged()
            })
            .disposed(by: disposeBag)
        updateForTraitCollectionChanged()
    }

    open func updateForTraitCollectionChanged() {
        switch traitCollection.horizontalSizeClass {
        case .unspecified, .regular:
            regularController.view.isHidden = false
            compactController.view.isHidden = true
        case .compact:
            regularController.view.isHidden = true
            compactController.view.isHidden = false
        @unknown default:
            // 按 R 处理
            regularController.view.isHidden = false
            compactController.view.isHidden = true
        }
    }
}
