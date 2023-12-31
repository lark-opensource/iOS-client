//
//  DaySceneViewController+Snapshot.swift
//  Calendar
//
//  Created by 张威 on 2020/10/14.
//

import UIKit
import Foundation
import RxRelay

/// DayScene - Snapshot
/// 基于 DaySceneViewController 构建 snapshot，用于 iPad 旋转触发 sceneMode 变化的转场过渡

extension DaySceneViewController {

    /// 基于 `DaySceneViewController` 构建 snapshot ViewController
    static func makeSnapshot(
        from source: DaySceneViewController,
        with dayCategory: HomeSceneMode.DayCategory
    ) -> UIViewController {
        return Snapshot(sourceChild: source, targetDaysPerScene: dayCategory.daysPerScene)
    }

    private final class Snapshot: UIViewController {

        /// day scene viewController
        let sourceChild: DaySceneViewController
        /// 转场的目标 daysPerScene
        let targetDaysPerScene: Int

        init(sourceChild: DaySceneViewController, targetDaysPerScene: Int) {
            assert(sourceChild.parent == nil)
            assert(sourceChild.view.superview == nil)
            self.sourceChild = sourceChild
            self.targetDaysPerScene = targetDaysPerScene
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear

            addChild(sourceChild)
            view.addSubview(sourceChild.view)
            sourceChild.view.backgroundColor = .brown
            sourceChild.didMove(toParent: self)
        }

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            let radio = CGFloat(sourceChild.daysPerScene) / CGFloat(targetDaysPerScene)
            let timeScaleViewWidth: CGFloat
            if let additionalTimeZone = sourceChild.dayStore.state.additionalTimeZone {
                timeScaleViewWidth = additionalTimeZone.getTimeZoneWidth(is12HourStyle: sourceChild.rxIs12HourStyle.value)
                + sourceChild.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: sourceChild.rxIs12HourStyle.value)
                + DayScene.UIStyle.Layout.showAdditionalTimeZoneSpacingWidth
            } else {
                timeScaleViewWidth = sourceChild.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: sourceChild.rxIs12HourStyle.value)
                + DayScene.UIStyle.Layout.hiddenAdditionalTimeZoneSpacingWidth
            }
            let sceneWidth = (size.width - timeScaleViewWidth) * radio + timeScaleViewWidth
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.sourceChild.view.frame.size = CGSize(width: sceneWidth, height: size.height)
            })
        }

    }

}
