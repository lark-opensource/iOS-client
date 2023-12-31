//
//  TestCaseTest1VC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2022/7/12.
//

import UIKit
import Foundation
import LKRichView

class TestCaseTest1VC: UIViewController {
    var testView: LKRichView!

    lazy var styleSheet: CSSStyleSheet = {
        let styleSheet = CSSStyleSheet(rules: [
//            CSSStyleRule.create(CSSSelector(value: Tag.p), [
//                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Reqular", size: 14))),
//                StyleProperty.fontSize(.init(.point, 14)),
//                StyleProperty.display(.init(.value, .block))
//            ]),
//            CSSStyleRule.create(CSSSelector(value: Tag.h1), [
//                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 24))),
//                StyleProperty.fontSize(.init(.point, 24)),
//                StyleProperty.display(.init(.value, .block))
//            ]),
//            CSSStyleRule.create(CSSSelector(value: Tag.h2), [
//                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 20))),
//                StyleProperty.fontSize(.init(.point, 20)),
//                StyleProperty.display(.init(.value, .block))
//            ]),
//            CSSStyleRule.create(CSSSelector(value: Tag.h3), [
//                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 18))),
//                StyleProperty.fontSize(.init(.point, 18)),
//                StyleProperty.display(.init(.value, .block))
//            ]),
//            CSSStyleRule.create(CSSSelector(value: Tag.at), [
//                StyleProperty.display(.init(.value, .inlineBlock)),
//                StyleProperty.backgroundColor(.init(.value, UIColor.blue)),
//                StyleProperty.color(.init(.value, UIColor.white)),
//                StyleProperty.padding(.init(.value, Edges(.point(4)))),
//                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(1), height: .em(1)))))
//            ]),
//            CSSStyleRule.create(CSSSelector(match: .className, value: "bold"), [
//                StyleProperty.fontWeigth(.init(.value, .bold))
//            ]),
//            CSSStyleRule.create(CSSSelector(match: .className, value: "italic"), [
//                StyleProperty.fontStyle(.init(.value, .italic))
//            ]),
//            CSSStyleRule.create(CSSSelector(match: .className, value: "italicBold"), [
//                StyleProperty.fontWeigth(.init(.value, .bold)),
//                StyleProperty.fontStyle(.init(.value, .italic))
//            ]),
//            CSSStyleRule.create(CSSSelector(match: .className, value: "point"), [
//                StyleProperty.verticalAlign(.init(.value, .top)),
//                StyleProperty.width(.init(.point, 4)),
//                StyleProperty.height(.init(.point, 4)),
//                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .point(2), height: .point(2)))))
//            ]),
//            CSSStyleRule.create(CSSSelector(match: .className, value: "green"), [
//                StyleProperty.backgroundColor(.init(.value, UIColor.green))
//            ])
        ])
        return styleSheet
    }()

    lazy var documentElement: LKRichElement = {
//        let element = LKBlockElement(tagName: Tag.p)
//
//        let at1 = LKInlineBlockElement(tagName: Tag.at).addChild(LKTextElement(text: "普通at"))
//        let point = LKInlineBlockElement(tagName: Tag.span, classNames: ["point", "green"])
//        let atPoint = LKInlineBlockElement(tagName: Tag.span)
//            .children([LKTextElement(text: "带point的名字"), point])
//        let at2 = LKInlineBlockElement(tagName: Tag.at)
//            .addChild(LKTextElement(text: "限制宽高的at1"))
//            .style(LKRichStyle().height(.point(60)).width(.point(55)))
//        let splitText = LKTextElement(text: "这是一段很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的文字，需要被折行")
//        let at3 = LKInlineBlockElement(tagName: Tag.at)
//            .addChild(LKTextElement(text: "限制宽高的at"))
//            .style(LKRichStyle().height(.point(60)).width(.point(55)))
//        element.children([at1, atPoint, at2, splitText, at3])
        let element = LKBlockElement(tagName: Tag.p, style: LKRichStyle().maxHeight(.point(100)))
        let img = LKInlineBlockElement(tagName: Tag.p, style: LKRichStyle().height(.point(100)).width(.point(100)))
        let text = LKTextElement(text: "Im a single text.")
        element.children([img, text, img, text, text])
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func initView() {
        testView = LKRichView(options: ConfigOptions([.debug(true), .maxHeightBuffer(100)]))
        testView.preferredMaxLayoutWidth = 375
        testView.delegate = self
        testView.isOpaque = true
        testView.loadStyleSheets([styleSheet])
        testView.documentElement = documentElement
        testView.backgroundColor = UIColor.lightGray
        testView.layer.borderColor = UIColor.green.cgColor
        testView.layer.borderWidth = 1
        testView.switchMode(.visual)
        testView.bindEvent(selectors: [CSSSelector(value: Tag.a)], isPropagation: true)
        self.view.addSubview(testView)
        testView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(375)
//            make.right.equalTo(-10)
//            make.height.equalTo(300)
        }
    }
}

extension TestCaseTest1VC: LKRichViewDelegate {
    func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
    }

    func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return nil
    }

    func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {

    }

    func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        print(element)
    }

    func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }

    func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }

    func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }
}
