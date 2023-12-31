//
//  BaseDemoViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/7/15.
//

import Foundation
import UIKit
import TangramComponent
import TangramUIComponent

public class BaseDemoViewController: UIViewController {
    public let wrapper = UIView()
    public let container = UIView(frame: .zero)
    public var render: ComponentRenderer!
    public var root: UIViewComponent<EmptyProps, EmptyContext>!
    public var rootLayout: LinearLayoutComponent!

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        setupView()
    }

    func setupView() {
        view.addSubview(wrapper)
        wrapper.layer.borderColor = UIColor.red.cgColor
        wrapper.layer.borderWidth = 1
        let margin: CGFloat = 10
        let width = view.bounds.width - margin * 2
        wrapper.frame = CGRect(x: margin, y: 100, width: width, height: 100)

        wrapper.addSubview(container)
        var layoutProps = LinearLayoutComponentProps()
        layoutProps.orientation = .row
        rootLayout = LinearLayoutComponent(children: [], props: layoutProps)

        root = UIViewComponent<EmptyProps, EmptyContext>(props: .empty)
        root.style.borderWidth = 1
        root.style.borderColor = UIColor.ud.lineBorderComponent
        root.style.maxWidth = TCValue(cgfloat: width)
        root.setLayout(rootLayout)

        render = ComponentRenderer(rootComponent: root, preferMaxLayoutWidth: width, preferMaxLayoutHeight: 100)
        render.bind(to: container)
        render.render()
    }
}
