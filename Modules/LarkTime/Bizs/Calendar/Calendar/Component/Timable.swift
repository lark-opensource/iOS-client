//
//  Timable.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/26.
//

import Foundation
import CalendarFoundation

protocol Timable { }

extension Timable {
    func startTimer(_ timer: inout Timer?, timerInterval: TimeInterval = 15, block: (() -> Void)?) {
        if timer == nil {
            let refreshTimer = Timer.scheduledTimer(
                withTimeInterval: timerInterval,
                repeats: true) { (_) in
                    block?()
            }
            RunLoop.main.add(refreshTimer, forMode: RunLoop.Mode.common)
            print("XXXX + startTimer")
            timer = refreshTimer

            timer?.fireDate = Date()
        }
    }

    func stopTimer(_ timer: inout Timer?) {
        timer?.invalidate()
        timer = nil
        print("XXXX + stopTimer")
    }
}
