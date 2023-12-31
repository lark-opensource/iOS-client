//
//  AvatarBaseSettingController.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/9.
//

import LarkUIKit
import LarkImageEditor
import ByteWebImage
import LarkVideoDirector
import LarkContainer
import UniverseDesignToast
import LarkAssetsBrowser
import LarkActionSheet
import EENavigator
import UniverseDesignActionPanel

class AvatarBaseSettingController: BaseSettingController {
    /// 右导航保存按钮
    lazy var saveButtonItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: nil, title: BundleI18n.LarkChatSetting.Lark_Legacy_Save, fontStyle: .medium)
        item.addTarget(self, action: #selector(saveGroupAvatar), for: .touchUpInside)
        return item
    }()

    let contentView = UIView()
    let scrollView = UIScrollView()
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkChatSetting.Lark_Legacy_EditPhoto
        self.navigationItem.rightBarButtonItem = self.saveButtonItem
        /// 默认不可以点击
        self.setRightButtonItemEnable(enable: false)
        self.view.backgroundColor = UIColor.ud.bgBase
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.contentInsetAdjustmentBehavior = .never
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.viewTopConstraint)
        }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            // 设置width.equalToSuperview()，可以上下滚动
            make.edges.width.equalToSuperview()
        }
    }

    /// 保存用户定制的群头像
    @objc
    func saveGroupAvatar() {}

    /// 把右导航按钮设置为可/不可点击
    func setRightButtonItemEnable(enable: Bool) {
        self.saveButtonItem.isEnabled = enable
        self.saveButtonItem.setBtnColor(color: enable ? UIColor.ud.primaryContentDefault : UIColor.ud.textDisable)
    }

    func getRightButtonItemEnableStatus() -> Bool {
        return self.saveButtonItem.isEnabled
    }
    /// 弹拍摄/从相册选择窗
    func showSelectActionSheet(arrowDirection: UIPopoverArrowDirection = .left, sender: UIView, navigator: EENavigator.Navigatable, finish: ((UIImage) -> Void)?) {
        // 拍摄完成后需要进行裁剪
        let complete: (UIImage, UIViewController) -> Void = { (image, picker) in
            let cropperVC = CropperFactory.createCropper(with: image)
            cropperVC.successCallback = { image, _, _ in
                // A present B，B push C，只需对B调用dismiss
                picker.dismiss(animated: true) {
                    finish?(image)
                }
            }
            cropperVC.cancelCallback = { _ in picker.dismiss(animated: true) }
            picker.navigationController?.pushViewController(cropperVC, animated: true)
        }
        var sourceRect = sender.bounds
        if arrowDirection == .left {
            sourceRect = CGRect(x: sender.bounds.width, y: sender.bounds.height / 2, width: 0, height: 0)
        } else if arrowDirection == .up {
            sourceRect = CGRect(x: sender.bounds.width / 2, y: sender.bounds.height, width: 0, height: 0)
        }
        let udactionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: false,
                popSource: UDActionSheetSource(
                    sourceView: sender,
                    sourceRect: sourceRect,
                    arrowDirection: arrowDirection)))

        // 拍摄
        udactionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_UploadImageTakePhoto) { [weak self] in
            guard let self else { return }
            LarkCameraKit.takePhoto(from: self, userResolver: self.userResolver, completion: complete)
        }
        // 从相册选择
        udactionSheet.addDefaultItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_ChooseFromPhotolibrary) { [weak self] in
            self?.showPhotoLibrary(finish: { image in
                finish?(image)
            })
        }
        // 取消
        udactionSheet.setCancelItem(text: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel)
        navigator.present(udactionSheet, from: self)
    }

    /// 从相册选择
    private func showPhotoLibrary(finish: ((UIImage) -> Void)?) {
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 1))
        picker.showSingleSelectAssetGridViewController()
        picker.imagePickerFinishSelect = { [weak self] (picker, result) in

            guard let asset = result.selectedAssets.first else { return }
            let hud = self.map { UDToast.showLoading(on: $0.view) }
            DispatchQueue.global().async {
                let shortSideLimit = LarkImageService.shared.imageUploadSetting.avatarConfig.limitImageSize
                let shortSide = min(asset.pixelWidth, asset.pixelHeight)
                let ratio = CGFloat(min(1, Double(shortSideLimit) / Double(shortSide)))
                let size = CGSize(width: round(CGFloat(asset.pixelWidth) * ratio),
                                  height: round(CGFloat(asset.pixelHeight) * ratio))
                let image = asset.imageWithSize(size: size)
                DispatchQueue.main.async {
                    hud?.remove()
                    guard let image = image else { return }
                    let cropperVC = CropperFactory.createCropper(with: image)
                    cropperVC.successCallback = { [weak picker] image, _, _ in
                        // A present B，B push C，只需对B调用dismiss
                        picker?.dismiss(animated: true, completion: { [weak self] in
                            guard let `self` = self else { return }
                            finish?(image)
                        })
                    }
                    cropperVC.cancelCallback = { [weak picker] _ in picker?.dismiss(animated: true) }
                    picker.pushViewController(cropperVC, animated: true)
                }
            }
        }
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.modalPresentationStyle = .fullScreen
        self.present(picker, animated: true, completion: nil)
    }
}
