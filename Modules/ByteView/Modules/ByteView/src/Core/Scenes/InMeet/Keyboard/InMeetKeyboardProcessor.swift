//
//  InMeetKeyboardProcessor.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/11/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

enum KeyPressStage {
    case begin, end, cancel
}

protocol InMeetKeyboardProcessor {
    // 返回是否可以处理该按键，按下和抬起时都会调用该方法
    func shouldHandle(press: UIPress, stage: KeyPressStage) -> Bool
    // 返回是否需要将事件继续向上传递
    func keyPressBegan(_ press: UIPress) -> Bool
    func keyPressEnded(_ press: UIPress) -> Bool
    func destroy()
}

class InMeetKeyboardEventRegistry {
    var processors: [InMeetKeyboardProcessor] = []

    func register(processor: InMeetKeyboardProcessor) {
        processors.append(processor)
    }

    deinit {
        processors.forEach { $0.destroy() }
        processors.removeAll()
    }
}
