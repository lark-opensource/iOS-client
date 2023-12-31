//
//  PayManagerService.swift
//  LarkInterface
//
//  Created by lichen on 2018/11/14.
//

import Foundation
import UIKit
import RxSwift

public enum PayErrorType: Error, CustomStringConvertible {
    case payTokenInvalid
    case payFailed
    case timeout
    case notUrl
    case hasOpeningDesk
    case missParam(String)

    public var description: String {
        switch self {
        case .notUrl:
            return "url string is not url"
        case .missParam(let param):
            return "miss param \(param)"
        case .payTokenInvalid:
            return "pay token is invalid"
        case .payFailed:
            return "pay failed"
        case .hasOpeningDesk:
            return "already have opening pay desk"
        case .timeout:
            return "pay timeout"
        }
    }
}

public struct PayManagerCallBack {
    public let callDeskCallback: (Bool) -> Void
    public let payCallback: (Error?) -> Void
    public let cacncelBlock: () -> Void

    public init(
        callDeskCallback: @escaping (Bool) -> Void,
        payCallback: @escaping (Error?) -> Void,
        cacncelBlock: @escaping () -> Void) {
        self.callDeskCallback = callDeskCallback
        self.payCallback = payCallback
        self.cacncelBlock = cacncelBlock
    }
}

// 支付方式
public enum PaymentMethod {
    case unknown
    case caijingPay /// 老的聚合支付收银台
    case bytePay /// 新的自有支付收银台
}

// 支付方式
public enum PayBusinessScene: String {
    /// 发红包
    case sendRedPacket = "send_redpacket"
    /// 领红包
    case receiveRedPacket = "receive_redpacket"
    /// 钱包
    case wallet = "wallet"
}

public protocol PayManagerService {
    var payToken: String? { get set }
    func fetchPayTokenIfNeeded()
    func cjpayInitIfNeeded(callback: ((Error?) -> Void)?)
    func pay(paramsString: String, referVc: UIViewController, payCallback: PayManagerCallBack, paymentMethod: PaymentMethod)
    func open(url: String, referVc: UIViewController, closeCallBack: ((Any) -> Void)?)
    func handle(open url: URL) -> Bool
    func openBankCardList(referVc: UIViewController)
    func openTransaction(referVc: UIViewController)
    func openPaySecurity(referVc: UIViewController)
    func openWithdrawDesk(url: String, referVc: UIViewController, closeCallBack: ((Any) -> Void)?)
    func fetchUserPhoneInfo() -> Observable<Bool>
    func getCJSDKConfig() -> String
    func payUpgrade(businessScene: PayBusinessScene)
    func getWalletScheme(callback: ((String?) -> Void)?)
}
