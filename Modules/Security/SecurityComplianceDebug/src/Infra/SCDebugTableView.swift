//
//  SCDebugTableView.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/12/5.
//

import Foundation

class SCDebugTableView: UITableView {
    init(frame: CGRect) {
        if #available(iOS 13, *) {
            super.init(frame: .zero, style: .insetGrouped)
        } else {
            super.init(frame: .zero, style: .grouped)
        }
        estimatedRowHeight = 100
        rowHeight = UITableView.automaticDimension
        register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        keyboardDismissMode = .onDrag
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
