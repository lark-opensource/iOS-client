//
//  MinutesSubtitleSkeletonView.swift
//  Minutes
//
//  Created by yangyao on 2022/9/8.
//

import UIKit
import SkeletonView
import UniverseDesignColor
import MinutesFoundation

class MinutesSubtitleSkeletonView: UIView {
    let gradient: SkeletonGradient = getSkeletongradientColor()
    
    static func getSkeletongradientColor() -> SkeletonGradient {
        var gradient: SkeletonGradient  = SkeletonGradient(baseColor: UIColor.ud.N100,
                                    secondaryColor: UIColor.ud.N300.withAlphaComponent(0.7))

        return gradient
    }
    
    private lazy var avatarView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = MinutesSubtitleCell.LayoutContext.imageSize / 2.0
        view.clipsToBounds = true
        view.isSkeletonable = true
        return view
    }()

    private lazy var lineBarTop: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        view.isSkeletonable = true
        return view
    }()

    private lazy var lineBarBottom: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        view.isSkeletonable = true
        return view
    }()

    func startLoading() {
        self.showAnimatedGradientSkeleton(usingGradient: self.gradient)
    }
    /// hide self when stop loading
    func stopLoading() {
        self.stopSkeletonAnimation()
        self.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        self.isSkeletonable = true

        addSubview(avatarView)
        addSubview(lineBarTop)
        addSubview(lineBarBottom)

        avatarView.snp.makeConstraints { make in
            make.size.equalTo(MinutesSubtitleCell.LayoutContext.imageSize)
            make.left.top.equalToSuperview().offset(MinutesSubtitleCell.LayoutContext.leftMargin)
        }

        lineBarTop.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.centerY.equalTo(avatarView)
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.width.equalTo(60)
        }

        let width = ScreenUtils.sceneScreenSize.width - MinutesSubtitleCell.LayoutContext.leftMargin - MinutesSubtitleCell.LayoutContext.rightMargin
        lineBarBottom.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalTo(avatarView.snp.bottom).offset(12)
            make.left.equalTo(avatarView.snp.left)
            make.width.equalTo(width)
        }
        
        self.showAnimatedGradientSkeleton(usingGradient: gradient)
        self.startSkeletonAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
