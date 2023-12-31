//
//  LarkBaseBannerView.swift
//  LarkBanner
//
//  Created by mochangxing on 2020/5/27.
//

import Foundation
import UIKit
import RustPB
import RxSwift
import Homeric
import LKCommonsTracker

public class LarkBaseBannerView: UIView {
    private let disposeBag = DisposeBag()
    public weak var delegate: LarkBannerDelegate?

    public let bannerData: LarkBannerData
    let contentView = UIControl()
    let bannerCloseView = LarkBannerCloseView()
    var bannerWidth: CGFloat

    public init(bannerData: LarkBannerData, bannerWidth: CGFloat) {
        self.bannerData = bannerData
        self.bannerWidth = bannerWidth
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(contentView)
        contentView.addSubview(bannerCloseView)
        bannerCloseView.backgroundColor = UIColor.clear
        bannerCloseView.rx.controlEvent(.touchUpInside).asObservable().subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.delegate?.onBannerClosed(bannerView: self)
        }).disposed(by: disposeBag)

        bannerCloseView.layer.zPosition = 1
    }

    /// 点击关闭按钮热区
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let expandDistance: CGFloat = 6
        let hotZoneRect = CGRect(x: self.bannerCloseView.frame.origin.x - expandDistance / 2,
                                 y: self.bannerCloseView.frame.origin.y - expandDistance / 2,
                                 width: self.bannerCloseView.bounds.width + expandDistance,
                                 height: self.bannerCloseView.bounds.height + expandDistance)
        if hotZoneRect.contains(point) && !self.bannerCloseView.isHidden {
            return self.bannerCloseView
        }
        return super.hitTest(point, with: event)
    }

    open func bindData(bannerData: LarkBannerData) {

    }

    open func getContentSize() -> CGSize {
        return .zero
    }

    open func updateLayout() {

    }

    func update(bannerWidth: CGFloat) -> CGFloat {
        self.bannerWidth = bannerWidth
        bindData(bannerData: bannerData)
        updateLayout()
        return self.getContentSize().height
    }
}

public protocol LarkBannerDelegate: AnyObject {
    func onBannerClosed(bannerView: LarkBaseBannerView)

    func onBannerClick(bannerView: LarkBaseBannerView, url: String)

    func onBannerShow()
}
