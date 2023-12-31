//
//  DemoVideoCoverViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/8/17.
//

import Foundation
import UIKit
import TangramUIComponent
import TangramComponent

class DemoVideoCoverViewController: BaseDemoViewController {
    private lazy var videoCover: VideoCoverComponent<EmptyContext> = {
        let props = VideoCoverComponentProps()
        props.duration = 12345
        props.setImageTask.update { imageView, completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                imageView.image = Resources.bilibili
                completion?(imageView.image, nil)
            }
        }
        let videoCover = VideoCoverComponent<EmptyContext>(props: props)
        videoCover.style.width = 200
        videoCover.style.height = 100
        videoCover.style.clipsToBounds = true
        videoCover.style.backgroundColor = UIColor.ud.N900
        return videoCover
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setupView() {
        super.setupView()
        rootLayout.props.align = .middle
        rootLayout.setChildren([videoCover])
        root.style.width = TCValue(cgfloat: view.bounds.width - 20)
        render.update(rootComponent: root)
        render.render()
    }
}
