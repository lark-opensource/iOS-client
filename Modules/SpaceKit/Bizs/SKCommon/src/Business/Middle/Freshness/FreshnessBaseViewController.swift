//
//  FreshnessBaseViewController.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/8/11.
//  

import SKFoundation
import SKUIKit
import SKResource
import SpaceInterface
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignDialog
import UniverseDesignToast
import UniverseDesignDatePicker
import EENavigator
import RxSwift

class FreshnessBaseViewController: SKTranslucentPanelController {

    enum Layout {
        static let headerHeight: CGFloat = 48
        static let itemHeight: CGFloat = 46
        static let panelWidthForPad: CGFloat = 540
        static let offset_16: CGFloat = 16
        static let offset_24: CGFloat = 24
        static var buttonHeight_48: CGFloat = 48
        static var buttonHeight_40: CGFloat = 40
    }

    var supportOrientations: UIInterfaceOrientationMask = .portrait {
        didSet {
            if SKDisplay.phone && supportOrientations != .portrait {
                dismissalStrategy = []
            } else {
                dismissalStrategy = [.viewSizeChanged]
            }
        }
    }

    lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = .clear
        return view
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.iconDisabled), for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.primaryContentDefault), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        return button
    }()

    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.setTitleColor(UDColor.textDisabled, for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.bgBody), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        return button
    }()

    let disposeBag = DisposeBag()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateContentWith()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateContentWith()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(Layout.headerHeight)
        }
    }

    override func transitionToRegularSize() {
        super.transitionToRegularSize()
        if modalPresentationStyle == .formSheet {
            containerView.backgroundColor = UDColor.bgBase
        }
    }

    /// 设置container宽度（iPhone横竖屏切换需要更新宽度）
    private func updateContentWith() {
        if SKDisplay.phone, LKDeviceOrientation.isLandscape() {
            containerView.snp.remakeConstraints { (make) in
                make.centerX.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
            }
        } else {
            containerView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }
        }
    }
}
