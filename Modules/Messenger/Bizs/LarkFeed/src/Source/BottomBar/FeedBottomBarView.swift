//
//  FeedBottomBarView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/26.
//

import UIKit
import Foundation
import LarkOpenFeed
import LarkContainer
import RxRelay
import RxSwift
import RxCocoa
import LarkNavigation
import SnapKit

protocol FeedBottomBarViewInterface: UIView {
    // 高度变化
    var updateHeightDriver: Driver<(CGFloat)> { get }
}

final class FeedBottomBarView: UIView {
    private let disposeBag = DisposeBag()
    private let context: UserResolver
    private lazy var providerManager: FeedBottomBarProviderManager = {
        FeedBottomBarProviderManager(context: context)
    }()
    private lazy var navigationService: NavigationService? = {
        try? context.resolve(assert: NavigationService.self)
    }()

    // 高度变化
    private let updateHeightRelay = BehaviorRelay<(CGFloat)>(value: (0))
    var updateHeightDriver: Driver<(CGFloat)> {
        return updateHeightRelay.asDriver()
    }
    private weak var currentView: UIView?

    init(frame: CGRect, context: UserResolver) {
        self.context = context
        super.init(frame: frame)
        self.bind()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind() {
        providerManager.visibleViewObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view) in
                guard let self = self else { return }
                guard view != self.currentView else { return }
                self.currentView?.removeFromSuperview()
                self.currentView = view
                if let providerView = view {
                    self.addSubview(providerView)
                    providerView.snp.makeConstraints { (make) in
                        make.edges.equalToSuperview()
                    }
                }
            }).disposed(by: self.disposeBag)

        navigationService?.tabNoticeShowDriver.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] height in
                // update height here
                guard let self = self else { return }
                self.updateHeight(height)
            }).disposed(by: self.disposeBag)
    }
}

extension FeedBottomBarView: FeedBottomBarViewInterface {
    func updateHeight(_ height: CGFloat) {
        updateHeightRelay.accept(height)
    }
}
