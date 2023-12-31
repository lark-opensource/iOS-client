//
//  MinutesAudioBgView.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/9/11.
//

import Foundation
import SnapKit

final class MinutesAudioBgView: UIView {

    private lazy var bgView: UIImageView = {
        let iv = UIImageView()
        iv.addSubview(audioIcon)
        audioIcon.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        return iv
    }()

    private lazy var audioIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = BundleResources.Minutes.minutes_subtitle_audio
        return iv
    }()

    private lazy var grandientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor(red: 0.87, green: 0.96, blue: 1, alpha: 1).cgColor, UIColor(red: 0.84, green: 0.88, blue: 0.98, alpha: 1).cgColor, UIColor(red: 0.58, green: 0.69, blue: 0.97, alpha: 0.79).cgColor]
        layer.locations = [0, 0.58, 1]
        layer.opacity = 0.25
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(grandientLayer)
        addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        grandientLayer.frame = bounds
        CATransaction.commit()
    }
}
