//
//  StickerTrackKit.swift
//  LarkKeyboardView
//
//  Created by 李晨 on 2020/10/21.
//

import Foundation
import AppReciableSDK

enum ImageLoadState {
    case start
    case cancel
    case finish(cost: TimeInterval, error: Error?)
}

enum StickerLoadEndType: Int {
    case unknown = 0
    case allSuccess = 1
    case leave = 2
}

final class StickerTrackKit: NSObject {

    static var allTrackKit = NSHashTable<StickerTrackKit>(options: .weakMemory)

    private var uploaded: Bool = false
    private var started: Bool = false

    private var identifier: String

    private var result: [String: TimeInterval] = [:]
    private var failed: [String] = []

    private var error: Error?

    private var dispose: DisposedKey?

    private var taskNumber: Int = 0 {
        didSet {
            if taskNumber == 0 {
                updateEventIfNeeded()
            } else {
                self.startIfNeeded()
            }
        }
    }

    func set(stickerID: String, state: ImageLoadState) {
        switch state {
        case .start:
            self.taskNumber += 1
        case .cancel:
            self.taskNumber -= 1
        case .finish(cost: let cost, error: let error):
            result[stickerID] = cost * 1000
            if error != nil {
                failed.append(stickerID)
                self.error = error
            }
            self.taskNumber -= 1
        }
    }

    static func leaveStickerPanel() {
        self.allTrackKit.allObjects.forEach { (kit) in
            kit.updateEventIfNeeded(force: true)
        }
    }

    private func startIfNeeded() {
        if self.started { return }
        self.started = true
        self.dispose = AppReciableSDK.shared.start(
            biz: .Messenger,
            scene: .Chat,
            event: Event.enterStickerSet,
            page: nil
        )
        StickerTrackKit.allTrackKit.add(self)
    }

    private func updateEventIfNeeded(force: Bool = false) {
        if !self.started { return }
        if uploaded { return }
        let endType: StickerLoadEndType = force ? .leave : .allSuccess

        if let dispose = self.dispose {
            var metric: [String: Any] = [:]
            var category: [String: Any] = [:]
            metric["sticker_package_id"] = self.identifier
            metric["sticker_detail"] = self.result
            category["end_type"] = endType.rawValue
            let extra = Extra(metric: metric, category: category)
            AppReciableSDK.shared.end(key: dispose, extra: extra)
        }

        if self.error != nil {
            var metric: [String: Any] = [:]
            var category: [String: Any] = [:]
            metric["sticker_package_id"] = self.identifier
            metric["sticker_detail"] = self.failed
            category["end_type"] = endType.rawValue
            let extra = Extra(metric: metric, category: category)
            let errorParams = ErrorParams(
                biz: .Messenger,
                scene: .Chat,
                event: Event.enterStickerSet,
                errorType: .Network,
                errorLevel: .Exception,
                userAction: nil,
                page: nil,
                errorMessage: nil,
                extra: extra
            )
            AppReciableSDK.shared.error(params: errorParams)
        }

        self.uploaded = true
    }

    init(identifier: String) {
        self.identifier = identifier
        super.init()
    }

    deinit {
        updateEventIfNeeded(force: true)
    }
}
