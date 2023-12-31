//
//  StyleSheetVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2020/1/7.
//

import UIKit
import Foundation
import LKRichView

class MyUILabel: UILabel {
    override var bounds: CGRect {
        didSet {
            print("setBounds: ", bounds)
        }
    }
    override var intrinsicContentSize: CGSize {
        print(preferredMaxLayoutWidth)
        return super.intrinsicContentSize
    }
    override var preferredMaxLayoutWidth: CGFloat {
        get {
            return super.preferredMaxLayoutWidth
        }
        set {
            super.preferredMaxLayoutWidth = newValue
        }
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size)
    }
}

class Attachment: LKRichAttachment {
    var verticalAlign: VerticalAlign = .middle

    var padding: Edges?

    let size: CGSize

    init(size: CGSize) {
        self.size = size
    }

    func getAscent(_ mode: WritingMode) -> CGFloat {
        switch mode {
        case .horizontalTB:
            return 0
        case .verticalLR, .verticalRL:
            return 0
        }
    }

    func createView() -> UIView {
        let imgView = UIImageView(frame: CGRect(origin: .zero, size: size))
        imgView.image = UIImage(named: "AppIcon")
        imgView.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(onTap)))
        return imgView
    }

    @objc
    private func onTap(_ target: Any) {
        print(target)
    }
}

class StyleSheetVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let text = "正常中文qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"

    var tableview = UITableView()

    lazy var styleSheet: CSSStyleSheet = {
        let styleSheet = CSSStyleSheet(rules: [
            CSSStyleRule.create(CSSSelector(value: Tag.p), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Reqular", size: 14))),
                StyleProperty.fontSize(.init(.point, 14)),
                StyleProperty.display(.init(.value, .block)),
                StyleProperty.margin(.init(.value, Edges(.point(20))))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h1), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 24))),
                StyleProperty.fontSize(.init(.point, 24)),
                StyleProperty.display(.init(.value, .block)),
                StyleProperty.margin(.init(.value, Edges(.point(10))))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h2), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 20))),
                StyleProperty.fontSize(.init(.point, 20)),
                StyleProperty.display(.init(.value, .block)),
                StyleProperty.margin(.init(.value, Edges(.point(20))))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.h3), [
                StyleProperty.font(.init(.value, UIFont(name: "PingFangSC-Semibold", size: 18))),
                StyleProperty.fontSize(.init(.point, 18)),
                StyleProperty.display(.init(.value, .block)),
                StyleProperty.margin(.init(.value, Edges(.point(10))))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.at), [
                StyleProperty.display(.init(.value, .inlineBlock)),
                StyleProperty.backgroundColor(.init(.value, UIColor.blue)),
                StyleProperty.color(.init(.value, UIColor.white)),
                StyleProperty.padding(.init(.value, Edges(.point(1), .point(4)))),
                StyleProperty.borderRadius(.init(.value, BorderRadius(LengthSize(width: .em(0.8), height: .em(0.8))))),
                StyleProperty.textAlign(.init(.value, .center))
            ]),
            CSSStyleRule.create(CSSSelector(value: Tag.a), [
                StyleProperty.display(.init(.value, .inline)),
                StyleProperty.color(.init(.value, UIColor.blue)),
                StyleProperty.textDecoration(.init(.value, .init(line: [.underline], style: .dashed)))
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
            ])
        ])
        return styleSheet
    }()

    func getDocumentElement() -> LKRichElement {
        let h1 = LKBlockElement(tagName: Tag.h1).children([LKTextElement(text: "H1 字段字号 48")])
        let h2 = LKBlockElement(tagName: Tag.h2).children([LKTextElement(text: "H2 字段字号 40")])
        let h3 = LKBlockElement(tagName: Tag.h3).children([LKTextElement(text: "H3 字段字号 36")])
        let element1 = LKBlockElement(tagName: Tag.p)
        element1.style.textDecoration(.init(line: [.underline], style: .dashed))
        let normal = LKTextElement(text: text)
            .style(LKRichStyle()
                .color(UIColor.black))
        let italic = LKTextElement(classNames: ["italic"], text: text)
            .style(LKRichStyle()
                .color(UIColor.gray))
        let atText = LKTextElement(text: "@に行きたい")
        let inlineBlock1 = LKInlineBlockElement(tagName: Tag.at).addChild(atText)
        let inlineBlock2 = LKInlineBlockElement(tagName: Tag.at).addChild(atText)

        let bold = LKTextElement(classNames: ["bold"], text: text)
            .style(LKRichStyle().color(UIColor.darkGray))
        let italicBold = LKTextElement(classNames: ["italicBold"], text: text)
            .style(LKRichStyle().color(UIColor.systemGray))
        let img = LKImgElement(img: UIImage(named: "AppIcon")?.cgImage)
        img.style.verticalAlign(.middle)

        let attachment = LKAttachmentElement(attachment: Attachment(size: CGSize(width: 200, height: 200)))

        let root = LKBlockElement(tagName: Tag.p)
        for _ in 0..<2 { //runBox
            let element = LKBlockElement(tagName: Tag.p)
            element.children([h1, h2, h3, element1.children([normal, inlineBlock1, italic, inlineBlock2, bold, italicBold, img, attachment])])
            root.addChild(element)
        }
        return root
    }

    var vmLock = NSLock()
    var vms: [LKRichViewCore] = []

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        DispatchQueue.global().async {
            for _ in 0..<1 {
                let core = LKRichViewCore()
                core.load(styleSheets: [self.styleSheet])
                if let renderer = core.createRenderer(self.getDocumentElement()) {
                    core.load(renderer: renderer)
                    _ = core.layout(CGSize(width: UIScreen.main.bounds.width - 40, height: CGFloat.greatestFiniteMagnitude))
                }
                self.vmLock.lock()
                self.vms.append(core)
                self.vmLock.unlock()
            }
            DispatchQueue.main.async {
                self.tableview.reloadData()
            }
        }
    }

    func initView() {
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(Cell.self, forCellReuseIdentifier: "A")
        tableview.rowHeight = UITableView.automaticDimension
        tableview.estimatedRowHeight = 100
        self.view.addSubview(tableview)
        tableview.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vmLock.lock()
        let count = vms.count
        vmLock.unlock()
        return count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        vmLock.lock()
//        let height = vms[indexPath.row].size.height
//        vmLock.unlock()
//        return height
//    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "A", for: indexPath) as? Cell ?? Cell()
//        vmLock.lock()
//        let vm = vms[indexPath.row]
//        vmLock.unlock()
//        cell.uilabel.text = text
        cell.richview.loadStyleSheets([styleSheet])
        cell.richview.documentElement = getDocumentElement()
//        cell.richview.setRichViewCore(vm)
//        cell.richview.bounds.size = vm.size
        cell.richview.delegate = self
        return cell
    }
}

class Cell: UITableViewCell {
    lazy var richview: LKRichView = {
        let richview = LKRichView(options: ConfigOptions([.debug(true), .maxHeightBuffer(0)]))
        richview.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 40
        richview.isUserInteractionEnabled = true
        richview.backgroundColor = UIColor.lightGray
        richview.isOpaque = true
        richview.layer.borderColor = UIColor.green.cgColor
        richview.layer.borderWidth = 1
        return richview
    }()

    lazy var uilabel: MyUILabel = {
        let label = MyUILabel()
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(richview)
        richview.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.bottom.equalToSuperview()
        }
//        addSubview(uilabel)
//        uilabel.snp.makeConstraints { make in
//            make.left.equalTo(20)
//            make.right.equalTo(-20)
//            make.top.bottom.equalToSuperview()
//        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StyleSheetVC: LKRichViewDelegate {
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
