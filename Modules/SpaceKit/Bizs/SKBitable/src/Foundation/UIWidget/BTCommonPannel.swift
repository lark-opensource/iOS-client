//
//  BTCommonPannel.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/30.
//

import UIKit
import LarkUIKit
import RxSwift
import SKUIKit
import SKCommon
import SKFoundation
import SnapKit
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon

protocol BTCommonPannelDelegate: AnyObject {
    func commonPanelBottomClicked(panel: BTCommonPannel, sourceView: UIView)
    func commonPanelSortItem(panel: BTCommonPannel, viewId: String, fromIndex: Int, toIndex: Int)
    func commonPanelBottomClosed(panel: BTCommonPannel)
}

struct BTCommonPannelConfig {
    let dragable: Bool
    let sortable: Bool
    let showBottomButton: Bool

    let title: String
    let bottomTitle: String
}

private class BTCommonPanelButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UDColor.udtokenBtnSeBgNeutralPressed : UDColor.bgFloat
        }
    }

    init() {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BTCommonPannel: DraggableViewController, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate {
    private static let titleHeight: CGFloat = 60
    private static let bottomHeight: CGFloat = 44
    private static let bottomButtonOffset: CGFloat = 12

    weak var delegate: BTCommonPannelDelegate?

    let dragable: Bool
    
    var hideRightIconWhenLandscape: Bool = false

    private lazy var tableViewWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var tableView: BTCommonTableView = {
        let view = BTCommonTableView()
        view.showsVerticalScrollIndicator = false
        view.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        // 避免按压拖动时, cell 左右被截断
        view.layer.masksToBounds = false
        return view
    }()
    
    private lazy var titleView: SKDraggableTitleView = {
        let view = SKDraggableTitleView()
        view.backgroundColor = UDColor.bgBody

        view.leftButton.isHidden = false
        view.leftButton.setImage(UDIcon.closeSmallOutlined, for: .normal)
        view.leftButton.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1.withAlphaComponent(0.5)), for: .highlighted)
        view.leftButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        view.topLine.isHidden = true
        
        return view
    }()
    
    private lazy var bottomButton: UIButton = {
        let view = BTCommonPanelButton()
        
        view.layer.cornerRadius = 6
        view.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        view.layer.borderWidth = 1.0
        view.backgroundColor = UDColor.bgFloat
        
        view.titleLabel?.font = .systemFont(ofSize: 16)
        view.setTitleColor(UDColor.textTitle, for: .normal)
        view.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        view.setImage(UDIcon.addOutlined.ud.resized(to: CGSizeMake(16, 16)).ud.withTintColor(UDColor.iconN1), for: .normal)
        view.addTarget(self, action: #selector(bottomButtonClicked(btn:)), for: .touchUpInside)

        return view
    }()
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [] // 目录这里的防护不需要toast,因为正文已经有了
        return preventer
    }()

    private let baseContext: BaseContext
    private let basePermissionHelper: BasePermissionHelper
    private let config: BTCommonPannelConfig

    required init(
        config: BTCommonPannelConfig,
        baseContext: BaseContext
    ) {
        DocsLogger.info("BTCommonPannel.init dragable:\(config.dragable)")
        self.dragable = config.dragable && !SKDisplay.pad
        self.baseContext = baseContext
        self.config = config
        self.basePermissionHelper = BasePermissionHelper(baseContext: baseContext)
        super.init(nibName: nil, bundle: nil)
        self.disableDrag = !self.dragable
        setupInit()
    }
    
    private func setupInit() {
        titleView.topLine.isHidden = !dragable
        if dragable {
            self.tableView.commonTableScrollDelegate = self
        }
        self.tableView.commonTableDelegate = self
        
        // 注册 UITableViewCell
        self.tableView.register(BTCommonItemCell.self, forCellReuseIdentifier: BTCommonItemCell.reuseIdentifier)
        
        transitioningDelegate = self
        if !dragable {
            gapState = .full
        }
        if UIApplication.shared.statusBarOrientation.isLandscape {
            gapState = .min
        }

        titleView.titleLabel.text = config.title
        bottomButton.setTitle(config.bottomTitle, for: .normal)
    }

    var initIndexPath: IndexPath? = nil
    private var hasViewDidiAppear = false
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        contentView = UIView()

        /*
         1. viewCapturePreventer 是基于 UITextField 实现的，在 TableView 原生拖动开始的时候偶现闪烁
         2. 所以不是直接把 viewCapturePreventer 作为 contentView，而是单独设置一个 UIView()
         3. 这样即使 viewCapturePreventer 出现闪烁，视觉上也不明显
         */
        let preventerContentView: UIView
        if ViewCapturePreventer.isFeatureEnable,
            UserScopeNoChangeFG.LYL.disableFixBaseDragTableSplash {
            preventerContentView = viewCapturePreventer.contentView
        } else {
            preventerContentView = UIView()
        }
        preventerContentView.backgroundColor = .clear
        contentView.addSubview(preventerContentView)
        preventerContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.backgroundColor = UDColor.bgBody
        contentView.layer.ud.setShadow(type: .s4Up)
        contentView.layer.cornerRadius = 12
        contentView.layer.maskedCorners = .top
        contentView.layer.masksToBounds = true
        
        if !SKDisplay.pad {
            if dragable {
                // 整个区域可拖动（scroll 区域还需要另外适配手势冲突情况，当 scroll 区域内容不可滚动时，此处生效）
                contentView.addGestureRecognizer(panGestureRecognizer)
            } else {
                // 仅标题区域可拖动
                titleView.addGestureRecognizer(panGestureRecognizer)
            }
        }
        
        view.addSubview(contentView)
        preventerContentView.addSubview(titleView)
        preventerContentView.addSubview(tableViewWrapper)
        tableViewWrapper.addSubview(tableView)
        preventerContentView.addSubview(bottomButton)

        titleView.snp.remakeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(Self.titleHeight)
        }
        
        updateStatus()
        
        addGestureRecognizer()
        
        basePermissionHelper.startObserve(observer: self)

        preventerContentView.bringSubviewToFront(titleView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
        hasViewDidiAppear = true
    }

    func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        tableView.handleScrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }

    func setData(data: BTCommonDataModel) {
        var realData = data
        realData.isCaptureAllowed = viewCapturePreventer.isCaptureAllowed
        tableView.hideRightIcon = hideRightIcon
        tableView.update(items: realData)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCornerRadii()

        if !hasViewDidiAppear,
            let indexPath = initIndexPath {
            scrollToRow(at: indexPath, at: .middle, animated: false)
        }
    }

    private func addGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapDimiss))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func onTapDimiss() {
        self.close()
    }
    
    override func dragDismiss() {
        self.titleView.isHidden = true
        self.bottomButton.isHidden = true
        self.close()
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }
    
    func open(from viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        let targetVC: UIViewController
        if SKDisplay.pad {
            let nav = SKNavigationController(rootViewController: self)
            nav.modalPresentationStyle = .formSheet
//            nav.preferredContentSize = CGSize(width: 540, height: 620)
            targetVC = nav
        } else {
            targetVC = self
        }
        viewController.present(targetVC, animated: animated, completion: completion)
    }
    
    func close() {
        delegate?.commonPanelBottomClosed(panel: self)
        if let navigationController = self.navigationController, navigationController.presentingViewController != nil {
            self.navigationController?.dismiss(animated: true)
        } else if self.presentingViewController != nil {
            self.dismiss(animated: true)
        } else {
            // 暂不支持
            DocsLogger.error("close pannle not surppoted")
        }
    }
    
    @objc
    private func closeButtonClicked() {
        close()
    }

    @objc
    private func bottomButtonClicked(btn: UIButton) {
        delegate?.commonPanelBottomClicked(panel: self, sourceView: bottomButton)
    }
    
    private var hideRightIcon: Bool {
        // iPhone 横屏下不能编辑
        hideRightIconWhenLandscape && UIApplication.shared.statusBarOrientation.isLandscape
    }
    
    private func updateStatus() {
        tableView.hideRightIcon = hideRightIcon
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        if isLandscape {
            contentView.snp.remakeConstraints { (make) in
                make.left.equalTo(view.safeAreaInsets.left)
                make.right.equalTo(-view.safeAreaInsets.right)
                if Display.pad {
                    make.top.equalTo(0.0)
                } else {
                    make.top.equalTo(contentViewMaxY)
                }
                make.bottom.equalToSuperview()
            }
        } else {
            contentView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                if Display.pad {
                    make.top.equalTo(0.0)
                } else {
                    make.top.equalTo(contentViewMaxY)
                }
                make.bottom.equalToSuperview()
            }
        }

        bottomButton.isHidden = !shouldShowBottomButtom
        if shouldShowBottomButtom {
            let bottomOffset: CGFloat = -self.view.safeAreaInsets.bottom - Self.bottomButtonOffset
            tableViewWrapper.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(Self.titleHeight + 16)
                make.bottom.equalToSuperview().offset(-Self.bottomHeight - 16 + bottomOffset)
            }
            tableView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview().inset(16)
                make.top.bottom.equalToSuperview()
            }
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            bottomButton.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(Self.bottomHeight)
                make.bottom.equalToSuperview().offset(bottomOffset)
            }
        } else {
            tableViewWrapper.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(Self.titleHeight + 16)
                make.bottom.equalToSuperview()
            }
            tableView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview().inset(16)
                make.top.bottom.equalToSuperview()
            }
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: max(self.view.safeAreaInsets.bottom, 16), right: 0)
        }

        tableView.dragInteractionEnabled = config.sortable
        if !SKDisplay.pad, UIApplication.shared.statusBarOrientation.isLandscape {
            tableView.dragInteractionEnabled = false
        }
    }
    
    private func setupCornerRadii() {
        contentView.layer.cornerRadius = 12
        contentView.layer.maskedCorners = .top
    }
    
    // MARK: - Tap Gesture Handling
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view ? true : false
    }
    // MARK: - Animation Transition,  UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingPresentAnimation(animateDuration: 0.25, layerAnimationOnly: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingDismissAnimation(animateDuration: 0.25, layerAnimationOnly: true)
    }
    
    private var shouldShowBottomButtom: Bool {
        get {
            if !config.showBottomButton {
                return false
            }
            if Display.phone, UIApplication.shared.statusBarOrientation.isLandscape {
                return false
            }
            return true
        }
    }

    @objc
    private func orientationDidChange() {
        updateStatus()
        tableView.reloadData()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateStatus()
    }
}

extension BTCommonPannel {
    /// 设置允许被截图
    func setCaptureAllowed(_ allow: Bool) {
        DocsLogger.info("BTCommonPannel setCaptureAllowed => \(allow)")
        viewCapturePreventer.isCaptureAllowed = allow
        tableView.update(isCaptureAllowed: viewCapturePreventer.isCaptureAllowed)
    }
}

extension BTCommonPannel: BasePermissionObserver {
    func initOrUpdateCapturePermission(hasCapturePermission: Bool) {
        DocsLogger.info("[BasePermission] BTCommonPannel initOrUpdateCapturePermission \(hasCapturePermission)")
        setCaptureAllowed(hasCapturePermission)
    }
}

extension BTCommonPannel: BTCommonTableViewDelegate, BTCommonTableViewScrollDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        handleScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }

    func commonTableViewSortItem(_ table: BTCommonTableView, viewId: String, fromIndex: Int, toIndex: Int) {
        delegate?.commonPanelSortItem(panel: self, viewId: viewId, fromIndex: fromIndex, toIndex: toIndex)
    }
}
