//
//  Controller.swift
//  LarkOCRDev
//
//  Created by 李晨 on 2022/8/23.
//

import Foundation
import UIKit
import LarkOCR

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 13.0, *) {
//            Demo.showExtract(in: self)
            Demo.showRecognition(in: self)
        }
    }
}
