//
//  LargeStringDemoVC.swift
//  LKRichViewDev
//
//  Created by 袁平 on 2021/10/9.
//

import Foundation
import UIKit
import LKRichView

class LargeStringDemoVC: UIViewController {
    // 超长文本
    lazy var subNodes: [Node] = {
        var subNodes = [Node]()
        let content = "正常中文qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
        let colors = [UIColor.blue, UIColor.black, UIColor.red, UIColor.green]
        (0..<2).forEach { index in
            let text = LKTextElement(text: content)
            text.style.font(UIFont.systemFont(ofSize: 17))
            text.style.fontSize(.point(17))
            text.style.color(colors[index % 4])
//            let container = LKBlockElement(tagName: Tag.p).children([text])
            subNodes.append(text)
        }
        (0..<1).forEach { _ in
            let img = LKImgElement(img: UIImage(named: "approve")?.cgImage)
            subNodes.insert(img, at: 0) // (0..<1000).randomElement()!
        }
//        (0..<100).forEach { _ in
//            let width: [CGFloat] = [100, 200, 300]
//            let height: [CGFloat] = [1000, 600, 900]
//            let attachment = LKAttachmentElement(attachment: Attachment(size: .init(width: width.randomElement()!, height: height.randomElement()!)))
//            let container = LKBlockElement(tagName: Tag.p).children([attachment])
//            if Bool.random() {
//                container.style.border(top: .init(style: .solid, width: .point(2), color: colors.randomElement()!)).backgroundColor(UIColor.purple)
//            }
//            subNodes.insert(container, at: (0..<1000).randomElement()!)
//        }

        return subNodes
    }()

    // 列表
//    lazy var subNodes: [Node] = {
//        var subNodes = [Node]()
//        (0..<1).forEach { index in
//            let ol = LKOrderedListElement(tagName: Tag.h1, start: index, olType: .number)
//            let li = LKListItemElement(tagName: Tag.h2, iconColor: UIColor.blue, ulIconSize: 8, olIconSize: 17)
//            let text = LKTextElement(text: "Hello-\(index)")
//            li.children([text])
//            ol.children([li])
//            subNodes.append(ol)
//        }
//        return subNodes
//    }()

    // 空P标签
//    lazy var subNodes: [Node] = {
//        let attachment1 = LKAttachmentElement(attachment: Attachment(size: CGSize(width: 100, height: 100)))
//        let figure1 = LKBlockElement(tagName: Tag.p).children([attachment1])
//
//        let attachment2 = LKAttachmentElement(attachment: Attachment(size: CGSize(width: 50, height: 50)))
//        let figure2 = LKBlockElement(tagName: Tag.p).children([attachment2])
//
//        let line = LKBlockElement(tagName: Tag.p)
//        line.style.minHeight(.point(22))
//
//        return [figure1, line, figure2]
//    }()

    lazy var documentElement: LKRichElement = {
        let element = LKBlockElement(tagName: Tag.p)
        element.style.maxHeight(.point(50))
        element.children(subNodes)
//        element.style.maxHeight(.point(200))
//        let border = BorderEdge(style: .solid, width: .point(1), color: UIColor.green)
//        element.style.backgroundColor(UIColor.red).border(top: border, right: border, bottom: border, left: border)
        return element
    }()

    let core = LKRichViewCore()
    let containerSize = CGSize(width: UIScreen.main.bounds.width - 20, height: 10_000)
    var tiledLayers: LKTiledCache?

    lazy var tableview: UITableView = {
        let tableview = UITableView()
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(Cell.self, forCellReuseIdentifier: "A")
        tableview.rowHeight = UITableView.automaticDimension
        tableview.estimatedRowHeight = 100
        return tableview
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(update))
        self.navigationItem.rightBarButtonItem = button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.initView()
        }
    }

    func initView() {
        view.addSubview(tableview)
        tableview.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    var toggle: Bool = true
    @objc
    func update() {
        tableview.reloadData()
    }
}

extension LargeStringDemoVC: UITableViewDelegate {
}

extension LargeStringDemoVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "A", for: indexPath) as? Cell ?? Cell()
        cell.richview.documentElement = documentElement
//        let renderer = core.createRenderer(documentElement)
//        core.load(renderer: renderer)
//        cell.richview.setRichViewCore(core)
        cell.richview.delegate = self

//        let attr = NSAttributedString(string: content, attributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.orange])
//        cell.uilabel.lineBreakMode = .byCharWrapping
//        cell.uilabel.font = UIFont.systemFont(ofSize: 17)
//        cell.uilabel.text = content
//        cell.uilabel.textColor = UIColor.orange
//        cell.uilabel.attributedText = attr
        return cell
    }
}

extension LargeStringDemoVC: LKRichViewDelegate {
    func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
        self.tiledLayers = cache
    }

    func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return self.tiledLayers
    }

    func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {
        print("LargeStringVC show more!!! ", isContentScroll)
    }

    func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }

    func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }

    func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }

    func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {

    }
}
