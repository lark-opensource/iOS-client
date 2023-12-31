//
//  ViewController.swift
//  LarkAssetsBrowserDev
//
//  Created by Saafo on 2020/12/15.
//

import Foundation
import SnapKit
import LarkAssetsBrowser
import LarkUIKit
import UIKit

class ViewController: UIViewController {
    // view
    lazy var pickerButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .cyan
        btn.setTitle("图片！", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(didTapPickerButton), for: .touchUpInside)
        return btn
    }()

    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        view.addSubview(pickerButton)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(250)
            make.height.equalTo(150)
        }
        pickerButton.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }

    @objc
    func didTapPickerButton() {
        self.navigationController?.present(KeyboardVC(), animated: true)
    }
}

class KeyboardVC: UIViewController {
    // keyboard
    let kb: AssetPickerSuiteView = {
        let kb = AssetPickerSuiteView(assetType: PhotoPickerAssetType.default, cameraType: .custom(true))
        kb.updateBottomOffset(0)
//        kb.delegate = config.delegate
//        kb.imageEditAction = { CoreTracker.trackImageEditEvent($0.event, params: $0.params) }
//        config.photoViewCallback(kb)
        return kb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(kb)
        kb.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(240)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        view.backgroundColor = .white
    }
}
