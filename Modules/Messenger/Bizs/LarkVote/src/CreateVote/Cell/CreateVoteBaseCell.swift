//
//  CreateVoteBaseCell.swift
//  LarkVote
//
//  Created by Fan Hui on 2022/3/22.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import UniverseDesignColor

class CreateVoteBaseCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
