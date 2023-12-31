//
//  UIScrollView+LarkSearch.swift
//  LarkSearch
//
//  Created by CharlieSu on 5/11/20.
//

import UIKit
import Foundation
import LarkPerf
import LKCommonsTracker
import Homeric
import RxSwift

private let searchScrollFPS = "searchScrollFPS"
private let trackedScrollViews: NSHashTable = NSHashTable<NSObject>.weakObjects()

extension UIScrollView {
    func trackFps(location: String, disposeBag: DisposeBag) {
        guard !trackedScrollViews.contains(self) else { return }
        trackedScrollViews.add(self)

        rx.willBeginDragging.subscribe(onNext: { (_) in
            FPSMonitorHelper.shared.startTrackFPS(task: searchScrollFPS, bind: self) { (result) in
                if result.fps <= 0 { return }
                let params: [AnyHashable: Any] = ["location": location, "fps": result.fps]
                Tracker.post(TeaEvent(Homeric.VIEW_SEARCH_RESULT_ROLL_FPS,
                                      params: params))
            }
        }).disposed(by: disposeBag)

        rx.didEndDecelerating.subscribe(onNext: { (_) in
            FPSMonitorHelper.shared.endTrackFPS(task: searchScrollFPS, bind: self)
        }).disposed(by: disposeBag)

        rx.didEndDragging.subscribe(onNext: { (decelerate) in
            if decelerate { return }
            FPSMonitorHelper.shared.endTrackFPS(task: searchScrollFPS, bind: self)
        }).disposed(by: disposeBag)
    }
}
