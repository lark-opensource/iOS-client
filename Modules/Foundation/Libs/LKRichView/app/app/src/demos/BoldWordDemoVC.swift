//
//  BlodWordDemoVC.swift
//  LKRichViewDev
//
//  Created by 李勇 on 2023/3/8.
//

import UIKit
import Foundation
@testable import LKRichView

/// 粗体/斜体/下划线/删除线，导致word被分割问题
class BoldWordDemoVC: UIViewController {
    private let content = "正常中文qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
    var textConent: String = ""
    private let richViewOne = LKRichView(frame: .zero)

    var textElements: [LKTextElement] = []
    private let richViewTwo = LKRichView(frame: .zero, options: ConfigOptions([.fixSplitForTextRunBox(true)]))

    override func viewDidLoad() {
        super.viewDidLoad()

        self.testCustWordBreakCursor()
        self.richViewOne.layer.borderWidth = 0.5
        self.richViewOne.layer.borderColor = UIColor.black.cgColor
        self.view.addSubview(self.richViewOne)
        self.richViewTwo.layer.borderWidth = 0.5
        self.richViewTwo.layer.borderColor = UIColor.black.cgColor
        self.view.addSubview(self.richViewTwo)
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "update", style: .plain, target: self, action: #selector(self.update)),
                                                   UIBarButtonItem(title: "refresh", style: .plain, target: self, action: #selector(self.refresh))]
    }

    @objc
    func refresh() {
        // 布局第一个LKRichView
        do {
            let core = LKRichViewCore()
            let rootElement = LKInlineElement(tagName: Tag.p)
            let textElement = LKTextElement(text: self.textConent); rootElement.addChild(textElement)
            core.load(renderer: core.createRenderer(rootElement))
            let size = core.layout(CGSize(width: self.view.bounds.width - 10.0, height: Double(Int.max))) ?? .zero
            self.richViewOne.setRichViewCore(core)
            self.richViewOne.frame = CGRect(x: 0, y: 100, width: size.width, height: size.height)
        }
        // 布局第二个LKRichView
        do {
            let core = LKRichViewCore()
            let rootElement = LKInlineElement(tagName: Tag.p)
            self.textElements.forEach { element in rootElement.addChild(element) }
            core.load(renderer: core.createRenderer(rootElement))
            core.setRendererDebugOptions(self.richViewTwo.configOptions)
            let size = core.layout(CGSize(width: self.view.bounds.width - 10.0, height: Double(Int.max))) ?? .zero
            self.richViewTwo.setRichViewCore(core)
            self.richViewTwo.frame = CGRect(x: 0, y: self.richViewOne.frame.height + 100 + 20, width: size.width, height: size.height)
        }
    }

    @objc
    func update() {
        self.textConent = ""; self.textElements = []

        let randomLength = arc4random() % 50 + 100
        // 构造randomLength个长度的内容
        var currTextConent: String = ""
        for _ in 0..<randomLength {
            currTextConent += String(content.randomElement() ?? "~")
            let random = arc4random() % 10 + 5
            if currTextConent.count >= random {
                self.textElements.append(LKTextElement(text: currTextConent))
                self.textElements.append(LKTextElement(text: " "))
                currTextConent += " "
                self.textConent += currTextConent
                currTextConent = ""
            }
        }
        self.textConent += "a"
        self.textElements.append(LKTextElement(text: "a"))
        // 布局第一个LKRichView
        do {
            let core = LKRichViewCore()
            let rootElement = LKInlineElement(tagName: Tag.p)
            rootElement.style.fontWeight(.bold)
            let textElement = LKTextElement(text: self.textConent)
            rootElement.addChild(textElement)
            core.load(renderer: core.createRenderer(rootElement))
            let size = core.layout(CGSize(width: self.view.bounds.width - 10.0, height: Double(Int.max))) ?? .zero
            self.richViewOne.setRichViewCore(core)
            self.richViewOne.frame = CGRect(x: 0, y: 100, width: size.width, height: size.height)
        }
        // 布局第二个LKRichView
        do {
            let core = LKRichViewCore()
            let rootElement = LKInlineElement(tagName: Tag.p)
            rootElement.style.fontWeight(.medium)
            self.textElements.forEach { element in rootElement.addChild(element) }
            core.load(renderer: core.createRenderer(rootElement))
            core.setRendererDebugOptions(self.richViewTwo.configOptions)
            let size = core.layout(CGSize(width: self.view.bounds.width - 10.0, height: Double(Int.max))) ?? .zero
            self.richViewTwo.setRichViewCore(core)
            self.richViewTwo.frame = CGRect(x: 0, y: self.richViewOne.frame.height + 100 + 20, width: size.width, height: size.height)
        }
    }

    func testCustWordBreakCursor() {
        do {
            let ctFrameSetter = CTFramesetterCreateWithAttributedString(NSAttributedString(string: " e9yH401Q ", attributes: [.font: UIFont.systemFont(ofSize: 10)]))
            let ctTypeSetter = CTFramesetterGetTypesetter(ctFrameSetter)
            let length = CTTypesetterSuggestLineBreak(ctTypeSetter, 0, 10)
            let range = CFRange(location: 0, length: length)
            let ctLine = CTTypesetterCreateLine(ctTypeSetter, range)
            print("((())) \(ctLine)")
        }
        do {
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: " e9yH401Q ", attributes: [.font: UIFont.systemFont(ofSize: 10)]))
            let ctline = CTLineCreateTruncatedLine(line, 10, .end, nil)
            print("((())) \(ctline)")
        }
    }

    func testRenderBlock() {
        do {
            let renderBlock = RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            // error
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            // error
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            // error
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
    }

    func testRenderInlineBlock() {
        do {
            let renderBlock = RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
    }

    func testRenderInline() {
        do {
            let renderBlock = RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            // error
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            // error
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            // error
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            // error
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInlineBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            // error
            renderBlock.appendChild(RenderBlock(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
        do {
            let renderBlock = RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil)
            renderBlock.appendChild(RenderInline(nodeType: .container, renderStyle: LKRenderRichStyle(), ownerElement: nil))
        }
    }
}
