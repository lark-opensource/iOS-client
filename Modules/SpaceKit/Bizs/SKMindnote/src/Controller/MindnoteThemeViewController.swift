//
//  MindnoteThemeViewController.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/9/4.
//  

import UIKit
import SnapKit
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor

enum ThemeType: String {
    case structure
    case theme
    case close //关闭主题
}

protocol ThemeCardDelegate: AnyObject {
    func excuteJsCallBack(type: ThemeType, key: String)
    func themeCardClosed()
}

class MindnoteThemeViewController: SKWidgetViewController {
    private let containerHeight: CGFloat = 180
    private lazy var headerView = SKPanelHeaderView()
    private lazy var structureView = MindnoteStructureSelectView()
    private weak var delegate: ThemeCardDelegate?
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    init(delegate: ThemeCardDelegate, hostViewController: UIViewController) {
        self.delegate = delegate
        super.init(contentHeight: containerHeight)
        headerView.setCloseButtonAction(#selector(close), target: self)
        headerView.setTitle(BundleI18n.SKResource.CreationMobile_MindNotes_Menu_title)
        // 设置当前的safeAreaInset用于初始化，具体数值需要等到viewSafeAreaInsetsDidChange方法触发更新
        self.topSafeAreaHeight = hostViewController.view.safeAreaInsets.top
        self.bottomSafeAreaHeight = hostViewController.view.safeAreaInsets.bottom
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubViews()
        if SKDisplay.pad, modalPresentationStyle == .popover {
            contentView.backgroundColor = UDColor.bgFloat
            structureView.optionBackgroundColor = UDColor.bgFloatOverlay
            headerView.backgroundColor = UDColor.bgFloat
            preferredContentSize = CGSize(width: 374.5, height: contentHeight)
            headerView.toggleCloseButton(isHidden: true)
            backgroundView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            contentView.snp.updateConstraints { (make) in
                make.height.equalTo(contentHeight)
            }
        }
    }

    private func setupSubViews() {
        if SKDisplay.pad, modalPresentationStyle == .popover {
            contentView.backgroundColor = UDColor.bgBody
        } else {
            backgroundView.backgroundColor = .clear
            contentView.backgroundColor = UDColor.bgBody
            contentView.layer.cornerRadius = 12
            contentView.layer.maskedCorners = .top
            resetContentHeight(orentation: UIApplication.shared.statusBarOrientation)
        }
        setupContainerView(contentView)
    }

    private func setupContainerView(_ container: UIView) {
        container.addSubview(headerView)
        container.addSubview(structureView)

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        structureView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
        }
    }
    
    public func resetContentHeight(orentation: UIInterfaceOrientation) {
        guard SKDisplay.phone else { return }
        if orentation.isLandscape {
            contentView.snp.remakeConstraints { (make) in
                make.width.equalToSuperview().multipliedBy(0.7)
                make.centerX.equalToSuperview()
                make.height.equalTo(contentHeight + bottomSafeAreaHeight + 20)
                make.bottom.equalToSuperview().offset(20)
            }
        } else {
            contentView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.backgroundView.safeAreaLayoutGuide)
                make.height.equalToSuperview()
            }
        }
    }

    func updateDatas(_ model: MindnoteThemeModel) {
        structureView.selectStructure = { [weak self](key) in
            self?.delegate?.excuteJsCallBack(type: .structure, key: key)
        }
        structureView.updateStructure(model)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.themeCardClosed()
        self.delegate?.excuteJsCallBack(type: .close, key: "")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard SKDisplay.pad else { return }
        close()
    }
    
    @objc
    private func didChangeStatusBarOrientation(_ notification: Notification) {
        guard SKDisplay.phone else { return }
        resetContentHeight(orentation: UIApplication.shared.statusBarOrientation)
    }

    @objc
    private func close() {
        dismiss(animated: true, completion: nil)
    }

}
