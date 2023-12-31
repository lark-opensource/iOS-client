//
//  CountDownStatusViewModel.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2021/5/18.
//

import Foundation
import LarkModel
import AsyncComponent
import EEFlexiable
import RxSwift
import Swinject
import LarkMessageBase
import LarkMessengerInterface
import ThreadSafeDataStructure

public protocol CountDownViewModelContext: ViewModelContext {
    var burnTimer: Observable<Int64> { get }
    var serverTime: Int64 { get }
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterID: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func isBurned(message: Message) -> Bool
    var scene: ContextScene { get }
}

public class CountDownStatusViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: CountDownViewModelContext>: MessageSubViewModel<M, D, C> {
    private var isDisplay: Bool = false
    private var unfairLock = os_unfair_lock_s()
    // 不要直接访问 _burnedDisposeBag，存在多线程读写
    private var _burnedDisposeBag = DisposeBag()
    private var burnedDisposeBag: DisposeBag {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return _burnedDisposeBag
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            _burnedDisposeBag = newValue
            os_unfair_lock_unlock(&unfairLock)
        }
    }

    // 通过lazy保护下，防止频繁去获取对象，可能导致退出密聊时崩溃
    private lazy var chat: Chat = {
        return metaModel.getChat()
    }()

    private var shouldBurn: Bool {
        return self.canBurn && !self.isBurned
    }

    private var isBurned: Bool {
        return context.isBurned(message: message)
    }

    private var canBurn: Bool {
        return message.burnLife > 0 && message.burnTime > 0
    }

    /// 暂时不进行倒计时。当 自己是发送方 && 还有人未读
    var pauseBurnWhenAnyOneUnReadForSender: Bool {
        assertionFailure("must override")
        return true
    }

    public private(set) var burnTimeText: String?

    private func burnTimeCountDown(message: Message) {
        burnedDisposeBag = DisposeBag()
        if pauseBurnWhenAnyOneUnReadForSender {
            handleBurnTime(serverTime: context.serverTime, message: message)
            return
        }
        if !shouldBurn {
            self.burnTimeText = nil
            handleBurnTime(serverTime: context.serverTime, message: message)
            self.binder.update(with: self)
            // 展示在屏幕的时候才需要立刻刷新 UI
            if self.isDisplay {
                updateComponentAndRoloadTable(component: binder.component)
            }
            return
        }
        self.context.burnTimer
            .subscribe(onNext: { [weak self] utctime in
                self?.handleBurnTime(serverTime: utctime, message: message)
            })
            .disposed(by: burnedDisposeBag)
    }

    private func handleBurnTime(serverTime: Int64, message: Message) {
        if isBurned {
            context.deleteRow(by: message.id)
            burnedDisposeBag = DisposeBag()
            return
        }
        format(
            burnTime: message.burnTime / 1000,
            burnLife: Int64(message.burnLife),
            serverTime: serverTime,
            atRangeHandler: { (timeText) in
                // 时间变化才需要刷新
                if burnTimeText == timeText { return }
                burnTimeText = timeText
                binder.update(with: self)
                // 展示在屏幕的时候才需要立刻刷新 UI
                if !self.isDisplay { return }
                updateComponentAndRoloadTable(component: binder.component)
            }
        ) {
            context.deleteRow(by: message.id)
            burnedDisposeBag = DisposeBag()
        }
    }

    private func format(burnTime: Int64,
                        burnLife: Int64,
                        serverTime: Int64,
                        atRangeHandler: (String) -> Void,
                        outOfRangeHandler: () -> Void) {
        var countdownTime: Int64 = 0
        // burnTime == 0 时显示burnLife
        if burnTime == 0 {
            countdownTime = burnLife
        } else {
            countdownTime = burnTime - serverTime

            if countdownTime < 0 {
                return outOfRangeHandler()
            }

            /// 纠偏，立即开始倒计时
            let tolerantTime = countdownTime - burnLife
            if tolerantTime > 0 {
                countdownTime -= tolerantTime
            }
        }

        /// 显示规则, 小于一天: hh:mm:ss, 大于一天: xd:hh:mm
        let one_day_seconds: Int64 = 24 * 3600
        if countdownTime >= one_day_seconds {
            let day = countdownTime / one_day_seconds
            let hours = (countdownTime - day * one_day_seconds) / 3600
            let minutes = (countdownTime - day * one_day_seconds - hours * 3600) / 60

            let dayText = "\(day)d:"
            let hoursText = (hours < 10) ? "0\(hours)h:" : "\(hours)h:"
            let minutesText = (minutes < 10) ? "0\(minutes)m" : "\(minutes)m"

            let result = dayText + hoursText + minutesText

            atRangeHandler(result)
        } else {
            let hours = countdownTime / 3600
            let minutes = (countdownTime - hours * 3600) / 60
            let seconds = countdownTime % 60

            let hoursText = (hours < 10) ? "0\(hours)h:" : "\(hours)h:"
            let minutesText = (minutes < 10) ? "0\(minutes)m:" : "\(minutes)m:"
            let secondsText = (seconds < 10) ? "0\(seconds)s" : "\(seconds)s"
            let result = hoursText + minutesText + secondsText
            atRangeHandler(result)
        }
    }

    public override func willDisplay() {
        self.isDisplay = true
        super.willDisplay()
        burnTimeCountDown(message: message)
    }

    public override func didEndDisplay() {
        self.isDisplay = false
        super.didEndDisplay()
        self.burnedDisposeBag = DisposeBag()
    }

    public override func shouldUpdate(_ new: Message) -> Bool {
        return self.message.unreadCount != new.unreadCount
            || self.message.readCount != new.readCount
            || self.message.burnLife != new.burnLife
            || self.message.burnTime != new.burnTime
            || !context.isBurned(message: message)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        burnTimeCountDown(message: metaModel.message)
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

}

public final class NormalCountDownStatusViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: CountDownViewModelContext>: CountDownStatusViewModel<M, D, C> {
    override var pauseBurnWhenAnyOneUnReadForSender: Bool {
        let chat = metaModel.getChat()
        if chat.type == .p2P {
            return context.isMe(message.fromId, chat: metaModel.getChat())
                && message.unreadCount != 0
        }
        //普通群聊里，无论是不是自己发的，都直接倒计时
        return false
    }
}
