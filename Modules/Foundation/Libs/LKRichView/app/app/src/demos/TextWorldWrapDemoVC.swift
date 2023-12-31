//
//  TextWorldWrapDemoVC.swift
//  LKRichViewDev
//
//  Created by Ping on 2023/1/10.
//

import UIKit
import Foundation
import LKRichView

// swiftlint:disable all
// https://meego.feishu.cn/larksuite/issue/detail/8643692
// lineBreakMode = .byWorld时，折行会有问题
class TextWorldWrapDemoVC: UIViewController {
    let text1 = "场景出现的吧。 出现版本从 5.21~5.24 ， 这个是已知问题么"

    var testView: LKRichView!

    lazy var documentElement: LKRichElement = {
        let element = LKBlockElement(tagName: Tag.p)
        let text = LKTextElement(text: text1).style(
            LKRichStyle()
                .color(UIColor.black)
                .font(UIFont.systemFont(ofSize: 17))
                .fontSize(.point(UIFont.systemFont(ofSize: 17).pointSize))
        )
        element.children([text])
        return element
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    func initView() {
        testView = LKRichView(options: ConfigOptions([.debug(true)]))
        testView.preferredMaxLayoutWidth = 291.79998779296875
        testView.switchMode(.visual)
        testView.backgroundColor = UIColor.lightGray
        testView.isOpaque = true
        testView.layer.borderColor = UIColor.green.cgColor
        testView.layer.borderWidth = 1
        self.view.addSubview(testView)
        testView.documentElement = documentElement
        testView.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }
    }
}
