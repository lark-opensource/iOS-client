//
//  TestViewController.swift
//  LKContentFixDev
//
//  Created by 李勇 on 2020/9/8.
//

import Foundation
import UIKit
@testable import LKContentFix

class TestViewController: UIViewController {
    private let testStr = "ʕ̢̣̣̣̣̩̩̩̩•͡˔•ོɁ̡̣̣̣̣̩̩̩̩ʕ̢̣̣̣̣̩̩̩̩•͡˔•ོɁ̡̣̣̣̣̩̩̩̩明确人传人"

    override func viewDidLoad() {
        super.viewDidLoad()
        let attrStr = NSAttributedString(string: self.testStr, attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .medium)])
        // 展示异常的标签
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.size.width, height: 30)))
        label.attributedText = attrStr
        self.view.addSubview(label)
        // 展示正常的标签
        let fixLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: 60), size: CGSize(width: UIScreen.main.bounds.size.width, height: 30)))
        LKStringFix.shared.reloadConfig(self.getConfig())
        fixLabel.attributedText = LKStringFix.shared.fix(attrStr)
        self.view.addSubview(fixLabel)
    }

    private func getConfig() -> StringFixConfig {
        let configStr =
                """
        {
            "11.0-11.99":{
                "\\u0295\\u0322\\u0323\\u0323\\u0323\\u0323\\u0329\\u0329\\u0329\\u0329":{
                    "replaceContent":{
                        "to":"\\u0295\\u0322\\u0323"
                    }
                },
                "\\u0241\\u0321\\u0323\\u0323\\u0323\\u0323\\u0329\\u0329\\u0329\\u0329":{
                    "replaceContent":{
                        "to":"\\u0241\\u0321\\u0323"
                    }
                },
                "\\u003f\\ufe0f":{
                    "replaceContent":{
                        "to":"\\u003f"
                    }
                }
            },
            "12.0-13.99":{
                "\\u0295\\u0322\\u0323\\u0323\\u0323\\u0323\\u0329\\u0329\\u0329\\u0329":{
                    "replaceContent":{
                        "to":"\\u0295\\u0322\\u0323"
                    }
                },
                "\\u0241\\u0321\\u0323\\u0323\\u0323\\u0323\\u0329\\u0329\\u0329\\u0329":{
                    "replaceContent":{
                        "to":"\\u0241\\u0321\\u0323"
                    }
                }
            }
        }
        """
        return StringFixConfig(fieldGroups: [StringFixConfig.key: configStr])!
    }

}
