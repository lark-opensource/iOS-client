//
//  MailAPMErrorDetector.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/5/17.
//

import Foundation
import RxSwift

class MailAPMErrorDetector {
    static let shared = MailAPMErrorDetector()

    private let overtime: TimeInterval = 3.0
    var timer: Observable<Int> = Observable<Int>.timer(RxTimeInterval.seconds(0),
                                                       period: RxTimeInterval.seconds(1),
                                                       scheduler: MainScheduler.instance)

    var timerCountDic = ThreadSafeDictionary<String, TimeInterval>()
    var timerDisposeBagDic = ThreadSafeDictionary<String, DisposeBag?>()
    var threadIDs = ThreadSafeArray<String>(array: [])
    var adbandonDic = ThreadSafeDictionary<String, Bool>()

    func startDetect(_ threadID: String) {
        timerDisposeBagDic.updateValue(DisposeBag(), forKey: threadID)
        guard let timerDisposeBag = timerDisposeBagDic[threadID], let disposeBag = timerDisposeBag else { return }
        threadIDs.append(newElement: threadID)
        adbandonDic.updateValue(false, forKey: threadID)

        self.timer.subscribe(onNext: { [weak self] (count) in
            guard let `self` = self else {
                return
            }
            let lastCount = self.timerCountDic[threadID] ?? 0
            self.timerCountDic.updateValue(lastCount + 1, forKey: threadID)
            if (Int(lastCount) + 1) >= Int(self.overtime) { // 超时
                self.reportTimeoutAction(threadID)
                self.timerDisposeBagDic.updateValue(nil, forKey: threadID)
                self.timerDisposeBagDic.updateValue(DisposeBag(), forKey: threadID)
            }
        }, onError: { (eror) in

        }).disposed(by: disposeBag)
    }

    @discardableResult // 返回true表示计时过程中受changelog影响，需取消UI强制执行逻辑
    func endDetect(_ threadID: String) -> Bool {
        guard threadIDs.all.contains(threadID) else {
            return true
        }
        resetDetect(threadID)
        return adbandonDic[threadID] ?? false
    }

    func abandonDetect(_ threadID: String) {
        guard threadIDs.all.contains(threadID) else {
            return
        }
        resetDetect(threadID)
        adbandonDic.updateValue(true, forKey: threadID)
    }

    private func reportTimeoutAction(_ threadID: String) {
        guard threadIDs.all.contains(threadID) else {
            return
        }
        MailTracker.log(event: "email_apm_user_interactive_error", params: ["event": "mark_as_read_fail"])
        resetDetect(threadID)
    }

    private func resetDetect(_ threadID: String) {
        timerDisposeBagDic.updateValue(nil, forKey: threadID)
        timerDisposeBagDic.updateValue(DisposeBag(), forKey: threadID)
        var index = -1
        for (idx, threadId) in threadIDs.all.enumerated() where threadId == threadID {
            index = idx
        }
        if index != -1 {
            threadIDs.remove(at: index)
        }
        adbandonDic.removeValue(forKey: threadID)
    }
}
