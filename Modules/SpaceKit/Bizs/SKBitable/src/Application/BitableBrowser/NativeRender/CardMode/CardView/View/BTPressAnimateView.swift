//
//  BTPressAnimateView.swift
//  SKBitable
//
//  Created by zoujie on 2023/11/8.
//  


import Foundation

class BTPressAnimateView: UIControl {
    
    var clickCallback: (() -> Void)?
    
    private var touchDownAnimationFinished: Bool = false
    
    private lazy var impactGenerator: UIImpactFeedbackGenerator = {
        let generator: UIImpactFeedbackGenerator
        if #available(iOS 13.0, *) {
            generator = UIImpactFeedbackGenerator(style: .soft)
        } else {
            // Fallback on earlier versions
            generator = UIImpactFeedbackGenerator(style: .light)
        }
        return generator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchCancel, .touchUpInside, .touchUpOutside])
        addTarget(self, action: #selector(didClick), for: .touchUpInside)
    }
    
    @objc
    private func touchDown() {
        self.touchDownAnimationFinished = false
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { complete in
            self.touchDownAnimationFinished = complete
        }
    }
    
    @objc
    private func touchUp() {
        if self.touchDownAnimationFinished {
            // 如果按下动画完成了，那么直接做抬起动画
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        } else {
            // 没有就先等个0.05s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                UIView.animate(withDuration: 0.1) {
                    self.transform = CGAffineTransform(scaleX: 1, y: 1)
                }
            }
        }
    }
    
    @objc
    private func didClick() {
        if #available(iOS 13.0, *) {
            impactGenerator.impactOccurred(intensity: 0.6)
        } else {
            // Fallback on earlier versions
            impactGenerator.impactOccurred()
        }
        clickCallback?()
    }
}
