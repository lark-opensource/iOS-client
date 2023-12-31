//
//  BTToolbarsContainerView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/19.
//  


import SKUIKit
import SKCommon
import SKFoundation

final class BTToolbarsContainerView: UIView {
    
    var fabCallback = DocsJSCallBack("")
    
    var toolbarCallback = DocsJSCallBack("")
    
    var toolbarParams = BTBottomToolBarParams()
    
    private(set) var bottomSafeArea: CGFloat = 0
    
    private(set) var hostWindow: UIWindow?
    
    /// 目录，分享表单等工具栏
    lazy var fabContainerView: FABContainer = FABContainer()
    /// 底部筛选排序工具栏
    lazy var toolbarView = BTBottomToolBar().construct { it in
        it.alpha = 0
    }
    
    init(bottomSafeArea: CGFloat) {
        super.init(frame: .zero)
        self.bottomSafeArea = bottomSafeArea
        setupViews()
        setFABHide(true)
        registOrientationChange()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        DocsLogger.btInfo("BTToolbarsContainerView deinit")
    }
    
    // MARK: - toolBar 接口
    /// toolbar 是否隐藏中
    var isToolbarHide: Bool {
        return self.toolbarView.alpha == 0
    }
    /// toolbar 是否符合展示条件
    var isToolbarShowable: Bool {
        if toolbarParams.menus.isEmpty {
            return false
        }
        if SKDisplay.phone {
            return UIApplication.shared.statusBarOrientation == .portrait
        }
        return true
    }
    
    /// 更新 toolBar 的数据
    /// - Parameter params: 当 params 中的 menus 为空时，进行隐藏
    func updateToolbar(params: BTBottomToolBarParams) {
        self.toolbarParams = params
        let isHide = !isToolbarShowable
        setToolbarHide(isHide, animated: false)
        // 这里即使隐藏也要更新一下 item 数据。
        if params.menus != toolbarView.models {
            self.toolbarView.updateModels(params.menus)
        }
    }
    
    func setToolbarHide(_ isHidden: Bool, animated: Bool) {
        // 只有允许展示时才会执行展示操作
        if !isHidden && !isToolbarShowable {
            return
        }
        resetToolbarViewLayout(isHidden: isHidden)
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.toolbarView.alpha = isHidden ? 0 : 1
        }
    }
    /// 处理转屏事件
    private func registOrientationChange() {
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.setToolbarHide(!self.isToolbarShowable, animated: false)
        }
    }

    // MARK: - FAB 接口
    func updateFAB(params: [FABData]) {
        fabContainerView.updateButtons(params)
    }
    
    func setFABHide(_ isHidden: Bool) {
        fabContainerView.isHidden = isHidden
    }
    
    // MARK: - 处理点击区域问题
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if fabContainerView.frame.contains(point) {
            return super.hitTest(point, with: event)
        }
        
        if toolbarView.frame.contains(point), !isToolbarHide {
            return super.hitTest(point, with: event)
        }
        return nil
    }
    
    private func setupViews() {
        addSubview(fabContainerView)
        addSubview(toolbarView)
        fabContainerView.snp.makeConstraints {
            $0.top.trailing.equalToSuperview()
            $0.bottom.equalTo(toolbarView.snp.top).offset(-14)
        }
        resetToolbarViewLayout(isHidden: true)
    }

    func resetToolbarViewLayout(isHidden: Bool) {
        toolbarView.snp.remakeConstraints {
            $0.height.equalTo(toolBarHeightWithSafeArea)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().offset(isHidden ? BTBottomToolBar.toolBarHeight : 0)
        }
    }
    
    /// 这里将安全区域作为高度是因为需要做显示和隐藏动画。
    private var toolBarHeightWithSafeArea: CGFloat {
        return BTBottomToolBar.toolBarHeight + bottomSafeArea
    }
}
