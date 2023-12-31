//
//  InlineAIDragBar.swift
//  LarkInlineAI
//
//  Created by ByteDance on 2023/4/25.
//

import Foundation
import UIKit
import UniverseDesignColor

class InlineAIDragBar: InlineAIItemBaseView {
    
    var doubleConfirm: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 8
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        let dragView = UIView(frame: .zero)
        self.addSubview(dragView)
        dragView.backgroundColor = UDColor.lineBorderCard
        dragView.layer.cornerRadius = 2
        dragView.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(4)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


