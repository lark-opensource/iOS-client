//
//  InstanceCoverLayer.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/3.
//  Copyright © 2019 EE. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import LarkContainer

public final class InstanceCoverView: UIView {
    private let disposeBag = DisposeBag()
    private var endDate: Date = Date()
    private var isCoverPassEvent: Bool = false
    @InjectedLazy var localRefreshService: LocalRefreshService

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        alpha = 0.55
        isHidden = true

        localRefreshService.rxMainViewNeedRefresh
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.isHidden = !self.shouldShowCover(endDate: self.endDate,
                                                      isCoverPassEvent: self.isCoverPassEvent)
            })
            .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(with endDate: Date, isCoverPassEvent: Bool, maskOpacity: CGFloat) {
        self.endDate = endDate
        self.isCoverPassEvent = isCoverPassEvent
        self.isHidden = !shouldShowCover(endDate: endDate, isCoverPassEvent: isCoverPassEvent)
        self.alpha = maskOpacity
    }

    private func shouldShowCover(endDate: Date, isCoverPassEvent: Bool) -> Bool {
        return endDate < Date() && isCoverPassEvent
    }
}


public final class InstanceCoverLayer: CALayer {
    private let disposeBag = DisposeBag()
    private var endDate: Date = Date()
    private var isCoverPassEvent: Bool = false
    @InjectedLazy var localRefreshService: LocalRefreshService

    public override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        backgroundColor = UIColor.ud.bgBody.cgColor
    }

    public override init() {
        super.init()
        opacity = 0.55
        isHidden = true

        localRefreshService.rxMainViewNeedRefresh
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.isHidden = !self.shouldShowCover(endDate: self.endDate,
                                                      isCoverPassEvent: self.isCoverPassEvent)
            })
            .disposed(by: disposeBag)
    }

    public override init(layer: Any) {
        super.init(layer: layer)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(with endDate: Date, isCoverPassEvent: Bool, maskOpacity: Float) {
        self.endDate = endDate
        self.isCoverPassEvent = isCoverPassEvent
        self.isHidden = !shouldShowCover(endDate: endDate, isCoverPassEvent: isCoverPassEvent)
        self.opacity = maskOpacity
    }

    private func shouldShowCover(endDate: Date, isCoverPassEvent: Bool) -> Bool {
        return endDate < Date() && isCoverPassEvent
    }

}
