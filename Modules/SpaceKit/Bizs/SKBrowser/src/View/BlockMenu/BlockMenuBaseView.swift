//
//  BlockMenuV2.swift
//  SKDoc
//
//  Created by zoujie on 2021/1/20.
//

import SKFoundation
import SKResource
import SKUIKit
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon

public protocol BlockMenuDelegate: AnyObject {
    var getCommentViewWidth: CGFloat { get }
    func notifyMenuHeight()
    func closeMenu(level: Int)
    func didClickedItem(_ item: BlockMenuItem, blockMenuPanel: BlockMenuBaseView, params: [String: Any]?)
    func drag(offset: CGFloat, reset: Bool)
    func countPrepareSize()
}

public class BlockMenuBaseView: UIView {
    public weak var delegate: BlockMenuDelegate?

    ///Block菜单层级
    public var menuLevel = 0
    ///Block菜单内边距
    var menuPadding: CGFloat = 8
    ///Block菜单底部内边距
    let menuBottomPadding: CGFloat = 12
    ///Block菜单距离父view左右最小边距
    public let menuMargin: CGFloat = 8
    ///iPad宽屏下Block菜单项<=5时的菜单宽度
    let iPadminMenuWidth: CGFloat = 422
    ///Block菜单距离superView底部的距离，仅用在当前在显示的view
    public var currentBottom: CGFloat = 0
    ///菜单距离屏幕底部在原有bottom上的偏移距离
    public var offsetBottom: CGFloat = 0
    ///菜单距离屏幕左右边界的距离
    public var offsetLeft: CGFloat = 0
    ///记录菜单上一次距离屏幕左右边界的距离
    var lastOffsetLeft: CGFloat = 0
    ///Block菜单的宽度
    public var menuWidth: CGFloat = 0
    ///Block菜单的高度
    public var menuHeight: CGFloat = 0
    ///记录当前Block菜单是否显示
    public var isShow: Bool = false
    ///是否显示下拉bar
    var shouldShowDropBar: Bool = true
    ///是否是新版Block菜单
    var isNewMenu: Bool = true
    ///加深底部阴影
    var subLayer: CALayer = CALayer()
    ///记录上次拖动的距离
    private var lastPanOffset: CGFloat = 0
    ///记录拖动手势开始的位置
    private var firstPanPoint: CGPoint?
    ///键盘变化回调
    public let publishObserver = PublishSubject<CGFloat>()
    ///当前键盘高度
    public var keyboardHeight: CGFloat = 0
    ///是否需要关闭当前面板，动画用
    private var needCloseMenu = false
    ///最小宽度，最大高度设置，避免下方菜单宽高超出上方菜单
    public var prepareSize: CGSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
    ///是否需要更新frame
    private var needUpdateConstraints = false

    private let disposeBag = DisposeBag()
    
    let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = 4
        view.clipsToBounds = false
        return view
    }()

    private lazy var dropDownBarView: UIButton = {
        let button = UIButton()
        let icon = UDIcon.getIconByKey(.vcToolbarDownFilled, renderingMode: .alwaysOriginal, size: CGSize(width: 20, height: 20))
        button.setImage(icon.ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        button.setImage(icon.ud.withTintColor(UDColor.N500), for: .highlighted)
        button.docs.addHighlight(with: UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4), radius: 4)
        return button
    }()

    init(shouldShowDropBar: Bool, isNewMenu: Bool) {
        self.shouldShowDropBar = shouldShowDropBar
        self.isNewMenu = isNewMenu
        super.init(frame: .zero)
        _addsubView()

        publishObserver.subscribe(onNext: { [weak self] keyboardHeight in
            guard let `self` = self else { return }
            self.keyboardHeight = keyboardHeight
            guard self.isShow else { return }
            UIView.animate(withDuration: 0.3, animations: {
                self.snp.updateConstraints { (make) in
                    make.bottom.equalToSuperview().offset(-self.getViewBottom())
                }
                self.layoutIfNeeded()
            })
        }).disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _addsubView() {
        self.backgroundColor = UDColor.bgBody
        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UDColor.lineBorderCard)
        self.layer.ud.setShadowColor(UDColor.shadowDefaultMd)
        self.layer.cornerRadius = 12
        self.layer.addSublayer(subLayer)
        self.layer.ud.setBackgroundColor(UDColor.bgBody, bindTo: self)
        subLayer.cornerRadius = 12
        subLayer.backgroundColor = UIColor.clear.cgColor
        subLayer.ud.setShadowColor(UDColor.shadowDefaultMd)

        self.addSubview(contentView)
        if isNewMenu {
            let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(drag(sender:)))
            self.addGestureRecognizer(dragGesture)
        }

        if shouldShowDropBar {
            self.addSubview(dropDownBarView)
            dropDownBarView.snp.makeConstraints { (make) in
                make.height.width.equalTo(20)
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(3)
            }

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapDown))
            dropDownBarView.addGestureRecognizer(tapGesture)
        }

        contentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(menuPadding)
            make.right.bottom.equalToSuperview().offset(-menuPadding)
            if shouldShowDropBar {
                make.top.equalTo(dropDownBarView.snp.bottom).offset(9)
            } else {
                make.top.equalToSuperview().offset(12)
            }
        }
    }

    public func  setMenus(data: [BlockMenuItem]) {}

    func setShadow(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) {
        let shadowRect = CGRect(x: -left, y: -top, width: self.bounds.size.width + left + right, height: self.bounds.size.height + top + bottom)
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 20
        self.layer.shadowOffset = CGSize(width: 0, height: 20)
        self.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath

        subLayer.frame = self.convert(self.layer.frame, to: nil)
        let bottomShadowRect = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height + 20)
        subLayer.shadowOpacity = 1
        subLayer.shadowRadius = 20
        subLayer.shadowOffset = CGSize(width: 0, height: 20)
        subLayer.shadowPath = UIBezierPath(rect: bottomShadowRect).cgPath
    }

    public func showMenu() {
        guard let superView = self.superview else { return }
        superView.bringSubviewToFront(self)
        offsetBottom = CGFloat(menuLevel * 8)
        self.isShow = true

        let commentViewWidth = delegate?.getCommentViewWidth ?? 0
        self.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview().offset(-commentViewWidth / 2)
            make.width.equalTo(self.menuWidth)
            make.height.equalTo(self.menuHeight)
            make.bottom.equalToSuperview().offset(self.menuHeight + 20)
        }
        superView.layoutIfNeeded()

        UIView.animate(withDuration: 0.3, animations: {
            self.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-self.getViewBottom())
            }
            superView.layoutIfNeeded()
            self.setShadow(top: 16, bottom: 20, left: 10, right: 10)
        }, completion: { _ in
            self.delegate?.notifyMenuHeight()
        })
    }

    ///菜单更新宽度和高度
    public func scale(leftOffset: CGFloat, isShrink: Bool = true) {
        let currentOffset = isShrink ? leftOffset : 0
        guard lastOffsetLeft != currentOffset || needUpdateConstraints else { return }
        var duration: CGFloat = 0.3
        //展开动画设为0.1秒
        if currentOffset < lastOffsetLeft {
            duration = 0.1
        }
        lastOffsetLeft = currentOffset
        UIView.animate(withDuration: TimeInterval(duration)) {
            self.snp.updateConstraints { (make) in
                make.width.equalTo(self.menuWidth)
                make.height.equalTo(self.menuHeight)
            }
            self.layoutIfNeeded()
        }
    }

    public func hideMenu() {
        guard let superView = self.superview, isShow else { return }
        isShow = false
        reset()
        UIView.animate(withDuration: 0.3) {
            self.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(self.menuHeight + self.currentBottom + 20)
            }
            superView.layoutIfNeeded()
        }
    }

    ///重置参数
    private func reset() {
        offsetLeft = 0
        lastOffsetLeft = 0
        prepareSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
    }

    private func getViewBottom() -> CGFloat {
        //block菜单距父view底部的边距
        guard let superView = self.superview else { return 0 }
        var bottom = superView.safeAreaInsets.bottom > 0 ? superView.safeAreaInsets.bottom - 4 : 8
        bottom = SKDisplay.pad ? 40 : bottom
        bottom += self.offsetBottom

        if self.keyboardHeight > 0 {
            bottom = self.offsetBottom + self.keyboardHeight + 8
        }
        currentBottom = bottom
        return bottom
    }

    public func updateMenuFrame() {
        guard self.superview != nil else { return }

        let commentViewWidth = delegate?.getCommentViewWidth ?? 0
        self.snp.updateConstraints { (make) in
            make.width.equalTo(self.menuWidth)
            make.height.equalTo(self.menuHeight)
            make.centerX.equalToSuperview().offset(-commentViewWidth / 2)
            make.bottom.equalToSuperview().offset(-getViewBottom())
        }
        layoutIfNeeded()
        delegate?.notifyMenuHeight()
    }

    ///更新view布局
    public func refreshLayout() {
        if isShow {
            delegate?.countPrepareSize()
            updateMenuFrame()
            setShadow(top: 16, bottom: 20, left: 10, right: 10)
        }
    }

    public func updateViewBottom(offset: CGFloat, reset: Bool = false) {
        if reset {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                self.snp.updateConstraints { (make) in
                    make.bottom.equalToSuperview().offset(-self.currentBottom)
                }
                self.superview?.layoutIfNeeded()
            })
            return
        }

        var currentOffset = offset
        if currentOffset > 0 {
            currentOffset = sqrt(currentOffset)
        }
        let bottom = currentBottom + currentOffset
        self.snp.updateConstraints { (make) in
            make.bottom.equalToSuperview().offset(-bottom)
        }
        layoutIfNeeded()
    }

    public func dropDown(action: String) {
        hideMenu()
        closeMenuReport(action: action)
        delegate?.closeMenu(level: menuLevel)
    }

    ///菜单下拉关闭事件埋点上报
    public func closeMenuReport(action: String) {
        let params: [String: Any] = ["action_source": action]
        DocsTracker.log(enumEvent: .blockMenuPullingDown, parameters: params)
    }

    func countMenuSize() {
        needUpdateConstraints = (self.bounds.size != CGSize(width: menuWidth, height: menuHeight))
    }

    @objc
    private func tapDown() {
        dropDown(action: "button_click")
    }

    @objc
    public func drag(sender: UIPanGestureRecognizer) {
        guard let superView = self.superview, isShow else { return }
        let currentPoint = sender.location(in: superView)
        var offsetY: CGFloat = 0
        switch sender.state {
        case .began:
            firstPanPoint = sender.location(in: superView)
        case .changed:
            guard let beganPoint = firstPanPoint else { return }
            offsetY = beganPoint.y - currentPoint.y
            needCloseMenu = !(offsetY > 0 || offsetY > lastPanOffset || -offsetY < 20)
            delegate?.drag(offset: offsetY, reset: false)
            lastPanOffset = offsetY
        case .ended:
            if needCloseMenu {
                self.dropDown(action: "pulling_down")
            } else {
                delegate?.drag(offset: 0, reset: true)
            }
        default:
            break
        }
    }
}
