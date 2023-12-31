//
//  BannerContainer.swift
//  UGBanner
//
//  Created by mochangxing on 2021/3/2.
//

import UIKit
import Foundation

final class BannerContainer: UIView {
    private var lastBannerView: UIView?
    private var contentSize: CGSize = .zero
    weak var delegate: LarkBannerDelegate?
    var bannerData: BannerInfo?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        return contentSize
    }

    override func layoutSubviews() {
        if self.frame.width != contentSize.width, let bannerData = bannerData {
            _ = onUpdateData(bannerData: bannerData)
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let superview = self.superview {
            // 被加到父视图时候进行曝光埋点
            delegate?.onBannerShow()
        }
    }

    func onUpdateData(bannerData: BannerInfo) -> Bool {
        self.bannerData = bannerData
        let bannerWidth = self.frame.width
        guard bannerWidth > 0,
              let (bannerView, bannerHeight) = LarkBannerViewFactory
                .createBannerView(bannerData: LarkBannerData(bannerInfo: bannerData),
                                  bannerWidth: self.frame.width) else {
            return false
        }
        bannerView.delegate = delegate
        if let lastBannerView = lastBannerView { lastBannerView.removeFromSuperview() }
        lastBannerView = bannerView
        self.addSubview(bannerView)
        bannerView.frame = CGRect(x: 0, y: 0, width: bannerWidth, height: bannerHeight)
        contentSize = CGSize(width: bannerWidth, height: bannerHeight)
        self.invalidateIntrinsicContentSize()
        return true
    }

    func onHide() {
        lastBannerView?.removeFromSuperview()
        lastBannerView = nil
        bannerData = nil
        contentSize = CGSize(width: self.frame.width, height: 0)
        self.invalidateIntrinsicContentSize()
    }
}
