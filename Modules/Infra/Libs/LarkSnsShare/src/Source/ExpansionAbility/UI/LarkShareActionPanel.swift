//
//  LarkSharePanel.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/11/17.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignPopover

public final class LarkShareActionPanel: UIViewController, PanelHeaderCloseDelegate {
    weak var delegate: LarkShareItemClickDelegate?
    var productLevel: String
    var scene: String
    var isRotatable: Bool = false
    private var popoverSize: CGSize = .zero
    private var shareAreaLineNum: Int = 0
    private var shareAreaPageNum: Int = 0
    private var panelTransition: UDPopoverTransition
    private var normalTransition = SharePanelTransition()
    private var popoverMaterial: PopoverMaterial?
    private let shareTypes: [LarkShareItemType]
    private var shareSettingDataSource: [[ShareSettingItem]] {
        didSet {
            if shareSettingDataSource.isEmpty {
                shareSettingArea.isHidden = true
            } else {
                shareSettingArea.isHidden = false
            }
        }
    }

    func reloadSettingData(dataSource: [[ShareSettingItem]]) {
        self.shareSettingDataSource = dataSource
        shareSettingArea.update(dataSource: dataSource)
    }

    /// 分享面板
    lazy var sharePanel: UIView = {
        let sharePanel = UIView()
        sharePanel.backgroundColor = ShareColor.panelBackgroundColor
        sharePanel.layer.cornerRadius = ShareCons.panelCornerRadius
        sharePanel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return sharePanel
    }()

    lazy var maskView: UIView = {
        let maskView = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapViewController(_:)))
        maskView.addGestureRecognizer(tap)
        return maskView
    }()

    /// 控件容器
    lazy var sharePanelContainer: UIStackView = {
        let container = UIStackView()
        container.spacing = ShareCons.defaultSpacing
        container.alignment = .center
        container.axis = .vertical
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    /// 分享面板头部
    lazy var panelHeader: SharePanelHeader = SharePanelHeader(self.productLevel, self.scene)

    /// 分割线
    private lazy var divideLineView: UIView = {
        let line = UIView()
        line.backgroundColor = ShareColor.panelDivideLineColor
        return line
    }()

    /// 分享面板配置区
    private lazy var shareSettingArea: ListTableView = ListTableView(dataSource: shareSettingDataSource, actionPanel: self)

    /// 分享面板 分享区
    private lazy var singleLineShareOptionArea = ShareOptionSingleLineView(shareTypes: shareTypes)
    private lazy var multiPageShareOptionArea = ShareOptionMultiLineView(shareTypes: shareTypes)
    private lazy var containerFooterView = UIView()

    init(shareTypes: [LarkShareItemType],
         shareSettingDataSource: [[ShareSettingItem]],
         popoverMaterial: PopoverMaterial,
         delegate: LarkShareItemClickDelegate?,
         _ productLevel: String,
         _ scene: String) {
        self.shareTypes = shareTypes
        self.shareSettingDataSource = shareSettingDataSource
        self.popoverMaterial = popoverMaterial
        self.delegate = delegate
        self.productLevel = productLevel
        self.scene = scene
        self.panelTransition = UDPopoverTransition(sourceView: popoverMaterial.sourceView,
                                                   sourceRect: popoverMaterial.sourceRect,
                                                   permittedArrowDirections: popoverMaterial.direction,
                                                   dismissCompletion: nil)
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.modalPresentationCapturesStatusBarAppearance = true

        if UIDevice.current.userInterfaceIdiom == .phone {
            self.transitioningDelegate = normalTransition
        } else {
            panelTransition.presentStypeInCompact = .overFullScreen
            self.transitioningDelegate = panelTransition
            self.popoverPresentationController?.sourceRect = popoverMaterial.sourceRect
            self.popoverPresentationController?.sourceView = popoverMaterial.sourceView
            self.popoverPresentationController?.permittedArrowDirections = popoverMaterial.direction
            self.popoverPresentationController?.backgroundColor = ShareColor.panelBackgroundColor
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard isInPoperover else { return }
        multiPageShareOptionArea.update()
        self.preferredContentSize = calculatePopoverSize()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        remakeConstraints()
        multiPageShareOptionArea.update()
        self.preferredContentSize = calculatePopoverSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubViews()
        setupConstraints()
        setupAppearance()
    }

    public override var shouldAutorotate: Bool {
        return self.isRotatable
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}

extension LarkShareActionPanel {
    private func setupSubViews() {
        self.view.addSubview(maskView)
        self.view.addSubview(sharePanel)
        sharePanel.addSubview(sharePanelContainer)
        sharePanelContainer.addArrangedSubview(panelHeader)
        sharePanelContainer.addArrangedSubview(divideLineView)
        sharePanelContainer.addArrangedSubview(shareSettingArea)
        sharePanelContainer.addArrangedSubview(singleLineShareOptionArea)
        sharePanelContainer.addArrangedSubview(multiPageShareOptionArea)
        sharePanelContainer.addArrangedSubview(containerFooterView)
    }

    private func setupConstraints() {
        maskView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(sharePanel.snp.top)
        }

        sharePanel.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide)
        }

        sharePanelContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.bottom.trailing.equalTo(view.safeAreaLayoutGuide)
        }

        panelHeader.snp.makeConstraints { make in
            make.width.top.equalToSuperview()
            make.height.equalTo(ShareCons.panelHeaderHeight)
            sharePanelContainer.setCustomSpacing(CGFloat.leastNormalMagnitude, after: panelHeader)
        }

        divideLineView.snp.makeConstraints { make in
            make.width.equalTo(self.view)
            make.top.equalTo(panelHeader.snp.bottom)
            make.height.equalTo(ShareCons.panelDivideLineHeight)
            sharePanelContainer.setCustomSpacing(CGFloat.leastNormalMagnitude, after: divideLineView)
        }

        shareSettingArea.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ShareCons.defaultSpacing)
            make.trailing.equalToSuperview().inset(ShareCons.defaultSpacing)
            if shareSettingDataSource.isEmpty {
                make.height.equalTo(0)
            } else {
                make.height.equalTo(getShareSettingAreaHeight())
            }
        }

        singleLineShareOptionArea.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(ShareCons.shareCellItemSize.height)
        }

        multiPageShareOptionArea.snp.makeConstraints { make in
            make.width.equalToSuperview()
            if multiPageShareOptionArea.lines == 1 {
                make.height.equalTo(ShareCons.shareCellItemSize.height)
            } else if multiPageShareOptionArea.numsOfPage == 1 {
                make.height.equalTo(ShareCons.shareCellItemSize.height * 2 + ShareCons.defaultSpacing)
            } else {
                make.height.equalTo((ShareCons.shareCellItemSize.height + ShareCons.defaultSpacing) * 2 + ShareCons.sharePageIndicatorHeight)
            }
        }

        containerFooterView.snp.remakeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(ShareCons.defaultSpacing / 2)
            self.sharePanelContainer.setCustomSpacing(0, after: singleLineShareOptionArea)
            self.sharePanelContainer.setCustomSpacing(0, after: multiPageShareOptionArea)
        }
    }

    private func setupAppearance() {
        self.panelHeader.delegate = self
        if #available(iOS 13.0, *) {
            self.normalTransition.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
        }

        if shareSettingDataSource.isEmpty {
            multiPageShareOptionArea.isHidden = false
            singleLineShareOptionArea.isHidden = true
        } else {
            multiPageShareOptionArea.isHidden = true
            singleLineShareOptionArea.isHidden = false
        }

        singleLineShareOptionArea.onShareItemViewClicked = { [weak self] type in
            guard let self = self else { return }
            self.delegate?.shareItemDidClick(itemType: type)
        }

        multiPageShareOptionArea.onItemViewClicked = { [weak self] type in
            guard let self = self else { return }
            self.delegate?.shareItemDidClick(itemType: type)
        }

        multiPageShareOptionArea.lineChanged = { [weak self] (lineNum, numsOfPage) in
            guard let self = self else { return }
            self.shareAreaLineNum = lineNum
            self.shareAreaPageNum = numsOfPage
            self.multiPageShareOptionArea.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                if lineNum == 1 {
                    make.height.equalTo(ShareCons.shareCellItemSize.height)
                } else if numsOfPage == 1 {
                    make.height.equalTo(ShareCons.shareCellItemSize.height * 2 + ShareCons.defaultSpacing)
                } else {
                    make.height.equalTo((ShareCons.shareCellItemSize.height + ShareCons.defaultSpacing) * 2 + ShareCons.sharePageIndicatorHeight)
                }
            }
        }
        multiPageShareOptionArea.productLevel = self.productLevel
        multiPageShareOptionArea.scene = self.scene
    }

    /// 点击蒙板注销vc
    @objc
    private func didTapViewController(_ gesture: UITapGestureRecognizer) {
        guard !sharePanel.frame.contains(gesture.location(in: view)) else { return }
        dismissCurrentVC()
    }

    @objc
    public func dismissCurrentVC(animated: Bool = true) {
        dismiss(animated: animated) { [weak self] in
            self?.delegate?.sharePanelDidClosed()
        }
    }

    func remakeConstraints() {
        if isInPoperover {
            self.maskView.isHidden = true
            self.panelHeader.isHidden = true
            self.divideLineView.isHidden = true
            self.view.backgroundColor = ShareColor.panelBackgroundColor
            self.updateSharePanelConstraintInpopover()
            self.containerFooterView.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(ShareCons.defaultSpacing)
                self.sharePanelContainer.setCustomSpacing(0, after: singleLineShareOptionArea)
                self.sharePanelContainer.setCustomSpacing(0, after: multiPageShareOptionArea)
            }
        } else {
            self.maskView.isHidden = false
            self.panelHeader.isHidden = false
            self.divideLineView.isHidden = false
            self.view.backgroundColor = .clear
            self.updateSharePanelConstraintNormal()
            self.containerFooterView.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(ShareCons.defaultSpacing / 2)
                self.sharePanelContainer.setCustomSpacing(0, after: singleLineShareOptionArea)
                self.sharePanelContainer.setCustomSpacing(0, after: multiPageShareOptionArea)
            }
        }
    }

    func updateSharePanelConstraintInpopover() {
        if let arrowDirection = self.popoverPresentationController?.permittedArrowDirections {
            sharePanel.snp.remakeConstraints { make in
                switch arrowDirection {
                case .up:
                    let topOffset = self.shareSettingDataSource.isEmpty ? ShareCons.popoverArrowHeight : 0
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalToSuperview()
                    make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(topOffset)
                case .down:
                    make.leading.trailing.equalToSuperview()
                    make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide)
                    make.bottom.equalToSuperview().inset(ShareCons.popoverArrowHeight)
                default:
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalToSuperview()
                    make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(ShareCons.popoverArrowHeight)
                }
            }
        }
    }

    func updateSharePanelConstraintNormal() {
        sharePanel.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide)
        }
    }

    /// 计算 popoverSize
    private func calculatePopoverSize() -> CGSize {
        var popoverWidth: CGFloat = 375
        var popoverHeight: CGFloat = ShareCons.defaultSpacing + getShareSettingAreaHeight() + getShareOptionAreaHeight() + ShareCons.defaultSpacing
        return CGSize(width: popoverWidth, height: popoverHeight)
    }

    private func getShareSettingAreaHeight() -> CGFloat {
        guard !self.shareSettingDataSource.isEmpty else {
            return 0.0
        }
        // 计算section间距
        var height: CGFloat = CGFloat(shareSettingDataSource.count - 1) * ShareCons.defaultSpacing
        for items in shareSettingDataSource {
            for item in items {
                if item.subTitle == nil {
                    height += ShareCons.configSingleLineHeight
                } else {
                    height += ShareCons.configMultiLineHeight
                }
            }
        }
        return height + ShareCons.defaultSpacing
    }

    private func getShareOptionAreaHeight() -> CGFloat {
        guard self.shareSettingDataSource.isEmpty else {
            return ShareCons.shareCellItemSize.height
        }
        if shareAreaLineNum == 1 {
            return ShareCons.shareCellItemSize.height
        } else if shareAreaPageNum == 1 {
            return ShareCons.shareCellItemSize.height * 2 + ShareCons.defaultSpacing
        } else {
            return (ShareCons.shareCellItemSize.height + ShareCons.defaultSpacing) * 2 + ShareCons.sharePageIndicatorHeight
        }
    }
}
