//
//  LKTextMagnifierDemo.swift
//  LarkUIKitDemo
//
//  Created by qihongye on 2018/12/25.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RichLabel

class LKTextMagnifierDemoViewController: UIViewController {
    lazy var label: UILabel = {
        let label = UILabel()
        label.text = "dafisjdfoi哦就啊阿胶哦欺骗微积分拼的快乐；了；去；‘饿哦地方哦大家；罚款老师的发丝哦返回抛弃我回复奥克兰；。弗拉上看见的逻辑啊是；弗怕；除了卡上的纠纷；阿斯顿发；爱上"
        label.numberOfLines = 0
        label.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        return label
    }()

    lazy var magnifier: LKMagnifier = {
        let magnifier = LKTextMagnifier()
        return magnifier
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.label)
        self.view.addSubview(self.magnifier.magifierView)

        self.label.snp.makeConstraints { (make) in
            make.top.equalTo(50)
            make.left.equalTo(50)
            make.right.equalTo(-50)
        }

        magnifier.targetView = self.label
        magnifier.sourceScanCenter = CGPoint(x: 70, y: 15)

        DispatchQueue.main.async {
            self.magnifier.update()
        }

        self.title = "LKTextMagnifier Demo"

        self.view.backgroundColor = UIColor.white
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self.label)
        magnifier.sourceScanCenter = point
        magnifier.update()
    }
}
