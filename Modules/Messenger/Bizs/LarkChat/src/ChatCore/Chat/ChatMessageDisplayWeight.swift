//
//  ChatMessageDisplayWeight.swift
//  LarkChat
//
//  Created by zc09v on 2020/1/21.
//

import Foundation
import UIKit
import LarkModel
import LarkSDKInterface
import RxSwift
import LKCommonsLogging

private let unitWeightHeight: CGFloat = 40
private var setDisplayWeight = false

//端上会给每种消息设置一个预估高度权重，背景参见https://bytedance.feishu.cn/docs/doccnjzcEP9RAI5uMeDR8s6806f
//如果拿不准，可以设置成1，宁小勿大
private let chatMessageDisplayWeights: [Int32: Double] =
    Message.TypeEnum.allCases.reduce([:]) { (result, type) -> [Int32: Double] in
        var result = result
        var weight: Double = 1
        switch type {
        case .text:
            weight = 1
        case .audio:
            weight = 1
        case .calendar:
            weight = 5
        case .card:
            weight = 3
        case .email:
            weight = 1
        case .file:
            weight = 1.5
        case .folder:
            weight = 1.5
        case .generalCalendar:
            weight = 5
        case .hongbao, .commercializedHongbao:
            weight = 2
        case .post:
            weight = 2
        case .image:
            weight = 2
        case .system:
            weight = 1
        case .shareGroupChat:
            weight = 3
        case .shareUserCard:
            weight = 3
        case .sticker:
            weight = 2
        case .mergeForward:
            weight = 1.5
        case .media:
            weight = 2
        case .shareCalendarEvent:
            weight = 5
        case .videoChat:
            weight = 2.5
        case .location:
            weight = 3.5
        case .unknown, .diagnose:
            weight = 1
        case .todo:
            weight = 3
        case .vote:
            weight = 3
        @unknown default:
            assert(false, "new value")
            weight = 1
        }
        result[Int32(type.rawValue)] = weight
        return result
    }
//text,post这类消息rust底层会根据字数自增权重，但端上有折叠逻辑，不能无限增大权重，需要指定权重上限
private let chatMessageDisplayMaxWeights: [Int32: Double] = [Int32(Message.TypeEnum.text.rawValue): 6,
                                                             Int32(Message.TypeEnum.post.rawValue): 6]

func setMessageDisplay(messageAPI: MessageAPI) {
    guard !setDisplayWeight else { return }
    setDisplayWeight = true
    var disposeBag: DisposeBag = DisposeBag()
    messageAPI.setMessageDisplay(weights: chatMessageDisplayWeights, maxWeights: chatMessageDisplayMaxWeights).subscribe(onNext: { (_) in
        disposeBag = DisposeBag()
    }, onError: { (error) in
        setDisplayWeight = false
        ChatMessagesViewController.logger.error("Settings_V1_SetDataDisplayWeightRequest报错: ", error: error)
        disposeBag = DisposeBag()
    }).disposed(by: disposeBag)
}

func exceptWeight(height: CGFloat) -> Int32? {
    return Int32(height / unitWeightHeight)
}
