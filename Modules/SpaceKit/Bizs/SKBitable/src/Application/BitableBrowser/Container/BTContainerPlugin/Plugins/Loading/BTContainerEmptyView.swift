//
//  BTContainerEmptyView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/11.
//

import Foundation
import UniverseDesignEmpty
import UniverseDesignColor

class BTContainerEmptyView: UIView {
    private let empty: UDEmpty
    
    init(empty: UDEmpty) {
        self.empty = empty
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.backgroundColor = UDColor.bgBody
        empty.removeFromSuperview()
        
        addSubview(empty)
        empty.snp.remakeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
}
