//
//  VCPersonasBasicViewController.swift
//  ByteView
//
//  Created by wpr on 2023/12/14.
//

import Foundation
import SnapKit
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewUI
import ByteViewCommon
import LarkAssetsBrowser

class VCPersonasBasicViewController: BaseViewController {

    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.text = "第一步 基本信息"
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private let personImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var imgNoticeLable: UILabel = {
        let label = UILabel()
        label.text = "请点击上传照片（上半身正脸照片）"
        label.font = .systemFont(ofSize: 18)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        return label
    }()

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        return view
    }()

    lazy var imgContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.N200
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var sexLable: UILabel = {
        let label = UILabel()
        label.text = "性别:"
        label.font = .systemFont(ofSize: 15)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var sexSegment: UISegmentedControl = {
        UISegmentedControl(items: sexDataSource)
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle("下一步", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = .ud.primaryContentDefault
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return button
    }()

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    let sexDataSource = ["男", "女"]

    var base64String: String?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func setupViews() {
        self.title = "数字人生成"
        view.backgroundColor = .ud.bgBody
        sexSegment.selectedSegmentIndex = 0

        sexSegment.setWidth(50, forSegmentAt: 0)
        sexSegment.setWidth(50, forSegmentAt: 1)

        let tap = UITapGestureRecognizer(target: self, action: #selector(chooseImageAction))
        imgContainerView.addGestureRecognizer(tap)

        imgContainerView.addSubview(personImageView)
        imgContainerView.addSubview(lineView)
        imgContainerView.addSubview(imgNoticeLable)

        view.addSubview(titleLable)
        view.addSubview(imgContainerView)
        view.addSubview(sexLable)
        view.addSubview(sexSegment)
        view.addSubview(confirmButton)
    }

    func layoutViews() {
        titleLable.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(30)
        }

        personImageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(personImageView.snp.width)
        }

        lineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(personImageView.snp.bottom)
            make.height.equalTo(1.0 / view.vc.displayScale) //1.0 / view.vc.displayScale
        }

        imgNoticeLable.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.greaterThanOrEqualTo(50)
            make.top.equalTo(lineView.snp.bottom)
            make.bottom.equalTo(imgContainerView)
        }

        imgContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLable.snp.bottom).offset(50)
            make.left.right.equalToSuperview().inset(20)
        }

        sexLable.snp.makeConstraints { make in
            make.top.equalTo(imgContainerView.snp.bottom).offset(60)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(40)
            make.height.equalTo(24)
        }

        sexSegment.snp.makeConstraints { make in
            make.centerY.equalTo(sexLable)
            make.left.equalTo(sexLable.snp.right).offset(10)
            make.height.equalTo(32)
        }

        confirmButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
    }

    deinit {
        Logger.ui.info("sdai VCPersonasBasicViewController deinit")
    }

    @objc private func chooseImageAction() {

        let imagePicker = ImagePickerViewController(assetType: .imageOnly(maxCount: 1), isOriginal: true, isOriginButtonHidden: false, sendButtonTitle: "发送", takePhotoEnable: false)
        imagePicker.showMultiSelectAssetGridViewController()
        imagePicker.imagePickerFinishSelect = { (picker, result) in
            guard let asset = result.selectedAssets.first, asset.mediaType == .image, let chooseImage = asset.originalImage(), let cropImage = Self.cropImageToSize(image: chooseImage) else {
                picker.dismiss(animated: true)
                return
            }
            DispatchQueue.main.async {
                Logger.ui.info("sdai choose image size \(cropImage.size)")
                Self.saveImage(image: cropImage)
                self.personImageView.image = cropImage
                self.base64String = cropImage.pngData()?.base64EncodedString()
                picker.dismiss(animated: true, completion: nil)
            }
        }
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true, completion: nil)
    }

    @objc private func confirmAction() {
        let vc = VCPersonasSytleViewController(base64String: base64String, isMale: sexSegment.selectedSegmentIndex == 0)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}


extension VCPersonasBasicViewController {
    func requestImageSystem() {
        let textToImageUrl = "http://10.87.29.237:7860/sdapi/v1/txt2img"
        let checkpointInfo = ["sd_model_checkpoint": "dreamshaper_8"]  //disneyPixarCartoon_v10  dreamshaper_8  kakarot28DCozy_cozy.safetensors
        let params: [String: Any] = ["prompt": "1 girl",
                      "steps": "15",
                      "override_settings": checkpointInfo,
                      "width": "512",
                      "height": "512"]

        let url = URL(string: textToImageUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        } catch let error {
            Logger.ui.error("sdai request error: \(error.localizedDescription)")
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error = error {
                Logger.ui.error("sdai task error: \(error)")
            } else if let data = data {
                Logger.ui.info("sdai success size: \(data)")
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    if let imageArray = responseJSON["images"] as? [String], imageArray.count > 0, let string = imageArray[0] as? String {
                        Logger.ui.info("sdai success info: \(responseJSON["info"])")
                        self?.addImage(base64String: string)
                    }
                }
            }
        }
        task.resume()
    }

    func requestImage() {
        let textToImageUrl = "http://10.87.29.237:7860/sdapi/v1/txt2img"
        let checkpointInfo = ["sd_model_checkpoint": "disneyPixarCartoon_v10"]  //disneyPixarCartoon_v10  dreamshaper_8  kakarot28DCozy_cozy.safetensors
        let params: [String: Any] = ["prompt": "1 girl",
                      "steps": "5",
                      "override_settings": checkpointInfo,
                      "width": "512",
                      "height": "512"]
    }

    func addImage(base64String: String) {
        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters), let image = UIImage(data: data) else {
            Logger.ui.error("sdai base64 error")
            return
        }
        DispatchQueue.main.async {
            self.imageView.image = image
            self.view.addSubview(self.imageView)
            self.imageView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(50)
                make.width.height.equalTo(300)
                make.centerX.equalToSuperview()
            }
        }
    }
}

extension VCPersonasBasicViewController {
    /// 具体裁剪方法
    static func cropImageToSize(image: UIImage) -> UIImage? {
        guard let imgData: Data = image.pngData() else { return nil }
        // 计算所需要图片的尺寸
        let originSize = image.size
        var size = CGSize(width: 512, height: 512)

        // 计算缩放尺寸
        let widthFactor = size.width / originSize.width
        let heightFactor = size.height / originSize.height
        let scaleFactor = widthFactor > heightFactor ? widthFactor : heightFactor
        let scaledWidth = originSize.width * scaleFactor
        let scaledHeight = originSize.height * scaleFactor

        Logger.ui.debug("lab bg: ratio \(scaledWidth) \(scaledHeight)")

        // 如果大小一样，不需要裁剪 直接返回
        if image.size.width == size.width && image.size.height == size.height {
            return image
        }

        // 降采样
        var croppingCGImage = image.cgImage
        // 降分辨率 降采样
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary   // 在创建对象时不解码图像（即true，在读取数据时就进行解码 为false 则在渲染时才进行解码）
        guard let imageSource = CGImageSourceCreateWithData(imgData as CFData, imageSourceOptions) else { // 用data因为并未decode,所占内存没那么大
            Logger.ui.error("lab bg: CGImageSource create failed")
            return nil
        }
        let maxPixelSize = max(scaledWidth, scaledHeight) // 可能会有浮点数，像素最好整数，如果要支持浮点数，需要额外设置kCGImageSourceShouldAllowFloat
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,   // 用原图产生缩略图
            kCGImageSourceShouldCacheImmediately: true,           // CreateThumbnailAtIndex必然会解码的，true是生成ImageIO的缓存，这个值对内存影响不大；开始下采样过程的那一刻解码图像；
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize)] as CFDictionary // 指定最大的尺寸初一一个常量系数来缩放图片，同时保持原始的长宽比，
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            Logger.ui.error("lab bg: downsampledImage create failed")
            return nil
        }
        croppingCGImage = downsampledImage

        // 裁剪图片
        var drawRect = CGRect.init()
        drawRect.origin.x = (scaledWidth - size.width) / 2
        drawRect.origin.y = (scaledHeight - size.height) / 2
        drawRect.size.width = size.width
        drawRect.size.height = size.height

        if let croppingCGImage = croppingCGImage {
            guard let newImageRef = croppingCGImage.cropping(to: drawRect) else { return nil }
            return UIImage(cgImage: newImageRef)
        } else {
            return nil
        }
    }


    static func saveImage(image: UIImage) {
        if let data = image.pngData() {
            let fileManager = FileManager.default
            if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsURL.appendingPathComponent("image.png")
                do {
                    try data.write(to: fileURL)
                } catch {
                    Logger.ui.error("Error writing image to file: \(error)")
                }
            }
        }
    }
}


