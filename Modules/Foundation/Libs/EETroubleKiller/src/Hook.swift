//
//  Hook.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/11/20.
//

import Foundation

extension TroubleKiller {
    public final class Hook {
        public typealias CaptureHookHandler = () -> Void

        /// triggered before capture
        public var beginCaptureHook: CaptureHookHandler?

        /// triggered after capture
        public var endCaptureHook: CaptureHookHandler?

        public typealias PetHookHandler = (Topic) -> Void

        /// triggered before pet
        public var beginPetHook: PetHookHandler?

        /// triggered after pet
        public var endPetHook: PetHookHandler?
    }
}
