//
//  ActionButton.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/29.
//

import Foundation
import UniverseDesignColor

final class ActionButton: UIControl {
    
    private lazy var impactGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .light)
        return generator
    }()
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var titleLable: UILabel = {
        let view = UILabel()
        view.isUserInteractionEnabled = false
        view.numberOfLines = 1
        view.font = .systemFont(ofSize: 12)
        view.textColor = UDColor.textPlaceholder
        view.textAlignment = .center
        return view
    }()
    
    private var clickCallback: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    private func setup() {
        layer.ud.setBorderColor(UDColor.N900.withAlphaComponent(0.05))
        layer.borderWidth = 1.0 / UIScreen.main.scale
        layer.cornerRadius = 12
        layer.ud.setBackgroundColor(UDColor.N900.withAlphaComponent(0.02))
        
        addSubview(iconView)
        addSubview(titleLable)
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
        }
        titleLable.snp.makeConstraints { make in
            make.width.equalToSuperview().inset(12)
            make.height.equalTo(18)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }
        
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchCancel, .touchUpInside, .touchUpOutside])
        addTarget(self, action: #selector(didClick), for: .touchUpInside)
    }
    
    @objc
    private func touchDown() {
        layer.ud.setBackgroundColor(UDColor.N900.withAlphaComponent(0.05))
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }
    
    @objc
    private func touchUp() {
        layer.ud.setBackgroundColor(UDColor.N900.withAlphaComponent(0.02))
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    @objc
    private func didClick() {
        impactGenerator.impactOccurred()
        clickCallback?()
    }
    
    func setData(_ data: ActionButtonModel) {
        iconView.image = data.icon
        titleLable.text = data.title
        titleLable.textColor = data.disable ? UDColor.textDisabled : UDColor.textPlaceholder
        clickCallback = data.clickCallback
    }
}
