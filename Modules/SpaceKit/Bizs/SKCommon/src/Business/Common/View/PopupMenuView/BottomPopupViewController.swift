//
//  BottomPopupViewController.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/30.
//

import SKUIKit
import UniverseDesignColor

public protocol BottomPopupViewControllerDelegate: AnyObject {
    func bottomPopupViewControllerDidConfirm(_ bottomPopupViewController: BottomPopupViewController)
    func bottomPopupViewControllerClosed(_ bottomPopupViewController: BottomPopupViewController)
    func bottomPopupViewControllerOnClick(_ bottomPopupViewController: BottomPopupViewController, at url: URL) -> Bool
}

public final class BottomPopupViewController: UIViewController {

    // MARK: - properties
    private let blankView: UIControl = UIControl()
    public weak var delegate: BottomPopupViewControllerDelegate?
    private let permStatistics: PermissionStatistics?

    // MARK: - Life cycle
    public var config: PopupMenuConfig

    public init(config: PopupMenuConfig, permStatistics: PermissionStatistics?) {
        self.config = config
        self.permStatistics = permStatistics
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
    }

    var menuHeight: CGFloat = 205

    let contentView: UIView = UIView()
    private var menuView: BottomPopupMenuView?
    lazy var panGestureRecognizer: UIPanGestureRecognizer = { // 拖动手势
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 1
        return panGestureRecognizer
    }()

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        menuHeight = 205 + (view.window?.safeAreaInsets.bottom ?? 0.0)
        configBlankView()
        configContentView()
        configMenuView()
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.1) {
            self.blankView.backgroundColor = UDColor.bgMask
            self.contentView.snp.updateConstraints({ (make) in
                make.bottom.equalToSuperview()
            })
            self.view.layoutIfNeeded()
        }
    }

    private func configBlankView() {
        blankView.addTarget(self, action: #selector(blankDidClick), for: .touchUpInside)
        view.addSubview(blankView)
        blankView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func configContentView() {
        contentView.backgroundColor = UDColor.bgBody
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
        view.addSubview(contentView)

        let safeAreaInsets = self.view.window?.safeAreaInsets ?? .zero
        let horizMargin = max(safeAreaInsets.left, safeAreaInsets.right)
        contentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(horizMargin)
            make.right.equalToSuperview().offset(-horizMargin)
            make.height.equalTo(menuHeight)
            make.bottom.equalToSuperview().offset(menuHeight)
        }
    }

    public func getMenuView() -> BottomPopupMenuView {
        return menuView ?? BottomPopupMenuView(config: config)
    }

    private func configMenuView() {
        let menu = BottomPopupMenuView(config: config)
        self.menuView = menu
        menu.delegate = self
        menu.titleView.addGestureRecognizer(panGestureRecognizer)
        contentView.addSubview(menu)

        menu.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(contentView)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    // MARK: - Actions
    @objc
    private func blankDidClick() {
        dismiss()
    }

    private func dismiss() {
        self.permStatistics?.reportPermissionShareAtPeopleClick(click: .close, target: .noneTargetView)
        UIView.animate(withDuration: 0.1, animations: {
            self.blankView.alpha = 0
            self.contentView.snp.updateConstraints({ (make) in
                make.bottom.equalToSuperview().offset(self.menuHeight)
            })
            self.view.layoutIfNeeded()
        }, completion: { (_) in
            self.dismiss(animated: true)
        })
    }

    @objc
    func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        let position = gestureRecognizer.translation(in: view)
        if gestureRecognizer.state == .changed, position.y >= 0 {
            contentView.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(position.y)
            }
        } else if gestureRecognizer.state == .ended, position.y >= 0 {
            dismiss()
        }
    }
}

// MARK: - Delegate
extension BottomPopupViewController: BottomPopupVCMenuDelegate {
    public func menuDidClickSendLark(_ menu: BottomPopupMenuView) {
        config.sendLark = !config.sendLark
    }

    public func menuDidConfirm(_ menu: BottomPopupMenuView) {
        self.permStatistics?.reportPermissionShareAtPeopleClick(click: .confirm,
                                                                target: .noneTargetView,
                                                                isSendNotice: config.sendLark)
        delegate?.bottomPopupViewControllerDidConfirm(self)
        dismiss()
    }

    public func menuClosed(_ menu: BottomPopupMenuView) {
        delegate?.bottomPopupViewControllerClosed(self)
        dismiss()
    }
    public func menuOnClick(_ menu: BottomPopupMenuView, at url: URL) -> Bool {
        return delegate?.bottomPopupViewControllerOnClick(self, at: url) ?? true
    }
}
