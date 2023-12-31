//
//  PresentWrapperController.swift
//  PresentViewController
//
//  Created by 李晨 on 2019/3/17.
//

import UIKit
import Foundation

public final class PresentWrapperController: UIViewController {

    public let subView: UIViewController
    public let subViewSize: CGSize

    public init(subView: UIViewController, subViewSize: CGSize) {
        self.subView = subView
        self.subViewSize = subViewSize
        super.init(nibName: nil, bundle: nil)
        self.addChild(subView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        self.view.addSubview(self.subView.view)
        self.subView.view.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.size.equalTo(self.subViewSize).priority(.high)
        }
    }
}
