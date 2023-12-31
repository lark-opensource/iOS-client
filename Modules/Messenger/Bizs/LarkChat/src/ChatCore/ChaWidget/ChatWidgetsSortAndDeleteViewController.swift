//
//  ChatWidgetsSortAndDeleteViewController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/3/28.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkMessageCore
import EENavigator
import LarkCore
import LarkAlertController
import UniverseDesignColor
import UniverseDesignToast

final class ChatWidgetsSortAndDeleteViewController: BaseUIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                                                    UIViewControllerTransitioningDelegate {
    private lazy var collectionView: UICollectionView = {
        let collectionViewLayout = ChatWidgetsSortAndDeleteCollectionCellFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressEvent(gesture:)))
        collectionView.addGestureRecognizer(longPressGesture)
        return collectionView
    }()

    private lazy var gradientBgView: GradientView = {
        let gradientBgView = GradientView()
        gradientBgView.backgroundColor = UIColor.clear
        gradientBgView.locations = [0.0, 1.0]
        gradientBgView.automaticallyDims = false
        return gradientBgView
    }()

    private lazy var navigationBar: UIView = {
        let navigationBar = ChatWidgetsNavigationBar { [weak self] in
            self?.dismiss(animated: true)
            self?.finishCallback()
        }
        return navigationBar
    }()

    private var draggingCell: ChatWidgetSortAndDeleteCollectionCell?
    private var draggingCellOriginCenter: CGPoint = .zero
    private var draggingStartPoint: CGPoint = .zero

    @objc
    private func longPressEvent(gesture: UILongPressGestureRecognizer) {
        let gestureState = gesture.state

        switch gestureState {
        case .began:
            let point = gesture.location(in: collectionView)
            guard let selectedIndexPath = collectionView.indexPathForItem(at: point) else {
                self.draggingCell = nil
                return
            }
            self.draggingCell = collectionView.cellForItem(at: selectedIndexPath) as? ChatWidgetSortAndDeleteCollectionCell
            self.draggingCellOriginCenter = self.draggingCell?.center ?? .zero
            self.draggingStartPoint = gesture.location(in: self.collectionView)
            self.draggingCell?.isUserDragging = true
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(CGPoint(x: self.collectionView.bounds.width / 2,
                                                                           y: self.draggingCellOriginCenter.y + gesture.location(in: self.collectionView).y - draggingStartPoint.y))
        case .ended:
            self.draggingCell?.isUserDragging = false
            self.draggingCell = nil
            collectionView.endInteractiveMovement()
        default:
            self.draggingCell?.isUserDragging = false
            self.draggingCell = nil
            collectionView.cancelInteractiveMovement()
        }
    }
    private let viewModel: ChatWidgetsSortAndDeleteViewModel
    private let disposeBag = DisposeBag()
    /// 记录超过限高的 Cell，展示内容遮罩
    private var cardMaskSet: Set<Int> = []
    private let finishCallback: () -> Void

    init(viewModel: ChatWidgetsSortAndDeleteViewModel, finishCallback: @escaping () -> Void) {
        self.viewModel = viewModel
        self.finishCallback = finishCallback
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
        self.viewModel.targetVC = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.clear
        self.view.addSubview(navigationBar)
        self.view.addSubview(gradientBgView)
        self.view.addSubview(collectionView)
        navigationBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        gradientBgView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(gradientBgView)
        }

        self.viewModel.refreshDriver
            .drive(onNext: { [weak self] in
                self?.collectionView.reloadData()
            }).disposed(by: self.disposeBag)
        self.viewModel.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        gradientBgView.colors = ChatWidgetsContainerView.UIConfig.widgetThemeGradientColors
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatWidgetsSortAndDeletePresentTransition()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatWidgetsSortAndDeleteDismissTransition()
    }

    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.viewModel.move(from: sourceIndexPath.item, to: destinationIndexPath.item)
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.collectionView.reloadData()
            }
            CATransaction.commit()
        })
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var cardHeight: CGFloat = self.viewModel.uiDataSource[indexPath.item].render.size().height
        let heightInfo: (CGFloat, Bool) = ChatWidgetSortAndDeleteCollectionCell.calculateCellHeightInfo(cardHeight)
        if heightInfo.1 {
            cardMaskSet.insert(indexPath.item)
        } else {
            cardMaskSet.remove(indexPath.item)
        }
        return CGSize(width: view.frame.size.width, height: heightInfo.0)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.item < self.viewModel.uiDataSource.count ?? 0 else {
            assertionFailure("keep the scene")
            return
        }
        let cellVM = self.viewModel.uiDataSource[indexPath.item]
        cellVM.willDisplay()
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.item < self.viewModel.uiDataSource.count ?? 0 else {
            return
        }
        let cellVM = self.viewModel.uiDataSource[indexPath.item]
        cellVM.didEndDisplay()
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.uiDataSource.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let widgetId = self.viewModel.uiDataSource[indexPath.item].metaModel.widget.id
        let cell = self.viewModel.uiDataSource[indexPath.item].dequeueReusableSortAndDeleteCell(collectionView,
                                                                                                indexPath: indexPath,
                                                                                                hideMask: !cardMaskSet.contains(indexPath.item)) { [weak self] in
            self?.showDeleteAlert(widgetId)
        }
        return cell
    }

    private func showDeleteAlert(_ widgetId: Int64) {
        if self.draggingCell != nil {
            /// 拖拽过程中不支持删除 Widget
            return
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChat.Lark_Group_RemoveWidget_Title)
        alertController.setContent(text: BundleI18n.LarkChat.Lark_Group_RemoveWidget_Desc)
        alertController.addSecondaryButton(text: BundleI18n.LarkChat.Lark_Group_RemoveWidget_Cancel_Button)
        alertController.addDestructiveButton(
            text: BundleI18n.LarkChat.Lark_Group_RemoveWidget_Remove_Button,
            dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.delete(widgetId)
                IMTracker.Chat.Main.Click.ChatWidgetRemove(self.viewModel.getChat(), widetIds: [widgetId])
            }
        )
        viewModel.navigator.present(alertController, from: self)
    }

    private func delete(_ widgetId: Int64) {
        DelayLoadingObservableWraper
            .wraper(observable: self.viewModel.delete(widgetId: widgetId), delay: 0.3, showLoadingIn: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] widgetId in
                guard let self = self else { return }
                UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_Group_WidgetRemoved_Toast, on: self.view)
                UIView.performWithoutAnimation {
                    guard let deleteIndex = self.viewModel.uiDataSource.firstIndex(where: { $0.metaModel.widget.id == widgetId }) else { return }
                    self.viewModel.uiDataSource.remove(at: deleteIndex)
                    self.collectionView.reloadSections(IndexSet(integer: 0))
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Group_UnabletoRemoveWidget_Toast, on: self.view, error: error)
            }).disposed(by: self.disposeBag)
    }
}

final class ChatWidgetsSortAndDeletePresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
              let sortAndDeleteVC = toVC as? ChatWidgetsSortAndDeleteViewController else {
                transitionContext.completeTransition(false)
                return
        }
        transitionContext.containerView.addSubview(sortAndDeleteVC.view)
        sortAndDeleteVC.view.alpha = 0
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                sortAndDeleteVC.view.alpha = 1
            },
            completion: { transitionContext.completeTransition($0) }
        )
    }
}

final class ChatWidgetsSortAndDeleteDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let sortAndDeleteVC = fromVC as? ChatWidgetsSortAndDeleteViewController else {
                transitionContext.completeTransition(false)
                return
        }
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                sortAndDeleteVC.view.alpha = 0
            },
            completion: { transitionContext.completeTransition($0) }
        )
    }
}

final class ChatWidgetsSortAndDeleteCollectionCellFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath, withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        let attributes = super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)
        attributes.transform = ChatWidgetSortAndDeleteCollectionCell.UIConfig.dragTransform
        return attributes
    }
}

final class ChatWidgetsNavigationBar: UIView {

    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.text = BundleI18n.LarkChat.Lark_Group_EditWidgets_DragToReorder_Text
        tipLabel.font = UIFont.systemFont(ofSize: 10)
        tipLabel.textColor = UIColor.ud.N00.alwaysLight
        return tipLabel
    }()

    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.attributedText = NSAttributedString(string: BundleI18n.LarkChat.Lark_Group_EditWidgets_Title, attributes: self.nameAttributes)
        return nameLabel
    }()

    private lazy var nameAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.ud.N00.alwaysLight,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    private lazy  var completeButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.LarkChat.Lark_Legacy_Finished, for: .normal)
        button.setTitleColor(UIColor.ud.N00.alwaysLight, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.rx.tap.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.finishCallback()
        }).disposed(by: disposeBag)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.clear
        return contentView
    }()

    private let disposeBag = DisposeBag()
    private let finishCallback: () -> Void

    init(finishCallback: @escaping () -> Void) {
        self.finishCallback = finishCallback
        super.init(frame: .zero)

        self.backgroundColor = ChatWidgetsContainerView.UIConfig.widgetThemeColor
        self.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.height.equalTo(44)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(safeAreaLayoutGuide)
        }

        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 2
        contentStackView.alignment = .center
        contentStackView.distribution = .fill
        contentView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        contentStackView.addArrangedSubview(nameLabel)
        contentStackView.addArrangedSubview(tipLabel)
        contentView.addSubview(self.completeButton)
        self.completeButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
