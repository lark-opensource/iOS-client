//
//  ViewController.swift
//  LarkGuideDemo
//
//  Created by sniperj on 2018/12/11.
//  Copyright © 2018 sniper. All rights reserved.
//

import Foundation
import UIKit
import LarkGuide
import LarkUIKit

class ViewController: UIViewController {

    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var button5: UIButton!

    let guideMarkController: GuideMarksController = GuideMarksController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.

    }

    @IBAction func button1tap(_ sender: Any) {
//        var mark = GuideMark { () -> UIView? in
//            return self.button1
//        }
//        mark.defaultText = "this is button1"
//        self.guideMarkController.start(by: self, guideMarks: { () -> [GuideMark] in
//            return [mark]
//        })

        var mark = GuideMark(initWith: { () -> UIView? in
            return self.button1
        }, bodyViewClass: BodyViewBubbleStyle.self)
        mark.bodyViewParamStyle = .easyHintBubbleView("nice", EasyhintBubbleView.globalPreferences)
        var mark2 = GuideMark(initWith: { () -> UIView? in
            return self.button2
        }, bodyViewClass: BodyViewBubbleStyle.self)
        mark2.bodyViewParamStyle = .easyHintBubbleView("sdasdas", EasyhintBubbleView.globalPreferences)
        self.guideMarkController.start(by: self, guideMarks: { () -> [GuideMark] in
            return [mark, mark2]
        })

    }

    @IBAction func button2tap(_ sender: Any) {

//        var mark = GuideMark { () -> UIView? in
//            return self.button1
//        }
//        mark.defaultText = "this is button1"
//        mark.cutoutCornerRadii = CGSize(width: self.button1.frame.width / 2, height: self.button1.frame.height / 2)
//
//        var mark2 = GuideMark { () -> UIView? in
//            return self.button2
//        }
//        mark2.defaultText = "this is button2"
//
//        var mark3 = GuideMark { () -> UIView? in
//            return self.button3
//        }
//        mark3.defaultText = "this is button3"
//
//        self.guideMarkController.start(by: self, guideMarks: { () -> [GuideMark] in
//            return [mark,mark2,mark3]
//        })
    }

    @IBAction func button3tap(_ sender: Any) {
//        var mark = GuideMark { () -> UIView? in
//            return self.button3
//        }
//        mark.defaultText = "this is button3"
//        self.guideMarkController.start(by: self, guideMarks: { () -> [GuideMark] in
//            return [mark]
//        }, blurEffectStyle: .dark)
    }

    @IBAction func button4tap(_ sender: Any) {
//        var mark = GuideMark { () -> UIView? in
//            return self.button4
//        }
//        mark.defaultText = "this is button4"
//        self.guideMarkController.start(by: self, guideMarks: { () -> [GuideMark] in
//            return [mark]
//        }, color: UIColor.red)
    }

    @IBAction func button5tap(_ sender: Any) {
    }
}
