//
//  AnimatedImageController.swift
//  ByteWebImage_Example
//
//  Created by xiongmin on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import ByteWebImage

class AnimatedImageController: UIViewController {

    var imageView: ByteImageView!
    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.imageView = ByteImageView()
        self.imageView.frame = CGRect(x: 0,
                                      y: 150,
                                      width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.width * 0.75)
        self.view.addSubview(self.imageView)
        self.imageView.bt.setImage(with: self.url)
    }

}
