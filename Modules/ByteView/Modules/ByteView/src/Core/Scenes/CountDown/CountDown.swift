//
//  CountDown.swift
//  ByteView
//
//  Created by wulv on 2022/5/1.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

struct CountDown {
    enum State: Equatable {
        /// 关闭
        case close
        /// 启动中
        case start
//        /// 暂停（一期无）
//        case pause
        /// 结束且未关闭（是否提前结束）
        case end(isPre: Bool)
    }

    var state: State = .close
    /// 剩余时长，s
    @RwAtomic var time: Int?
    /// 24时制（时，分，秒）
    // disable-lint: magic number
    var in24HR: (Int, Int, Int)? {
        guard let time = time else { return nil }
        let h = time / 3600
        let m = time % 3600 / 60
        let s = time % 3600 % 60
        return (h, m, s)
    }
    // enable-lint: magic number
    /// start or prolong 后，是否有过小时位
    var everHasHour: Bool = false
}

extension CountDown {
    enum Stage: Equatable {
        /// 进行中，富余阶段
        case normal
        /// 临近阶段
        case closeTo
        /// 即将结束
        case warn
        /// 已结束
        case end
    }

    var timeStage: Stage {
        guard let time = time else { return Stage.end }
        // > 1 min
        if time > 60 {
            return Stage.normal
        }
        // > 10s
        if time > 10 {
            return Stage.closeTo
        }
        // > 0s
        if time > 0 {
            return Stage.warn
        }
        return Stage.end
    }
}
