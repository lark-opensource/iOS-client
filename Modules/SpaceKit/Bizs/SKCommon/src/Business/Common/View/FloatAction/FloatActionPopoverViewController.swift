//
//  FloatActionPopoverViewController.swift
//  SKCommon
//
//  Created by zoujie on 2021/1/5.
//  


import Foundation
import RxSwift
import LarkTraitCollection
import SKUIKit

public final class FloatActionPopoverViewController: UIViewController {

    public let actionView: FloatActionView
    private let bag = DisposeBag()

    public init(actionView: FloatActionView) {
        self.actionView = actionView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(actionView)
        actionView.onItemClick = { [weak self] completion in
            self?.dismiss(animated: true, completion: completion)
        }
        
        actionView.snp.makeConstraints { (make) in
            // iOS 13 后 UIPopover被SafeArea约束，详见： http://danlec.com/st4k#questions/57988889
            make.center.equalTo(view.safeAreaLayoutGuide)
        }

        // 监听sizeClass
        guard SKDisplay.pad else { return }
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                if change.old != change.new {
                    self?.dismiss(animated: false)
                }
            }).disposed(by: bag)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = actionView.bounds.size
    }
}
