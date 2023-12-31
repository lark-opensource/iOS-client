//
//   AlertController.swift
//   Alert
//
//  Created by WangXiaoZhen on 2018/1/20.
//  Copyright © 2018年 WangXiaoZhen. All rights reserved.
//

import UIKit
import SKFoundation
import EENavigator
import UniverseDesignColor

/*
 使用方法:
 let alertVC =  DocsAlertController()
 let item1 =  AlertAction(title: "添加到", style: .normal, handler: { print("添加到") })
 alertVC.addAction(item1)
 self.present(alertVC, animated: true, completion: nil)
 **/
public typealias ActionHandler = () -> Void

public enum AlertDirection: Int {
    case vertical
    case horizontal
}

public enum AlertActionStyle: Int {
    case normal
    case notenabled
    case option
    case destructive
}

public protocol AlertActionDelegate: AnyObject {
    func alertDismiss()
    func getAlertAction() -> [ AlertAction]
    func getItemHeightFor(_ action: AlertAction) -> CGFloat
    func getTitleColor() -> UIColor
    func getItemColor() -> UIColor
    func getAlertDirection() -> AlertDirection
    func checkDestructiveUsingDifferentColor() -> Bool
}

public final class AlertAction {
    public var title: String?
    public var titleFont: UIFont?
    public var horizontalAlignment: UIControl.ContentHorizontalAlignment?
    public var image: UIImage?
    public var isSelected: Bool?
    public var canBeSelected: Bool?
    public var style = AlertActionStyle.normal
    public var handler: ActionHandler?
    public var needRedPoint: Bool = false
    public var subtitle: String?
    public var needSeparateLine: Bool = false

    public init(title: String, image: UIImage?, handler: ActionHandler?) {
        self.title = title
        self.image = image
        self.handler = handler
    }

    convenience public init(title: String, handler: ActionHandler?) {
        self.init(title: title, image: nil, handler: handler)
    }

    convenience public init(title: String, style: AlertActionStyle, handler: ActionHandler?) {
        self.init(title: title, image: nil, handler: handler)
        self.style = style
    }

    convenience public init(title: String,
                            style: AlertActionStyle,
                            horizontalAlignment: UIControl.ContentHorizontalAlignment,
                            isSelected: Bool,
                            canBeSelected: Bool,
                            needSeparateLine: Bool = false,
                            handler: ActionHandler?) {
        self.init(title: title, style: style, handler: handler)
        self.horizontalAlignment = horizontalAlignment
        self.isSelected = isSelected
        self.canBeSelected = canBeSelected
        self.needSeparateLine = needSeparateLine
    }
}

protocol AlertControllerDelegate: AnyObject {
    func didDismiss(_ alertController: DocsAlertController)
}

// 对于垂直方向的提示框，请使用LarkActionSheet.ActionSheet，确保样式统一
// DocsAlertController仅用于水平方向的提示框
public final class DocsAlertController: UIViewController {
    weak var delegate: AlertControllerDelegate?

    private var itemHeight = CGFloat(50)
    private var titleColor = UDColor.textTitle
    private var itemColor = UIColor.ud.N00
    private var destructiveUsingDifferentColor = true
    private var actions: [AlertAction] = []
    private var direction: AlertDirection = .vertical
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy internal var alertView: AlertView! = {
        let alertView = AlertView(frame: .zero, delegate: self)
        alertView.layer.cornerRadius = 12
        alertView.layer.maskedCorners = .top
        return alertView
    }()
    lazy var dimBackgroundView: UIControl = {
        let control = UIControl(frame: CGRect(x: 0,
                                              y: 0,
                                              width: Navigator.shared.mainSceneWindow?.frame.width ?? 0,
                                              height: Navigator.shared.mainSceneWindow?.frame.height ?? 0))
        control.backgroundColor = self.modalPresentationStyle == .popover ? UDColor.bgFloat : UDColor.bgMask
        control.addTarget(self, action: #selector(touchBackGround), for: .touchDown)
        return control
    }()
    public let watermarkConfig = WatermarkViewConfig()
    public init(direction: AlertDirection = .vertical) {
        super.init(nibName: nil, bundle: nil)
        self.direction = direction
        transitioningDelegate = self
        modalPresentationStyle = .custom
        modalTransitionStyle = .coverVertical
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resetAlertViewFrame()
        dimBackgroundView.frame = CGRect(x: 0,
                                         y: 0,
                                         width: view.frame.width,
                                         height: view.frame.height)
        alertView.setAlertView(alertView.bounds.width)
        alertView.backgroundColor = self.modalPresentationStyle == .popover ? UDColor.bgFloat : UDColor.bgBody
        if modalPresentationStyle == .popover {
            preferredContentSize = CGSize(width: 375, height: heightForAlertView())
        }

    }
    override public func viewDidLoad() {
        super.viewDidLoad()
        guard self.actions.count > 0 else {
            spaceAssertionFailure("Must addAction")
            return
        }
        view.backgroundColor = UIColor.clear
        view.addSubview(dimBackgroundView)
        view.addSubview(alertView)
        alertView.setAlertView(view.frame.width)
        watermarkConfig.add(to: view)
    }

    @objc
    public func touchBackGround() {
        delegate?.didDismiss(self)
        dismiss(animated: true, completion: nil)
    }

    func heightForAlertView() -> CGFloat {
        var alertViewHeight: CGFloat = 0
        if self.direction == .vertical {
            self.actions.forEach { (action) in
                alertViewHeight += getItemHeightFor(action)
            }
        }
        if let headerView = alertView.headerView { alertViewHeight += headerView.frame.size.height }
        if modalPresentationStyle != .popover {
            alertViewHeight += view.safeAreaInsets.bottom
        }
        return alertViewHeight
    }

    private func resetAlertViewFrame() {
        let height = heightForAlertView()
        let y = (modalPresentationStyle == .popover) ? 0 : view.frame.height - height
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            alertView.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
                make.height.equalTo(height)
                make.top.equalToSuperview().offset(y)
            }
        } else {
            alertView.snp.remakeConstraints { (make) in
                make.left.right.equalTo(view.safeAreaLayoutGuide)
                make.height.equalTo(height)
                make.top.equalToSuperview().offset(y)
            }
        }
    }
    
    public func didChangeOrentation() {
        guard SKDisplay.phone else {
            return
        }
        resetAlertViewFrame()
    }
}

extension  DocsAlertController {
    public func add(_ item: AlertAction) {
        actions.append(item)
    }
    public func removeAllAction() {
        actions.removeAll()
    }
    public func setItemHeight(_ itemHeight: CGFloat) {
        self.itemHeight = itemHeight
    }
    public func setTitleColor(_ titleColor: UIColor) {
        self.titleColor = titleColor
    }
    public func setItemColor(_ itemColor: UIColor) {
        self.itemColor = itemColor
    }
    public func setHeaderView(_ view: UIView) {
        self.alertView.headerView = view
    }

    public func setDestructiveDifferentColor(different: Bool) {
        self.destructiveUsingDifferentColor = different
    }
}

extension  DocsAlertController: AlertActionDelegate {
    public func alertDismiss() {
        delegate?.didDismiss(self)
        dismiss(animated: true, completion: nil)
    }
    public func getAlertAction() -> [ AlertAction] {
        return self.actions
    }
    public func getItemHeightFor(_ action: AlertAction) -> CGFloat {
        if let subtitle = action.subtitle, !subtitle.isEmpty {
            return self.itemHeight + 20
        } else {
            if action.style == .destructive {
                return CGFloat(50)
            } else {
                return self.itemHeight
            }
        }
    }
    public func getTitleColor() -> UIColor {
        return self.titleColor
    }
    public func getItemColor() -> UIColor {
        return self.itemColor
    }
    public func getAlertDirection() -> AlertDirection {
        return self.direction
    }

    public func checkDestructiveUsingDifferentColor() -> Bool {
        return self.destructiveUsingDifferentColor
    }
}

extension DocsAlertController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController, source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return  AlertPresentSlideUp()
    }
    public func animationController(forDismissed dismissed: UIViewController )
        -> UIViewControllerAnimatedTransitioning? {
            return  AlertDismissSlideDown()
    }
}
