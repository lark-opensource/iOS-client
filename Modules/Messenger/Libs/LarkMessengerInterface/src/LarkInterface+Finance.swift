//
//  LarkInterface+Finance.swift
//  Pods
//
//  Created by ChalrieSu on 2018/10/18.
//

import UIKit
import Foundation
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface

public enum OpenRedPacketModel {
    case message(message: Message)
    case messageId(id: String)
    case ids(mesageId: String, hongbaoId: String)
}

// MARK: 打开红包
public struct OpenRedPacketBody: PlainBody {
    public static let pattern = "//client/finance/redPacket/open"

    public let model: OpenRedPacketModel
    public let chatId: String?

    public init(chatId: String?, model: OpenRedPacketModel) {
        self.chatId = chatId
        self.model = model
    }
}

// MARK: 红包封面页面
public struct RedPacketCoverBody: CodablePlainBody {
    public static let pattern = "//client/finance/redPacket/cover"
    public let selectedCoverId: Int64?

    public init(selectedCoverId: Int64? = nil) {
        self.selectedCoverId = selectedCoverId
    }
}

// MARK: 红包封面页面详情
public struct RedPacketCoverDetailBody: PlainBody {
    public static let pattern = "//client/finance/redPacket/coverDetail"

    public var tapCoverId: Int64
    public var confirmHandler: (() -> Void)?
    public var covers: [HongbaoCover]
    public var coverIdToThemeTypeMap: [String: String] = [:]

    public init(tapCoverId: Int64,
                covers: [HongbaoCover]) {
        self.tapCoverId = tapCoverId
        self.covers = covers
    }
}

// 红包封面改变的通知
public struct PushRedPacketCoverChange: PushMessage {
    public let cover: HongbaoCover

    public init(cover: HongbaoCover) {
        self.cover = cover
    }
}

public struct RedPacketResultBody: Body {
    private static let prefix = "//client/finance/redPacket/result"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:redPacketID", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(RedPacketResultBody.prefix)/\(redPacketInfo.redPacketID)") ?? .init(fileURLWithPath: "")
    }

    public let redPacketInfo: RedPacketInfo

    public let receiveInfo: RedPacketReceiveInfo

    public var dismissBlock: ((UIViewController) -> Void)?

    public init(redPacketInfo: RedPacketInfo,
                receiveInfo: RedPacketReceiveInfo,
                transitionDelegate: UIViewControllerTransitioningDelegate? = nil,
                dismissBlock: ((UIViewController) -> Void)? = nil) {
        self.redPacketInfo = redPacketInfo
        self.receiveInfo = receiveInfo
        self.dismissBlock = dismissBlock
    }
}

/// 红包历史记录
public struct RedPacketHistoryBody: CodablePlainBody {
    public static let pattern = "//client/finance/redPacket/history"

    public init() {}
}

/// 收红包历史记录
public struct RedPacketReceivedHistoryBody: CodablePlainBody {
    public static let pattern = "//client/finance/redPacket/received"

    public init() {}
}

/// 发红包历史记录
public struct RedPacketSentHistoryBody: CodablePlainBody {
    public static let pattern = "//client/finance/redPacket/sent"

    public init() {}
}

// MARK: 钱包页
public struct WalletBody: CodablePlainBody {
    public static let pattern = "//client/finance/wallet"

    public var walletUrl: String?
    public init(walletUrl: String?) {
        self.walletUrl = walletUrl
    }
}

// MARK: 提现页面
public struct WithdrawBody: CodablePlainBody {
    public static let pattern = "//client/finance/wallet/withdraw"

    public init() { }
}

// MARK: 发送红包页面
public struct SendRedPacketBody: PlainBody {
    public static let pattern = "//client/finance/hongbao/new"

    public let chat: Chat

    public init(chat: Chat) {
        self.chat = chat
    }
}

// MARK: 发送红包鉴权
public struct SendRedPacketCheckAuthBody: PlainBody {
    public static let pattern = "//client/finance/hongbao/checkAuth"

    public let chat: Chat
    public let alertContent: String
    public weak var from: UIViewController?

    public init(chat: Chat,
                alertContent: String,
                from: UIViewController? = nil) {
        self.chat = chat
        self.alertContent = alertContent
        self.from = from
    }
}

// MARK: 提示用户填写电话信息
public struct AlertAddPhoneBody: PlainBody {
    public static let pattern = "//client/finance/alert/addPhone"

    public var content: String?

    public init(content: String? = nil) {
        self.content = content
    }
}
