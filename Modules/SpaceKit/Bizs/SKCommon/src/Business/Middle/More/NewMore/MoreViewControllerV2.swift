//
//  MoreViewControllerV2.swift
//  SKCommon
//
//  Created by lizechuang on 2021/2/25.
//

import SKFoundation
import SKUIKit
import RxSwift
import LarkTraitCollection
import UniverseDesignToast
import SKResource
import UniverseDesignColor
import Foundation
import UIKit
import SKInfra

// 使用说明
// https://bytedance.feishu.cn/docs/doccn2g5gT8oZZtc5OuaAYCT2d2#


public final class MoreViewControllerV2: SKWidgetViewController {

    private var isPopover: Bool {
        return SKDisplay.pad && self.modalPresentationStyle == .popover
    }
    
    let viewModel: MoreViewModel
    private let bag = DisposeBag()

    public var needAddWatermark: Bool {
        get { self.watermarkConfig.needAddWatermark }
        set {
            self.watermarkConfig.needAddWatermark = newValue
        }
    }
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    // MARK: - Views
    lazy var moreView: MoreView = {
        let moreView = MoreView(frame: self.view.bounds,
                                sectionData: viewModel.dataSource,
                                docsInfo: viewModel.docsInfo,
                                draggable: !self.isPopover,
                                bottomSafeAreaHeight: self.bottomSafeAreaHeight,
                                realTopContainerHeight: self.topSafeAreaHeight + 44,
                                from: self)
        moreView.delegate = self
        if let onboardingItemType = viewModel.onboardingConfig?.onboardingMoreItemType() {
            moreView.setOnboardingItemType(onboardingItemType)
        }
        return moreView
    }()
    
    public init(viewModel: MoreViewModel) {
        self.viewModel = viewModel
        super.init(contentHeight: 323)
        viewModel.hostController = self
        NotificationCenter.default.addObserver(self, selector: #selector(willChangeStatusBarOrientation(_:)), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(docsInfoIconKeyDidChanged), name: Notification.Name.Docs.docsInfoIconKeyUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(templateTagChange), name: NSNotification.Name.Docs.templateTagChange, object: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupItems()
        setupView()
        bind()
        
        // 监听sizeClass
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                if change.old != change.new || self?.modalPresentationStyle == .popover {
                    self?._dismissIfNeed()
                }
            }).disposed(by: bag)

        viewModel.reportViewMoreEvent()
        reportSentivePermViewMoreEvent()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let bgColor = UIColor.clear
        contentView.backgroundColor = bgColor
        backgroundView.backgroundColor = bgColor
        if SKDisplay.pad, isPopover {
            backgroundView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            let moreViewRealHeight = moreView.calculateRealHeight()
            if moreViewRealHeight > 0 {
                self.preferredContentSize = CGSize(width: CGFloat.scaleBaseline, height: moreViewRealHeight)
            }
        }
    }

    private func updateContentHeight() {
        let moreViewRealHeight = moreView.calculateRealHeight()
        if moreViewRealHeight > 0 {
            preferredContentSize = CGSize(width: CGFloat.scaleBaseline, height: moreViewRealHeight)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        if !SKDisplay.pad {
            super.viewDidAppear(animated)
        }
        needToDisplayOnboarding()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if !isPopover {
            contentView.snp.updateConstraints { (make) in
                make.height.equalTo(contentHeight + bottomSafeAreaHeight)
            }
            moreView.realTopContainerHeight = topSafeAreaHeight + 44
            moreView.bottomSafeAreaHeight = bottomSafeAreaHeight
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            let orientation = LKDeviceOrientation.getInterfaceOrientation()
            self?.didChangeStatusBarOrientation(to: orientation)
        }
    }
    
    public func didChangeStatusBarOrientation(to newOrentation: UIInterfaceOrientation) {
        guard SKDisplay.phone || newOrentation != .unknown else { return }
        setupItems()
        moreView.resetHeight(orentation: newOrentation)
    }

    @objc
    func willChangeStatusBarOrientation(_ notice: Notification) {
        _dismissIfNeed()
    }

    @objc
    private func docsInfoIconKeyDidChanged(_ notification: Notification) {
        guard let newDocsInfo = notification.object as? DocsInfo,
              newDocsInfo.objToken == viewModel.docsInfo.objToken else {
            return
        }
        moreView.setIconInfoToImageView(with: newDocsInfo)
    }
    
    @objc
    private func templateTagChange(_ notification: Notification) {
        guard  viewModel.docsInfo.isVersion == false else { return }
        guard let info = notification.userInfo else { return }
        guard let objToken = info["objToken"] as? String, let show = info["isShow"] as? Bool else { return }
        guard objToken == viewModel.docsInfo.objToken else { return }
        moreView.updateTemplateTag(isShow: show)
    }
}

// MARK: - Private - Setup
extension MoreViewControllerV2 {
    private func setupItems() {
        self.resetHeight(self.view.frame.height)
        contentView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentHeight + bottomSafeAreaHeight)
        }
    }

    private func setupView() {
        moreView.delegate = self
        contentView.addSubview(moreView)
        moreView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        moreView.setupSubviews()
        moreView.config(with: viewModel.docsInfo)
        if OpenAPI.enableTemplateTag(docsInfo: viewModel.docsInfo) {
            moreView.updateTemplateTag(isShow: OpenAPI.showTemplateTag(docsInfo: viewModel.docsInfo))
        } else {
            moreView.updateTemplateTag(isShow: false)
        }
    }

    private func bind() {
        viewModel.setup()
        viewModel.dataSourceUpdated
            .drive(onNext: { [weak self] dataSource in
                guard let self = self else { return }
                guard !self.isBeingDismissed else {
                    DocsLogger.warning("more vc isBeingDismissed, stop update source")
                    return
                }
                self.moreView.dataSource = dataSource
                self.moreView.reloadData()
                // 刷新下 moreView 高度
                self.updateContentHeight()
                self.moreView.resetHeight(orentation: UIApplication.shared.statusBarOrientation)
            }).disposed(by: bag)

        viewModel.readingDataUpdated
            .subscribe(onNext: { [weak self] (info) in
                guard let self = self else { return }
                guard !self.isBeingDismissed else {
                    DocsLogger.warning("more vc isBeingDismissed, stop update readingData")
                    return
                }
                self.moreView.update(readingDataInfo: info)
            }, onError: { [weak self] (error) in
                DocsLogger.error("\(error.localizedDescription)")
                // 请求 readingData 失败不再弹 toast，如 shortcut 本体被删场景，会出现无意义的错误提示
//                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed,
//                                       on: self.view.window ?? self.view)
            }).disposed(by: bag)
        viewModel.docsInfosUpdated
            .subscribe(onNext: { [weak self] (info) in
                guard let self = self, let docsInfo = info else { return }
                guard !self.isBeingDismissed else {
                    DocsLogger.warning("more vc isBeingDismissed, stop update docsinfo")
                    return
                }
                self.moreView.config(with: docsInfo)
            }, onError: { (error) in
                DocsLogger.error("docsInfoUpdated error \(error)")
            }).disposed(by: bag)
        viewModel.dismissAction
            .drive(onNext: { [weak self] (complete) in
                guard let self = self else { return }
                self.doDismiss(completion: complete)
            }).disposed(by: bag)
    }

//    private func addNetMonitor() {
//        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (_, _) in
//            guard let self = self else { return }
//            self.moreView.reloadData()
//        }
//    }
    
    private func _dismissIfNeed() {
        if SKDisplay.pad {
            dismiss(animated: true, completion: nil)
        }
    }

    public func doDismiss(completion: @escaping () -> Void) {
        animatedView(isShow: false, animate: false, compltetion: completion)
    }
    
    private func reportSentivePermViewMoreEvent() {
        if moreView.isShowSentivePerm {
            var params: [String: String] = [
                "is_security_icon_show": "true"
            ]
            if let userPermission = viewModel.dataProvider.userPermissions {
                let haveChangePerm = userPermission.canModifySecretLevel()
                params["is_have_change_perm"] = haveChangePerm ? "true" : "false"
            }
            DocsTracker.newLog(enumEvent: .spaceDocsMoreMenuView, parameters: params)
        }
    }
}

// MARK: - MoreViewDelegate
extension MoreViewControllerV2: MoreViewDelegate {
    public func didClickMaskErea() {
        animatedView(isShow: false, animate: true, compltetion: nil)
    }

    // 选中item，当item为mSwitch类型是isSwitchOn才有意义
    public func didClick(_ item: ItemsProtocol, isSwitchOn: Bool) {
        viewModel.clickAction.accept((item, isSwitchOn, nil))
    }
    
    // 选中item，当item为mSwitch类型是isSwitchOn才有意义
    public func didClick(_ item: ItemsProtocol, isSwitchOn: Bool, style: MoreViewV2RightButtonCell.Style) {
        viewModel.clickAction.accept((item, isSwitchOn, style))
    }
}
