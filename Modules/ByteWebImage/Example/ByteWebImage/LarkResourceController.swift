//
//  LarkResourceController.swift
//  ByteWebImage_Example
//
//  Created by xiongmin on 2021/4/19.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import ByteWebImage

class LarkResourceController: UIViewController {

    var resource: LarkImageResource?
    var imageView: UIImageView!
    var request: ImageRequest?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.imageView = UIImageView()
//        self.imageView.bt.isOpenDownsample = true
        self.imageView.frame = CGRect(x: 0,
                                      y: 150,
                                      width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.width * 0.75)
        self.view.addSubview(self.imageView)
        self.request = self.imageView.bt.setLarkImage(with: resource!, options: .default)

    }

}
