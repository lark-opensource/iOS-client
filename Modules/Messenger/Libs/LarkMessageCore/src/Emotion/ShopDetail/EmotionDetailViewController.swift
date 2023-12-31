//
//  EmotionDetailViewController.swift
//  LarkUIKit
//
//  Created by huangjianming on 2019/8/6.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkModel
import EENavigator
import LarkAlertController
import LarkCore
import LarkEmotionKeyboard
import LarkMessengerInterface
import ByteWebImage
import UniverseDesignShadow

open class EmotionDetailViewController: BaseUIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    // MARK: - 成员变量
    let cellIdentifier = "EmotionDetailViewControllerCell"
    var viewModel: EmotionShopDetailViewModel
    let disposeBag = DisposeBag()
    var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    let emptyViewContainer = UIView()
    let loadingViewContainer = UIView()
    let unAuthorizedViewContainer = UIView()

    lazy var errorImageView: UIImageView = {
        let errorImageView = UIImageView()
        errorImageView.image = BundleResources.emotionEmptyIcon
        return errorImageView
    }()

    lazy var errorLabel: UILabel = {
        let errorLabel = UILabel()
        errorLabel.font = UIFont.systemFont(ofSize: 16)
        errorLabel.textAlignment = .center
        errorLabel.textColor = UIColor.ud.textPlaceholder
        errorLabel.text = BundleI18n.LarkMessageCore.Lark_Chat_StickerPackNoStickerPack
        return errorLabel
    }()

    lazy var unAuthorizedLabel: UILabel = {
        let errorLabel = UILabel()
        errorLabel.font = UIFont.systemFont(ofSize: 16)
        errorLabel.textAlignment = .center
        errorLabel.textColor = UIColor.ud.textPlaceholder
        errorLabel.text = BundleI18n.LarkMessageCore.Lark_Chat_StickerPackNoPermission
        return errorLabel
    }()

    lazy var unAuthorizedImageView: UIImageView = {
        let unAuthorizedImageView = UIImageView()
        unAuthorizedImageView.image = BundleResources.emotionUnauthorizeIcon
        return unAuthorizedImageView
    }()

    lazy var floatView: StickerFloatView = {
        let floatView = StickerFloatView()
        return floatView
    }()

    init(viewModel: EmotionShopDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - 生命周期
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavibar()
        setupCollectionView()
        self.view.backgroundColor = UIColor.ud.bgBody
        showLoadingView()
        self.viewModel.dataDriver().drive(onNext: { [weak self] (valid) in
            if valid {
                self?.reloadData()
            } else {
                self?.resetAllView()
                self?.showErrorView()
            }
        }).disposed(by: self.disposeBag)
        self.viewModel.fetchData()
    }

    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader,
                                                            at: IndexPath(row: 0, section: 0)) as? EmotionShopDetailCollectionHeaderView else {
            return
        }
        updateCollectionViewHeaderLayout(header: header, conintainerWidth: self.collectionView.frame.size.width)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader,
                                                            at: IndexPath(row: 0, section: 0)) as? EmotionShopDetailCollectionHeaderView else {
            return
        }
        updateCollectionViewHeaderLayout(header: header, conintainerWidth: size.width)
    }

    func updateCollectionViewHeaderLayout(header: EmotionShopDetailCollectionHeaderView, conintainerWidth: CGFloat) {
        // 宽度超过600使用ipad布局
        if conintainerWidth > 600 {
            header.layoutForIpad()
        } else {
            header.layoutForIphone()
        }
    }

    // MARK: - 内部方法
    func setupNavibar() {
        addBackItem()
    }

    func addRightItem() {
        let barItem = LKBarButtonItem(image: Resources.emotionShopShareIcon)
        barItem.button.addTarget(self, action: #selector(shareBtnTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = barItem
    }

    func removeRightItem() {
        self.navigationItem.rightBarButtonItem = nil
    }

    func resetAllView() {
        self.hideLoadingView()
        self.hideEmptyView()
        self.hideCollectionView()
        self.hideUnAuthorizedView()
    }

    func reloadData() {
        if !checkStickerExisted() {
            self.resetAllView()
            self.showUnAuthorizedView()
            removeRightItem()
        } else if checkStickerSetValid() {
            self.resetAllView()
            self.showAndReloadCollectionView()
            addRightItem()
            self.titleString = self.viewModel.stickerSet?.title ?? ""
        } else {
            self.resetAllView()
            self.showErrorView()
            removeRightItem()
        }
    }

    func hideCollectionView() {
        self.collectionView.isHidden = true
    }

    func showAndReloadCollectionView() {
        self.collectionView.isHidden = false
        self.collectionView.reloadData()
    }

    func showLoadingView() {
        loadingPlaceholderView.isHidden = false
    }

    func hideLoadingView() {
        loadingPlaceholderView.isHidden = true
    }

    func showUnAuthorizedView() {
        self.unAuthorizedViewContainer.isHidden = false
        self.view.addSubview(self.unAuthorizedViewContainer)
        unAuthorizedViewContainer.snp.makeConstraints { (make) in
            make.width.equalTo(125)
            make.height.equalTo(158)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }

        self.unAuthorizedViewContainer.addSubview(self.unAuthorizedImageView)
        unAuthorizedImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(125)
            make.top.left.equalToSuperview()
        }

        self.unAuthorizedViewContainer.addSubview(self.unAuthorizedLabel)
        unAuthorizedLabel.snp.makeConstraints { (make) in
            make.centerX.bottom.equalToSuperview()
        }
    }

    func hideUnAuthorizedView() {
        self.unAuthorizedViewContainer.isHidden = true
    }

    func showErrorView() {
        self.view.addSubview(self.emptyViewContainer)
        self.emptyViewContainer.isHidden = false
        emptyViewContainer.snp.makeConstraints { (make) in
            make.width.equalTo(125)
            make.height.equalTo(158)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }

        self.emptyViewContainer.addSubview(self.errorImageView)
        errorImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(125)
            make.top.left.equalToSuperview()
        }

        self.emptyViewContainer.addSubview(self.errorLabel)
        errorLabel.snp.makeConstraints { (make) in
            make.centerX.bottom.equalToSuperview()
        }
    }

    func hideEmptyView() {
        self.emptyViewContainer.isHidden = true
    }

    func checkStickerExisted() -> Bool {
        if self.viewModel.stickerSet != nil {
            return true
        }
        return false
    }

    func checkStickerSetValid() -> Bool {
        guard let stickerSet = self.viewModel.stickerSet else {
            return false
        }
        return !stickerSet.title.isEmpty || !stickerSet.title.isEmpty || !stickerSet.preview.key.isEmpty
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 6
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.headerReferenceSize = CGSize(width: self.view.frame.size.width, height: 306)
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        self.collectionView = collectionView
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(EmotionShopDetailCollectionCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.register(EmotionShopDetailCollectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "kHeaderViewID")
        collectionView.backgroundColor = UIColor.ud.bgBody
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture(sender:)))
        self.collectionView.addGestureRecognizer(longGesture)
        self.view.addSubview(self.collectionView)
        self.collectionView.isHidden = true
        self.collectionView.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalToSuperview()
        }
    }

    func showUpgradeAlert() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackBuyToast, font: .systemFont(ofSize: 17))
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackKnow)
        self.viewModel.navigator.present(alertController, from: self)
    }

    // MARK: - 点击和手势时间
    @objc
    private func shareBtnTapped() {
        guard let stickerSet = self.viewModel.stickerSet else { return }
        //右上角设置按钮点击
        let forwardbody = EmotionShareBody(stickerSet: stickerSet)
        self.viewModel.navigator.present(
            body: forwardbody,
            from: self,
            prepare: { $0.modalPresentationStyle = .fullScreen })
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        let state = sender.state
        if state == .ended || state == .failed || state == .cancelled {
            self.floatView.removeFromSuperview()
            return
        }

        //防止long press重复调用时逻辑一直被调用
        if self.floatView.superview != nil {
            return
        }

        for cell in self.collectionView.visibleCells {
            if cell.frame.contains(sender.location(in: self.collectionView)) {
                if let view = self.view {
                    guard let indexPath = self.collectionView.indexPath(for: cell) else {
                        return
                    }
                    guard let sticker = self.viewModel.stickerSet?.stickers[indexPath.row] else {
                        return
                    }
                    floatView.emotionView.bt.setLarkImage(with: .sticker(key: sticker.image.origin.key,
                                                                         stickerSetID: sticker.stickerSetID),
                                                          placeholder: BundleResources.emotionPlaceholderIcon,
                                                          trackStart: {
                                                            return TrackInfo(scene: .Chat, fromType: .sticker)
                                                          })
                    floatView.desLabel.text = sticker.description_p
                    view.addSubview(floatView)
                    let rect = cell.convert(cell.bounds, to: view)
                    let width: CGFloat = 152
                    let height: CGFloat = sticker.description_p.isEmpty ? 158 : 170
                    var x = rect.centerX - width / 2
                    if x < 8 {
                        x = 8
                        floatView.setArrowDirection(direction: .left, height: 154)
                    } else if x + width + 8 > view.frame.size.width {
                        x = view.frame.size.width - width - 8
                        floatView.setArrowDirection(direction: .right, height: 154)
                    } else {
                        floatView.setArrowDirection(direction: .center, height: 154)
                    }
                    floatView.frame = CGRect(
                        x: x > 0 ? x : 0,
                        y: rect.top - height,
                        width: width,
                        height: height
                    )
                    floatView.layer.ud.setShadow(type: .s4Down)
                }
            }
        }
    }

    // MARK: - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionViewCell: EmotionShopDetailCollectionCell = collectionView
            .dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? EmotionShopDetailCollectionCell else {
                return UICollectionViewCell(frame: CGRect.zero)
        }
        if let sticker = self.viewModel.stickerSet?.stickers[indexPath.row] {
            collectionViewCell.imageView.bt.setLarkImage(with: .sticker(key: sticker.image.thumbnail.key,
                                                                        stickerSetID: sticker.stickerSetID),
                                                         placeholder: BundleResources.emotionPlaceholderIcon,
                                                         trackStart: {
                                                            return TrackInfo(scene: .Chat, fromType: .sticker)
                                                         })
        }
        return collectionViewCell
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.stickerSet?.stickers.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        //配置headerView的子控件
        guard let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "kHeaderViewID",
            for: indexPath
        ) as? EmotionShopDetailCollectionHeaderView else {
            return UICollectionReusableView()
        }
        updateCollectionViewHeaderLayout(header: headerView, conintainerWidth: self.collectionView.frame.size.width)
        if let stickerSet = self.viewModel.stickerSet {
            let state = self.viewModel.getDownloadState(stickerSet: stickerSet)
            headerView.setState(state: state)
            headerView.stateView.isHidden = !self.checkStickerSetValid()
            headerView.configure(
                stickerSet: stickerSet,
                addBtnOn: { [weak self] in
                    if stickerSet.hasPaid_p {
                        self?.viewModel.addEmotionPackage(stickerSet: stickerSet)
                        StickerTracker.trackStickerSetAdded(from: .emotionDetail, stickerID: stickerSet.stickerSetID, stickersCount: stickerSet.stickers.count)
                    } else {
                        self?.showUpgradeAlert()
                    }
                }
            ) { [weak self] in
                self?.showEmotionChatPannel()
                StickerTracker.trackStickerSetUsed()
            }
        }
        return headerView
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = collectionView.frame.size.width
        if let stickerSet = self.viewModel.stickerSet {
            return CGSize(width: width, height: EmotionShopDetailCollectionHeaderView.headerHeight(stickerSet: stickerSet, superViewWidth: collectionView.frame.size.width))
        }
        return CGSize(width: width, height: 306)
    }

    func showEmotionChatPannel() {
        guard let stickerSet = self.viewModel.stickerSet else { return }
        //右上角设置按钮点击
        let forwardbody = EmotionShareToPanelBody(stickerSet: stickerSet)
        self.viewModel.navigator.present(
            body: forwardbody,
            from: self,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }
}
