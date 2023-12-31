//
//  AudioInputTrigger.swift
//  LarkMedia
//
//  Created by fakegourmet on 2023/9/5.
//

import Foundation

@available(iOS 17.0, *)
class AudioInputTrigger {
    @RwAtomic
    private var isCancelled: Bool = false
    @RwAtomic
    private(set) var isOutDated: Bool = false
    @RwAtomic
    private var isLastMuted: Bool?
    @RwAtomic
    private var completion: ((Bool) -> Void)?

    let isMuted: Bool
    init(isMuted: Bool, isMock: Bool = false) {
        self.isMuted = isMuted
        if isMock {
            isOutDated = true
            isCancelled = true
        }
        LarkAudioSession.logger.info("AudioInputTrigger init mute: \(isMuted)")
        guard !isMock else {
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            guard let self = self, !self.isCancelled else {
                return
            }
            if let isLastMuted = self.isLastMuted {
                self.completion?(isLastMuted == isMuted)
            }
            self.isOutDated = true
        }
    }

    func update(isMuted: Bool, completion: ((Bool) -> Void)?) {
        self.isLastMuted = isMuted
        self.completion = completion
    }

    func cancel() {
        isCancelled = true
    }
}
