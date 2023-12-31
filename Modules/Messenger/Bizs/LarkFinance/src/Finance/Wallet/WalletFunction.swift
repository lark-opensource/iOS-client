//
//  WalletFunction.swift
//  LarkFinance
//
//  Created by CharlieSu on 2018/10/29.
//

import UIKit
import Foundation

enum WalletFunction: CaseIterable {
    case bankCard, transaction, secure, help

    var title: String {
        switch self {
        case .bankCard:
            return BundleI18n.LarkFinance.Lark_Legacy_Cards
        case .transaction:
            return BundleI18n.LarkFinance.Lark_Legacy_Transactions
        case .secure:
            return BundleI18n.LarkFinance.Lark_Legacy_Security
        case .help:
            return BundleI18n.LarkFinance.Lark_Legacy_HelpCenter
        }
    }

    var image: UIImage {
        switch self {
        case .bankCard:
            return Resources.wallet_bank_card
        case .transaction:
            return Resources.wallet_transaction
        case .secure:
            return Resources.wallet_secure
        case .help:
            return Resources.wallet_help
        }
    }
}
