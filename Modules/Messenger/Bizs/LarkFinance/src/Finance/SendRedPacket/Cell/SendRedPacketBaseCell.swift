//
//  SendRedPacketBaseCell.swift
//  LarkFinance
//
//  Created by JackZhao on 2021/11/23.
//

import Foundation
import LarkUIKit
import SnapKit
import RxCocoa
import RxSwift
import RichLabel
import UIKit
import UniverseDesignColor

class SendRedPacketBaseCell: UITableViewCell {

    let disposeBag: DisposeBag = DisposeBag()

    var result: RedPacketCheckResult? {
        didSet {
            if let result = self.result {
                self.updateCellContent(result)
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCellContent()
        self.backgroundColor = UIColor.ud.bgBase
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCellContent(_ result: RedPacketCheckResult) {
        assertionFailure("need override this function")
    }

    func setupCellContent() {
        assertionFailure("need override this function")
    }
}
