//
//  AIAnimationView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/5/12.
//  


import UIKit
import Lottie
import SnapKit
import UniverseDesignIcon

class AIAnimationView: UIView {
    
    var logoThinkingView: LOTAnimationView
    
    struct Layout {
        static let iconSize = CGSize(width: 18, height: 18)
    }
    
    lazy var aiIconView: UIImageView = {
        let imgView = UIImageView()
        let icon = UDIcon.getIconByKey(.myaiColorful, size: Layout.iconSize)
        imgView.image = icon
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    override init(frame: CGRect) {
        let bundle = Bundle.resourceBundle
        let path = bundle.path(forResource: "logo_thinking", ofType: "json") ?? ""
        logoThinkingView = LOTAnimationView(filePath: path)
        logoThinkingView.backgroundColor = UIColor.clear
        logoThinkingView.loopAnimation = true
        super.init(frame: frame)
        setupInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupInit() {
        addSubview(logoThinkingView)
        addSubview(aiIconView)
        
        logoThinkingView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
            make.top.equalToSuperview().inset(3)
            make.left.equalToSuperview().offset(1)
        }
        
        aiIconView.snp.makeConstraints { make in
            make.edges.equalTo(logoThinkingView)
        }
    }
    
    func stop() {
        logoThinkingView.isHidden = true
        logoThinkingView.stop()
        aiIconView.isHidden = false
    }
    
    func play() {
        logoThinkingView.play()
        aiIconView.isHidden = true
        logoThinkingView.isHidden = false
    }
}
