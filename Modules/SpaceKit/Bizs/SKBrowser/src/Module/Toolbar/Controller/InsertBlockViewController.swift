// 
// Created by duanxiaochen.7 on 2020/7/1.
// Affiliated with SKCommon.
// 
// Description: 工具栏新建面板

import Foundation
import UIKit
import SnapKit
import HandyJSON
import SKCommon
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon

protocol InsertBlockDelegate: AnyObject {
    func didSelectBlock(id: String)
    func noticeWebScrollUpHeight(id: String, height: CGFloat)
}

// MARK: - UI Constants

struct InsertBlockUIConstant {
    weak var hostView: UIView?

    var panelTopPadding: CGFloat { CGFloat(8.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var sectionHeaderHeight: CGFloat { CGFloat(38.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var sectionHeaderTitleFontSize: CGFloat { CGFloat(16.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var blockCellSpacing: CGFloat { CGFloat(2.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var blockCellWidth: CGFloat { CGFloat(66.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var blockCellIconTopSpace: CGFloat { CGFloat(4.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var blockCellIconEdge: CGFloat { CGFloat(48.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var blockCellImageEdge: CGFloat { CGFloat(24.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var blockCellTextFontSize: CGFloat { CGFloat(12.0) }
    var blockCellIconTextSpacing: CGFloat { CGFloat(8.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var blockCellIconCornerRadius: CGFloat { CGFloat(8.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var sectionInsetValue: CGFloat { CGFloat(16.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var sectionHeaderInsetValue: CGFloat { CGFloat(16.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var sectionSpacing: CGFloat { CGFloat(16.0).scaledForWindow(atWidth: hostView?.frame.width) }
    var redDotWidth: CGFloat { CGFloat(8.0).scaledForWindow(atWidth: hostView?.frame.width) }
}


class InsertBlockViewController: DraggableViewController,
                                 UICollectionViewDelegateFlowLayout, UICollectionViewDataSource,
                                 UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate {

    weak var delegate: InsertBlockDelegate?

    private var model: InsertBlockDataModel

    private var uiConstant = InsertBlockUIConstant()

    var viewDistanceToWindowBottom: CGFloat = 0

    var maxPopoverViewHeight: CGFloat = CGFloat.greatestFiniteMagnitude

    // MARK: Subviews
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onTapBackground), for: .touchUpInside)
        return button
    }()

    private lazy var headerView = UIView().construct { it in
        if modalPresentationStyle != .popover {
            it.backgroundColor = UDColor.bgBody
            it.addGestureRecognizer(panGestureRecognizer)
        } else {
            it.backgroundColor = UDColor.bgFloat
        }

        if needsHandle {
            let handle = UIView(frame: .zero).construct { h in
                h.backgroundColor = UDColor.N300
                h.layer.cornerRadius = 2
                h.layer.masksToBounds = true
            }
            it.addSubview(handle)
            handle.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(8)
                make.width.equalTo(40)
                make.height.equalTo(4)
            }
        }
        it.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let separator = UIView().construct { s in
            s.backgroundColor = UDColor.lineDividerDefault
        }
        it.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
        
        if self.modalPresentationStyle != .popover {
            it.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(24)
            }
        }
    }

    private lazy var titleLabel = UILabel().construct { it in
        it.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        it.textColor = UIColor.ud.textTitle
    }

    private lazy var flowLayout = UICollectionViewFlowLayout().construct { it in
        it.scrollDirection = .vertical
        it.minimumLineSpacing = uiConstant.sectionSpacing
        it.sectionInset = UIEdgeInsets(top: uiConstant.panelTopPadding, left: 0, bottom: view.safeAreaInsets.bottom + 20, right: 0)
    }

    private lazy var sectionCollection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout).construct { it in
        it.backgroundColor = modalPresentationStyle != .popover ? UDColor.bgBody : UDColor.bgFloat
        it.clipsToBounds = false
        it.showsVerticalScrollIndicator = false
        it.register(BlockSectionCell.self, forCellWithReuseIdentifier: NSStringFromClass(BlockSectionCell.self))
        it.delegate = self
        it.dataSource = self
    }

    // MARK: Configurations

    private var hasNoticedDismissal = false

    private var needsHandle: Bool = false //{ SKDisplay.phone && (contentNeededHeight > contentViewMaxY) }
    
    private let draggableHeaderHeight: CGFloat = 48

    private var panelNeededHeight: CGFloat { uiConstant.panelTopPadding + model.contentHeight(uiConstant: uiConstant) }

    private var contentNeededHeight: CGFloat {
        draggableHeaderHeight
            + panelNeededHeight
            + (modalPresentationStyle == .popover ? 20 : view.safeAreaInsets.bottom)
            + viewDistanceToWindowBottom // 为 Magic Share 适配
    }

    // MARK: Life Cycle Events

    init(model: InsertBlockDataModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds = self.presentingViewController?.view.bounds ?? view.bounds
        contentViewMinY = bounds.maxY * 0.5
        contentViewMaxY = max(contentViewMinY, bounds.maxY - contentNeededHeight)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapBackground))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        setupContentView()
        sectionCollection.reloadData()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        sectionCollection.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentViewMinY = view.bounds.maxY * 0.5
        contentViewMaxY = max(contentViewMinY, view.bounds.maxY - contentNeededHeight)
        gapState = .max
        addCornerToContentView()
        noticeWebviewToScrollUp()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        //这里增加调用是为了避免万一发生内存泄漏deinit不会触发导致文档无法操作
        if !isMyWindowCompactSize() {
            noticeDismissal()
        }
        super.viewDidDisappear(animated)
    }

    deinit {
        // ⚠️ hasNoticedDismissal为false时，deinit一定需要调用noticeDismissal，因为+面板在iPad上弹出时会屏蔽webview上的点击事件，如果不调用会导致无法操作文档！！！
        if !hasNoticedDismissal {
            noticeDismissal()
        }
    }

    @objc
    private func onTapBackground() {
        dismiss(animated: true) { [weak self] in
            self?.noticeDismissal()
        }
    }

    override func dragDismiss() {
        dismiss(animated: true) { [weak self] in
            self?.noticeDismissal()
        }
    }

    // MARK: - Private Methods
    func noticeDismissal() {
        didSelectBlock(id: "close")
    }

    func noticeWebviewToScrollUp() {
        // 根据投影计算实际 webview 需要上移的高度
        let windowMaxY = SKDisplay.windowBounds(view).maxY
        let popoverMinY = headerView.convert(headerView.bounds, to: nil).minY // 用 headerview 是因为 popover 和半屏都要考虑
        let webviewScrollUpOffset = windowMaxY - popoverMinY
        delegate?.noticeWebScrollUpHeight(id: "setPanelHeight", height: webviewScrollUpOffset)
    }

    private func setupContentView() {
        contentView = UIView()
        contentView.backgroundColor = modalPresentationStyle != .popover ? UDColor.bgBody : UDColor.bgFloat
        view.addSubview(contentView)
        if modalPresentationStyle != .popover {
            uiConstant.hostView = contentView
            contentView.snp.makeConstraints { (make) in
                make.top.equalTo(view.bounds.maxY)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
            self.gapState = .bottom
            view.layoutIfNeeded()
            contentView.addSubview(sectionCollection)
            contentView.addSubview(headerView)
        } else {
            // 这个 preferredContentSize 是用来设置 popover 的大小的
            let viewHeight = min(maxPopoverViewHeight, contentNeededHeight)
            preferredContentSize = CGSize(width: CGFloat.scaleBaseline, height: viewHeight)
            // popover 的内容是填满的，而不是像 overCurrentContext 那样占半个屏幕，所以视图层级不一样
            view.addSubview(sectionCollection)
            view.addSubview(headerView)
        }

        setupHeaderView()
        setupCollectionView()
    }

    private func addCornerToContentView() {
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 12
        contentView.layer.maskedCorners = .top
    }

    private func setupHeaderView() {
        headerView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(draggableHeaderHeight)
        }
        titleLabel.text = model.title
    }

    private func setupCollectionView() {
        sectionCollection.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    // MARK: - Collection View Setup,  UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        model.children.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let rowModel = model.children[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(BlockSectionCell.self),
                                                            for: indexPath) as? BlockSectionCell else { return BlockSectionCell() }
        cell.insertDelegate = self
        cell.isPopover = modalPresentationStyle == .popover
        cell.configure(with: rowModel, uiConstant: uiConstant)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: view.bounds.width, height: model.children[indexPath.item].rowHeight(uiConstant: uiConstant))
    }
    // MARK: - Gesture Handling,  UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view ? true : false
    }
    // MARK: - Animation Transition,  UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingPresentAnimation(animateDuration: 0.25)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingDismissAnimation(animateDuration: 0.25)
    }
}


// MARK: - Insert Block Delegate

extension InsertBlockViewController: InsertBlockDelegate {
    func didSelectBlock(id: String) {
        delegate?.didSelectBlock(id: id)
        hasNoticedDismissal = true
    }

    func noticeWebScrollUpHeight(id: String, height: CGFloat) {
        delegate?.noticeWebScrollUpHeight(id: id, height: height)
    }
}
