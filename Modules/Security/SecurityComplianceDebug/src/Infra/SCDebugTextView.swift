//
//  SCDebugTextView.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/12/6.
//

import Foundation

class SCDebugTextView: UITextView {
    init(){
        super.init(frame: .zero, textContainer: nil)
        textColor = .ud.textTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

