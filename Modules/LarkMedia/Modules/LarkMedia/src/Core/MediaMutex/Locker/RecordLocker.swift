//
//  RecordLocker.swift
//  LarkMedia
//
//  Created by fakegourmet on 2022/11/15.
//

import Foundation

class RecordLocker: MixMediaLocker {
    convenience init() {
        self.init(mediaType: .record)
    }
}
