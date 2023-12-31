//
//  CommentLoadingView.swift
//  SKCommon
//
//  Created by huayufan on 2022/5/10.
//  


import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignLoading

class CommentLoadingView: UIView {

    private var spin: UDSpin?
    
    private var bgView = UIView()
    
    /// primary（蓝色） 、neutralWhite 、neutralGray
    convenience init(spinColor: UDSpin.PresetColor = .primary) {
        self.init(frame: .zero)
        spin = UDLoading.presetSpin(color: spinColor)
        addSubview(bgView)
        addSubview(spin!)
        
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        spin?.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(4)
        }
        
        // 吸收点击事件
        addGestureRecognizer(UITapGestureRecognizer())
        // 吸收长按事件
        addGestureRecognizer(UILongPressGestureRecognizer())
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func udpate(backgroundColor: UIColor, alphe: CGFloat) {
        bgView.backgroundColor = backgroundColor
        bgView.alpha = alphe
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
