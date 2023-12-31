//
//  SelectiveDrawerController.swift
//  LarkUIKit
//
//  Created by shizhengyu on 2020/4/3.
//

import UIKit
import Foundation

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

    public init(backgroundColor: UIColor = UIColor(white: 0, alpha: 0.3),
                cornerRadius: CGFloat,
                thresholdOffset: CGFloat,
                maxContentHeight: CGFloat,
                cellType: AnyClass,
                tableViewDataSource: UITableViewDataSource,
                tableViewDelegate: UITableViewDelegate,
                headerView: UIView? = nil,
                footerView: UIView? = nil,
                headerViewHeight: CGFloat = 0,
                footerViewHeight: CGFloat = 0) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.thresholdOffset = thresholdOffset
        self.maxContentHeight = maxContentHeight
        self.cellType = cellType
        self.tableViewDataSource = tableViewDataSource
        self.tableViewDelegate = tableViewDelegate
        self.headerView = headerView
        self.footerView = footerView
        self.headerViewHeight = headerViewHeight
        self.footerViewHeight = footerViewHeight
    }
}

private enum UI {
    static let statusBarHeight: CGFloat = 20
    static let containerFrameAnimationDuration = 0.25
}

open class SelectiveDrawerController: UIViewController {
    private let config: DrawerConfig
    private let transition: DrawerTransition
    private var startPanTableViewOffset: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private let cancelBlock: (() -> Void)?
    public var cellReuseIdentifier: String {
        return NSStringFromClass(config.cellType)
    }

    private var viewAppeared: Bool = false

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
        setPanHandle()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// 第一次出现更新 contentHeight
        if !viewAppeared {
            calculateContentHeight()
            setCornerRadius()
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
            updateContaineViewFrame(point.y - startPanTableViewOffset)
        case .cancelled, .ended, .failed:
            panEnded()
        default:
            break
        }
    }

    @objc
    func dismiss(_ gesture: UIGestureRecognizer) {
        dismiss(animated: true, completion: {
            self.cancelBlock?()
        })
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.dataSource = config.tableViewDataSource
        tableView.delegate = config.tableViewDelegate
        tableView.register(config.cellType, forCellReuseIdentifier: NSStringFromClass(config.cellType))
        tableView.estimatedRowHeight = 0
        tableView.bounces = false

        return tableView
    }()

    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.N00
        return containerView
    }()

    private lazy var originY: CGFloat = {
        return view.frame.height - contentHeight
    }()
}

private extension SelectiveDrawerController {
    func layoutPageSubviews() {
        addBackgroundControl()
        view.addSubview(containerView)
        containerView.addSubview(tableView)
        if let footerView = config.footerView {
            containerView.addSubview(footerView)
        }
        containerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentHeight)
        }
        if let headerView = config.headerView {
            containerView.addSubview(headerView)
            headerView.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(config.headerViewHeight)
            }
        }
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            if let headerView = config.headerView {
                make.top.equalTo(headerView.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
            if let footerView = config.footerView {
                make.bottom.equalTo(footerView.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }
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

    func calculateContentHeight() {
        guard let dataSource = config.tableViewDataSource else { return }
        guard let delegate = config.tableViewDelegate else { return }
        let dataSourceCount: Int = dataSource.tableView(tableView, numberOfRowsInSection: 0)
        guard dataSourceCount > 0 else { return }

        var totalCellHeight: CGFloat = 0
        for i in 0..<dataSourceCount {
            totalCellHeight += delegate.tableView?(tableView, heightForRowAt: IndexPath(row: i, section: 0)) ?? 0.0
        }
        var height = totalCellHeight + config.headerViewHeight + config.footerViewHeight
        height = min(height, view.frame.height - UI.statusBarHeight)

        if let safeAreaInsets = self.view.window?.safeAreaInsets {
            height += safeAreaInsets.bottom
            height = min(height, view.frame.height - safeAreaInsets.top)
        }
        height = min(height, config.maxContentHeight)
        self.contentHeight = height
    }

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
        tableView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(pan:)))
    }

    func updateContaineViewFrame(_ offsetY: CGFloat) {
        let result = originY + offsetY
        let finalY = max(originY, result)
        containerView.frame = CGRect(x: 0, y: finalY, width: view.frame.width, height: contentHeight)
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
        if (containerView.frame.minY - originY) > config.thresholdOffset {
            dismiss(animated: true, completion: {
                self.cancelBlock?()
            })
        } else {
            UIView.animate(withDuration: UI.containerFrameAnimationDuration, delay: 0, options: .curveEaseInOut, animations: {
                self.containerView.frame = CGRect(x: 0, y: self.originY, width: self.view.frame.width, height: self.contentHeight)
            })
        }
    }
}
