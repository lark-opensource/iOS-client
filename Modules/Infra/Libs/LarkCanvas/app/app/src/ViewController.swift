//
//  ViewController.swift
//  LarkCanvasDev
//
//  Created by Saafo on 2021/2/4.
//

import UIKit
import Foundation
import EENavigator
import LarkCache
import LarkCanvas
import LarkUIKit
import SnapKit
import UniverseDesignColor

@available(iOS 13.0, *)
class ViewController: UIViewController, LKCanvasViewControllerDelegate {

    let key = "chat_114514"

    var drawBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Draw", for: .normal)
        btn.setTitleColor(.blue, for: .normal)
        return btn
    }()
    var clearBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Clear cache", for: .normal)
        btn.setTitleColor(.red, for: .normal)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // 修改 LarkCanvas 全局缓存配置 为 LarkCache
        LKCanvasConfig.cacheProvider = GlobalCanvasCacheProvider()
        view.addSubview(drawBtn)
        view.addSubview(clearBtn)
        drawBtn.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        clearBtn.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(drawBtn.snp.bottom).offset(30)
        }
        view.backgroundColor = UIColor.ud.bgBody
        drawBtn.addTarget(self, action: #selector(presentCanvas), for: .touchUpInside)
        clearBtn.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateBtnTitle()
    }
    @objc
    func clearAll() {
        _ = LKCanvasConfig.cacheProvider.saveCache(identifier: key, data: nil)
        updateBtnTitle()
    }
    func updateBtnTitle() {
        let size: String
        // show data size in demo (for debug only)
        if let cacheProviderWithSizeCheck = LKCanvasConfig.cacheProvider as? GlobalCanvasCacheProvider {
            size = cacheProviderWithSizeCheck.checkCacheSize(identifier: key)
        } else {
            size = "exist: \(LKCanvasConfig.cacheProvider.checkCache(identifier: key))"
        }
        clearBtn.setTitle("Clear cache(\(size))", for: .normal)
    }

    lazy var canvas: LKCanvasViewController = {
        LKCanvasViewController(
            identifier: self.key,
            from: "demo",
            options: [.set(title: "PencilKit"), .saveOn(mode: .saveOnChanged)],
            delegate: self
        )
    }()
    @objc
    func presentCanvas() {
        Navigator.shared.present(
            canvas,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
    }

    // MARK: - LKCanvasViewController delegate
    func canvasWillFinish(in controller: LKCanvasViewController,
                          drawingImage: UIImage, canvasData: Data,
                          canvasShouldDismissCallback: @escaping (Bool) -> Void) {
        print("finish!")
        // do dealing with data here
        // finally, dismiss the controller
        canvasShouldDismissCallback(true)
        let ivc = ImageViewController()
        ivc.image = drawingImage
        ivc.modalPresentationStyle = .formSheet
        self.present(ivc, animated: true)
        return
    }
    func canvasDidEnter(lifeCycle: LKCanvasViewController.LifeCycle) {
        switch lifeCycle {
        case .canvasDidTouch(canvas: _, touch: let touch, isFirstTouch: _):
            print("Using pencil: \(touch.type == .pencil)")
//        case .viewDidLayout:
//            canvas.canvas.overrideUserInterfaceStyle = .light
//            canvas.canvas.toolPicker?.colorUserInterfaceStyle = .light
        default:
            break
        }
    }
}

// only for demo
private class ImageViewController: UIViewController {
    var image: UIImage?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .clear
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
