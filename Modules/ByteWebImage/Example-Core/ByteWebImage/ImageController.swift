//
//  ImageController.swift
//  ByteWebImage_Example
//
//  Created by xiongmin on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import ByteWebImage

class ImageController: UIViewController {

    var url: URL?
    var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.imageView = UIImageView()
        self.imageView.frame = CGRect(x: 0, y: 150, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 0.75)
        self.view.addSubview(self.imageView)
       self.imageView.bt.setImage(self.url, options: [])
//        DispatchQueue.global().async {
//            request?.cancel()
//        }
//        request?.cancel()
    }

}
