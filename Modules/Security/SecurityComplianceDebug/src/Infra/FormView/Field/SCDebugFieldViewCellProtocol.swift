//
//  SCDebugFieldViewCellProtocol.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation

protocol SCDebugFieldViewCellProtocol where Self: UITableViewCell {
    static var cellID: String { get }
    func configModel(model: SCDebugFieldViewModel)
}
