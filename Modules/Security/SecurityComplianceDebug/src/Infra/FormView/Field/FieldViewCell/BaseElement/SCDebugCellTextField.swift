//
//  SCDebugCellTextField.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/30.
//

import Foundation

class SCDebugCellTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 15)
        textColor = .black
        returnKeyType = .done
        borderStyle = .roundedRect
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
