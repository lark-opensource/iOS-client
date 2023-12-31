//
//  MailOutboxCell.swift
//  MailSDK
//
//  Created by majx on 2019/7/29.
//

import Foundation
import UIKit
import SnapKit

protocol MailOutboxTipsViewDelegate: AnyObject {
    func didClickDismissOutboxTips()
    func didClickOutboxTips()
}

extension MailOutboxTipsViewDelegate {
    func didClickDismissOutboxTips() {}
    func didClickOutboxTips() {}
}
