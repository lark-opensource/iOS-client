//
//  BitableHomeLoadingView.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/1.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor

final class BitableHomeLoadingView: UIView {
    private lazy var loadingView = UIImageView().construct { it in
        let loadingIcon = UDIcon.getIconByKey(
            .loadingOutlined,
            iconColor: UIColor.ud.primaryPri500,
            size: CGSize(width: 20, height: 20)
        )
        it.image = loadingIcon
        it.isHidden = true
    }

    init() {
        super.init(frame: .zero)

        setupSubview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubview() {
        backgroundColor = .ud.bgBody

        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    func startAnimation() {
        self.loadingView.isHidden = false
        BTUtil.startRotationAnimation(view: self.loadingView)
    }

    func stopAnimation() {
        self.loadingView.isHidden = true
        BTUtil.stopRotationAnimation(view: self.loadingView)
    }
}
