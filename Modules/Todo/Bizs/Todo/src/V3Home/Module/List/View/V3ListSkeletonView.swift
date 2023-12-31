//
//  V3ListSkeletonView.swift
//  Todo
//
//  Created by wangwanxin on 2022/11/9.
//

import Foundation
import UniverseDesignLoading

final class V3ListSkeletonView: UIView {

    private lazy var squareView = initCornerView()
    private lazy var bar1View = initCornerView()
    private lazy var bar2View = initCornerView()
    private lazy var cricleView = initCornerView(redius: 12)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .clear
        setupSubViews()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        showUDSkeleton()

    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        isSkeletonable = true
        addSubview(squareView)
        addSubview(bar1View)
        addSubview(bar2View)
        addSubview(cricleView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        squareView.frame = CGRect(
            x: 16.0,
            y: 16.0,
            width: 16.0,
            height: 16.0
        )

        bar1View.frame = CGRect(
            x: squareView.frame.maxX + 8.0,
            y: 16.0,
            width: 120.0,
            height: 16.0
        )

        bar2View.frame = CGRect(
            x: squareView.frame.maxX + 8.0,
            y: bar1View.frame.maxY + 10.0,
            width: 220.0,
            height: 12.0
        )

        cricleView.frame = CGRect(
            x: frame.width - 24.0 - 16.0,
            y: 12.0,
            width: 24.0,
            height: 24.0
        )
    }

    private func initCornerView(redius: CGFloat = 4.0) -> UIView {
        let view = UIView()
        view.layer.cornerRadius = redius
        view.layer.masksToBounds = true
        view.isSkeletonable = true
        return view
    }

}
