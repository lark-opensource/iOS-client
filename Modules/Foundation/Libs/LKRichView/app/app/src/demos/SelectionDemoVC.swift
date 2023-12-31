//
//  SelectionDemoVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2020/1/27.
//

import Foundation
import LKRichView
import UIKit

// swiftlint:disable all

class SelectionDemoVC: UIViewController {
    var testView: LKRichContainerView!

    lazy var styleSheet: CSSStyleSheet = {
        let styleSheet = CSSStyleSheet(rules: [
            CSSStyleRule.create(CSSSelector(value: Tag.p), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Reqular", size: 16))),
                StyleProperty.display(.init(.value, .block))
//                StyleProperty.lineHeight(.init(.point, 30))
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
                StyleProperty.backgroundColor(.init(.value, UIColor.systemBlue)),
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
            .children([LKTextElement(text: "point名字"), point])

        let at2 = LKInlineBlockElement(tagName: Tag.at)
            .addChild(LKTextElement(text: "限制宽高的at1"))
            .style(LKRichStyle().height(.point(60)).width(.point(200)))
        let underlineWithAbbr = LKInlineBlockElement(tagName: Tag.abbr)
                .addChild(LKTextElement(classNames: ["underline"], text: "有下划线的企业词典国"))

        let splitText = LKTextElement(text: "这是一段\n很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长很长的文字，需要被折行")

        let at3 = LKInlineBlockElement(tagName: Tag.at)
            .addChild(LKTextElement(text: "限制宽高的at2"))
            .style(LKRichStyle().height(.point(150)).width(.point(100)))

        let anchor = LKAnchorElement(tagName: Tag.a, classNames: [], text: "")
            .children([
                LKImgElement(style: LKRichStyle().verticalAlign(.middle), img: UIImage(named: "AppIcon")?.cgImage),
                LKTextElement(text: "Mr名的一句名言就是一个人做👨、哈哈好哈哈哈哈哈哈真的超级好")
            ])
        anchor.style.textDecoration(TextDecoration(line: [.lineThrough, .underline], style: .solid, thickness: 1, color: UIColor.red))
        element.children([
            LKBlockElement(tagName: Tag.span).children([anchor, splitText]),
            LKBlockElement(id: "p1", tagName: Tag.p).children([
                at1, atPoint, at2, anchor, underlineWithAbbr, at3
            ])
        ])

        let liText = LKTextElement(text: "一些简单的文字一些简单的文字").style(LKRichStyle().fontSize(.point(17)))
        let ol1 = LKOrderedListElement(tagName: Tag.p, start: 3, olType: .lowercaseRoman).children([
            LKListItemElement(tagName: Tag.p).children([anchor, liText, splitText, splitText]),
            LKListItemElement(tagName: Tag.p).children([liText, splitText, splitText])
        ])
        let ol = LKOrderedListElement(tagName: Tag.p, start: 99, olType: .number).children([
            LKListItemElement(tagName: Tag.p).children([liText]),
            ol1,
            LKListItemElement(tagName: Tag.p).children([liText])
        ])
        let ul1 = LKUnOrderedListElement(tagName: Tag.p, ulType: .disc).children([LKListItemElement(tagName: Tag.p).children([liText])])
        let ul = LKUnOrderedListElement(tagName: Tag.p, ulType: .circle).children([ul1])

        let atContainer = LKInlineElement(tagName: Tag.span).children([
            LKTextElement(text: "一个名"),
            LKInlineBlockElement(tagName: Tag.span).children([
                LKTextElement(text: "字"),
                LKInlineElement(tagName: Tag.span, classNames: ["point", "green"])
            ]).style(LKRichStyle().isBlockSelection(true))
        ])
        let container = LKBlockElement(tagName: Tag.p)
        container.children([
            ol1,
            element,
//            LKTextElement(text: "一二三四五六七八九十一二三四五六七八九十一二三四五1111"),
//            LKInlineElement(tagName: Tag.span).children([
//                LKTextElement(text: "一个名"),
//                LKInlineBlockElement(tagName: Tag.span).children([
//                    LKTextElement(text: "字"),
//                    LKInlineElement(tagName: Tag.span, classNames: ["point", "green"])
//                ]).style(LKRichStyle().isBlockSelection(true))
//            ]),
//            LKTextElement(text: "Delivered Version: 5.3.0-a9dbc15b55-dev\nCommit: a9dbc15b55b8b6e30a903bf372382a113d5210c4\n"),
//            LKTextElement(text: "一二三四五六七八九十一二三四五六七八九十一二三四五1111"),
//            LKInlineElement(tagName: Tag.span).children([
//                LKTextElement(text: "一个名"),
//                LKInlineBlockElement(tagName: Tag.span).children([
//                    LKTextElement(text: "字"),
//                    LKInlineElement(tagName: Tag.span, classNames: ["point", "green"])
//                ]).style(LKRichStyle().isBlockSelection(true))
//            ]),
//            LKTextElement(text: "text reaches the right side of the view. Text then begins a new line at the left side of the view under the beginning of the previous line, and layout proceeds in the same manner to the bottom of the text view.text reaches the right side of the view. Text then begins a new line at the left side of the view under the beginning of the previous line, and layout proceeds in the same manner to the bottom of the text view.text reaches the right side of the view. Text then begins a new line at the left side of the view under the beginning of the previous line, and layout proceeds in the same manner to the bottom of the text view.text reaches the right side of the view. Text then begins a new line at the left side of the view under the beginning of the previous line, and layout proceeds in the same manner to the bottom of the text view.text reaches the right side of the view. Text then begins a new line at the left side of the view under the beginning of the previous line, and layout proceeds in the same manner to the bottom of the text view.text reaches the right side of the view. Text then begins a new line at the left side of the view under the beginning of the previous line, and layout proceeds in the same manner to the bottom of the text view.text reaches the right side of the view. Text then begins a new line at the left side of the view under the beginning of the previous line, and layout proceeds in the same manner to the bottom of the te"),
            selectionCrashCase,
            LKBlockElement(id: "p2", tagName: Tag.p).children([at1, atPoint])
        ])

        return container
    }()

    private lazy var i18nCase = LKTextElement(text: "แต่งไงได้งี้一些简单的文字一些简单的文字แต่งไงได้งี้")

    private lazy var selectionCrashCase: LKRichElement = {
        let anchor = LKAnchorElement(tagName: Tag.a, classNames: [], text: "")
            .children([
                LKImgElement(style: LKRichStyle().verticalAlign(.middle), img: UIImage(named: "AppIcon")?.cgImage),
                LKTextElement(text: "Mr名的一句名言就是一个人做👨、哈哈好哈哈哈哈哈哈真的超级好")
            ])
        anchor.style.textDecoration(TextDecoration(line: [.lineThrough, .underline], style: .solid, thickness: 1, color: UIColor.red))
        return anchor
    }()

    private lazy var rhsReverseCase: LKRichElement = {
        let titleElement = LKBlockElement(tagName: Tag.p).children([
            LKTextElement(
                classNames: ["text"],
                text: "title"
            )
        ])
        titleElement.style.color(.red).lineHeight(.em(1.3))

        let container = LKBlockElement(tagName: Tag.p)
        let emoElement1 = LKImgElement(
            classNames: ["emotion"],
            img: UIImage(named: "approve")!.cgImage
        )
        emoElement1.style.height(.em(1.2))
        emoElement1.defaultString = "emoElement1"
        let emoElement2 = LKImgElement(
            classNames: ["emotion"],
            img: UIImage(named: "approve")!.cgImage
        )
        emoElement2.style.height(.em(1.2))
        emoElement2.defaultString = "emoElement2"
        let emoElement3 = LKImgElement(
            classNames: ["emotion"],
            img: UIImage(named: "approve")!.cgImage
        )
        emoElement3.style.height(.em(1.2))
        emoElement3.defaultString = "emoElement3"
        let line = LKInlineBlockElement(tagName: Tag.emotion)
            .children([emoElement1,emoElement2,emoElement3])
//            .style(LKRichStyle().height(.point(150)).width(.point(100)))

        let anchor = LKAnchorElement(tagName: Tag.a, classNames: [], text: "")
            .children([
                LKTextElement(text: "这是一个 Anchor 这是一个 Anchor 这是一个 Anchor 这是一个 Anchor")
            ])
        anchor.style.textDecoration(TextDecoration(line: [.lineThrough, .underline], style: .solid, thickness: 1, color: UIColor.red))
        container.children([
            anchor,
            line
        ])

        let resBlock = LKBlockElement(tagName: Tag.p).children([titleElement,container])
        return resBlock
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

    private lazy var copyButton = UIButton()
    private lazy var activeSelectButton = UIButton()

    func initView() {
        testView = LKRichContainerView(options: ConfigOptions([.debug(false)]))
        testView.richView.preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - 150
        testView.richView.delegate = self
        testView.richView.isOpaque = true
        testView.richView.clipsToBounds = true
        testView.richView.loadStyleSheets([styleSheet])
        testView.richView.documentElement = documentElement
        testView.richView.backgroundColor = UIColor.lightGray
        testView.richView.displayMode = .sync
//        testView.layer.borderColor = UIColor.green.cgColor
//        testView.layer.borderWidth = 1
//        testView.switchMode(.visual)
        testView.richView.bindEvent(selectors: [CSSSelector(value: Tag.a)], isPropagation: true)
        self.view.addSubview(testView)
        testView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalTo(75)
            make.right.equalTo(-75)
//            make.height.equalTo(300)
        }
        testView.richView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        self.view.addSubview(copyButton)
        copyButton.addTarget(self, action: #selector(onCopyButtonClick), for: .touchUpInside)
        copyButton.setTitle("copy", for: .normal)
        copyButton.backgroundColor = .lightGray
        copyButton.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 40, height: 20))
            $0.top.equalTo(testView.snp.bottom).offset(10)
            $0.left.equalTo(10)
        }

        self.view.addSubview(activeSelectButton)
        activeSelectButton.addTarget(self, action: #selector(onActiveSelectButtonClick), for: .touchUpInside)
        activeSelectButton.setTitle("active/inActive", for: .normal)
        activeSelectButton.backgroundColor = .lightGray
        activeSelectButton.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 120, height: 20))
            $0.top.equalTo(testView.snp.bottom).offset(10)
            $0.left.equalTo(copyButton.snp.right).offset(10)
        }
    }

    @objc
    private func onCopyButtonClick() {
        print("copyStr: \(testView.richView.getCopyString()?.string ?? "") isSelectAll: \(testView.richView.isSelectAll())")
    }

    private var isActive = false
    @objc
    private func onActiveSelectButtonClick() {
        if isActive {
            testView.richView.switchMode(.normal)
        } else {
            testView.richView.switchMode(.visual)
        }
        isActive = !isActive
    }
}

extension SelectionDemoVC: LKRichViewDelegate {
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
