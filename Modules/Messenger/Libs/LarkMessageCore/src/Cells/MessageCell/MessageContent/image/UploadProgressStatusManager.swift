//
//  UploadProgressStatusManager.swift
//  LarkMessageCore
//
//  Created by kangsiwan on 2022/7/12.
//

import Foundation
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer
import LarkFeatureGating
import LarkSDKInterface
import LKCommonsLogging

/// 图片发送进度管理， 三个状态的转换如下
///      showing
///  ⬇️⬆️             ⬆️
///  hiding   <->   waiting
final class UploadProgressStatusManager {
    private static let logger = Logger.log(UploadProgressStatusManager.self, category: "ProgressStatusManager")

    // 控制是否展示
    private let isShowProgressReplay: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    // 控制展示进度。这个是VM给的进度，一般是SDK传的
    private let realValueReplay: BehaviorRelay<Float> = BehaviorRelay(value: SendImageProgressState.zero.rawValue)
    // 在FG内的话，有0.5s的展示时延，所以不是sdk给的实时进度。如果在FG外，就传realValueReplay给外面
    let progressReplay: BehaviorRelay<Float> = BehaviorRelay(value: SendImageProgressState.zero.rawValue)
    private let disposeBag = DisposeBag()

    private var delayShowTimer: Timer?
    private var progressStatus: ProgressStatus = .hiding
    enum ProgressStatus: Int {
        case showing = 1 // 正在展示
        case waiting = 2 // 已经命令展示，但展示设置了0.5s的时延
        case hiding = 3 // 正在隐藏
    }

    private let messageId: String
    private let dependency: () -> SDKDependency?

    init(messageId: String, dependency: @escaping () -> SDKDependency?) {
        self.messageId = messageId
        self.dependency = dependency
        observer()
    }

    func observer() {
        Observable
            .combineLatest(realValueReplay.distinctUntilChanged(), isShowProgressReplay.distinctUntilChanged())
            .filter({ progress, _ in
                return progress == SendImageProgressState.sendSuccess.rawValue || progress == SendImageProgressState.sendFail.rawValue
            })
            .subscribe(onNext: { [weak self] progress, _ in
                UploadProgressStatusManager.logger.info("\(self?.messageId) success or failed \(progress)")
                self?.progressReplay.accept(progress)
            }).disposed(by: disposeBag)

        Observable
            .combineLatest(realValueReplay.distinctUntilChanged(), isShowProgressReplay.distinctUntilChanged())
            .filter({ progress, _ in
                return !(progress == SendImageProgressState.sendSuccess.rawValue || progress == SendImageProgressState.sendFail.rawValue)
            })
            .throttle(.milliseconds(100), latest: true, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] progress, isShow in
                if isShow {
                    UploadProgressStatusManager.logger.info("\(self?.messageId) is showing \(progress)")
                    self?.progressReplay.accept(progress)
                } else {
                    UploadProgressStatusManager.logger.info("\(self?.messageId) hiding \(progress)")
                    // view 收到 wait 信号会 hideProgress
                    self?.progressReplay.accept(SendImageProgressState.wait.rawValue)
                }
            }).disposed(by: disposeBag)
    }

    /// 开始计时准备展示progress
    func start(messageLocalStatus: Message.LocalStatus) {
        switch messageLocalStatus {
        case .process:
            UploadProgressStatusManager.logger.info("\(messageId) message Status process")
            goShowing()
        case .fakeSuccess:
            UploadProgressStatusManager.logger.info("\(messageId) message Status fakeSuccess")
            goWaiting()
        case .success:
            UploadProgressStatusManager.logger.info("\(messageId) message Status success")
            assertionFailure("if success, shouldn't go here")
        case .fail:
            UploadProgressStatusManager.logger.info("\(messageId) message Status fail")
            goHiding()
        }
    }

    /// 更新progress
    func update(value: Float) {
        // 如果在隐藏就进入等待状态
        if progressStatus == .hiding {
            goWaiting()
        }
        // 如果在等待，或者展示状态，无需做什么
        realValueReplay.accept(value)
    }

    /// 不展示progress
    func successeEnd() {
        UploadProgressStatusManager.logger.info("\(messageId) successeEnd")
        realValueReplay.accept(SendImageProgressState.sendSuccess.rawValue)
        goHiding()
    }

    func failEnd() {
        UploadProgressStatusManager.logger.info("\(messageId) failEnd")
        realValueReplay.accept(SendImageProgressState.sendFail.rawValue)
        goHiding()
    }

    // 只有.hiding .waiting状态可以
    @objc
    private func goShowing() {
        guard [.hiding, .waiting].contains(progressStatus) else { return }
        progressStatus = .showing
        UploadProgressStatusManager.logger.info("\(messageId) go showing")
        isShowProgressReplay.accept(true)
        invalidateTimer()
    }

    // 只有.showing .waiting状态可以
    private func goHiding() {
        guard [.showing, .waiting].contains(progressStatus) else { return }
        progressStatus = .hiding
        UploadProgressStatusManager.logger.info("\(messageId) go hiding")
        isShowProgressReplay.accept(false)
        // 是否包含取消计时
        invalidateTimer()
    }

    // 只有.hiding状态可以
    private func goWaiting() {
        guard progressStatus == .hiding else { return }
        progressStatus = .waiting
        UploadProgressStatusManager.logger.info("\(messageId) go waiting")
        isShowProgressReplay.accept(false)
        scheduledTimer()
    }

    // 开始计时
    private func scheduledTimer() {
        let delay = delayProgress()
        DispatchQueue.main.async { [weak self] in
            self?.delayShowTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { [weak self] _ in
                UploadProgressStatusManager.logger.info("\(self?.messageId) 500ms timer")
                self?.goShowing()
            })
        }
    }

    // 销毁计时
    private func invalidateTimer() {
        guard self.delayShowTimer != nil else { return }
        DispatchQueue.main.async {
            self.delayShowTimer?.invalidate()
            self.delayShowTimer = nil
        }
    }

    // 获取延时展示的时间
    private func delayProgress() -> Double {
        guard let dependency = self.dependency() else {
            return 0.5
        }
        // 网络好：0.5s；评估中：0.1s；弱网：0s
        // 网好的时候，希望0.5s能传完；网差的时候，希望用户马上得到反馈
        // 对齐发消息策略的转圈圈
        switch dependency.currentNetStatus {
        case .excellent:
            return 0.5
        case .evaluating:
            return 0.1
        case .netUnavailable, .serviceUnavailable, .weak, .offline:
            return 0
        default:
            return 0
        }
    }
}
