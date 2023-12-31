//
//  LKDisplayAssetViewModel.swift
//  LarkAssetsBrowser
//
//  Created by qihongye on 2021/8/8.
//

import Foundation
import LarkUIKit
import ByteWebImage

public enum LKDisplayAssetState: Equatable {
    case none
    case start
    case progress(Float)
    case end

    public static func == (_ l: LKDisplayAssetState, _ r: LKDisplayAssetState) -> Bool {
        switch (l, r) {
        case (.none, .none): return true
        case (.start, .start): return true
        case (.progress, .progress): return true
        case (.end, .end): return true
        default: return false
        }
    }
}

final class LKDisplayAssetViewModel {
    let asset: LKDisplayAsset
    var updateStateCallback: ((LKDisplayAssetState, LKDisplayAsset) -> Void)? {
        didSet {
            updateStateCallback?(state, asset)
        }
    }

    private(set) var state: LKDisplayAssetState
    private var timer: Timer?

    init(asset: LKDisplayAsset) {
        self.asset = asset
        if let key = asset.originalImageKey,
           LarkImageService.shared.isCached(resource: .default(key: key), options: .all) {
            state = .none
        } else if asset.originalImageSize == 0 || asset.originalImageKey == nil {
            state = .none
        } else {
            state = .start
        }
    }

    func updateState(_ state: LKDisplayAssetState) {
        switch (self.state, state) {
        case (.none, _):
            return
        case (.start, _):
            self.state = state
        case (.progress, .progress), (.progress, .end), (.progress, .start):
            self.state = state
        case (.end, .none):
            timer?.invalidate()
            timer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(end2None),
                userInfo: nil,
                repeats: false
            )
            return
        default:
            return
        }

        updateStateCallback?(self.state, asset)
    }

    @objc
    private func end2None() {
        timer?.invalidate()
        timer = nil
        if self.state == .end {
            self.state = .none
            updateStateCallback?(.none, asset)
        }
    }
}
