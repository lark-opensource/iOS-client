//
//  MinutesSelectiveDrawerController.swift
//  Minutes
//
//  Created by yangyao on 2023/2/22.
//

import Foundation
import FigmaKit
import MinutesFoundation

/// 为简化场景，暂不支持多section
public struct DrawerConfig {
    // 背景蒙层的颜色, 默认透明
    public var backgroundColor: UIColor
    // 抽屉上边沿圆角
    public let cornerRadius: CGFloat
    // 抽屉下滑多少会导致dismiss
    public let thresholdOffset: CGFloat
    // 最大的抽屉展示高度，超过后内容区域可滑动
    public let maxContentHeight: CGFloat
    // 如果个数超过最大高度，初始化要展示的高度
    public let initialShowHeight: CGFloat
    // cell的类型
    public let cellType: AnyClass
    public var tableViewDataSource: UITableViewDataSource?
    public var tableViewDelegate: UITableViewDelegate?
    // 自定义头部视图
    public var headerView: UIView?
    // 自定义尾部视图
    public var footerView: UIView?
    // 头部视图高度
    public var headerViewHeight: CGFloat
    // 尾部视图高度
    public var footerViewHeight: CGFloat

    public var isRegular: Bool

    public init(backgroundColor: UIColor = UIColor(white: 0, alpha: 0.3),
                cornerRadius: CGFloat,
                thresholdOffset: CGFloat,
                maxContentHeight: CGFloat,
                initialShowHeight: CGFloat,
                cellType: AnyClass,
                tableViewDataSource: UITableViewDataSource,
                tableViewDelegate: UITableViewDelegate,
                headerView: UIView? = nil,
                footerView: UIView? = nil,
                headerViewHeight: CGFloat = 0,
                footerViewHeight: CGFloat = 0,
                isRegular: Bool = false) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.thresholdOffset = thresholdOffset
        self.maxContentHeight = maxContentHeight
        self.initialShowHeight = initialShowHeight
        self.cellType = cellType
        self.tableViewDataSource = tableViewDataSource
        self.tableViewDelegate = tableViewDelegate
        self.headerView = headerView
        self.footerView = footerView
        self.headerViewHeight = headerViewHeight
        self.footerViewHeight = footerViewHeight
        self.isRegular = isRegular
    }
}

private enum DrawUI {
    static let statusBarHeight: CGFloat = 20
    static let containerFrameAnimationDuration = 0.25
}

open class MinutesSelectiveDrawerController: UIViewController {
    private let config: DrawerConfig
    private let transition: DrawerTransition
    private var startPanTableViewOffset: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private let cancelBlock: (() -> Void)?
    public var cellReuseIdentifier: String {
        return NSStringFromClass(config.cellType)
    }

    private var viewAppeared: Bool = false

    private var initialShowHeight: CGFloat = 0
    private var tableViewHeight: CGFloat = 0
    private var safeAreaInsetsBottom: CGFloat = 0
    private var isNeedScroll: Bool = false
    private var originY: CGFloat = 0
    private let tableViewTopMargin: CGFloat = 15
    private var tableViewBottomMargin: CGFloat = 5
    
    public init(config: DrawerConfig, cancelBlock: (() -> Void)? = nil) {
        assert(config.tableViewDataSource != nil, "tableViewDataSource can't be nil")
        assert(config.tableViewDelegate != nil, "tableViewDelegate can't be nil")
        self.config = config
        self.cancelBlock = cancelBlock
        self.transition = DrawerTransition(backgroundColor: config.backgroundColor)
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = transition
        modalPresentationStyle = .custom
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        calculateContentHeight()
        layoutPageSubviews()
        if !config.isRegular {
            setPanHandle()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// 第一次出现更新 contentHeight
        if !viewAppeared {
            calculateContentHeight()
            if !config.isRegular {
                setCornerRadius()
            }
            viewAppeared = true
        }
    }

    @objc
    func handlePan(pan: UIPanGestureRecognizer) {
        let point = pan.translation(in: containerView)
        switch pan.state {
        case .began:
            startPanTableViewOffset = tableView.contentOffset.y
        case .changed:
            updateContaineViewFrame(point.y)
        case .cancelled, .ended, .failed:
            panEnded()
        default:
            break
        }
    }
    
    @objc
    func handleScrollPan(pan: UIPanGestureRecognizer) {
        let point = pan.translation(in: containerView)
        switch pan.state {
        case .began:
            startPanTableViewOffset = tableView.contentOffset.y
        case .changed:
            updateContaineViewFrame(point.y - startPanTableViewOffset)
        case .cancelled, .ended, .failed:
            panEnded()
        default:
            break
        }
    }

    func updateContaineViewFrame(_ offsetY: CGFloat) {
        let result = originY + offsetY
        let maxY = result + contentHeight
        let margin = 0.0 // 最大展开时允许上拖多少距离
        guard maxY + margin >= view.bounds.height else {
            return
        }
        containerView.frame = CGRect(x: 0, y: result, width: view.frame.width, height: contentHeight)
    }
    
    @objc
    func dismiss(_ gesture: UIGestureRecognizer) {
        dismiss(animated: true, completion: {
            self.cancelBlock?()
        })
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.dataSource = config.tableViewDataSource
        tableView.delegate = config.tableViewDelegate
        tableView.register(config.cellType, forCellReuseIdentifier: NSStringFromClass(config.cellType))
        tableView.bounces = config.isRegular
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = 12
        return tableView
    }()

    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.6)
        return containerView
    }()
    
    private lazy var blurView: BackgroundBlurView = {
        let blurView = BackgroundBlurView()
        blurView.blurRadius = 24
        blurView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.1)
        return blurView
    }()
}


private extension MinutesSelectiveDrawerController {
    func layoutPageSubviews() {
        view.backgroundColor = .clear
        
        addBackgroundControl()
        view.addSubview(containerView)
        containerView.addSubview(blurView)
        containerView.addSubview(tableView)
        if let footerView = config.footerView {
            containerView.addSubview(footerView)
        }
        containerView.snp.makeConstraints { (make) in
            if config.isRegular {
                make.edges.equalToSuperview()
            } else {
                make.top.equalTo(self.view.snp.bottom).offset(-initialShowHeight)
                make.left.right.equalToSuperview()
                make.height.equalTo(contentHeight)
            }
        }
        blurView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }
        if let headerView = config.headerView {
            containerView.addSubview(headerView)
            headerView.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(config.headerViewHeight)
            }
        }
        tableView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(16)
            if let headerView = config.headerView {
                make.top.equalTo(headerView.snp.bottom).offset(tableViewTopMargin)
            } else {
                make.top.equalToSuperview().offset(tableViewTopMargin)
            }
            if config.isRegular {
                make.bottom.equalToSuperview().offset(-16)
            } else {
                make.bottom.equalToSuperview().offset(-tableViewBottomMargin-safeAreaInsetsBottom)
            }
        }
        tableView.isScrollEnabled = isNeedScroll
        if let footerView = config.footerView {
            containerView.addSubview(footerView)
            footerView.snp.makeConstraints { (make) in
                make.top.equalTo(tableView.snp.bottom)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(config.footerViewHeight)
            }
        }

        setCornerRadius()
    }

    // disable-lint: magic number
    func calculateContentHeight() {
        guard let dataSource = config.tableViewDataSource else { return }
        guard let delegate = config.tableViewDelegate else { return }
        let dataSourceCount: Int = dataSource.tableView(tableView, numberOfRowsInSection: 0)
        guard dataSourceCount > 0 else { return }

        var totalCellHeight: CGFloat = 0
        for i in 0..<dataSourceCount {
            totalCellHeight += delegate.tableView?(tableView, heightForRowAt: IndexPath(row: i, section: 0)) ?? 0.0
        }
        tableViewHeight = totalCellHeight
        tableViewBottomMargin = ScreenUtils.hasTopNotch ? 5 : 16
        var height = totalCellHeight + config.headerViewHeight + config.footerViewHeight + tableViewTopMargin + tableViewBottomMargin

        if let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets {
            safeAreaInsetsBottom = safeAreaInsets.bottom
            height += safeAreaInsets.bottom
            height = min(height, view.frame.height - safeAreaInsets.top)
        }
        height = min(height, config.maxContentHeight)
        self.contentHeight = height
        isNeedScroll = config.initialShowHeight < contentHeight
        initialShowHeight = config.initialShowHeight <= contentHeight ? config.initialShowHeight : contentHeight
        self.originY = self.view.frame.height - initialShowHeight
    }
    // enable-lint: magic number
    func addBackgroundControl() {
        let control = UIControl()
        control.backgroundColor = .clear
        control.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        view.addSubview(control)
        control.frame = view.frame
    }

    func setPanHandle() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
        containerView.addGestureRecognizer(pan)
        tableView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan(pan:)))
    }
    

    func setCornerRadius() {
        let rect = CGRect(x: 0, y: 0, width: view.frame.width, height: contentHeight)
        let maskPath = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight],
                                    cornerRadii: CGSize(width: config.cornerRadius, height: config.cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath
        containerView.layer.mask = maskLayer
    }

    func panEnded() {
        let maxTopMargin = UIScreen.main.bounds.height - contentHeight
        if (containerView.frame.minY - originY) > config.thresholdOffset {
            dismiss(animated: true, completion: {
                self.cancelBlock?()
            })
        } else if originY - containerView.frame.minY  > 10 {
           UIView.animate(withDuration: DrawUI.containerFrameAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
               self.containerView.frame = CGRect(x: 0, y: maxTopMargin, width: self.view.frame.width, height: self.contentHeight)
           }) { _ in
               self.originY = self.containerView.frame.minY
           }
        } else {
            UIView.animate(withDuration: DrawUI.containerFrameAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
                self.containerView.frame = CGRect(x: 0, y: self.originY, width: self.view.frame.width, height: self.contentHeight)
            }) { _ in
                self.originY = self.containerView.frame.minY
            }
        }
    }
}

