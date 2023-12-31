//
//  DraggableBottomView.swift
//  SKSheet
//
//  Created by lijuyou on 2022/4/7.
//  


import SKFoundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

open class DraggableBottomView: UIView {
    
    public private(set) weak var hostView: UIView?
    public lazy var headerView: UIView = {
        return createHeaderView() ?? createDefaultHeaderView()
    }()
    
    private var hostViewHeight: CGFloat { hostView?.bounds.height ?? 0 }
    //真实Max模式高度
    public private(set) var maxViewHeight: CGFloat = 0
    //初始显示高度
    public private(set) var initViewHeight: CGFloat = 0
    //默认min模式高度
    open var defaultMinModeHeight: CGFloat { hostViewHeight * 0.4 }
    //默认max模式高度
    open var defaultMaxModeHeight: CGFloat { hostViewHeight * 0.7 }
    //是否可以往上拖拽
    open var canDragUp: Bool { false }
    //拖拽view的高度
    open var headerViewHeight: CGFloat { 32 }
    
    private var startPanningY: CGFloat = -1
    
    public init(hostView: UIView) {
        self.hostView = hostView
        super.init(frame: .zero)
        backgroundColor = UDColor.bgBody
        layer.ud.setShadowColor(UDColor.shadowDefaultLg) // tokenize
        layer.shadowOpacity = 1
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: -6)
        layer.cornerRadius = 12
        layer.maskedCorners = .top
        
        initViewHeight = defaultMinModeHeight
        maxViewHeight = defaultMaxModeHeight
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        guard let hostView = hostView else { return }
        addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(headerViewHeight)
            make.left.right.equalToSuperview()
        }
        setupHeaderViewGesture()
        
        hostView.addSubview(self)
        self.snp.makeConstraints { make in
            make.top.equalTo(hostView.bounds.height)
            make.bottom.equalTo(hostView.snp.bottom)
            make.left.right.equalToSuperview()
        }
        
        setupSubViews()
        hostView.layoutIfNeeded()
    }
    
    private func setupHeaderViewGesture() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panToChangeSize(sender:)))
        self.headerView.addGestureRecognizer(panGestureRecognizer)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToHide(sender:)))
        self.headerView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func createDefaultHeaderView() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: self.headerViewHeight)).construct { make in
            make.layer.cornerRadius = 12
            make.layer.maskedCorners = .top
            make.layer.masksToBounds = true
            make.backgroundColor = UDColor.bgBody
            let icon = UDIcon.getIconByKey(.vcToolbarDownFilled, renderingMode: .alwaysOriginal, size: CGSize(width: 22, height: 22))
            let arrowImageView = UIImageView(image: icon.ud.withTintColor(UDColor.iconDisabled))
            make.addSubview(arrowImageView)
            arrowImageView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(2)
                make.centerX.equalToSuperview()
                make.height.equalTo(22)
                make.width.equalTo(22)
            }
        }
        return headerView
    }
    
    // MARK: - 子类扩展
    open func setupSubViews() { }
    
    open func onSizeChange(isShow: Bool) { }
    
    //子类创建自定义header
    open func createHeaderView() -> UIView? {
        nil
    }
    
    // MARK: - Event Handle
    
    @objc
    private func panToChangeSize(sender: UIPanGestureRecognizer) {
        guard let hostView = self.hostView else { return }
        let fingerY = sender.location(in: hostView).y
        let translationY = sender.translation(in: hostView).y
        switch sender.state {
        case .began:
            startPanningY = fingerY
        case .changed:
            duringPanning(panel: self, translation: translationY)
        case .ended, .cancelled, .failed:
            endedPanning(panel: self, to: fingerY)
        default: break
        }
    }
    
    @objc
    private func tapToHide(sender: UITapGestureRecognizer) {
        self.hide(immediately: false)
    }
    
    
    // MARK: - Public Method
    
    open func show(completion: (() -> Void)? = nil) {
        guard let hostView = self.hostView else { return }
        let targetTop = hostView.bounds.height - self.initViewHeight
        UIView.animate(withDuration: 0.25) {
            self.snp.updateConstraints { (make) in
                make.top.equalTo(targetTop)
            }
            hostView.layoutIfNeeded()
        } completion: { (completed) in
            if completed {
                completion?()
                self.onSizeChange(isShow: true)
            }
        }
    }

    open func hide(immediately: Bool, completion: (() -> Void)? = nil) {
        guard let hostView = hostView else { return }
        guard self.superview != nil else { return }
        if immediately {
            self.removeFromSuperview()
            completion?()
            self.onSizeChange(isShow: false)
        } else {
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self.snp.remakeConstraints { make in
                        make.top.equalTo(hostView.bounds.height)
                        make.left.right.equalToSuperview()
                    }
                    hostView.layoutIfNeeded()
                },
                completion: { finish in
                    if finish {
                        self.removeFromSuperview()
                    }
                    completion?()
                    self.onSizeChange(isShow: false)
                }
            )
        }
    }
    
    public func updateContentHeight(_ contentHeight: CGFloat) {
        guard let hostView = self.hostView else { return }
        guard self.superview != nil else { return }
        initViewHeight = min(contentHeight, defaultMinModeHeight)
        if contentHeight > defaultMinModeHeight {
            maxViewHeight = defaultMaxModeHeight
        } else {
            maxViewHeight = contentHeight
        }
        DocsLogger.info("updateContentHeight：\(contentHeight),initViewHeight:\(initViewHeight),maxViewHeight:\(maxViewHeight)")
        
        let offsetY = hostView.bounds.height - initViewHeight
        self.snp.updateConstraints { make in
            make.top.equalTo(offsetY)
        }
        hostView.layoutIfNeeded()
        self.onSizeChange(isShow: true)
    }
}

// MARK: - 拖拽处理
private extension DraggableBottomView {
    
    var minTop: CGFloat { hostViewHeight > 0 ? hostViewHeight - initViewHeight : 0 }
    var maxTop: CGFloat { hostViewHeight > 0 ? hostViewHeight - maxViewHeight : 0 }

    func duringPanning(panel: UIView, translation: CGFloat) {
        guard let hostView = hostView else { return }
        var targetTop = startPanningY + translation
        if !canDragUp {
            targetTop = max(targetTop, maxTop)
        }
        panel.snp.updateConstraints { make in
            make.top.equalTo(targetTop)
        }
        hostView.layoutIfNeeded()
    }

    func endedPanning(panel: UIView, to y: CGFloat) {
        guard let hostView = hostView else { return }
        var targetTop: CGFloat = minTop
        if y > minTop { // 面板很低，即将收起
            self.hide(immediately: false)
            return
        } else if y < maxTop { // 面板超过了最大高度
            targetTop = maxTop
        } else {
            if startPanningY < y {
                targetTop = minTop
            } else {
                targetTop = maxTop
            }
        }
        UIView.animate(withDuration: 0.25) {
            panel.snp.updateConstraints { make in
                make.top.equalTo(targetTop)
            }
            hostView.layoutIfNeeded()
        } completion: {_ in
            self.onSizeChange(isShow: true)
        }
        startPanningY = -1
    }
}
