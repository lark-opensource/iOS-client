//
//  BorderDemoVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2019/11/4.
//

import Foundation
import UIKit
import LKRichView

// swiftlint:disable all
class BorderDemoVC: UIViewController {
    var testView: LKRichView!

    lazy var documentElement: LKRichElement = {
        let element = LKBlockElement(tagName: Tag.p)
        element.style.textDecoration(TextDecoration(line: .lineThrough, style: .solid))
            .font(UIFont.systemFont(ofSize: 40))
            .color(UIColor.white)
            .backgroundColor(UIColor.gray)
            .padding(top: .point(20))
            .border(top: BorderEdge(style: .solid, width: .point(3), color: UIColor.black),
                    right: BorderEdge(style: .solid, width: .em(1), color: UIColor.yellow))
            .borderRadius(topLeft: LengthSize(width: .point(10), height: .point(10)),
                          bottomLeft: LengthSize(width: .percent(50), height: .percent(50)))
        let atText = LKTextElement(text: "@に行きたい づ て で と ど な に ぬ ね の は ば ぱ ひ び ぴ ふ ぶ ぷ へ べ ぺ ほ ぼ ぽ ま み む め も ゃや ゅ ゆ ょ よ ら り る れ ろ ゎ わ ゐ ゑ を ん ゔ ゕ ゖ ゙ ゚ ゛ ゜ゝ ゞ ゟ゠ ァ ア ィ イ ゥ ウ ェ エ ォ オ カ ガ キ ギ ク グ ケ ゲ コ ゴ サ ザ シ ジ ス ズ セ ゼ ソ ゾ タ ダ チ ヂ ッ ツ ヅ テ デ ト ド ナ ニ ヌ ネ ノ ハ バ パ ヒ ビ ピ フ")
        element.children([
            atText,
            LKInlineElement(tagName: Tag.span).children([
                LKInlineBlockElement(tagName: Tag.span, style: LKRichStyle().width(.em(1)).height(.em(1)).backgroundColor(UIColor.red)),
                LKTextElement(text: "ABCDEFGHIJKLMN")
            ]),
            atText
        ])

        return element
    }()

    var uilabel = UILabel()

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
        testView = LKRichView(options: ConfigOptions([.debug(false)]))
        testView.preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - 20
        testView.isOpaque = true
        testView.documentElement = documentElement
        self.view.addSubview(testView)
        testView.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }

        self.view.addSubview(uilabel)
        uilabel.numberOfLines = 0
        uilabel.snp.makeConstraints { make in
            make.top.equalTo(testView.snp.bottom).offset(100)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }

        let attrString = NSMutableAttributedString()
        let colors = [UIColor.blue, UIColor.black, UIColor.red, UIColor.green]
        for i in 0..<1000 {
            attrString.append(NSAttributedString(string: "正常中文qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890", attributes: [.foregroundColor: colors[i % 4]]))
        }
        uilabel.attributedText = attrString
    }
}
