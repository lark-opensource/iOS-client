//
//  ViewController.swift
//  BadgeDemo
//
//  Created by 康涛 on 2019/3/26.
//  Copyright © 2019 康涛. All rights reserved.
//

import Foundation
import UIKit
import LarkBadge
import SnapKit

class ViewController: UIViewController {
    lazy var viewRoot: UIButton = { return getView() }()
    lazy var viewA: UIButton = { return getView() }()
    lazy var viewB: UIButton = { return getView() }()
    lazy var viewC: UIButton = { return getView() }()
    lazy var viewD: UIButton = { return getView() }()
    lazy var viewE: UIButton = { return getView() }()
    lazy var viewF: UIButton = { return getView() }()
    lazy var viewG: UIButton = { return getView() }()
    lazy var viewH: UIButton = { return getView() }()

    lazy var viewP: UIButton = { return getView() }()
    lazy var viewQ: UIButton = { return getView() }()
    lazy var viewO: UIButton = { return getView() }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupChildView()

        BadgeManager.setBadge(Path().tab_calendar.doc_more, type: .label(.text("sdsdf")))

        // 1
        let view = UIView()
        view.backgroundColor = .green
        // BadgeManager.setBadge(Path().root.e.g, type: .dot)

        viewD.badge.observe(for: Path().root.a.b.d)
        viewD.badge.combine(to: Path().root.e.g)

        viewG.badge.observe(for: Path().root.e.g)
        viewE.badge.observe(for: Path().root.e)
        viewF.badge.observe(for: Path().root.e.f)
        viewRoot.badge.observe(for: Path().root) { (node1, node2) in
            print(node1)
            print(node2)
        }

       // viewRoot.badge.setType(.image(.default(.update)))
       // viewRoot.badge.setSize(CGSize(width: 50, height: 50))

        viewE.badge.set(type: .dot(.lark))
        viewE.badge.set(offset: CGPoint(x: -10, y: -10))

        viewA.badge.observe(for: Path().root.a)
        viewB.badge.observe(for: Path().root.a.b)
        viewB.badge.set(type: .image(.default(.new)))

        viewC.badge.observe(for: Path().root.a.b.c)
        viewC.badge.set(type: .dot(.lark))
        viewC.badge.set(offset: CGPoint(x: -30, y: -30))
        viewC.badge.set(style: .weak)

        // 2
        BadgeManager.setBadge(Path().root.a.b.c, type: .image(.default(.edit)))
    }

    @objc
    fileprivate func clear() {
        BadgeManager.forceClearAll()
    }

    @objc
    fileprivate func action(value: UIButton) {
        if value == viewQ { viewRoot.badge.set(cornerRadius: 25) }
        if value == viewO { viewRoot.badge.set(offset: CGPoint(x: -20, y: -20)) }

        if value == viewA {
            viewA.badge.isHidden(!viewA.badge.isHidden)
            return
        }

        value.badge.set(number: (value.badge.bodyCount + 1) * 10)

    }

    @objc
    fileprivate func longPress(value: UILongPressGestureRecognizer) {
        guard value.state == .began, let view = value.view else { return }
        view.badge.clearBadge()
    }

    @objc
    fileprivate func change() {
        navigationController?.pushViewController(ViewControllerB(), animated: true)
    }

    // MARK: - Private
    func setupViews() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                                                      target: self, action: #selector(clear))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                                     target: self, action: #selector(change))
    }

    // swiftlint:disable function_body_length
    func setupChildView() {
        view.addSubview(viewRoot)
        view.addSubview(viewA)
        view.addSubview(viewB)
        view.addSubview(viewC)
        view.addSubview(viewD)
        view.addSubview(viewE)
        view.addSubview(viewF)
        view.addSubview(viewG)
        view.addSubview(viewH)
        view.addSubview(viewP)
        view.addSubview(viewQ)
        view.addSubview(viewO)

        view.subviews.forEach {
            $0.snp.makeConstraints { $0.size.equalTo(CGSize(width: 60, height: 60)) }
        }

        viewRoot.snp.makeConstraints {
            $0.centerX.equalTo(view.snp.centerX)
            $0.top.equalTo(view.snp.top).offset(140)
        }

        viewA.snp.makeConstraints {
            $0.centerX.equalTo(viewRoot.snp.centerX).offset(-100)
            $0.top.equalTo(viewRoot.snp.bottom).offset(50)
        }

        viewB.snp.makeConstraints {
            $0.centerX.equalTo(viewRoot.snp.centerX).offset(-100)
            $0.top.equalTo(viewRoot.snp.bottom).offset(150)
        }
        viewC.snp.makeConstraints {
            $0.centerX.equalTo(viewA.snp.centerX).offset(-50)
            $0.top.equalTo(viewB.snp.bottom).offset(50)
        }
        viewD.snp.makeConstraints {
            $0.centerY.equalTo(viewC.snp.centerY)
            $0.left.equalTo(viewC.snp.right).offset(50)
        }

        viewE.snp.makeConstraints {
            $0.centerX.equalTo(viewRoot.snp.centerX).offset(100)
            $0.top.equalTo(viewRoot.snp.bottom).offset(50)
        }
        viewF.snp.makeConstraints {
            $0.centerX.equalTo(viewE.snp.centerX).offset(-50)
            $0.top.equalTo(viewE.snp.bottom).offset(50)
        }
        viewG.snp.makeConstraints {
            $0.centerX.equalTo(viewE.snp.centerX).offset(50)
            $0.top.equalTo(viewE.snp.bottom).offset(50)
        }

        viewP.snp.makeConstraints {
            $0.centerX.equalTo(view.snp.centerX).offset(-100)
            $0.bottom.equalTo(view.snp.bottom).offset(-100)
        }
        viewP.setTitle("Size", for: .normal)

        viewP.uiBadge.addBadge(type: .label(.number(23)))

        viewQ.snp.makeConstraints {
            $0.centerX.equalTo(view.snp.centerX)
            $0.bottom.equalTo(view.snp.bottom).offset(-100)
        }
        viewQ.setTitle("Corner", for: .normal)

        viewO.snp.makeConstraints {
            $0.centerX.equalTo(view.snp.centerX).offset(100)
            $0.bottom.equalTo(view.snp.bottom).offset(-100)
        }
        viewO.setTitle("Offset", for: .normal)
    }
    // swiftlint:enable function_body_length

    func getView() -> UIButton {
        let view = UIButton(type: .custom)
        view.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        view.addTarget(self, action: #selector(action(value:)), for: .touchUpInside)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(value:)))
        view.addGestureRecognizer(longPress)
        return view
    }
}
