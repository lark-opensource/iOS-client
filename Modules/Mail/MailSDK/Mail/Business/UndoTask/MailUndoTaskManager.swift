//
//  MailUndoTask.swift
//  MailSDK
//
//  Created by majx on 2020/8/25.
//

import Foundation
import RxSwift

struct MailUndoTask {
    enum UndoTaskType: String {
        case send
        case trash
        case scheduled
        case archive
        case spam
        case unspam
        case marksread
        case marksunread
        case moveto
        case changeLabels
    }
    let type: UndoTaskType
    let uuid: String
    let draftId: String?
    let createTime: TimeInterval
}

class MailUndoTaskManager {
    struct UndoConfig {
        let enable: Bool
        let time: Int64
    }

    static let `default` = MailUndoTaskManager()
    var disposeBag = DisposeBag()

     // one task at the same time
    var task: MailUndoTask?
    var timer: CADisplayLink?
    var timeLeave: Int64?
    var lastTimestamp: CFTimeInterval?
    var update: ((Int64) -> Void)?
    var dismiss: (() -> Void)?

    var sendConfig: UndoConfig {
        let enable = Store.settingData.getCachedCurrentSetting()?.undoSendEnable ?? false
        let time = Store.settingData.getCachedCurrentSetting()?.undoTime ?? 5
        return UndoConfig(enable: enable, time: time)
    }

    func update(type: MailUndoTask.UndoTaskType, _ uuid: String, _ draftId: String?, onUpdate: ((Int64) -> Void)?, onDismiss: @escaping () -> Void) {
        task = MailUndoTask(type: type, uuid: uuid, draftId: draftId, createTime: Date().timeIntervalSince1970)
        update = onUpdate
        dismiss = onDismiss
        timing()
        MailLogger.info("mail undo update uuid ---> \(uuid)")
    }

    func undo(feedCardID: String?, onComplete: (() -> Void)?, onError: (() -> Void)?) {
        guard let uuid = task?.uuid else { return }
        MailLogger.info("mail undo action uuid ---> \(uuid)")
        MailDataServiceFactory.commonDataService?.undoMailAction(by: uuid, feedCardID: feedCardID).subscribe(onNext: {(_) in
            MailLogger.info("mail undo success uuid ---> \(uuid)")
            onComplete?()
        }, onError: { (error) in
            MailLogger.error("mail undo error uuid ---> \(uuid) error: \(error)")
            onError?()
        }).disposed(by: disposeBag)
        reset()
    }

    private func timing() {
        timer?.invalidate()
        if let task = task {
            if task.type == .send {
                timeLeave = sendConfig.enable ? sendConfig.time : nil
            } else {
                timeLeave = 7
            }
        }
        timer = CADisplayLink(target: self, selector: #selector(updateToast))
        
        if let newTimer = timer {
            newTimer.add(to: .main, forMode: .default)
            newTimer.preferredFramesPerSecond = 5
        }
    }

    @objc
    private func updateToast() {
        guard var timeLeave = timeLeave else { return }
        guard let displaylink = self.timer else { return }
        if let timestamp = lastTimestamp {
            if displaylink.timestamp - timestamp > 1 {
                timeLeave = timeLeave - 1
                lastTimestamp = displaylink.timestamp
            }
        } else {
            self.lastTimestamp = displaylink.timestamp
        }
        if timeLeave <= 0 {
            self.reset()
        } else {
            update?(timeLeave)
            self.timeLeave = timeLeave
        }
    }

    func reset() {
        dismiss?()
        timer?.invalidate()
        timer = nil
        timeLeave = nil
        lastTimestamp = nil
        task = nil
        update = nil
        dismiss = nil
    }
}
