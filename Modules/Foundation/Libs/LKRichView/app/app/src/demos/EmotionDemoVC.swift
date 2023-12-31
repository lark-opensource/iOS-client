//
//  EmotionDemoVC.swift
//  LKRichViewDev
//
//  Created by 袁平 on 2021/10/11.
//

import Foundation
import UIKit
import LKRichView

class EmotionDemoVC: UIViewController {
    var testView: LKRichView!

    let image = UIImage(named: "approve")!

    lazy var subNodes: [Node] = {
        var subNodes = [Node]()
        (0..<40).forEach { _ in
            let emotion = LKImgElement(img: image.cgImage)
            emotion.style.width(.point(80))
            emotion.style.height(.point(80))
            subNodes.append(emotion)
        }
        return subNodes
    }()

    lazy var documentElement: LKRichElement = {
        let element = LKBlockElement(tagName: Tag.p)
        element.style.maxHeight(.point(100))

        element.children(subNodes)
        return element
    }()

    let core = LKRichViewCore()
    let containerSize = CGSize(width: UIScreen.main.bounds.width - 20, height: 10_000)

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
        initView()
    }

    func initView() {
        let renderer = core.createRenderer(documentElement)
        core.load(renderer: renderer)
        let size = core.layout(containerSize) ?? .zero

        testView = LKRichView(frame: CGRect(x: 10, y: 100, width: size.width, height: size.height), options: ConfigOptions([.debug(true)]))
        self.view.addSubview(testView)
        testView.setRichViewCore(core)
    }

    var toggle: Bool = true
    @objc
    func update() {
        documentElement.style.maxHeight(toggle ? nil : .point(100))
        let renderer = core.createRenderer(documentElement)
        core.load(renderer: renderer)
        let size = core.layout(containerSize) ?? .zero
        testView.frame.size = size
        testView.setRichViewCore(core)
        toggle.toggle()
    }
}
