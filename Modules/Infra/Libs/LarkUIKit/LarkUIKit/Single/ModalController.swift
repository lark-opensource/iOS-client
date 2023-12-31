//
//  ModalController.swift
//  LarkUIKit
//
//  Created by lichen on 2017/10/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsLogging

open class ModalController: UIViewController {
    static private var logger = Logger.log(ModalController.self, category: "LarkUIKit")

    public enum Layout {
        case autoLayout
        case size(CGSize)
    }

    fileprivate let backgroundView: UIView = UIView()
    fileprivate let container: UIView = UIView()
    fileprivate let dismissBtn: UIButton = UIButton(type: .custom)
    public var showCloseBtn: Bool = true {
        didSet {
            self.dismissBtn.isHidden = !self.showCloseBtn
        }
    }

    let alertView: UIView
    let layout: Layout

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public init(_ alertView: UIView, layout: Layout) {
        self.alertView = alertView
        self.layout = layout
        super.init(nibName: nil, bundle: nil)
        self.backgroundView.backgroundColor = UIColor.ud.color(0, 0, 0, 0.45)
        self.view.addSubview(self.backgroundView)
        self.backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.view.addSubview(self.container)
        self.container.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.container.addSubview(alertView)
        alertView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            if case .size(let size) = layout {
                make.size.equalTo(size)
            }
        }

        self.dismissBtn.setImage(Resources.closeAlert, for: .normal)
        self.dismissBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        self.container.addSubview(self.dismissBtn)
        dismissBtn.snp.makeConstraints { (make) in
            make.bottom.equalTo(alertView.snp.top).offset(-10)
            make.right.equalTo(alertView.snp.right)
            make.width.height.equalTo(26)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.dismissBtn.isHidden = !self.showCloseBtn
        self.container.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.view.alpha = 0
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, animations: {
                self.container.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.view.alpha = 1
            })
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        Self.logger.info("model controller: view will appear")
    }

    deinit {
        Self.logger.info("model controller: dealloc")
    }

    @objc
    public func hide() {
        self.container.transform = CGAffineTransform(scaleX: 1, y: 1)
        UIView.animate(withDuration: 0.1, animations: {
            self.container.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.view.alpha = 0
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
        Self.logger.info("model controller: view hide")
    }
}
