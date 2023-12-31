//
//  SkeletonImageView.swift
//  Moment
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import UIKit
import SkeletonView
import ByteWebImage
import UniverseDesignColor

final class SkeletonImageView: ByteImageView {

    private lazy var skeleton: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgBody
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        view.isSkeletonable = true
        view.isHidden = true
        return view
    }()

    //当需要在图片上盖一些东西，但又不希望它盖住skeleton时，可以添加在这个coverContainer上面
    lazy var coverContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = .ud.primaryOnPrimaryFill
        addSubview(coverContainer)
        coverContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(skeleton)
        isSkeletonable = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !skeleton.isHidden {
            startSkeleton()
        }
    }
    func startSkeleton() {
        skeleton.isHidden = false
        if self.bounds.width == 0 || self.bounds.height == 0 {
            return
        }
        if isSkeletonActive {
            if skeleton.bounds.equalTo(self.bounds) {
                return
            }
            //当骨架图已经展示且布局发生改变，则需要隐藏掉重新渲染一遍
            hideSkeleton()
        }
        skeleton.frame = self.bounds
        let gradient = SkeletonGradient(baseColor: UIColor.ud.N200.withAlphaComponent(0.5),
                                                secondaryColor: UIColor.ud.N200)
        showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    func stopSkeleton() {
        hideSkeleton()
        skeleton.isHidden = true
    }
}
