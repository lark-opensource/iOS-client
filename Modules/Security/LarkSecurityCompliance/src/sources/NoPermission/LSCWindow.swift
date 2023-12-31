//
//  LSCWindow.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/12.
//
import UIKit
import LarkWaterMark
import LarkContainer
import RxSwift
import LarkSecurityComplianceInfra

final class LSCWindow: UIWindow, UserResolverWrapper {
    private var waterMarkView: UIView?
    private let bag = DisposeBag()

    @ScopedProvider private var waterMarkService: WaterMarkService?

    let userResolver: UserResolver

    init(resolver: UserResolver, frame: CGRect) {
        self.userResolver = resolver
        super.init(frame: frame)
        setupWatermark()
    }

    private func setupWatermark() {
        guard let waterMarkService else {
            Logger.info("watermark service is nil")
            return
        }
        waterMarkService
            .globalCustomWaterMarkView
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (waterMarkImageView) in
                guard let `self` = self else { return }
                self.updateWaterMark(waterMarkImageView)
            })
            .disposed(by: bag)
    }

    private func updateWaterMark(_ waterMarkImageView: UIView) {
        waterMarkView?.removeFromSuperview()
        waterMarkView = waterMarkImageView
        addSubview(waterMarkImageView)
        waterMarkImageView.contentMode = .top
        waterMarkImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        waterMarkImageView.layer.zPosition = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
