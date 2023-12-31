//
//  MailHomeTableView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/3/22.
//

import Foundation
import UIKit

class MailHomeTableView: UITableView {
    var viewWidth: CGFloat = 0.0 {
        didSet {
          if oldValue != viewWidth {
              self.relayoutHeader()
          }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        viewWidth = frame.width
    }

    func relayoutHeader() {
        (tableHeaderView as? MailThreadListHeaderView)?.superViewWidth = frame.width
        tableHeaderView?.frame = CGRect(x: 0, y: 0, width: frame.width, height: tableHeaderView?.intrinsicContentSize.height ?? 0)
    }
}
