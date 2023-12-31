//
//  AuroraPreviewController.swift
//  UDCCatalog
//
//  Created by Hayden Wang on 2023/8/9.
//  Copyright © 2023 姚启灏. All rights reserved.
//

import UIKit
import FigmaKit
import UniverseDesignButton
import UniverseDesignColor

// swiftlint:disable all

class AuroraPreviewController: UIViewController {

    var auroraConfig: AuroraViewConfiguration
    var useGradient: Bool
    var blobOpacity: CGFloat
    var backgroundColor: UIColor
    var blurRadius: CGFloat
    private var backgroundBlurRadius: CGFloat = 35
    private var blurOpacity: CGFloat = 0.6

    private lazy var backgroundView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var auroraView: AuroraView = {
        let view = AuroraView(config: auroraConfig, blobType: useGradient ? .gradient : .blur)
        // view.headColor = UIColor.ud.bgBody.withAlphaComponent(0.6)
        return view
    }()

    /// 模糊背景
    private lazy var blurView: VisualBlurView = {
        let blurView = VisualBlurView()
        blurView.fillColor = backgroundColor
        blurView.blurRadius = backgroundBlurRadius
        blurView.fillOpacity = blurOpacity
        return blurView
    }()

    private lazy var blurLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0
        label.text = "BlurRadius: \(Int(backgroundBlurRadius))"
        return label
    }()

    private lazy var opacityLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0
        label.text = "FillOpacity: \(String(format: "%.2f", blurOpacity))"
        return label
    }()

    private lazy var blurSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 80
        slider.value = Float(backgroundBlurRadius)
        return slider
    }()

    private lazy var opacitySlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = Float(blurOpacity)
        return slider
    }()

    private lazy var closeButton: FKGradientButton = {
        let button = FKGradientButton()
        button.setTitle("关闭", for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        button.colorStyle = .solidGradient(
            background: UDColor.AIPrimaryFillDefault,
            highlightedBackground: UDColor.AIPrimaryFillPressed,
            disabledBackground: UDColor.AIPrimaryFillLoading
        )
        return button
    }()

    private lazy var chooseBackgroundButton: UIButton = {
        let button = UDButton(.secondaryBlue)
        button.setTitle("选择背景图", for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
//        button.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        return button
    }()

    private lazy var clearBackgroundButton: UIButton = {
        let button = UDButton(.secondaryRed)
        button.setTitle("清除背景图", for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
//        button.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        return button
    }()

    init(auroraConfig: AuroraViewConfiguration, useGradient: Bool, blobOpacity: CGFloat, backgroundColor: UIColor, blurRadius: CGFloat) {
        self.auroraConfig = auroraConfig
        self.useGradient = useGradient
        self.blobOpacity = blobOpacity
        self.backgroundColor = backgroundColor
        self.blurRadius = blurRadius
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backgroundView)
        view.addSubview(blurView)
        view.addSubview(auroraView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        auroraView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.backgroundColor = backgroundColor
        auroraView.blobsBlurRadius = blurRadius
        auroraView.blobsOpacity = blobOpacity
        blurView.isHidden = !useGradient
        blurSlider.isHidden = !useGradient
        opacitySlider.isHidden = !useGradient
        blurLabel.isHidden = !useGradient
        opacityLabel.isHidden = !useGradient
        chooseBackgroundButton.isHidden = !useGradient
        clearBackgroundButton.isHidden = !useGradient

        view.addSubview(closeButton)
        view.addSubview(blurLabel)
        view.addSubview(opacityLabel)
        view.addSubview(blurSlider)
        view.addSubview(opacitySlider)
        view.addSubview(chooseBackgroundButton)
        view.addSubview(clearBackgroundButton)

        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(50)
        }
        chooseBackgroundButton.snp.makeConstraints { make in
            make.left.equalTo(closeButton)
            make.bottom.equalTo(closeButton.snp.top).offset(-20)
        }
        clearBackgroundButton.snp.makeConstraints { make in
            make.right.equalTo(closeButton)
            make.bottom.equalTo(chooseBackgroundButton)
            make.left.equalTo(chooseBackgroundButton.snp.right).offset(20)
            make.width.equalTo(chooseBackgroundButton)
        }
        blurLabel.snp.makeConstraints { make in
            make.left.equalTo(closeButton)
            make.height.equalTo(blurSlider)
            make.width.equalTo(120)
            make.right.equalTo(blurSlider.snp.left).offset(-8)
            make.centerY.equalTo(blurSlider)
        }
        blurSlider.snp.makeConstraints { make in
            make.right.equalTo(closeButton)
            make.bottom.equalTo(chooseBackgroundButton.snp.top).offset(-16)
        }
        opacityLabel.snp.makeConstraints { make in
            make.left.equalTo(closeButton)
            make.height.equalTo(opacitySlider)
            make.width.equalTo(120)
            make.right.equalTo(opacitySlider.snp.left).offset(-8)
            make.centerY.equalTo(opacitySlider)
        }
        opacitySlider.snp.makeConstraints { make in
            make.right.equalTo(closeButton)
            make.bottom.equalTo(blurSlider.snp.top).offset(-16)
        }
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        chooseBackgroundButton.addTarget(self, action: #selector(chooseBackgroundImage), for: .touchUpInside)
        clearBackgroundButton.addTarget(self, action: #selector(clearBackgroundImage), for: .touchUpInside)
        blurSlider.addTarget(self, action: #selector(didChangeSliderValue(_:)), for: .valueChanged)
        opacitySlider.addTarget(self, action: #selector(didChangeSliderValue(_:)), for: .valueChanged)
    }

    @objc
    private func close() {
        dismiss(animated: true)
    }

    @objc
    private func didChangeSliderValue(_ sender: UISlider) {
        if sender == opacitySlider {
            let alpha = CGFloat(sender.value)
            opacityLabel.text = "FillOpacity: \(String(format: "%.2f", alpha))"
            blurView.fillOpacity = alpha
        } else {
            let radius = Int(sender.value)
            if blurView.blurRadius != CGFloat(radius) {
                blurLabel.text = "BlurRadius: \(radius)"
                blurView.blurRadius = CGFloat(radius)
            }
        }
    }
    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        // 设置代理
        imagePicker.delegate = self
        // 设置图片来源为相册
        imagePicker.sourceType = .photoLibrary
        // 允许编辑照片
        imagePicker.allowsEditing = false
        return imagePicker
    }()

    @objc
    private func chooseBackgroundImage() {
        present(imagePicker, animated: true, completion: nil)
    }

    @objc
    private func clearBackgroundImage() {
        backgroundView.image = nil
        // 强制触发一次 BlurView 的更新
        blurView.blurRadius += 1
        blurView.blurRadius -= 1
    }
}

extension AuroraPreviewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    // 处理选择的照片
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 从 info 中获取编辑后的照片
        let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        // 关闭 ImagePicker
        picker.dismiss(animated: true, completion: nil)
        // 在这里处理获取到的照片，例如将其设置为 UIImageView 的 image 属性
        // imageView.image = selectedImage
        backgroundView.image = selectedImage
    }

    // 处理取消选择照片的情况
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// swiftlint:enable all
