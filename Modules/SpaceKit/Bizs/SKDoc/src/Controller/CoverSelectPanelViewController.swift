//
//  CoverSelectPanelViewController.swift
//  SKDoc
//
//  Created by lizechuang on 2021/1/27.
//

import SKFoundation
import LarkFoundation
import SKCommon
import SKResource
import SKUIKit
import RxSwift
import LarkCamera
import LarkAssetsBrowser
import LarkContainer
import LarkVideoDirector
import LarkTraitCollection
import UniverseDesignColor
import EENavigator
import LarkSensitivityControl
import SKInfra

public final class CoverSelectPanelViewController: BaseViewController {

    weak var viewModel: CoverSelectPanelViewModel?

    private var officialSeries: OfficialCoverPhotosSeries?

    private var curIndex: Int = 0

    private lazy var header: CoverSelectPanelHeader = {
        return CoverSelectPanelHeader(frame: .zero)
    }()

    private lazy var officialSelectView: OfficialCoverPhotosSelectView = {
        let officialSelectView = OfficialCoverPhotosSelectView(frame: .zero, isIPadDisplay: (self.modalPresentationStyle == .formSheet), with: OfficialCoverPhotosSeries())
        officialSelectView.delegate = self
        return officialSelectView
    }()

    private lazy var localSelectView: LocalCoverPhotosSelectView = {
        let localSelectView = LocalCoverPhotosSelectView(frame: .zero)
        localSelectView.delegate = self
        return localSelectView
    }()

    private lazy var backgroundScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = false
        return scrollView
    }()

    private lazy var loadingView: UIView = DocsUDLoadingImageView()
    private lazy var loadFailView: CoverSelectLoadFailView = CoverSelectLoadFailView()

    let bag = DisposeBag()

    public init(viewModel: CoverSelectPanelViewModel?) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel?.hostView = self.view
        title = BundleI18n.SKResource.CreationMobile_Docs_DocCover_ChooseCover_Title
        setupRightBarItems()
        setupSubViews()
        bindViewModel()
        // 监听sizeClass
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                guard let self = self else { return }
                if change.old != change.new {
                    self.officialSelectView.refreshDisplay()
                }
            }).disposed(by: bag)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupBackgroundScrollView()
    }

    override public func refreshLeftBarButtons() {
        super.refreshLeftBarButtons()
        let itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems
        if self.presentingViewController != nil && !itemComponents.contains(closeButtonItem) {
            self.navigationBar.leadingBarButtonItems.insert(closeButtonItem, at: 0)
        }
    }

    private func setupSubViews() {
        self.view.backgroundColor = UDColor.bgBase
        self.view.addSubview(header)
        self.view.addSubview(backgroundScrollView)
        self.view.addSubview(loadingView)
        self.view.insertSubview(header, aboveSubview: backgroundScrollView)
        self.view.insertSubview(header, aboveSubview: loadingView)
        header.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
        var items: [SpaceMultiListPickerItem] = [SpaceMultiListPickerItem]()
        items.append(SpaceMultiListPickerItem(identifier: CoverConstants.officialSectionHeaderIdentifier, title: BundleI18n.SKResource.CreationMobile_Docs_DocCover_OfficialGallery_Tab))
        items.append(SpaceMultiListPickerItem(identifier: CoverConstants.localSectionHeaderIdentifier, title: BundleI18n.SKResource.CreationMobile_Docs_DocCover_LocalUpload_Tab))
        header.update(items: items, currentIndex: 0)
        backgroundScrollView.snp.makeConstraints { (make) in
            make.top.equalTo(header.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        loadingView.snp.makeConstraints { (make) in
            make.top.equalTo(header.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        setLoadingViewShow(true)
        backgroundScrollView.addSubview(officialSelectView)
        backgroundScrollView.addSubview(localSelectView)
    }

    private func bindViewModel() {
        viewModel?.output.initialDataDriver.drive(onNext: {[weak self] (series) in
            guard let self = self else { return }
            self.officialSelectView.updateOfficialCoverPhotosSeries(series)
            self.officialSeries = series
            self.setLoadingViewShow(false)
            self.setLoadFailViewShow(false)
            self.header.updateRandomViewShowStatus(true)
        }).disposed(by: bag)
        viewModel?.output.initialDataFailed.drive(onNext: {[weak self] (error) in
            guard let self = self else { return }
            DocsLogger.error("failed: \(error)")
            self.setLoadingViewShow(false)
            self.setLoadFailViewShow(true)
        }).disposed(by: bag)
        viewModel?.output.submitDataDriver.drive(onNext: {[weak self] () in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: bag)
        header.sectionChangedSignal.emit(onNext: { [weak self] newIndex in
            guard let self = self else { return }
            self.handleSectionChanged(index: newIndex)
        }).disposed(by: bag)
        header.randomOptionSelect
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let self = self else {
                    return
                }
                self.viewModel?.input.randomSelectOfficialCoverPhoto.onNext(self.officialSeries)
            }).disposed(by: bag)
        loadFailView.retryAction
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let self = self else {
                    return
                }
                self.viewModel?.input.initialize.accept(())
            }).disposed(by: bag)
        viewModel?.input.initialize.accept(())
    }

    private func setupRightBarItems() {
        guard viewModel?.hadSelectCover ?? false else {
            return
        }
        let btnItem = SKBarButtonItem(title: BundleI18n.SKResource.CreationMobile_Docs_DocCover_Remove_Tab,
                                      style: .plain,
                                      target: self,
                                      action: #selector(removeCurrentCover))
        btnItem.id = .remove
        btnItem.foregroundColorMapping = SKBarButton.primaryColorMapping
        self.navigationBar.trailingBarButtonItems = [btnItem]
    }

    private func setupBackgroundScrollView() {
        let pageWidth = self.backgroundScrollView.bounds.width
        let pageHeight = self.backgroundScrollView.bounds.height
        let totalWidth: CGFloat = pageWidth * 2
        officialSelectView.frame = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        localSelectView.frame = CGRect(x: pageWidth, y: 0, width: pageWidth, height: pageHeight)
        backgroundScrollView.contentSize = CGSize(width: totalWidth, height: pageHeight)
        let offsetX = CGFloat(curIndex) * pageWidth
        backgroundScrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        if !loadFailView.isHidden {
            loadFailView.frame = officialSelectView.frame
        }
    }

    private func setLoadingViewShow(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            view.bringSubviewToFront(loadingView)
        }
    }

    private func setLoadFailViewShow(_ show: Bool) {
        loadFailView.isHidden = !show
        if show {
            if loadFailView.superview == nil {
                backgroundScrollView.addSubview(loadFailView)
                loadFailView.frame = officialSelectView.frame
            }
            backgroundScrollView.bringSubviewToFront(loadFailView)
        }
    }

    @objc
    private func removeCurrentCover() {
        self.viewModel?.input.didSelectOfficialCoverPhoto.onNext((nil, nil))
    }

    private func handleSectionChanged(index: Int) {
        self.curIndex = index
        let pageWidth = self.backgroundScrollView.bounds.width
        let offsetX = CGFloat(index) * pageWidth
        self.backgroundScrollView.contentOffset = CGPoint(x: offsetX, y: 0)
    }
}

extension CoverSelectPanelViewController: OfficialCoverPhotosSelectViewDelegate {
    func didSelectOfficialCoverPhotoWith(_ info: OfficialCoverPhotoInfo, sourceSeries: String) {
        self.viewModel?.input.didSelectOfficialCoverPhoto.onNext((info, sourceSeries))
    }
}

extension CoverSelectPanelViewController: LocalCoverPhotosSelectViewDelegate {
    func didSelectLocalCoverPhotoActionWith(_ action: LocalCoverPhotoAction) {
        switch action {
        case .album:
            displayAlbum()
        case .takePhoto:
            displayCamera()
        }
    }
    
    func didTapLinkActionWith(url: URL?) {
        guard let jumpUrl = url else {
            DocsLogger.error("fail jumpUrl is nil")
            return
        }
        guard let navVC = self.navigationController else {
            DocsLogger.error("fail jumpUrl: \(String(describing: url)) navController is nil")
            return
        }
        let navigator = viewModel?.model?.userResolver.navigator
        navigator?.push(jumpUrl, from: navVC)
    }
}

extension CoverSelectPanelViewController {
    private func displayAlbum() {
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 1),
                                               sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
                                               takePhotoEnable: false)
        picker.modalPresentationStyle = .fullScreen
        picker.imagePickerFinishSelect = { [weak self] (vc, result) in
            guard let self = self, let asset = result.selectedAssets.first else { return }
            vc.dismiss(animated: true, completion: nil)
            self.viewModel?.input.didSelectLocalCoverPhoto.onNext((asset, result.isOriginal))
        }
        picker.imagePikcerCancelSelect = { (vc, _) in
            vc.dismiss(animated: true, completion: nil)
        }
        picker.showMultiSelectAssetGridViewController()
        specialPresent(picker, animated: true)
    }
}

extension CoverSelectPanelViewController: LarkCameraControllerDelegate {
    private func displayCamera() {
        let userResolver = Container.shared.getCurrentUserResolver()
        LarkCameraKit.takePhoto(
            from: self, userResolver: userResolver,
            mutatingConfig: { $0.autoSave = true },
            completion: { [weak self] image, camera in
                camera.dismiss(animated: true)
                self?.viewModel?.input.didTakeLocalCoverPhoto.onNext(image)
            }
        )
    }

    private func specialPresent(_ viewControllerToPresent: UIViewController,
                         animated flag: Bool,
                         completion: (() -> Void)? = nil) {
        var vc: UIViewController?
        if let window = self.view.window {
            vc = window.lu.visibleViewController()
        } else if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow && ($0.rootViewController != nil) }) {
            vc = window.lu.visibleViewController()
        }
        vc?.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    public func camera(_ camera: LarkCameraController, didTake photo: UIImage, with lensName: String?) {
        do {
            try Utils.savePhoto(token: Token(PSDATokens.DocX.cover_takephoto_click_upload), image: photo) { _, _ in }
        } catch {
            DocsLogger.error("Utils savePhoto error")
        }
        DispatchQueue.main.async {
            camera.dismiss(animated: true)
            self.viewModel?.input.didTakeLocalCoverPhoto.onNext(photo)
        }
    }
}
