//
//  NormalReszieDemoVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2019/9/29.
//

import Foundation
import UIKit
import LKRichView

// swiftlint:disable all

//class AtElement: LKInlineBlockElement {
//    override init(id: String = "", tagName: Tag, classNames: [String] = [], style: LKRichStyle = LKRichStyle()) {
//        super.init(id: id, tagName: .at, classNames: classNames, style: style)
//    }
//}

class NormalResizeDemoVC: UIViewController {
    let text = "正常中文qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"

    var testView: LKRichView!

    lazy var documentElement: LKRichElement = {
        let element1 = LKBlockElement(tagName: Tag.p)
        element1.style.textDecoration(.init(line: [.lineThrough, .underline], style: .dashed))
        let normal = LKTextElement(text: text)
            .style(LKRichStyle()
                .color(UIColor.black)
                .fontSize(.point(20)))
        let italic = LKTextElement(text: text)
            .style(LKRichStyle()
                .color(UIColor.gray)
                .fontSize(.point(16))
                .fontStyle(.italic))
        let atText = LKTextElement(text: "@に行きたい")
        let inlineBlock1 = LKInlineBlockElement(tagName: Tag.at).addChild(atText)
        let inlineBlock2 = LKInlineBlockElement(tagName: Tag.at).addChild(atText)
        inlineBlock1.style.borderRadius(topLeft: LengthSize(width: .em(1), height: .em(1)))
            .backgroundColor(UIColor.blue)
            .color(UIColor.white)
        inlineBlock2.style.height(.point(30))

        let bold = LKTextElement(text: text)
            .style(LKRichStyle()
                .color(UIColor.darkGray)
                .fontSize(.point(16))
                .fontWeight(.bold))
        let italicBold = LKTextElement(text: text)
            .style(LKRichStyle()
                .color(UIColor.systemGray)
                .fontSize(.point(16))
                .fontStyle(.italic)
                .fontWeight(.bold))
        let img = LKImgElement(img: UIImage(named: "AppIcon")?.cgImage)
        img.style.verticalAlign(.middle)

        let element2 = LKBlockElement(tagName: Tag.p)
        let text1 = LKTextElement(text: """
Code review can have an important function of teaching developers something new about a language, a framework, or general software design principles. It's always fine to leave comments that help a developer learn something new. Sharing knowledge is part of improving the code health of a system over time.
""")
        text1.style.fontSize(.point(20))
        let text2 = LKTextElement(text: """
CR有一个重要的功能是它可以教会开发者一些语言、框架、通用软件设计原则相关的新东西。留下帮助开发者学习新东西的评论总是好的。分享知识是持续的提高系统代码质量的一部分。请记住，如果你的评论只是单纯教育性质的，不是那些能在这篇文章中找到的规范，那么请在前面加一个“Nit:”或者注明作者不需要解决它。
""")
        element2.style.fontSize(.point(14)).display(.block).width(.percent(95))

        let element = LKBlockElement(tagName: Tag.p)
        element.style.lineHeight(.point(30))
        element.children([
            element1.children([normal, inlineBlock1, italic, inlineBlock2, bold, italicBold, img]),
            element2.children([
                text1,
                text2
            ])
        ])
        return element
    }()

    lazy var moveButton: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(moveMoveButton(_:)))
        view.addGestureRecognizer(gesture)
        return view
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

//        testView.addSubview(moveButton)
//        moveButton.snp.makeConstraints { (make) in
//            make.width.height.equalTo(8)
//            make.right.bottom.equalTo(-8)
//        }
    }

    @objc
    private func moveMoveButton(_ pan: UIPanGestureRecognizer) {
        let currentPoint = pan.location(in: self.testView)
        testView.snp.remakeConstraints { (make) in
            make.top.equalTo(100)
            make.left.equalTo(10)
            make.width.equalTo(currentPoint.x)
            make.height.equalTo(CGFloat(fabsf(Float(currentPoint.y))))
        }
    }
}
