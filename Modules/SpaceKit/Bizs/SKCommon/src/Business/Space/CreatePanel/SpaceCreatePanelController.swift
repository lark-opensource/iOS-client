//
//  SpaceCreatePanelController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/4/11.
//

import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import UniverseDesignColor
import UniverseDesignToast
import SKFoundation
import SKUIKit
import SKResource
import LarkTraitCollection

public typealias SpaceCreatePanelAnimation = SKPanelAnimation
public typealias SpaceCreatePanelAnimationController = SKPanelAnimationController

public protocol SpaceCreatePanelOnboardingController: UIViewController {
    var createOnboardingRect: CGRect { get }
    var templateOnboardingRect: CGRect { get }
}

public extension SpaceCreatePanelController {
    typealias Item = SpaceCreatePanelItem
}

private extension SpaceCreatePanelController {
    typealias ItemCell = SpaceCreatePanelItemCell
    struct Layout {
        static let collectionViewTopInset: CGFloat = 8
        static let collectionViewContentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        static let itemHeight: CGFloat = 78
        static let interLineSpacing: CGFloat = 0
        static let interItemSpacing: CGFloat = 0
        static let collectionViewSeperatorPadding: CGFloat = 0.5
        static let createTemplateSeperatorHeight: CGFloat = 0.5
        static let cancelSeperatorHeight: CGFloat = 0.5
        static let closeButtonHeight: CGFloat = 48

        let itemCount: Int
        let maxItemPerLine: Int
        let collectionViewHeight: CGFloat

        init(itemCount: Int) {
            self.itemCount = itemCount
            if itemCount % 4 == 1 {
                maxItemPerLine = 5
            } else {
                maxItemPerLine = 4
            }
            let lineCount = ceil(CGFloat(itemCount) / CGFloat(maxItemPerLine))
            let spacing: CGFloat
            if lineCount >= 1 {
                spacing = (lineCount - 1) * Self.interLineSpacing
            } else {
                spacing = 0
            }
            collectionViewHeight = lineCount * Self.itemHeight + spacing + Self.collectionViewContentInsets.top + Self.collectionViewContentInsets.bottom
        }
    }
}
// 设计稿: https://www.figma.com/file/WVXAmUYZWowFWhyIOiolL6/%E6%96%B0%E5%BB%BA%E9%9D%A2%E6%9D%BF?node-id=49%3A3979
public final class SpaceCreatePanelController: SKPanelController,
                                         UICollectionViewDelegate,
                                         UICollectionViewDataSource,
                                         UICollectionViewDelegateFlowLayout,
                                         TemplateSuggestionViewDelegate,
                                         SpaceCreatePanelOnboardingController {

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Layout.interLineSpacing
        layout.minimumInteritemSpacing = Layout.interItemSpacing
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = Layout.collectionViewContentInsets
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ItemCell.self, forCellWithReuseIdentifier: ItemCell.reuseIdentifier)
        return collectionView
    }()

    private lazy var createTemplateSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var templateView: TemplateSuggestionView = {
        let view = TemplateSuggestionView()
        // 新创建面板里，模板header的背景色是N00
        view.backgroundColor = .clear
        view.grayBgView.backgroundColor = .clear
        view.delegate = self
        return view
    }()

    private lazy var cancelSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var closeButton: SKHighlightButton = {
        let button = SKHighlightButton()
        button.normalBackgroundColor = UDColor.bgBody
        button.highlightBackgroundColor = UIColor.ud.N100
        let title = BundleI18n.SKResource.Doc_List_Cancel
        button.setTitle(title, withFontSize: 16, fontWeight: .regular, color: UDColor.textTitle, forState: .normal)
        return button
    }()

    private let items: [Item]
    private let layout: Layout
    private let templateViewModel: SpaceCreatePanelTemplateViewModel
    private let disposeBag = DisposeBag()

    private let templateEnable: Bool
    private var contentPopoverBottomConstraint: Constraint!
    private var contentFullScreenBottomConstraint: Constraint!

    public var cancelHandler: (() -> Void)?

    public init(items: [Item], templateViewModel: SpaceCreatePanelTemplateViewModel) {
        self.items = items
        self.templateViewModel = templateViewModel
        layout = Layout(itemCount: items.count)

        // 初始化时固定模板中心FG的值，保证内部使用一致
        templateEnable = TemplateRemoteConfig.templateEnable

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func setupUI() {
        super.setupUI()
        containerView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(Layout.closeButtonHeight)
        }
        closeButton.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)

        containerView.addSubview(cancelSeperatorView)
        cancelSeperatorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(closeButton.snp.top)
            make.height.equalTo(Layout.cancelSeperatorHeight)
        }

        if templateEnable {
            containerView.addSubview(templateView)
            let templateHeight = templateView.grayBgViewHeight + templateView.collectionViewHeight
            templateView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                contentFullScreenBottomConstraint = make.bottom.equalTo(cancelSeperatorView.snp.top).constraint
                contentPopoverBottomConstraint = make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).constraint
                make.height.equalTo(templateHeight)
            }

            containerView.addSubview(createTemplateSeperatorView)
            createTemplateSeperatorView.snp.makeConstraints { make in
                make.height.equalTo(Layout.createTemplateSeperatorHeight)
                make.left.right.equalToSuperview()
                make.bottom.equalTo(templateView.snp.top)
            }

            containerView.addSubview(collectionView)
            collectionView.snp.makeConstraints { make in
                make.bottom.equalTo(createTemplateSeperatorView.snp.top).offset(-Layout.collectionViewSeperatorPadding)
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(Layout.collectionViewTopInset)
                make.height.equalTo(layout.collectionViewHeight)
            }
            templateViewModel.setup(templateView: templateView)
        } else {
            containerView.addSubview(collectionView)
            collectionView.snp.makeConstraints { make in
                contentFullScreenBottomConstraint = make.bottom.equalTo(cancelSeperatorView.snp.top)
                    .offset(-Layout.collectionViewSeperatorPadding).constraint
                contentPopoverBottomConstraint = make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom)
                    .offset(-Layout.collectionViewSeperatorPadding).constraint
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(Layout.collectionViewTopInset)
                make.height.equalTo(layout.collectionViewHeight)
            }
        }
    }

    public override func transitionToRegularSize() {
        super.transitionToRegularSize()
        closeButton.isHidden = true
        cancelSeperatorView.isHidden = true
        contentPopoverBottomConstraint.activate()
        contentFullScreenBottomConstraint.deactivate()
        var preferredSize = containerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        // 默认宽度 375
        preferredSize.width = 375
        preferredContentSize = preferredSize
    }

    public override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        closeButton.isHidden = false
        cancelSeperatorView.isHidden = false
        contentPopoverBottomConstraint.deactivate()
        contentFullScreenBottomConstraint.activate()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            guard let self = self else { return }
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    @objc
    public override func didClickMask() {
        cancelHandler?()
        dismiss(animated: true)
    }

    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.reuseIdentifier, for: indexPath)
        guard let itemCell = cell as? ItemCell else {
            assertionFailure()
            return cell
        }
        guard indexPath.item < items.count else {
            assertionFailure()
            return itemCell
        }
        let item = items[indexPath.item]
        itemCell.update(item: item)
        return itemCell
    }

    // MARK: - UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.item < items.count else {
            assertionFailure()
            return
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? ItemCell else {
            assertionFailure()
            return
        }
        if !cell.itemEnabled && !DocsNetStateMonitor.shared.isReachable {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet, on: self.view.window ?? self.view)
        }
        let item = items[indexPath.item]
        let event = Item.CreateEvent(createController: self, itemEnable: cell.itemEnabled)
        item.clickHandler(event)
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth: CGFloat
        let contentWidth = collectionView.frame.width - Layout.collectionViewContentInsets.left - Layout.collectionViewContentInsets.right
        if items.count < layout.maxItemPerLine {
            itemWidth = contentWidth / CGFloat(items.count)
        } else {
            itemWidth = contentWidth / CGFloat(layout.maxItemPerLine)
        }
        return CGSize(width: itemWidth, height: Layout.itemHeight)
    }

    // MARK: - 模版创建 TemplateSuggestionViewDelegate
    func didClickMoreButtonOfTemplateSuggestionView(templateSuggestionView: TemplateSuggestionView) {
        templateViewModel.handleClickMore(createController: self)
    }

    func templateSuggestionView(templateSuggestionView: TemplateSuggestionView, didClick template: TemplateModel) {
        templateViewModel.createBy(template: template, createController: self)
    }

    // MARK: - 新手引导 SpaceCreatePanelOnboardingController
    public var createOnboardingRect: CGRect {
        return collectionView.convert(collectionView.bounds, to: view.window)
    }

    public var templateOnboardingRect: CGRect {
        guard templateEnable else {
            assertionFailure("template disabled, should not start template onboarding")
            return .zero
        }
        return templateView.convert(templateView.bounds, to: view.window)
    }
}
