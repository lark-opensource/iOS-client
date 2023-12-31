//
//  OPBGSuspendView.swift
//  OPPlugin
//
//  Created by zhysan on 2022/6/21.
//

import UIKit
import Lottie
import FigmaKit
import SnapKit
import UniverseDesignColor

final class OpenBGMediaSuspendView: UIView {
    
    // MARK: - public
    
    let iconView: UIImageView = {
        let vi = UIImageView()
        vi.backgroundColor = UIColor.ud.bgFiller
        vi.layer.cornerRadius = 24
        vi.layer.masksToBounds = true
        return vi
    }()
    
    func animate(_ animate: Bool) {
        DispatchQueue.main.async { [weak self] in
            if animate {
                self?.lottieView.play(toProgress: 0.5)
            } else {
                self?.lottieView.stop()
            }
        }
    }
    
    // MARK: - private
    
    private lazy var lottieView: LOTAnimationView = {
        let path = BundleConfig.OPPluginBundle.path(forResource: "lottie/bg-audio-animation", ofType: ".json")!
        let vi = LOTAnimationView(filePath: path)
        vi.loopAnimation = true
        vi.autoReverseAnimation = true
        vi.shouldRasterizeWhenIdle = true
        return vi
    }()
    
    // MARK: - lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.ud.bgFloatOverlay
        layer.cornerRadius = 8
        
        addSubview(iconView)
        addSubview(lottieView)
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.center.equalToSuperview()
        }
        
        lottieView.snp.makeConstraints { make in
            make.edges.equalTo(iconView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
