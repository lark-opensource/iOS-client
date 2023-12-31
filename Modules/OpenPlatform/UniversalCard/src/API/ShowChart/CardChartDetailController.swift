//
//  CardChartDetailController.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/9/26.
//

import Foundation
import LarkUIKit
import UniversalCardInterface
import LKCommonsLogging
import UniverseDesignIcon
import EENavigator
import ECOProbe
import LarkContainer
import LarkFeatureGating
import UniverseDesignColor

class CardChartDetailController: BaseUIViewController {
    
    @FeatureGating("openplatform.card.chart_detail_drakmode_change.enable")
    private var darkModeChangeEnabled: Bool
    
    @FeatureGating("openplatform.universalcard.chart_ui")
    private var chartUIEnabled: Bool
    
    private struct Layout {
        static let containerEdgeTop: CGFloat = 4
        static let containerEdgeBottom: CGFloat = 8
        static let closeBtnEdgeRight: CGFloat = 26
        static let closeBtnSide: CGFloat = 14
    }
    
    private static let logger = Logger.oplog(CardChartDetailController.self, category: "CardChartDetailController")
    
    private var containerData: UniversalCardData
    private var targetElement: UniversalCardConfig.TargetElementConfig
    private var translateConfig: UniversalCardConfig.TranslateConfig
    private let contextKey = "CardChartDetailController" + UUID().uuidString
    private let trace = OPTraceService.default().generateTrace()
    
    private lazy var container: UniversalCard = { UniversalCard.create(resolver: userResolver) }()
    private let logger = Logger.log(UniversalCard.self, category: "CardChartDetailController")

    private lazy var card: UniversalCard = { UniversalCard.create(resolver: userResolver) }()

    private let userResolver: UserResolver

    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UDIcon.getIconByKey(.closeOutlined), for: .normal)
        closeButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        closeButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
        return closeButton
    }()
    
    init(
        userResolver: UserResolver,
        containerData: UniversalCardData,
        targetElement: UniversalCardConfig.TargetElementConfig,
        translateConfig: UniversalCardConfig.TranslateConfig
    ) {
        self.userResolver = userResolver
        self.containerData = containerData
        self.targetElement = targetElement
        self.translateConfig = translateConfig
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if chartUIEnabled {
            view.backgroundColor = UIColor.ud.rgb("#ffffff") & UIColor.ud.rgb("#1f2329")
        }
        setupView()
        if #unavailable(iOS 16.0) {
            innerUpdateDeviceOrientation(.landscapeRight)
        }
    }
    
    private func setupView() {
        let size = chartDetailViewSize()
        let layout = UniversalCardLayoutConfig(preferWidth: size.width, preferHeight: size.height, maxHeight: nil)
        let context = UniversalCardContext(key: contextKey, trace: trace, sourceData: containerData, sourceVC: self, dependency: nil, renderBizType: nil, bizContext: nil)
        let config = UniversalCardConfig(
            width: size.width,
            height: size.height,
            translateConfig: translateConfig,
            actionEnable: true,
            actionDisableMessage: nil,
            targetElement: targetElement
        )
        let source = (containerData, context, config)
        container.updateMode(layoutConfig: layout)
        container.render(layout: layout, source: source, lifeCycle: nil)
        self.view.addSubview(container.getView())
        let safeAreaTop = userResolver.navigator.mainSceneWindow?.safeAreaInsets.top ?? 0
        let edgeLeftOrRight = Layout.closeBtnSide + Layout.closeBtnEdgeRight
        if Display.pad {
            if chartUIEnabled {
                container.getView().snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(safeAreaTop)
                    make.left.right.equalToSuperview().inset(edgeLeftOrRight)
                    make.bottom.equalToSuperview().offset(-Layout.containerEdgeBottom)
                }
            } else {
                container.getView().snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(safeAreaTop)
                    make.left.bottom.right.equalToSuperview()
                }
            }
        } else {
            if chartUIEnabled {
                container.getView().snp.makeConstraints({ make in
                    make.top.equalToSuperview().offset(Layout.containerEdgeTop)
                    make.right.equalToSuperview().offset(-edgeLeftOrRight)
                    make.left.equalToSuperview().offset(safeAreaTop)
                    make.bottom.equalToSuperview().offset(-Layout.containerEdgeBottom)
                })
            } else {
                container.getView().snp.makeConstraints({ make in
                    make.top.bottom.right.equalToSuperview()
                    make.left.equalToSuperview().offset(safeAreaTop)
                })
            }
        }
        self.view.addSubview(self.closeButton)
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.closeBtnSide)
            make.top.equalToSuperview().offset(Display.phone ? 17 : safeAreaTop + 7)
            make.trailing.equalToSuperview().offset(-Layout.closeBtnEdgeRight)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard Display.pad else {
            return
        }
        updateChartDetailLayout()
    }
    
    private func updateChartDetailLayout() {
        let size = chartDetailViewSize()
        let layoutConfig = UniversalCardLayoutConfig(preferWidth: size.width, preferHeight: size.height, maxHeight: nil)
        card.updateLayout(layoutConfig: layoutConfig)
    }
    
    private func chartDetailViewSize() -> CGSize {
        let safeAreaTop = userResolver.navigator.mainSceneWindow?.safeAreaInsets.top ?? 0
        let edgeLeftOrRight = Layout.closeBtnSide + Layout.closeBtnEdgeRight
        var width: CGFloat = 0
        var height: CGFloat = 0
        if Display.pad {
            let superviewSz = view.frame.size
            if chartUIEnabled {
                width = superviewSz.width - 2 * edgeLeftOrRight
                height = superviewSz.height - safeAreaTop - Layout.containerEdgeBottom
            } else {
                width = superviewSz.width
                height = superviewSz.height - safeAreaTop
            }
        } else {
            let screenSz = UIScreen.main.bounds.size
            if chartUIEnabled {
                width = screenSz.height - safeAreaTop - edgeLeftOrRight
                height = screenSz.width - Layout.containerEdgeTop - Layout.containerEdgeBottom
            } else {
                width = screenSz.height - safeAreaTop
                height = screenSz.width
            }
        }
        return CGSize(width: width, height: height)
    }
    
    @objc private func hide() {
        self.dismiss(animated: false, completion: nil)
        if #unavailable(iOS 16.0) {
            self.innerUpdateDeviceOrientation(.portrait)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    /// iOS15及以下系统的转屏方法，使用UIDevice做旋转
    private func innerUpdateDeviceOrientation(_ orientation: UIInterfaceOrientation) {
        let value = orientation.rawValue
        Self.logger.info("updateDeviceOrientation to \(value), isAutomatic = \(orientation)")
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if darkModeChangeEnabled {
            if #available(iOS 13.0, *),
               let previousTraitCollection = previousTraitCollection,
               previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                card.render()
                Self.logger.info("traitCollectionDidChange hasDifferentColorAppearance")
            }
        }
    }
}
