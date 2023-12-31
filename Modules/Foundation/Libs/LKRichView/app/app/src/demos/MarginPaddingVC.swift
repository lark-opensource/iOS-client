//
//  MarginPaddingVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2020/1/27.
//

import UIKit
import Foundation
import LKRichView

public enum Tag: Int8, LKRichElementTag {
    case p
    case h1
    case h2
    case h3
    case a
    case at
    case emotion
    case span
    case quote
    case abbr

    public var typeID: Int8 {
        return rawValue
    }
}

class MarginPaddingDemoVC: UIViewController {
    var testView: LKRichView!

    lazy var styleSheet: CSSStyleSheet = {
        let styleSheet = CSSStyleSheet(rules: [
            CSSStyleRule.create(CSSSelector(value: Tag.p), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Reqular", size: 16))),
                StyleProperty.display(.init(.value, .block))
//                StyleProperty.maxHeight(.init(.point, 250))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h1), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 24))),
                StyleProperty.fontSize(.init(.point, 24)),
                StyleProperty.display(.init(.value, .block))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h2), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 20))),
                StyleProperty.fontSize(.init(.point, 20)),
                StyleProperty.display(.init(.value, .block))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h3), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 18))),
                StyleProperty.fontSize(.init(.point, 18)),
                StyleProperty.display(.init(.value, .block))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.at), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.backgroundColor(.init(.value, UIColor.blue)),
                StyleProperty.color(.init(.value, UIColor.white)),
                StyleProperty.padding(.init(.value, Edges(.point(10), .point(20), .point(20)))),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(1), height: .em(1)))))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.a), [
                StyleProperty.display(.init(.value, .inline)),
                StyleProperty.lineHeight(.init(.value, 14)),
                StyleProperty.textDecoration(.init(.value, .none))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.quote), [
                StyleProperty.display(.init(.value, .block)),
                StyleProperty.color(.init(.value, UIColor.gray)),
                StyleProperty.padding(.init(.value, Edges(.point(20), .point(5), .point(5), .point(17)))),
                StyleProperty.margin(.init(.value, Edges(.point(20), .point(0)))),
                StyleProperty.border(.init(.value, Border(nil, nil, nil, BorderEdge(style: .solid, width: .point(3), color: UIColor.blue))))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "bold"), [
                StyleProperty.fontWeigth(.init(.value, .bold))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "italic"), [
                StyleProperty.fontStyle(.init(.value, .italic))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "italicBold"), [
                StyleProperty.fontWeigth(.init(.value, .bold)),
                StyleProperty.fontStyle(.init(.value, .italic))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "point"), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.verticalAlign(.init(.value, .top)),
                StyleProperty.width(.init(.point, 4)),
                StyleProperty.height(.init(.point, 4)),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .point(2), height: .point(2)))))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "green"), [
                StyleProperty.backgroundColor(.init(.value, UIColor.green))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "underline"), [
                StyleProperty.textDecoration(.init(.value, .init(line: .underline, style: .solid, thickness: 1)))
            ]),
            CSSStyleRule.create(CSSSelector(match: .className, value: "lineThrough"), [
                StyleProperty.textDecoration(.init(.value, .init(line: .lineThrough, style: .solid, thickness: 1)))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.abbr), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.verticalAlign(.init(.value, .baseline)),
                StyleProperty.border(.init(.value, Border(nil, nil, BorderEdge(style: .dashed, width: .point(1), color: UIColor.red), nil))),
                StyleProperty.padding(LKRichStyleValue(.value, Edges(nil, nil, .point(2.5))))
            ])
        ])
        return styleSheet
    }()

    lazy var documentElement: LKRichElement = {
        let element = LKBlockElement(tagName: Tag.quote)

        let at1 = LKInlineBlockElement(tagName: Tag.at).addChild(LKTextElement(text: "普通at"))

        let point = LKInlineElement(tagName: Tag.span, classNames: ["point", "green"])
        let atPoint = LKInlineBlockElement(tagName: Tag.span)
            .children([LKTextElement(text: "带point的名字"), point])

        let at2 = LKInlineBlockElement(tagName: Tag.at)
            .addChild(LKTextElement(text: "限制宽高的at1"))
            .style(LKRichStyle().height(.point(60)).width(.point(55)))
        let underlineWithAbbr = LKInlineBlockElement(tagName: Tag.abbr)
                .addChild(LKTextElement(classNames: ["underline"], text: "有下划线的企业词典国"))

        let splitText = LKTextElement(text: "这是一段\n很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的文字，需要被折行")

        let at3 = LKInlineBlockElement(tagName: Tag.at)
            .addChild(LKTextElement(text: "限制宽高的at2"))
            .style(LKRichStyle().height(.point(150)).width(.point(100)))

        let anchor = LKAnchorElement(tagName: Tag.a, classNames: ["bold"], text: "", href: "https://toutiao.com")
            .children([
                LKImgElement(style: LKRichStyle().verticalAlign(.middle), img: UIImage(named: "AppIcon")?.cgImage),
                LKTextElement(text: "头条头条头条头条头条头条头条头条头条头条头")
            ])
        anchor.style.textDecoration(TextDecoration(line: [.lineThrough, .underline], style: .solid, thickness: 1, color: UIColor.red))
        element.children([
            LKBlockElement(id: "p1", tagName: Tag.p).children([
                at1, atPoint, at2, anchor, underlineWithAbbr,
                at3
            ]),
            LKBlockElement(id: "p2", tagName: Tag.p).children([
                at1,
                LKInlineElement(tagName: Tag.span).children([anchor]),
                splitText
            ]),
            LKBlockElement(id: "p3", tagName: Tag.p).children([splitText])
        ])

        let liText = LKTextElement(text: "国一些简单的文字一些简单的文字一些简单的文字一些简单的文字").style(LKRichStyle().fontSize(.point(17)))
        let ol1 = LKOrderedListElement(tagName: Tag.p, classNames: ["italicBold"], start: 3, olType: .lowercaseRoman).children([
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

        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            anchor,
            at1, at2, at3,
//            ul, ol,
//            element
        ])

        return container
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
        testView = LKRichView(options: ConfigOptions([.debug(false)]))
        testView.preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - 20
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
            make.left.equalTo(10)
            make.right.equalTo(-10)
//            make.height.equalTo(300)
        }
    }
}

extension MarginPaddingDemoVC: LKRichViewDelegate {
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
