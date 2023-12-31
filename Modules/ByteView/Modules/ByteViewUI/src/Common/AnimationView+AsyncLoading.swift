//
//  AnimationView+AsyncLoading.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2022/1/21.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Lottie

extension LOTAnimationView: AsyncLoadingProtocol {
    func playIfNeeded() {
        playIfNeeded { [weak self] in
            self?.play()
        }
    }

    func stopIfNeeded() {
        stopIfNeeded { [weak self] in
            self?.stop()
        }
    }
}
