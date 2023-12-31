//
//  WikiCreateViewController.swift
//  SKWiki
//
//  Created by 邱沛 on 2021/3/4.
//
import SKCommon
import SKResource
import SKFoundation
import SKUIKit
import UniverseDesignColor
import UIKit
import SnapKit
import RxSwift

private extension WikiCreateViewController {
    struct Layout {
        static let collectionViewTopInset: CGFloat = 8
        static let collectionViewContentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        static let itemHeight: CGFloat = 78
        static let interLineSpacing: CGFloat = 0
        static let interItemSpacing: CGFloat = 0
        static let collectionViewSeparatorPadding: CGFloat = 0.5
        static let createTemplateSeparatorHeight: CGFloat = 0.5
        static let cancelSeparatorHeight: CGFloat = 0.5
        static let closeButtonHeight: CGFloat = 48

        private(set) var itemCount: Int
        private(set) var maxItemPerLine: Int
        private(set) var collectionViewHeight: CGFloat

        init(itemCount: Int) {
            self.itemCount = itemCount
            maxItemPerLine = Self.maxItemPerLine(for: itemCount)
            collectionViewHeight = Self.collectionViewHeight(for: itemCount, maxItemPerLine: maxItemPerLine)
        }

        mutating func update(itemCount: Int) {
            self.itemCount = itemCount
            maxItemPerLine = Self.maxItemPerLine(for: itemCount)
            collectionViewHeight = Self.collectionViewHeight(for: itemCount, maxItemPerLine: maxItemPerLine)
        }

        private static func maxItemPerLine(for itemCount: Int) -> Int {
            if itemCount % 4 == 1 {
                return 5
            } else {
                return 4
            }
        }

        private static func collectionViewHeight(for itemCount: Int, maxItemPerLine: Int) -> CGFloat {
            let lineCount = ceil(CGFloat(itemCount) / CGFloat(maxItemPerLine))
            let spacing: CGFloat
            if lineCount >= 1 {
                spacing = (lineCount - 1) * Self.interLineSpacing
            } else {
                spacing = 0
            }
            return lineCount * Self.itemHeight + spacing + Self.collectionViewContentInsets.top + Self.collectionViewContentInsets.bottom
        }
    }
}

public class WikiCreateViewController: SKPanelController,
                                UICollectionViewDelegate,
                                UICollectionViewDataSource,
                                UICollectionViewDelegateFlowLayout {

    var dismissCallback: (() -> Void)?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Layout.interLineSpacing
        layout.minimumInteritemSpacing = Layout.interItemSpacing
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = Layout.collectionViewContentInsets
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(WikiCreateViewCell.self, forCellWithReuseIdentifier: WikiCreateViewCell.reuseIdentifier)
        return collectionView
    }()

    private lazy var cancelSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var closeButton: SKHighlightButton = {
        let button = SKHighlightButton()
        button.normalBackgroundColor = UDColor.bgBody
        button.highlightBackgroundColor = UDColor.N100
        let title = BundleI18n.SKResource.Doc_List_Cancel
        button.setTitle(title, withFontSize: 16, fontWeight: .regular, color: UDColor.textTitle, forState: .normal)
        return button
    }()

    private var contentPopoverBottomConstraint: Constraint!
    private var contentFullScreenBottomConstraint: Constraint!

    // data
    private(set) var items: [WikiCreateItem]
    private var layout: Layout
    private var layoutLoaded = false

    // 供外部更新事件使用
    let updateBag = DisposeBag()

    public init(items: [WikiCreateItem]) {
        self.items = items
        layout = Layout(itemCount: items.count)
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        DocsLogger.info("WikiCreateViewController deinit")
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

        containerView.addSubview(cancelSeparatorView)
        cancelSeparatorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(closeButton.snp.top)
            make.height.equalTo(Layout.cancelSeparatorHeight)
        }

        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            contentFullScreenBottomConstraint = make.bottom.equalTo(cancelSeparatorView.snp.top)
                .offset(-Layout.collectionViewSeparatorPadding).constraint
            contentPopoverBottomConstraint = make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom)
                .offset(-Layout.collectionViewSeparatorPadding).constraint
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(Layout.collectionViewTopInset)
            make.height.equalTo(layout.collectionViewHeight)
        }

        layoutLoaded = true
    }

    public override func transitionToRegularSize() {
        super.transitionToRegularSize()
        closeButton.isHidden = true
        cancelSeparatorView.isHidden = true
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
        cancelSeparatorView.isHidden = false
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

    func update(items: [WikiCreateItem]) {
        self.items = items
        layout.update(itemCount: items.count)
        guard layoutLoaded else { return }
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(layout.collectionViewHeight)
        }
        collectionView.reloadData()
    }

    @objc
    public override func didClickMask() {
        dismiss(animated: true, completion: dismissCallback)
    }

    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WikiCreateViewCell.reuseIdentifier, for: indexPath)
        guard let itemCell = cell as? WikiCreateViewCell else {
            assertionFailure()
            return cell
        }
        guard indexPath.item < items.count else {
            assertionFailure()
            return itemCell
        }
        let item = items[indexPath.item]
        itemCell.update(item)
        return itemCell
    }

    // MARK: - UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.item < items.count else {
            assertionFailure()
            return
        }
        let item = items[indexPath.item]
        if item.enable {
            dismiss(animated: true, completion: item.action)
        } else {
            item.action()
        }
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
}
