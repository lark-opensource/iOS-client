//
//  MagnifierVC.swift
//  LKRichViewDev
//
//  Created by qihongye on 2022/1/10.
//

import Foundation
import UIKit
import LKRichView

class MagnifierViewController: UIViewController {
    lazy var input: UITextField = {
        let filed = UITextField()
        filed.backgroundColor = .cyan
        filed.delegate = self
        return filed
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.text = "dafisjdfoi哦就啊阿胶哦欺骗微积分拼的快乐；了；去；‘饿哦地方哦大家；罚款老师的发丝哦返回抛弃我回复奥克兰；。弗拉上看见的逻辑啊是；\n弗怕；除了卡上的纠纷；阿斯顿发；爱上"
        label.numberOfLines = 0
        label.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        return label
    }()

    lazy var magnifier: Magnifier = {
//        if #available(iOS 15, *) {
//            return TextMagnifierForIOS15(configuration: TextMagnifierForIOS15.GraphicConfiguration(scale: 1.0))
//        } else {
//            return TextMagnifier(configuration: .default)
//        }
        return TextMagnifier(configuration: .default)
    }()

    func initView() {
        self.view.addSubview(self.label)
        self.view.addSubview(self.magnifier.magnifierView)
        self.view.addSubview(self.input)

        self.label.snp.makeConstraints { (make) in
            make.top.equalTo(200)
            make.left.equalTo(50)
            make.right.equalTo(-50)
        }
        self.input.snp.makeConstraints { make in
            make.top.equalTo(self.label.snp.bottom).offset(0)
            make.left.equalTo(50)
            make.right.equalTo(-50)
            make.height.equalTo(20)
        }

        magnifier.targetView = self.label
        magnifier.sourceScanCenter = CGPoint(x: 70, y: 15)
        magnifier.locateAt(anchorPoint: CGPoint(x: 70, y: 15))

        DispatchQueue.main.async {
            self.magnifier.updateRenderer()
        }

        self.title = "Magnifier Demo"

        self.view.backgroundColor = UIColor.white
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self.label)
        magnifier.sourceScanCenter = point
        magnifier.updateRenderer()
        magnifier.locateAt(anchorPoint: touches.first!.location(in: self.view)
                            .applying(CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: -40)))
    }
}

extension MagnifierViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
