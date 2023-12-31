//
//  CommonListBaseHeaderView.swift
//  SKBitable
//
//  Created by zoujie on 2023/7/27.
//  


import Foundation
import SnapKit
import UniverseDesignColor

public class CommonListBaseHeaderView: CommonListBaseView {
    
    lazy var containerView = UIView().construct { it in
        it.backgroundColor = .clear
    }
    
    func setCloseButtonHidden(isHidden: Bool) {}
    
    override func setUpView() {
        layer.cornerRadius = 12
        layer.maskedCorners = .top
        layer.masksToBounds = true
        backgroundColor = UDColor.bgFloat
        
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
