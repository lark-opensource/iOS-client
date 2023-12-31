//
//  SegmentViewController.swift
//  LarkUIKitDemo
//
//  Created by K3 on 2018/4/25.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit

class SegmentViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        view.backgroundColor = UIColor.white

        let segmentView = SegmentView(segment: StandardSegment())
        view.addSubview(segmentView)
        segmentView.snp.makeConstraints { (maker) in
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            maker.left.right.bottom.equalTo(view)
        }

        let screenWidth = UIScreen.main.bounds.width
        let viewFrame = CGRect(x: 0, y: 0, width: screenWidth, height: 100)
        let viewA = UIView(frame: viewFrame)
        viewA.backgroundColor = UIColor.white
        let viewB = UIView(frame: viewFrame)
        viewB.backgroundColor = UIColor.green
        segmentView.set(views: [
            (title: "First", view: viewA),
            (title: "Second", view: viewB)
            ]
        )
    }
}
