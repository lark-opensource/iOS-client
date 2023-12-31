//
//  PhotoPreviewController.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/21.
//

import Foundation
import UIKit

final class PhotoPreviewController: BasePreviewController {

    private let imageView: UIImageView = UIImageView()

    var image: UIImage? {
        get { return imageView.image }
        set { imageView.image = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        view.backgroundColor = UIColor.black

        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }
}
