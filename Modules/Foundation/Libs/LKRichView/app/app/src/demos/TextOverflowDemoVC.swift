//
//  TextOverflowDemoVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2022/10/20.
//

import UIKit
import Foundation
import LKRichView

// swiftlint:disable all
class TextOverflowDemoVC: UIViewController {
    let text1 = "正常中文"
    let text2 = "qwertyuiopasdfghjklzxcvbnm"
    let text3 = "QWERTYUIOPASDFGHJKLZXCVBNM"
    let text4 = "1234567890"

    var testView: LKRichView!

    lazy var documentElement: LKRichElement = {
        let element = LKBlockElement(tagName: Tag.p)
        element.style.lineHeight(.point(30)).textOverflow(.noWrapEllipsis)
        if true {
            let p = LKBlockElement(tagName: Tag.p)
            p.style.textDecoration(.init(line: [.lineThrough, .underline], style: .dashed))
            let normal = LKTextElement(text: text1)
                .style(LKRichStyle()
                    .color(UIColor.black)
                    .fontSize(.point(20)))
            let italic = LKTextElement(text: text2)
                .style(LKRichStyle()
                    .color(UIColor.gray)
                    .fontSize(.point(16))
                    .fontStyle(.italic))
            let atText = LKTextElement(text: "@に行きたい")
            let inlineBlock1 = LKInlineBlockElement(tagName: Tag.at).addChild(atText)
            inlineBlock1.style.borderRadius(topLeft: LengthSize(width: .em(1), height: .em(1)))
                .backgroundColor(UIColor.blue)
                .color(UIColor.white)

            let bold = LKTextElement(text: text3)
                .style(LKRichStyle()
                    .color(UIColor.darkGray)
                    .fontSize(.point(16))
                    .fontWeight(.bold))
            let italicBold = LKTextElement(text: text4)
                .style(LKRichStyle()
                    .color(UIColor.systemGray)
                    .fontSize(.point(16))
                    .fontStyle(.italic)
                    .fontWeight(.bold))
            let img = LKImgElement(img: UIImage(named: "AppIcon")?.cgImage)
            img.style.verticalAlign(.middle)
            element.addChild(p.children([normal, inlineBlock1, italic, bold, italicBold, img]))
        }

        if true {
            let p = LKBlockElement(tagName: Tag.p)
            let text = LKTextElement(text: """
    Code review can have an important function of teaching developers something new about a language, a framework, or general software design principles. It's always fine to leave comments that help a developer learn something new. Sharing knowledge is part of improving the code health of a system over time.
    """)
            element.addChild(p.children([text]))
        }

        if true {
            let p = LKBlockElement(tagName: Tag.p)
            p.style.fontSize(.point(14)).display(.block).width(.percent(95))
            let text = LKTextElement(text: """
    CR有一个重要的功能是它可以教会开发者一些语言、框架、通用软件设计原则相关的新东西。留下帮助开发者学习新东西的评论总是好的。分享知识是持续的提高系统代码质量的一部分。请记住，如果你的评论只是单纯教育性质的，不是那些能在这篇文章中找到的规范，那么请在前面加一个“Nit:”或者注明作者不需要解决它。
    """)
            element.addChild(p.children([text]))
        }

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
        testView.preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - 20
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
