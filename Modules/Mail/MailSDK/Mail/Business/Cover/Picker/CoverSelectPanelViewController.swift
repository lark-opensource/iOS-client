//
//  CoverSelectPanelViewController.swift
//  SKDoc
//
//  Created by lizechuang on 2021/1/27.
//

import LarkFoundation
import RxSwift
import LarkCamera
import LarkAssetsBrowser
import LarkTraitCollection
import UniverseDesignColor
import LarkUIKit

class CoverSelectPanelViewController: BaseUIViewController {

    var viewModel: CoverSelectPanelViewModel?

    private var officialSeries: OfficialCoverPhotosSeries?

    private var curIndex: Int = 0

//    private lazy var header: CoverSelectPanelHeader = {
//        return CoverSelectPanelHeader(frame: .zero)
//    }()

    private lazy var officialSelectView: OfficialCoverPhotosSelectView = {
        let officialSelectView = OfficialCoverPhotosSelectView(frame: .zero, isIPadDisplay: Display.pad, with: OfficialCoverPhotosSeries(), provider: viewModel?.provider?.provider.configurationProvider, imageService: viewModel?.provider?.imageService)
        officialSelectView.delegate = self
        return officialSelectView
    }()

//    private lazy var localSelectView: LocalCoverPhotosSelectView = {
//        let localSelectView = LocalCoverPhotosSelectView(frame: .zero)
//        localSelectView.delegate = self
//        return localSelectView
//    }()

    private lazy var backgroundScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.isScrollEnabled = false
        return scrollView
    }()

    private lazy var loadingView = MailBaseLoadingView()
    private lazy var loadFailView: CoverSelectLoadFailView = CoverSelectLoadFailView()

    let bag = DisposeBag()

    init(viewModel: CoverSelectPanelViewModel?) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel?.hostView = self.view
        title = BundleI18n.MailSDK.Mail_Cover_MobileSelectCover
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupBackgroundScrollView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Display.pad, let nav = navigationController as? LkNavigationController {
            nav.update(style: .custom(UDColor.bgFloat, tintColor: nav.navigationBar.tintColor))
        }
    }

    private func setupSubViews() {
        self.view.backgroundColor = Display.pad ? UDColor.bgFloatBase : UDColor.bgContentBase
//        self.view.addSubview(header)
        self.view.addSubview(backgroundScrollView)
        self.view.addSubview(loadingView)
//        self.view.insertSubview(header, aboveSubview: backgroundScrollView)
//        self.view.insertSubview(header, aboveSubview: loadingView)
//        header.snp.makeConstraints { (make) in
//            make.top.equalTo(view.snp.top)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(40)
//        }
//        var items: [SpaceMultiListPickerItem] = [SpaceMultiListPickerItem]()
//        items.append(SpaceMultiListPickerItem(identifier: CoverConstants.officialSectionHeaderIdentifier, title: "官方图库"))
//        if viewModel?.enableSelectFromAlbum == true {
//            items.append(SpaceMultiListPickerItem(identifier: CoverConstants.localSectionHeaderIdentifier, title: "本地上传"))
//        }
//        header.update(items: items, currentIndex: 0)
        backgroundScrollView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        loadingView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            let navHeight = navigationController?.navigationBar.frame.height ?? 0
            let navBarTopPadding = Display.pad ? 0 : UIApplication.shared.statusBarFrame.height
            make.centerY.equalToSuperview().offset(-(navHeight + navBarTopPadding) / 2)
        }
        // 延迟显示 loading，避免闪烁
        setLoadingViewShow(false)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { [weak self] in
            guard let self = self,
                  self.officialSeries == nil || self.officialSeries?.isEmpty == true,
                  self.loadFailView.isHidden
            else { return }
            self.setLoadingViewShow(true)
        }
        backgroundScrollView.addSubview(officialSelectView)
//        if viewModel?.enableSelectFromAlbum == true {
//            backgroundScrollView.addSubview(localSelectView)
//        }
    }

    private func bindViewModel() {
        viewModel?.output.initialDataDriver.drive(onNext: {[weak self] (series) in
            guard let self = self else { return }
            self.officialSelectView.updateOfficialCoverPhotosSeries(series)
            self.officialSeries = series
            self.setLoadingViewShow(false)
            self.setLoadFailViewShow(false)
//            self.header.updateRandomViewShowStatus(true)
        }).disposed(by: bag)
        viewModel?.output.initialDataFailed.drive(onNext: {[weak self] (error) in
            guard let self = self else { return }
            MailLogger.error("failed: \(error)")
            self.setLoadingViewShow(false)
            self.setLoadFailViewShow(true)
        }).disposed(by: bag)
        viewModel?.output.submitDataDriver.drive(onNext: {[weak self] () in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: bag)
//        header.sectionChangedSignal.emit(onNext: { [weak self] newIndex in
//            guard let self = self else { return }
//            self.handleSectionChanged(index: newIndex)
//        }).disposed(by: bag)
//        header.randomOptionSelect
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] () in
//                guard let self = self else {
//                    return
//                }
//                self.viewModel?.input.randomSelectOfficialCoverPhoto.onNext(self.officialSeries)
//            }).disposed(by: bag)
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
        let removeButtonItem = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_Cover_RemoveMobile)
        removeButtonItem.button.addTarget(self, action: #selector(removeCurrentCover), for: .touchUpInside)
        navigationItem.rightBarButtonItem = removeButtonItem
    }

    private func setupBackgroundScrollView() {
        let pageWidth = self.backgroundScrollView.bounds.width
        let pageHeight = self.backgroundScrollView.bounds.height
        let totalWidth: CGFloat = pageWidth * 2
        officialSelectView.frame = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
//        if viewModel?.enableSelectFromAlbum == true {
//            localSelectView.frame = CGRect(x: pageWidth, y: 0, width: pageWidth, height: pageHeight)
//        }
        backgroundScrollView.contentSize = CGSize(width: totalWidth, height: pageHeight)
        let offsetX = CGFloat(curIndex) * pageWidth
        backgroundScrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        if !loadFailView.isHidden {
            loadFailView.frame = officialSelectView.frame
        }
    }

    private func setLoadingViewShow(_ show: Bool) {
        if show {
            view.bringSubviewToFront(loadingView)
            loadingView.play()
        } else {
            loadingView.stop()
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
        self.navigationController?.dismiss(animated: true)
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

//extension CoverSelectPanelViewController: LocalCoverPhotosSelectViewDelegate {
//    func didSelectLocalCoverPhotoActionWith(_ action: LocalCoverPhotoAction) {
//        switch action {
//        case .album:
//            displayAlbum()
//        case .takePhoto:
//            displayCamera()
//        }
//    }
//}

//extension CoverSelectPanelViewController {
//    private func displayAlbum() {
//        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 1),
//                                               // TODO: Kubrick
//                                               sendButtonTitle: "上传封面",
//                                               takePhotoEnable: false)
//        picker.modalPresentationStyle = .fullScreen
//        picker.imagePickerFinishSelect = { [weak self] (vc, result) in
//            guard let self = self, let asset = result.selectedAssets.first else { return }
//            vc.dismiss(animated: true, completion: nil)
//            self.viewModel?.input.didSelectLocalCoverPhoto.onNext((asset, result.isOriginal))
//        }
//        picker.imagePikcerCancelSelect = { (vc, _) in
//            vc.dismiss(animated: true, completion: nil)
//        }
//        picker.showMultiSelectAssetGridViewController()
//        specialPresent(picker, animated: true)
//    }
//}

//extension CoverSelectPanelViewController: LarkCameraControllerDelegate {
//    private func displayCamera() {
//        guard !LarkFoundation.Utils.isSimulator else { return }
//        let camera = LarkCameraController()
//        camera.mediaType = .photo
//        camera.modalPresentationStyle = .fullScreen
//        camera.delegate = self
//        specialPresent(camera, animated: true)
//    }
//
//    private func specialPresent(_ viewControllerToPresent: UIViewController,
//                         animated flag: Bool,
//                         completion: (() -> Void)? = nil) {
//        var vc: UIViewController?
//        if let window = self.view.window {
//            vc = window.lu.visibleViewController()
//        } else if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow && ($0.rootViewController != nil) }) {
//            vc = window.lu.visibleViewController()
//        }
//        vc?.present(viewControllerToPresent, animated: flag, completion: completion)
//    }
//
//    func camera(_ camera: LarkCameraController, didTack photo: UIImage) {
//        Utils.savePhoto(image: photo) { _, _ in }
//        DispatchQueue.main.async {
//            camera.dismiss(animated: true)
//            self.viewModel?.input.didTakeLocalCoverPhoto.onNext(photo)
//        }
//    }
//}
