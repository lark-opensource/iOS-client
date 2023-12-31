//
//  DemoImageViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/8/30.
//

import Foundation
import UIKit
import TangramUIComponent
import TangramComponent

class DemoImageViewController: BaseDemoViewController {
    lazy var imageProps: UIImageViewComponentProps = {
        let props = UIImageViewComponentProps()
        props.setImage.update { imageView, completion in
            imageView.image = .random()
            completion(imageView.image, nil)
        }
        props.onTap.update {
            print("ImageView Tapped")
        }
        return props
    }()

    lazy var image: UIImageViewComponent<EmptyContext> = {
        let image = UIImageViewComponent<EmptyContext>(props: imageProps)
        image.style.width = 100
        image.style.height = 100
        return image
    }()

    lazy var imageHeight: UITextField = {
        let tagText = UITextField()
        tagText.layer.borderWidth = 1
        tagText.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        tagText.placeholder = "Image Height"
        return tagText
    }()

    lazy var imageWidth: UITextField = {
        let tagWidth = UITextField()
        tagWidth.layer.borderWidth = 1
        tagWidth.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        tagWidth.placeholder = "Image Width"
        return tagWidth
    }()

    lazy var showError: SwitchView = {
        let showIcon = SwitchView(title: "Show Error")
        showIcon.isOn = false
        return showIcon
    }()

    lazy var enabelTap: SwitchView = {
        let enabelTap = SwitchView(title: "Enable Tap")
        return enabelTap
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTool()
    }

    override func setupView() {
        super.setupView()
        rootLayout.setChildren([image])
        root.style.width = TCValue(cgfloat: view.bounds.width - 20)
        render.update(rootComponent: root)
        render.render()
    }

    func setupTool() {
        view.addSubview(imageHeight)
        imageHeight.snp.makeConstraints { make in
            make.top.equalTo(wrapper.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }

        view.addSubview(imageWidth)
        imageWidth.snp.makeConstraints { make in
            make.top.equalTo(imageHeight.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }

        view.addSubview(showError)
        showError.snp.makeConstraints { make in
            make.top.equalTo(imageWidth.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
        }

        view.addSubview(enabelTap)
        enabelTap.snp.makeConstraints { make in
            make.top.equalTo(imageWidth.snp.bottom).offset(12)
            make.leading.equalTo(showError.snp.trailing).offset(12)
        }

        let updateButton = UIButton()
        updateButton.setTitle("Update", for: .normal)
        updateButton.setTitleColor(UIColor.ud.N900, for: .normal)
        updateButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        updateButton.layer.borderWidth = 1
        updateButton.addTarget(self, action: #selector(update), for: .touchUpInside)
        view.addSubview(updateButton)
        updateButton.snp.makeConstraints { make in
            make.top.equalTo(showError.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(44)
        }
    }

    @objc
    func update() {
        if let text = imageHeight.text, !text.isEmpty, let height = Double(text) {
            image.style.width = TCValue(cgfloat: CGFloat(height))
        }
        if let text = imageWidth.text, !text.isEmpty, let width = Double(text) {
            image.style.height = TCValue(cgfloat: CGFloat(width))
        }
        if showError.isOn {
            imageProps.setImage.update { imageView, completion in
                imageView.image = nil
                imageView.backgroundColor = UIColor.ud.N50
                completion(nil, NSError(domain: "", code: -1, userInfo: [:]))
            }
        } else {
            imageProps.setImage.update { imageView, completion in
                imageView.image = .random()
                completion(imageView.image, nil)
            }
        }
        if enabelTap.isOn {
            imageProps.onTap.update {
                print("ImageView Tapped")
            }
        } else {
            imageProps.onTap.update(new: nil)
        }

        render.update(rootComponent: root)
        render.render()
    }
}
