//
//  StickerManageViewController.swift
//  Lark
//
//  Created by ChalrieSu on 2017/11/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkModel
import Photos
import UniverseDesignToast
import LarkAlertController
import EENavigator
import LarkMessengerInterface
import LarkContainer
import LarkCore
import LarkActionSheet
import RustPB
import UniverseDesignActionPanel
import LarkSDKInterface
import LarkSetting
import ByteWebImage

public final class StickerManageViewController: BaseUIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UserResolverWrapper {

    /// 选中的Sticker表情
    var selectedStickers: [RustPB.Im_V1_Sticker] {
        didSet {
            self.panel.selectCount = selectedStickers.count
        }
    }
    private let showType: ShowType

    /// 所有的sticker表情
    private var stickerModels = [RustPB.Im_V1_Sticker]()
    @ScopedInjectedLazy private var stickerService: StickerService?

    private let cellID = String(describing: PhotoScrollPickerCell.self)
    private var collectionView: UICollectionView
    private var layout: UICollectionViewFlowLayout
    private var panel: StickerManagePanel
    fileprivate let disposeBag = DisposeBag()
    public let userResolver: UserResolver
    public init(showType: ShowType, userResolver: UserResolver) {
        self.showType = showType
        self.userResolver = userResolver
        self.selectedStickers = [RustPB.Im_V1_Sticker]()
        layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        panel = StickerManagePanel()
        super.init(nibName: nil, bundle: nil)
        self.stickerModels = stickerService?.stickers ?? []
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.titleString = BundleI18n.LarkMessageCore.Lark_Legacy_StickerManager

        stickerService?.stickersObserver.asDriver().drive(onNext: { [weak self] (models) in
            guard let `self` = self else { return }
            self.stickerModels = models
            self.selectedStickers = self.selectedStickers.filter({ (selectedSticker) -> Bool in
                return self.stickerModels.contains(where: { (sticker) -> Bool in
                    return sticker.image.origin.key == selectedSticker.image.origin.key
                })
            })
            self.collectionView.reloadData()
        }).disposed(by: self.disposeBag)

        let rightBarButtonItem = LKBarButtonItem(title: BundleI18n.LarkMessageCore.Lark_Legacy_AddSticker)
        rightBarButtonItem.setBtnColor(color: UIColor.ud.textLinkNormal)
        self.navigationItem.rightBarButtonItems = [rightBarButtonItem]
        rightBarButtonItem.button.addTarget(self, action: #selector(rightBarButtonItemClicked), for: .touchUpInside)

        switch self.showType {
        case .present:
            self.addCloseItem()
        case .push:
            self.addBackItem()
        }

        self.view.addSubview(panel)
        panel.stickButtonCallback = {[weak self] in
            self?.stickSelectedStickers()
        }
        panel.deleteButtonCallback = { [weak self] sender in
            self?.addAlertWhenDeleteButtonTap(sender: sender)
        }
        panel.snp.makeConstraints { (make) in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }

        self.view.addSubview(collectionView)
        self.view.backgroundColor = UIColor.ud.bgBody
        collectionView.register(StickerManageCollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(panel.snp.top)
        }
        let itemWidth = self.view.bounds.width / 5
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
    }

    public override func viewWillAppear(_ animated: Bool) {
        let itemWidth = self.view.bounds.width / 5
        self.layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        self.layout.invalidateLayout()
        collectionView.reloadData()
        super.viewWillAppear(animated)
    }

    private func addAlertWhenDeleteButtonTap(sender: UIControl) {
        let udactionSheets = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: true,
                popSource: UDActionSheetSource(
                    sourceView: sender,
                    sourceRect: CGRect(x: sender.bounds.width / 2, y: 0, width: 0, height: 0),
                    preferredContentWidth: 300,
                    arrowDirection: .down)))
        udactionSheets.setTitle(BundleI18n.LarkMessageCore.Lark_Legacy_UnrecoverableAfterRemoved)
        udactionSheets.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_Delete) { [weak self] in
            self?.deleteSelectedStickers()
        }
        udactionSheets.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)
        self.navigator.present(udactionSheets, from: self)
    }

    @objc
    private func rightBarButtonItemClicked() {
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 9),
                                               isOriginButtonHidden: true,
                                               sendButtonTitle: BundleI18n.LarkMessageCore.Lark_Legacy_LarkConfirm)
        picker.showMultiSelectAssetGridViewController()
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.imagePickerFinishSelect = { [weak self] (picker, result) in
            self?.pickedStickerImages(assets: result.selectedAssets)
            picker.dismiss(animated: true, completion: nil)
        }
        picker.imageEditAction = { StickerTracker.trackImageEditEvent($0.event, params: $0.params) }
        picker.modalPresentationStyle = .fullScreen
        self.navigationController?.present(picker, animated: true, completion: nil)
    }

    func pickedStickerImages(assets: [PHAsset]) {
        guard !assets.isEmpty else {
            return
        }
        let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            let sendImageRequest = SendImageRequest(
                input: .assets(assets),
                sendImageConfig: SendImageConfig(
                    isSkipError: false,
                    checkConfig: SendImageCheckConfig(
                        imageSize: CGSize(width: 2000, height: 2000),
                        fileSize: 5 * 1024 * 1024, isOrigin: false,
                        scene: .Chat, fromType: .sticker)),
                uploader: StickerSendImageUploader(fromVC: self, stickerService: self.stickerService, nav: self.navigator))
            SendImageManager.shared
                .sendImage(request: sendImageRequest)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    hud.remove()
                }, onError: { [weak self] error in
                    guard let `self` = self else { return }
                    hud.remove()
                    // custom会报出三种错误
                    // 一个是上传错误，这个在stickerService.uploadStickers接口内部已经处理过了
                    // 一个是检查失败（主要是检查sticker个数是否超限），这个已经在uploader里处理过了
                    // 一个是getCompressResult（拿不到压缩后的结果），但设置了isSkipError是false，所以如果有压缩错误已经在compress阶段抛出错误了
                    // 所以这里跳过custom阶段的所有错误
                    if let imageError = error as? LarkSendImageError,
                        imageError.type == .custom {
                        return
                    }
                    if let imageError = error as? LarkSendImageError,
                        let compressError = imageError.error as? CompressError,
                        let err = AttachmentImageError.getCompressError(error: compressError) {
                        let alertController = LarkAlertController()
                        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Legacy_Hint)
                        alertController.setContent(text: err)
                        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_LarkConfirm)
                        self.navigator.present(alertController, from: self)
                    } else {
                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip, on: self.view)
                    }
                }, onCompleted: {
                    hud.remove()
                }).disposed(by: self.disposeBag)
        }
    }

    private func selectIndexForModel(_ stickerModel: RustPB.Im_V1_Sticker) -> Int? {
        return self.selectedStickers.firstIndex(where: { (sticker) -> Bool in
            sticker.image.origin.key == stickerModel.image.origin.key
        })
    }

    /// 选中sticker顶置
    private func stickSelectedStickers() {
        let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)

        let sortedStickers = self.selectedStickers + self.stickerModels.filter({ (sticker) -> Bool in
            return !self.selectedStickers.contains(sticker)
        })

        self.stickerService?
            .patchStickers(stickers: sortedStickers)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] (_) in
                guard let `self` = self else { return }
                self.selectedStickers = []
                self.collectionView.reloadData()
                hud.remove()
            }, onCompleted: { [weak self] in
                guard let `self` = self else { return }
                self.selectedStickers = []
                self.collectionView.reloadData()
                hud.remove()
            })
            .disposed(by: disposeBag)
    }

    /// 删除选中sticker
    private func deleteSelectedStickers() {
        let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        self.stickerService?
            .deleteStickers(stickers: self.selectedStickers)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] (_) in
                guard let `self` = self else { return }
                self.selectedStickers = []
                self.collectionView.reloadData()
                hud.remove()
            }, onCompleted: { [weak self] in
                guard let `self` = self else { return }
                self.selectedStickers = []
                self.collectionView.reloadData()
                hud.remove()
            })
            .disposed(by: disposeBag)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            let itemWidth = size.width / 5
            self.layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            self.layout.invalidateLayout()
            self.collectionView.reloadData()
        }, completion: nil)
    }
    // MARK: - UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < self.stickerModels.count else {
            return
        }
        //所有选中的sticker对应的index
        var reloadedIndexs: [IndexPath] = [IndexPath]()
        for selectedSticker in self.selectedStickers {
            let index = self.stickerModels.firstIndex(where: { (sticker) -> Bool in
                return selectedSticker.image.origin.key == sticker.image.origin.key
            })
            if let index = index {
                reloadedIndexs.append(IndexPath(row: index, section: 0))
            }
        }

        let model = self.stickerModels[indexPath.row]
        let index = self.selectedStickers.firstIndex(where: { (selectedSticker) -> Bool in
            selectedSticker.image.origin.key == model.image.origin.key
        })

        if let index = index {
            //如果当前cell里面的model已经选中，则从选中的数组中去掉
            selectedStickers.remove(at: index)
        } else {
            //否则把当前选中的model加入到选中models中，同时reload该cell
            selectedStickers.append(model)
            reloadedIndexs.append(IndexPath(row: indexPath.row, section: 0))
        }
        UIView.performWithoutAnimation {
            collectionView.reloadItems(at: Array(reloadedIndexs))
        }
    }
    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as? StickerManageCollectionViewCell {
            cell.model = stickerModels[indexPath.row]
            cell.selectIndex = self.selectIndexForModel(stickerModels[indexPath.row])
            return cell
        }
        return UICollectionViewCell()
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerModels.count
    }
}

public final class StickerSendImageUploader: LarkSendImageUploader {
    public typealias AbstractType = Void
    private var stickerService: StickerService?
    weak var fromVC: UIViewController?
    private let nav: Navigatable
    public init(fromVC: UIViewController?, stickerService: StickerService?, nav: Navigatable) {
        self.fromVC = fromVC
        self.stickerService = stickerService
        self.nav = nav
    }

    static let getCompressResult = -45_900_008 // 获取不到compress的结果
    static let checkFailed = -45_900_009 // 检查失败，process已经处理

    struct SendImageError: CustomUploadError {
        public var code: Int
    }

    public func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        return Observable<AbstractType>.create { [weak self] observer in
            guard let `self` = self,
                  let compressResult = request.getCompressResult(),
                  let vc = self.fromVC else {
                observer.onError(SendImageError(code: StickerSendImageUploader.getCompressResult))
                return Disposables.create()
            }
            let imageSourceResultArray: [Result<ImageSourceResult, CompressError>] = compressResult.map { $0.result }
            let imageData: [Data] = imageSourceResultArray.compactMap { imageSourceResult -> Data? in
                switch imageSourceResult {
                case .success(let imageSource):
                    // 之前的逻辑是，在Wi-Fi和蜂窝下分别压缩sticker到1M和0.5M，如果不够，会继续调整参数再压缩一次
                    // 但是1M和0.5M太小了，并且循环压缩图片会消耗性能。
                    // 所以对齐安卓策略，不区分网络状态，以及不压缩太小的值，同时sticker调整为非原图上传。
                    return imageSource.data
                // 因为sticker选择isSkipError=false，所以出错后直接抛错，此处应该不会再有case .failure的情况
                case .failure(let error):
                    assertionFailure()
                    observer.onError(error)
                    return nil
                }
            }
            // 如果有图片没有通过检查，直接返回，提示错误
            if imageData.count != imageSourceResultArray.count {
                return Disposables.create()
            }
            // 之前的接口有两部分能力，一部分是检查是否超过sticker保存的上限1000个，一部分是检查新sticker图片大小和像素是否超过阈值
            // 接入新组件后，检查图片大小的能力已经做了，所以业务方这里只需要检查是否超过保存个数上限
            if let error = self.stickerService?.checkNewStickerEnable(newCount: imageData.count) {
                DispatchQueue.main.async {
                    let alertController = LarkAlertController()
                    alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Legacy_Hint)
                    alertController.setContent(text: error)
                    alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_LarkConfirm)
                    self.nav.present(alertController, from: vc)
                }
                observer.onError(SendImageError(code: StickerSendImageUploader.checkFailed))
                // 上传的图片中，有一个报错，都不上传
                return Disposables.create()
            }
            self.stickerService?
                .uploadStickers(imageDatas: imageData, from: self.fromVC)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_) in
                    observer.onNext(())
                    observer.onCompleted()
                }, onError: { (error) in
                    observer.onError(error)
                })
            return Disposables.create()
        }
    }
}

final class StickerManagePanel: UIView {
    var selectCount: Int = 0 {
        didSet {
            if selectCount > 0 {
                deleteButton.isEnabled = true
                deleteButton.setTitle(BundleI18n.LarkMessageCore.Lark_Legacy_StickerDeleted + "(\(selectCount))", for: .normal)
                stickButton.isEnabled = true
            } else {
                deleteButton.isEnabled = false
                deleteButton.setTitle(BundleI18n.LarkMessageCore.Lark_Legacy_StickerDeleted, for: .normal)
                stickButton.isEnabled = false
            }
        }
    }
    var stickButtonCallback: (() -> Void)?
    var deleteButtonCallback: ((_ sender: UIControl) -> Void)?

    private let stickButton: UIButton
    private let deleteButton: UIButton

    init(selectCount: Int = 0) {
        stickButton = UIButton()
        deleteButton = UIButton()
        super.init(frame: CGRect.zero)

        self.selectCount = selectCount

        stickButton.setTitle(BundleI18n.LarkMessageCore.Lark_Legacy_StickerStick, for: .normal)
        stickButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        stickButton.setTitleColor(UIColor.ud.N900, for: .normal)
        stickButton.setTitleColor(UIColor.ud.N400, for: .disabled)
        stickButton.titleLabel?.textAlignment = .left
        stickButton.isEnabled = false
        stickButton.addTarget(self, action: #selector(stickButtonTapped), for: .touchUpInside)
        addSubview(stickButton)
        stickButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(15)
        }

        deleteButton.setTitle(BundleI18n.LarkMessageCore.Lark_Legacy_StickerDeleted, for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        deleteButton.setTitleColor(UIColor.ud.colorfulRed, for: .normal)
        deleteButton.setTitleColor(UIColor.ud.N400, for: .disabled)
        deleteButton.titleLabel?.textAlignment = .right
        deleteButton.isEnabled = false
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped(sender:)), for: .touchUpInside)
        addSubview(deleteButton)
        deleteButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-15)
        }

        self.lu.addTopBorder(color: UIColor.ud.N300)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func stickButtonTapped() {
        self.stickButtonCallback?()
    }

    @objc
    private func deleteButtonTapped(sender: UIControl) {
        self.deleteButtonCallback?(sender)
    }

}
