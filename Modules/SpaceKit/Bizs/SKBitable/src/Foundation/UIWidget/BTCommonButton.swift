//
//  BTCommonButton.swift
//  SKBitable
//
//  Created by zoujie on 2023/9/20.
//  


import Foundation
import UniverseDesignColor

final class BTCommonButton: UIControl {
    private var model: BTCommonDataItemIconInfo?
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(iconView)
        
        iconView.snp.makeConstraints { make in
            make.size.equalTo(0)
            make.center.equalToSuperview()
        }
        
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchCancel, .touchUpInside, .touchUpOutside])
        addTarget(self, action: #selector(didClick), for: .touchUpInside)
    }
    
    @objc
    private func touchDown() {
        guard let highlightColor = model?.highlightColor else {
            return
        }
        iconView.image = iconView.image?.ud.withTintColor(highlightColor)
    }
    
    @objc
    private func touchUp() {
        guard let tinColor = model?.color else {
            return
        }
        iconView.image = iconView.image?.ud.withTintColor(tinColor)
    }
    
    @objc
    private func didClick() {
        model?.clickCallback?(self)
    }
    
    func update(data: BTCommonDataItemIconInfo?) {
        self.model = data
        if data?.image != nil || data?.customRender != nil{
            iconView.image = data?.image
            iconView.isHidden = false
            data?.customRender?(iconView)
            
            let iconSize = data?.size ?? CGSize(width: 16, height: 16)
            if case let .top(topOffset) = data?.alignment {
                iconView.snp.remakeConstraints { make in
                    make.size.equalTo(iconSize)
                    make.centerX.equalToSuperview()
                    make.top.equalToSuperview().offset(topOffset)
                }
            } else {
                iconView.snp.remakeConstraints { make in
                    make.size.equalTo(iconSize)
                    make.center.equalToSuperview()
                }
            }
            
        } else {
            iconView.isHidden = true
            
            iconView.snp.remakeConstraints { make in
                make.size.equalTo(0)
                make.edges.equalToSuperview()
            }
        }
    }
}
