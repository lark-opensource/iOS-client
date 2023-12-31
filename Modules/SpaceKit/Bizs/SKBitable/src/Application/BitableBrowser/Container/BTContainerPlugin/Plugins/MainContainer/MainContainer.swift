//
//  MainContainer.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/28.
//

import UIKit

class MainContainer: UIView {
    
    var layoutSubviewsCallback: ((_ frame: CGRect) -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutSubviewsCallback?(self.frame)
    }
}
