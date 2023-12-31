//
//  SelectiveDrawerController.swift
//  ByteView
//
//  Created by helijian on 2021/11/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUI

struct DrawerConfig {
    var backgroundColor: UIColor
    let cornerRadius: CGFloat
    let thresholdOffset: CGFloat // 下滑dismiss距离
    let maxContentHeight: CGFloat
    let cellType: AnyClass
    var tableViewDataSource: UITableViewDataSource?
    var tableViewDelegate: UITableViewDelegate?
    var headerText: String?
    init(backgroundColor: UIColor,
         cornerRadius: CGFloat,
         thresholdOffset: CGFloat,
         maxContentHeight: CGFloat,
         cellType: AnyClass,
         tableViewDataSource: UITableViewDataSource,
         tableViewDelegate: UITableViewDelegate,
         headerText: String) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.thresholdOffset = thresholdOffset
        self.maxContentHeight = maxContentHeight
        self.cellType = cellType
        self.tableViewDataSource = tableViewDataSource
        self.tableViewDelegate = tableViewDelegate
        self.headerText = headerText
    }
}

//临时不支持跟随下面VC转屏，TODO: Chenyizhuo
class SelectiveDrawerController: BaseViewController {
    private let config: DrawerConfig
    private let transition: DrawerTransition
    private var startPanTableViewOffset: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var headerViewHeight: CGFloat = 49
    private var statusBarHeight: CGFloat = 88
    private var viewAppeared: Bool = false
    private let dismissCallBack: (() -> Void)?
    init(config: DrawerConfig, dismissCallBack: (() -> Void)? = nil) {
        self.config = config
        self.dismissCallBack = dismissCallBack
        self.transition = DrawerTransition(backgroundColor: config.backgroundColor)
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = transition
        modalPresentationStyle = .custom
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        calculateContentHeight()
        layoutViews()
        setPanHandle()
        view.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewAppeared {
            calculateContentHeight()
            setCornerRadius()
            viewAppeared = true
        }
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = config.tableViewDataSource
        tableView.delegate = config.tableViewDelegate
        tableView.register(config.cellType, forCellReuseIdentifier: NSStringFromClass(config.cellType))
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

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    private lazy var splitLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .left
        label.text = config.headerText
        label.backgroundColor = UIColor.ud.bgFloat
        return label
    }()

    func layoutViews() {
        addBackgroundControl()
        view.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(contentHeight)
        }
        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(headerViewHeight)
        }
        headerView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(11)
            make.left.right.equalToSuperview().inset(16)
        }
        headerView.addSubview(splitLine)
        splitLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        containerView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        setCornerRadius()
    }

    func addBackgroundControl() {
        let control = UIControl()
        control.backgroundColor = .clear
        control.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        view.addSubview(control)
        control.frame = view.frame
    }

    func calculateContentHeight() {
        guard let dataSource = config.tableViewDataSource else { return }
        guard let delegate = config.tableViewDelegate else { return }
        let dataSourceCount: Int = dataSource.tableView(tableView, numberOfRowsInSection: 0)
        guard dataSourceCount > 0 else { return }
        var totalCellHeight: CGFloat = 0
        for i in 0 ..< dataSourceCount {
            totalCellHeight += delegate.tableView?(tableView, heightForRowAt: IndexPath(row: i, section: 0)) ?? 0.0
        }
        var height = totalCellHeight + headerViewHeight
        height = min(height, view.frame.height - statusBarHeight)
        if let safeAreaInsets = self.view.window?.safeAreaInsets {
            height += safeAreaInsets.bottom
            height = min(height, view.frame.height - safeAreaInsets.top)
        }
        height = min(height, config.maxContentHeight)
        self.contentHeight = height
    }

    private func setCornerRadius() {
        let rect = CGRect(x: 0, y: 0, width: view.frame.width, height: contentHeight)
        let maskPath = UIBezierPath(roundedRect: rect, byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight], cornerRadii: CGSize(width: config.cornerRadius, height: config.cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath
        containerView.layer.mask = maskLayer
    }

    private func setPanHandle() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        containerView.addGestureRecognizer(pan)
        tableView.panGestureRecognizer.addTarget(self, action: #selector(handlePan))
    }

    private func updateContainerViewFrame(_ offsetY: CGFloat) {
        let result = originY + offsetY
        let finanY = max(originY, result)
        containerView.frame = CGRect(x: 0, y: finanY, width: view.frame.width, height: contentHeight)
    }

    private func panEnd() {
        if (containerView.frame.minY - originY) > config.thresholdOffset {
            self.dismissCallBack?()
            dismiss(animated: true, completion: nil)
        } else {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                self.containerView.frame = CGRect(x: 0, y: self.originY, width: self.view.frame.width, height: self.contentHeight)
            })
        }
    }

    @objc
    func handlePan(pan: UIPanGestureRecognizer) {
        let point = pan.translation(in: containerView)
        switch pan.state {
        case .began:
            startPanTableViewOffset = tableView.contentOffset.y
        case .changed:
            updateContainerViewFrame(point.y - startPanTableViewOffset)
        case .cancelled, .ended, .failed:
            panEnd()
        default:
            break
        }
    }

    @objc
    func dismissVC(_ gesture: UIGestureRecognizer) {
        self.dismissCallBack?()
        dismiss(animated: true, completion: nil)
    }
}

private class DrawerPresentationController: UIPresentationController {

    private let dimmingView = UIView()

    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         backgroundColor: UIColor = UIColor(white: 0, alpha: 0.3)) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dimmingView.backgroundColor = backgroundColor
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        presentingViewController.view.tintAdjustmentMode = .dimmed
        dimmingView.alpha = 0
        containerView?.addSubview(dimmingView)
        let coordinator = presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = containerView {
            dimmingView.frame = containerView.frame
        }
    }
}

class DrawerTransition: NSObject, UIViewControllerTransitioningDelegate {
    private let backgroundColor: UIColor

    init(backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
    }

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            return DrawerPresentationController(presentedViewController: presented,
                                                presenting: presenting,
                                                backgroundColor: backgroundColor)
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

class DrawerSelectiveCell: UITableViewCell {

    private lazy var langNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layoutViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(langNameLabel)
        langNameLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
    }

    func configCell(language: String) {
        langNameLabel.attributedText = NSAttributedString(string: language, config: .body)
    }
}

class SelectTargetDrawerCenter: NSObject, UITableViewDataSource, UITableViewDelegate {
    typealias CallBack = (Int) -> Void

    fileprivate enum Layout {
        static let cornerRadius: CGFloat = 12
        static let thresholdOffset: CGFloat = 120
        static let maxHeightFactor: CGFloat = 0.7
        static let maxContentHeight: CGFloat = VCScene.bounds.height * Layout.maxHeightFactor
        static let cellHeight: CGFloat = 48
        static let headerText: String = I18n.View_MV_TranslateContentTo_SelectPage
    }

    private let languages: [String]
    private let dismissCallBack: (() -> Void)?
    private let selectedCallBack: CallBack?
    private let router: Router
    init(router: Router, languages: [String], dismissCallBack: (() -> Void)? = nil, selectedCallBack: CallBack? = nil) {
        self.router = router
        self.languages = languages
        self.dismissCallBack = dismissCallBack
        self.selectedCallBack = selectedCallBack
    }

    private weak var currentDrawer: SelectiveDrawerController?
    func showSelectDrawer() {
        let config = DrawerConfig(backgroundColor: UIColor.ud.bgMask,
                                  cornerRadius: Layout.cornerRadius,
                                  thresholdOffset: Layout.thresholdOffset,
                                  maxContentHeight: Layout.maxContentHeight,
                                  cellType: DrawerSelectiveCell.self,
                                  tableViewDataSource: self,
                                  tableViewDelegate: self,
                                  headerText: Layout.headerText)
        let drawerVC = SelectiveDrawerController(config: config, dismissCallBack: self.dismissCallBack)
        self.currentDrawer = drawerVC
        guard let topVC = router.topMost else { return }
        topVC.present(drawerVC, animated: true, completion: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let language = languages[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DrawerSelectiveCell.self)) as? DrawerSelectiveCell {
            cell.configCell(language: language)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentDrawer?.dismiss(animated: true, completion: nil)
        selectedCallBack?(indexPath.row)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.cellHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
