//
//  CollaboratorLoadingView.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/20.
//  


import UIKit
import SnapKit
import UniverseDesignLoading
import UniverseDesignColor

class CollaboratorLoadingView: UIView {

    init(topOffset: CGFloat) {
        super.init(frame: .zero)
        backgroundColor = UDColor.bgBody
        let animationView = UDLoading.loadingImageView()
        addSubview(animationView)
        animationView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(topOffset)
            make.centerX.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
