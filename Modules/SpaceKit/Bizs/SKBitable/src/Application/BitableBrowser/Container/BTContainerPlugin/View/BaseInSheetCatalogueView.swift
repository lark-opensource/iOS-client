//
//  BaseInSheetCatalogueView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/7.
//

import Foundation
import SKFoundation
import UniverseDesignColor
import SKCommon
import UniverseDesignTheme
import SKUIKit
import HandyJSON

class BaseInSheetCatalogueView: UIView {
    private var currentViewData: BTViewContainerModel?
    
    var moreClick: (() -> Void)?
    var viewCatalogSelect: ((Int) -> Void)?

    private class Constains {
        static let viewCatalogueHeight: CGFloat = 60.0
        static let toolbarHeight: CGFloat = 36.0
    }
    
    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()

    private lazy var contentView: UIStackView = {
        let view = UIStackView()
        view.spacing = 0
        view.axis = .vertical
        view.backgroundColor = .clear
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var viewCatalogueContainer: ViewCatalogueContainer = {
        let view = ViewCatalogueContainer(yOffset: 2)
        view.gradientLayer.isHidden = true
        view.delegate = self
        return view
    }()

    private(set) lazy var viewToolBar: ViewToolBar = {
        let view = ViewToolBar()
        return view
    }()

    override var bounds: CGRect {
        didSet {
            guard bounds != .zero else {
                return
            }

            updateGradient()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        remakConstraints()
    }

    private func setup() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(updateLayerColor), name: UDThemeManager.didChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(updateLayerColor), name: Notification.Name.DocsThemeChanged, object: nil)
        }
        
        layer.addSublayer(gradientLayer)
        addSubview(contentView)

        contentView.addArrangedSubview(viewCatalogueContainer)
        contentView.addArrangedSubview(viewToolBar)
        viewCatalogueContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(Constains.viewCatalogueHeight)
        }
        viewToolBar.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(Constains.toolbarHeight)
        }
        remakConstraints()
    }
    
    @objc
    private func statusBarOrientationChange() {
        remakConstraints()
    }
    
    private func remakConstraints() {
        guard contentView.superview != nil else { return }
        let orientation = LKDeviceOrientation.getInterfaceOrientation()
        let leftInset = orientation == .landscapeRight ? self.safeAreaInsets.left : 0
        let rightInset = orientation == .landscapeLeft ? self.safeAreaInsets.right : 0
        contentView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().inset(leftInset)
            make.right.equalToSuperview().inset(rightInset)
            make.bottom.equalToSuperview()
        }
        
        updateLayerColor()
        updateGradient()
    }

    private func updateGradient() {
        // 只需要一个视图栏的高度，工具栏另有自己的渐变色
        let orientation = LKDeviceOrientation.getInterfaceOrientation()
        let leftInset = orientation == .landscapeRight ? self.safeAreaInsets.left : 0
        let rightInset = orientation == .landscapeLeft ? self.safeAreaInsets.right : 0
        gradientLayer.frame = CGRectMake(leftInset, 0, self.bounds.width - leftInset - rightInset, Constains.viewCatalogueHeight)
    }

    func updateCurrentViewData(currentViewData: BTViewContainerModel?) {
        var animated = true
        if self.currentViewData?.tableId == nil {
            // 第一次进来，不需要动画
            animated = false
        } else if let lastTableId = self.currentViewData?.tableId, lastTableId != currentViewData?.tableId {
            // 不是第一次加载，并且tableId不同，代表切表
            animated = false
        }
        self.currentViewData = currentViewData
        guard let currentViewData = currentViewData else {
            return
        }
        viewCatalogueContainer.setData(currentViewData: currentViewData, animated: animated)
    }
}

extension BaseInSheetCatalogueView: ViewCatalogueDelegate {
    func viewCatalogueMoreClick(sourceView: UIView) {
        moreClick?()
    }

    func viewCatalogue(sourceView: UIView, didSelect index: Int) {
        viewCatalogSelect?(index)
    }
    
    @objc
    func updateLayerColor() {
        let isDark = UIColor.docs.isCurrentDarkMode
        let top = (isDark ? UIColor(hexString: "#242629") : UDColor.bgFloatBase) ?? .clear
        let bottom = (isDark ? UIColor(hexString: "#202123") : UIColor(hexString: "#F7F9FA")) ?? .clear
        gradientLayer.ud.setColors([top, bottom])
    }
}
