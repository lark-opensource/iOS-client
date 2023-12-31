//
//  LineCampVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2022/11/24.
//

import UIKit
import Foundation
import LKRichView

// swiftlint:disable all
class LineCampViewController: UIViewController {
    let text1 = "正常中文"
    let text2 = "qwertyuiopasdfghjklzxcvbnm"
    let text3 = "QWERTYUIOPASDFGHJKLZXCVBNM"
    let text4 = "1234567890"

    var textfiled1: UITextField!
    var button1: UIButton!
    var testView1: LKRichView!

    var textfiled2: UITextField!
    var button2: UIButton!
    var testView2: LKRichView!

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
        textfiled1 = UITextField()
        textfiled1.font = UIFont.systemFont(ofSize: 18)
        textfiled1.placeholder = "Input max line."
        textfiled1.text = "3"
        textfiled1.keyboardType = .numberPad
        textfiled1.layer.borderWidth = 2
        textfiled1.layer.borderColor = UIColor.black.cgColor
        self.view.addSubview(textfiled1)
        textfiled1.snp.makeConstraints { make in
            make.top.equalTo(100)
            make.left.equalTo(10)
            make.height.equalTo(20)
        }
        button1 = UIButton()
        button1.setTitle("Submit", for: .normal)
        button1.setTitleColor(.black, for: .normal)
        button1.layer.borderWidth = 2
        button1.layer.borderColor = UIColor.black.cgColor
        self.view.addSubview(button1)
        button1.snp.makeConstraints { make in
            make.top.equalTo(textfiled1)
            make.right.equalTo(-10)
            make.left.equalTo(textfiled1.snp.right).offset(50)
            make.width.equalTo(100)
            make.height.equalTo(20)
        }
        button1.addTarget(self, action: #selector(changeMaxLineOfTest1), for: .touchUpInside)
        // testView1
        testView1 = LKRichView(options: ConfigOptions([.debug(true)]))
        testView1.preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - 20
        testView1.switchMode(.visual)
        testView1.backgroundColor = UIColor.lightGray
        testView1.isOpaque = true
        testView1.layer.borderColor = UIColor.green.cgColor
        testView1.layer.borderWidth = 1
        self.view.addSubview(testView1)
        testView1.snp.makeConstraints { (make) in
            make.top.equalTo(textfiled1.snp.bottom).offset(10)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }
        changeMaxLineOfTest1()

        // ---------------------------------------------------
        textfiled2 = UITextField()
        textfiled2.font = UIFont.systemFont(ofSize: 18)
        textfiled2.placeholder = "Input max line."
        textfiled2.text = "5"
        textfiled2.keyboardType = .numberPad
        textfiled2.layer.borderWidth = 2
        textfiled2.layer.borderColor = UIColor.black.cgColor
        self.view.addSubview(textfiled2)
        textfiled2.snp.makeConstraints { make in
            make.top.equalTo(testView1.snp.bottom).offset(20)
            make.left.equalTo(10)
            make.height.equalTo(20)
        }
        button2 = UIButton()
        button2.setTitle("Submit", for: .normal)
        button2.setTitleColor(.black, for: .normal)
        button2.layer.borderWidth = 2
        button2.layer.borderColor = UIColor.black.cgColor
        self.view.addSubview(button2)
        button2.snp.makeConstraints { make in
            make.top.equalTo(textfiled2)
            make.right.equalTo(-10)
            make.left.equalTo(textfiled2.snp.right).offset(50)
            make.width.equalTo(100)
            make.height.equalTo(20)
        }
        button2.addTarget(self, action: #selector(changeMaxLineOfTest2), for: .touchUpInside)
        // testView2
        testView2 = LKRichView(options: ConfigOptions([.debug(true)]))
        testView2.preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - 20
        testView2.switchMode(.visual)
        testView2.backgroundColor = UIColor.lightGray
        testView2.isOpaque = true
        testView2.layer.borderColor = UIColor.green.cgColor
        testView2.layer.borderWidth = 1
        self.view.addSubview(testView2)
        testView2.documentElement = buildRandomAllInlineElement(maxLine: 1)
        testView2.snp.makeConstraints { (make) in
            make.top.equalTo(textfiled2.snp.bottom).offset(10)
            make.left.equalTo(10)
            make.right.equalTo(-10)
        }
        changeMaxLineOfTest2()
    }

    @objc
    private func changeMaxLineOfTest1() {
        guard let input = textfiled1.text, let maxLine = Int(input) else {
            return
        }
        testView1.documentElement = buildRandomAllInlineElement(maxLine: maxLine)
    }

    @objc
    private func changeMaxLineOfTest2() {
        guard let input = textfiled2.text, let maxLine = Int(input) else {
            return
        }
        testView2.documentElement = buildRandomInlineBlockElement(maxLine: maxLine)
    }

    func buildRandomAllInlineElement(maxLine: Int) -> LKRichElement {
        let element = LKBlockElement(tagName: Tag.p)
        element.style.lineHeight(.point(30)).lineCamp(.init(maxLine: maxLine))
        var children: [LKTextElement] = []
        for _ in 0..<Int.random(in: 20...40) {
            let ele = LKTextElement(text: [text1, text2, text3, text4].randomElement() ?? text1)
            ele.style.color(StringTool.randomColor()).fontSize(.point([CGFloat]([20, 30, 40]).randomElement() ?? 20))
            children.append(ele)
        }
        element.children(children)
        return element
    }

    private func buildRandomInlineBlockElement(maxLine: Int) -> LKRichElement {
        let element = LKBlockElement(tagName: Tag.p)
        element.style.lineHeight(.point(30)).lineCamp(.init(maxLine: maxLine))
        var children: [LKRichElement] = []
        for _ in 0..<Int.random(in: 5...10) {
            children.append(buildRandomBlockElement())
        }
        element.children(children)
        return element
    }

    private func buildRandomBlockElement() -> LKBlockElement {
        let element = LKBlockElement(tagName: Tag.p)
        element.style.color(StringTool.randomColor()).fontSize(.point(CGFloat.random(in: 10.0...30.0)))
        if Int.random(in: 1...10) > 5 {
            let inline = LKInlineElement(tagName: Tag.span)
            inline.addChild(LKTextElement(text: [text1, text2, text3, text4].randomElement() ?? text1))
            inline.addChild(LKTextElement(text: [text1, text2, text3, text4].randomElement() ?? text1))
            element.addChild(inline)
        }
        if Int.random(in: 1...10) > 5 {
            let inlineBlock = LKInlineBlockElement(tagName: Tag.at)
            inlineBlock.style.borderRadius(topLeft: LengthSize(width: .em(1), height: .em(1)))
                .backgroundColor(UIColor.blue)
                .color(UIColor.white)
                .width(.point(UIScreen.main.bounds.width / 4))
            inlineBlock.addChild(LKTextElement(text: [text1, text2, text3, text4].randomElement() ?? text1))
            element.addChild(inlineBlock)
        }
        if Int.random(in: 1...10) > 5 {
            let inlineBlock = LKInlineBlockElement(tagName: Tag.at)
            inlineBlock.style.borderRadius(topLeft: LengthSize(width: .em(1), height: .em(1)))
                .backgroundColor(UIColor.blue)
                .color(UIColor.white)
            inlineBlock.addChild(LKTextElement(text: [text1, text2, text3, text4].randomElement() ?? text1))
            inlineBlock.addChild(LKTextElement(text: [text1, text2, text3, text4].randomElement() ?? text1))
            element.addChild(inlineBlock)
        }
        if Int.random(in: 1...10) > 5 {
            let liText = LKTextElement(text: "国一些简单的文字一些简单的文字一些简单的文字一些简单的文字").style(LKRichStyle().fontSize(.point(17)))
            let ol1 = LKOrderedListElement(tagName: Tag.p, start: 3, olType: .lowercaseRoman).children([
                LKListItemElement(tagName: Tag.p).children([liText]),
                LKListItemElement(tagName: Tag.p).children([liText])
            ])
            let ol = LKOrderedListElement(tagName: Tag.p, start: 99, olType: .number).children([
                LKListItemElement(tagName: Tag.p).children([liText]),
                ol1,
                LKListItemElement(tagName: Tag.p).children([liText])
            ])
            let ul1 = LKUnOrderedListElement(tagName: Tag.p, ulType: .disc).children([LKListItemElement(tagName: Tag.p).children([liText])])
            let ul = LKUnOrderedListElement(tagName: Tag.p, ulType: .circle).children([ul1])
            element.addChild(ol).addChild(ol1).addChild(ul)
        }
        if Int.random(in: 1...10) > 5 {
            element.addChild(buildRandomBlockElement())
        }
        return element
    }
}
