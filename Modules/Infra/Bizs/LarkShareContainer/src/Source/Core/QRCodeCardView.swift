//
//  QRCodeCardView.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2021/1/4.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import QRCode

private enum Layout {
    static let topMargin: CGFloat = 32
    static let qrcodeMinMargin: CGFloat = 42
    static let qrcodeSize: CGFloat = 220
    static let bgQrcodeSize: CGFloat = 240
    static let smallQrcodeSize: CGFloat = 160
    static let smallBgQrcodeSize: CGFloat = 180
}

final class QRCodeCardView: BaseCardView {
    init(
        circleAvatar: Bool = true,
        retryHandler: @escaping () -> Void
    ) {
        super.init(
            needBaseSeparateLine: true,
            circleAvatar: circleAvatar,
            retryHandler: retryHandler
        )
        addPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var contentView: UIView {
        return qrcodeContentView
    }

    override func bind(with statusMaterial: StatusViewMaterial) {
        super.bind(with: statusMaterial)
        let qrcodeSize = useSmallQRCodeSize() ? Layout.smallQrcodeSize : Layout.qrcodeSize
        let bgQrcodeSize = useSmallQRCodeSize() ? Layout.smallQrcodeSize : Layout.bgQrcodeSize
        if case .success(let m) = statusMaterial {
            if let image = QRCodeTool.createQRImg(str: m.link, size: qrcodeSize) {
                qrcodeView.image = image
                bgQrcodeView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
                contentView.snp.remakeConstraints { (make) in
                    make.top.equalToSuperview().offset(Layout.topMargin)
                    make.width.equalTo(bgQrcodeSize)
                    make.height.equalTo(contentView.snp.width)
                    make.centerX.equalToSuperview()
                }
                bgQrcodeView.snp.remakeConstraints { (make) in
                    make.width.height.equalToSuperview()
                    make.centerX.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
                qrcodeView.snp.remakeConstraints { (make) in
                    make.top.equalToSuperview().offset(10)
                    make.width.equalTo(qrcodeSize)
                    make.height.equalTo(qrcodeView.snp.width)
                    make.centerX.equalToSuperview()
                }
                contentView.superview?.layoutIfNeeded()
            }
        }
    }

    func useSmallQRCodeSize() -> Bool {
        // SE 1st and elder iPhone use small qr code size
        return UIScreen.main.bounds.height <= 568
    }

    private lazy var qrcodeContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addSubview(bgQrcodeView)
        view.addSubview(qrcodeView)
        return view
    }()

    private lazy var bgQrcodeView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var qrcodeView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    func centreContentView() {
        centreSuccessContainer()
    }
}
