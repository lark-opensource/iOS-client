//
//  GuideFlowManager.swift
//  InstructionsExample
//
//  Created by sniper on 2018/11/14.
//  Copyright © 2018 Ephread. All rights reserved.
//

import Foundation
import LKCommonsLogging

final class GuideFlowManager {

    // 当前步骤的index
    var currentIndex = -1

    var guideMarks: [GuideMark]?

    var stopFlowBlock: (() -> Void)?

    private static let logger = Logger.log(GuideFlowManager.self)

    unowned let guideMarksViewController: GuideMarksViewController

    init(guideMarksViewController: GuideMarksViewController) {
        self.guideMarksViewController = guideMarksViewController
    }

    func startFlow (withGuideMarks guideMarks: [GuideMark]?) {
        guard guideMarks != nil else { return }
        self.guideMarks = guideMarks
        showNextGuide()
    }

    func reset () {
        currentIndex = -1
    }

    func stopFlow () {
        reset()
        guideMarksViewController.maskViewManager.showOverlay(false) { [weak self] (_) -> Void in
            guard let strongSelf = self else { return }
            strongSelf.guideMarksViewController.detachFromWindow()
            strongSelf.stopFlowBlock?()
        }
    }

    func showNextGuide () {

        currentIndex += 1
        GuideFlowManager.logger.info("func showNextGuide currentIndex = \(currentIndex)")
        if currentIndex == 0 {
            guideMarksViewController.prepareShowMaskView {
                self.createAndShowGuide()
            }
            return
        }

        self.guideMarksViewController.hide {
            self.showOrStop()
        }
    }

    func createAndShowGuide () {
        GuideFlowManager.logger.info("func createAndShowGuide currentIndex = \(currentIndex)")
        if let tempGuideMarks = guideMarks {
            guard tempGuideMarks.count > currentIndex,
            currentIndex >= 0 else {
                self.stopFlow()
                return
            }
            GuideFlowManager.logger.info("func createAndShowGuide tempGuideMarks.cout = \(tempGuideMarks.count) currentIndex = \(currentIndex)")
            let currentGuideMark = tempGuideMarks[currentIndex]
            self.guideMarksViewController.show(byMark: currentGuideMark)
        }
    }

    fileprivate func showOrStop () {
        if self.currentIndex < self.guideMarks?.count ?? -1 {
            self.createAndShowGuide()
        } else {
            self.stopFlow()
        }
    }
}
