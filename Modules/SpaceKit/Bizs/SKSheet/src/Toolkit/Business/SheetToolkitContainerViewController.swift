//
//  SheetToolkitContainerViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/11/11.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation

enum ToolkitViewType: String {
    case operation
    case style
    case insert
    case view
}

protocol SheetToolkitContainerViewControllerDelegate: AnyObject {
    func toolkitDidFireAction(identifier: String, value: Any?, viewType: ToolkitViewType, controller: SheetToolkitContainerViewController, itemIsEnable: Bool)
    func toolkitDidChangeViewType(toViewType: ToolkitViewType, controller: SheetToolkitContainerViewController)
    func toolkitRequestExitSelf(controller: SheetToolkitContainerViewController)
}

class SheetToolkitContainerViewController: SheetBaseToolkitViewController {

    //所有的信息
    weak var delegate: SheetToolkitContainerViewControllerDelegate?
    var shouldRefreshView = true
    private var maxWidth: CGFloat = SKDisplay.activeWindowBounds.width
    private var _superWidth: CGFloat = 0
    var superWidth: CGFloat {
        get {
            if _superWidth == 0 {
                return self.view.window?.bounds.size.width ?? SKDisplay.activeWindowBounds.width
            } else {
                return _superWidth
            }
        }
        set {
            _superWidth = newValue
        }
    }
    private var status: [SheetToolkitTapItem] = []
    private var childrenToolkit: [SheetToolkitFacadeViewController] = []

    private var pageIndexView: SheetToolkitPageIndexView
    private var pageView: SheetToolkitPageView = SheetToolkitPageView()

    private var clearBadgeIdentifiers = [String]()
    //红点处理
    private var preClickTabIdentifier: String?

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.toolkit.rawValue
    }

    var contentWidth: CGFloat {
        return min(maxWidth, superWidth)
    }
    
    init(superWidth: CGFloat, maxWidth: CGFloat) {
        pageIndexView = SheetToolkitPageIndexView(frame: CGRect(x: 0, y: 0, width: 0, height: 48), superWidth: superWidth, maxWidth: self.maxWidth)
        super.init(nibName: nil, bundle: nil)
        self.superWidth = superWidth
        self.maxWidth = maxWidth
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        pageIndexView.delegate = self
        setupLayout()
        childrenToolkit.append(SheetToolkitFacadeViewController())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldRefreshView = true
        if clearBadgeIdentifiers.count > 0 {
            badgeDelegate?.finishBadges(identifiers: clearBadgeIdentifiers, controller: self)
        }
    }

    private func setupLayout() {
        pageIndexView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: itemHeight)
        pageView.removeFromSuperview()
        pageView = SheetToolkitPageView(frame: self.view.bounds)
        pageView.setVCDelegate(delegate: self)
        pageIndexView.pageableView = pageView
        view.addSubview(pageView)
        pageView.tabBarView = pageIndexView
        pageView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(SheetToolkitNavigationController.draggableViewHeight)
            maker.width.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if shouldRefreshView {
            pageIndexView.refreshCurrentView()
            shouldRefreshView = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldRefreshView {
            pageIndexView.refreshCurrentView()
            shouldRefreshView = false
        }
    }

    func showView(identitifer: String) {
        pageIndexView.switchView.mockClickButton(tapId: identitifer, byUser: true)
    }

    func fetchExistToolkit(identifier: String) -> SheetToolkitFacadeViewController? {
        return childrenToolkit.first(where: { $0.tapItem.tapId == identifier })
    }
    
    func updateStatus(_ newStatus: [SheetToolkitTapItem]) {
        status = newStatus
        refreshPageIndexView()

        func makeToolkit(identifier: String) -> SheetToolkitFacadeViewController? {
            switch identifier {
            case ToolkitViewType.style.rawValue:
                let vc = SheetStyleToolkitViewController()
                vc.delegate = self
                return vc
            default:
                let vc = SheetOperationToolkitViewController()
                vc.delegate = self
                return vc
            }
        }

        var newChildrenToolkit = [SheetToolkitFacadeViewController]()
        for toolkitItem in status where toolkitItem.enable == true {
            if let oldVC = fetchExistToolkit(identifier: toolkitItem.tapId) {
                oldVC.update(toolkitItem)
                newChildrenToolkit.append(oldVC)
            } else if let newVC = makeToolkit(identifier: toolkitItem.tapId) {
                newVC.update(toolkitItem)
                newChildrenToolkit.append(newVC)
            }
        }

        pageIndexView.itemNumber = newChildrenToolkit.count
        let reload = shouldReload(old: childrenToolkit, new: newChildrenToolkit)

        childrenToolkit = newChildrenToolkit
        pageView.privateAgent.delegate = pageIndexView

        if reload {
            for vc in self.children {
                vc.view.removeFromSuperview()
                vc.removeFromParent()
            }
            pageView.reloadCollectionView()
            if let buttonId = pageIndexView.switchView.lastHighlightedButton?.tapId {
                pageIndexView.switchView.mockClickButton(tapId: buttonId, byUser: false)
            }
        }
    }
    
    func resetBorderPanel() {
        if let operationVC = fetchExistToolkit(identifier: ToolkitViewType.style.rawValue) {
            operationVC.reset()
        }
    }

    private func shouldReload(old: [SheetToolkitFacadeViewController], new: [SheetToolkitFacadeViewController]) -> Bool {
        guard old.count == new.count else { return true }
        var allMatch = true
        for (index, obj) in old.enumerated() {
            if obj.tapItem.tapId != new[index].tapItem.tapId {
                allMatch = false
                break
            } else {
                continue
            }
        }
        return !allMatch
    }

    private func refreshPageIndexView() {
        let models = status.map { (item) -> SheetToolkitSwitchView.ButtonModel in
            var model = SheetToolkitSwitchView.ButtonModel()
            model.identifier = item.tapId
            model.title = item.title
            model.enable = item.enable
            return model
        }
        pageIndexView.update(models, preferWidth: contentWidth)
    }
    
    deinit {
        DocsTracker.log(enumEvent: .sheetCloseFabPanel, parameters: nil)
    }
}

extension SheetToolkitContainerViewController: SheetToolkitPageViewControllerDelegate {

    func childViewController(atIndex index: Int) -> UIViewController {
        let currentToolkits = childrenToolkit
        guard index >= 0, index < currentToolkits.count else {
            return SheetOperationToolkitViewController()
        }
        return currentToolkits[index]
    }

    func parentViewController() -> UIViewController {
        return self
    }
}

extension SheetToolkitContainerViewController: SheetOperationToolkitViewControllerDelegate {

    func didClickItem(identifier: String, finishGuide: Bool, itemIsEnable: Bool, controller: SheetOperationToolkitViewController) {
        delegate?.toolkitDidFireAction(identifier: identifier, value: nil, viewType: .operation, controller: self, itemIsEnable: itemIsEnable)
    }

    func shouldDisplayBadge(identifier: String, controller: SheetOperationToolkitViewController) -> Bool {
        return badgedList.contains(identifier)
    }
    
    func clearBadges(identifiers: [String], controller: SheetOperationToolkitViewController) {
        badgeDelegate?.finishBadges(identifiers: identifiers, controller: self)
    }
}

extension SheetToolkitContainerViewController: SheetStyleToolkitViewControllerDelegate {
    func didRequestChangeStyle(identifier: String, value: Any?, controller: SheetStyleToolkitViewController) {
        delegate?.toolkitDidFireAction(identifier: identifier, value: value, viewType: .style, controller: self, itemIsEnable: true)
    }
}

extension SheetToolkitContainerViewController: SheetToolkitPageIndexViewDelegate {
    func viewRequestExitPanel(view: SheetToolkitPageIndexView) {
        delegate?.toolkitRequestExitSelf(controller: self)
    }

    func didClickButton(_ btn: String, byUser: Bool, view: SheetToolkitPageIndexView) {
        guard btn != preClickTabIdentifier else {
            return
        }

        preClickTabIdentifier = btn
        if byUser, let viewType = ToolkitViewType(rawValue: btn) {
            badgeDelegate?.finishBadges(identifiers: clearBadgeIdentifiers, controller: self) // 将上一个 tab 的小红点清掉
            delegate?.toolkitDidChangeViewType(toViewType: viewType, controller: self)
        }
        //小红点逻辑
        var identifiers = [String]()
        identifiers.append(btn)
        for toolKitItem in status where toolKitItem.tapId == btn {
            for (_, item) in toolKitItem.items {
                identifiers.append(item.identifier)
            }
        }
        clearBadgeIdentifiers = identifiers // 将这个 tab 的小红点记录下来，下次清理
    }

    func shouldDisplayRedPoint(_ buttonIdentitifer: String) -> Bool {
        return badgedList.contains(buttonIdentitifer)
    }

    func didPanBegin(point: CGPoint, view: SheetToolkitPageIndexView) {
        navBarGestureDelegate?.panBegin(point, allowUp: allowUpDrag)
    }

    func didPanMoved(point: CGPoint, view: SheetToolkitPageIndexView) {
        navBarGestureDelegate?.panMove(point, allowUp: allowUpDrag)
    }

    func didPanEnded(point: CGPoint, view: SheetToolkitPageIndexView) {
        navBarGestureDelegate?.panEnd(point, allowUp: allowUpDrag)
    }
}

extension SheetToolkitContainerViewController: SheetToolkitHostViewDelegate {
    func didPanBegin(point: CGPoint, view: SheetToolkitHostView) {
        navBarGestureDelegate?.panBegin(point, allowUp: allowUpDrag)
    }
    
    func didPanMoved(point: CGPoint, view: SheetToolkitHostView) {
        navBarGestureDelegate?.panMove(point, allowUp: allowUpDrag)
    }
    
    func didPanEnded(point: CGPoint, view: SheetToolkitHostView) {
        navBarGestureDelegate?.panEnd(point, allowUp: allowUpDrag)
    }
}

protocol SheetToolkitPageIndexViewDelegate: AnyObject {
    func viewRequestExitPanel(view: SheetToolkitPageIndexView)
    func didClickButton(_ btn: String, byUser: Bool, view: SheetToolkitPageIndexView)
    func shouldDisplayRedPoint(_ buttonIdentitifer: String) -> Bool
    func didPanBegin(point: CGPoint, view: SheetToolkitPageIndexView)
    func didPanMoved(point: CGPoint, view: SheetToolkitPageIndexView)
    func didPanEnded(point: CGPoint, view: SheetToolkitPageIndexView)
}

class SheetToolkitPageIndexView: UIView {
    weak var delegate: SheetToolkitPageIndexViewDelegate?
    weak var pageableView: SheetToolkitPageView?
    var itemNumber: Int = 1
    var currentIndex: Int = -1
    private var superWidth: CGFloat = SKDisplay.activeWindowBounds.width
    private var maxWidth: CGFloat = SKDisplay.activeWindowBounds.width
    lazy var switchView: SheetToolkitSwitchView = {
        let view = SheetToolkitSwitchView()
        view.backgroundColor = UIColor.ud.bgBody
        view.delegate = self
        return view
    }()

    lazy var lineView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ud.N400
        return view
    }()

    func update(_ models: [SheetToolkitSwitchView.ButtonModel], preferWidth: CGFloat?) {
        switchView.update(models, preferWidth: preferWidth)
        itemNumber = models.count
        itemNumber = max(itemNumber, 1)
    }
    
    init(frame: CGRect, superWidth: CGFloat, maxWidth: CGFloat) {
        super.init(frame: frame)
        self.superWidth = superWidth
        self.maxWidth = maxWidth
        backgroundColor = UIColor.ud.bgBody
        addSubview(switchView)
        addSubview(lineView)
        var leftRightInset: CGFloat = 0
        if superWidth > maxWidth {
            leftRightInset = (superWidth - maxWidth) / 2.0
        }
        switchView.snp.makeConstraints { (make) in
            make.height.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(-leftRightInset)
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture(gesture:)))
        self.addGestureRecognizer(pan)
    }

    @objc
    func didReceivePanGesture(gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        if gesture.state == .began {
            delegate?.didPanBegin(point: point, view: self)
        } else if gesture.state == .changed {
            delegate?.didPanMoved(point: point, view: self)
        } else {
            delegate?.didPanEnded(point: point, view: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshCurrentView() {
        if currentIndex >= 0 {
            pageableView?.jumpToItem(index: currentIndex, animated: false)
        }
    }
}

extension SheetToolkitPageIndexView: SheetToolkitSwitchViewDelegate {
    func didClickNormalButton(_ btn: String, byUser: Bool, view: SheetToolkitSwitchView) {
        let index = switchView.buttonModels.firstIndex { $0.identifier == btn } ?? 0
        currentIndex = index
        pageableView?.jumpToItem(index: currentIndex, animated: true)
        delegate?.didClickButton(btn, byUser: byUser, view: self)
    }

    func didClickDisableButton(_ btn: String, byUser: Bool, view: SheetToolkitSwitchView) {
        delegate?.didClickButton(btn, byUser: byUser, view: self)
    }

    func didClickBack(view: SheetToolkitSwitchView) { }

    func shouldDisplayRedPoint(_ buttonIdentitifer: String) -> Bool {
        return delegate?.shouldDisplayRedPoint(buttonIdentitifer) ?? false
    }
}

extension SheetToolkitPageIndexView: SheetToolkitPageViewDelegate {

    func numberOfItems() -> Int {
        return itemNumber
    }

    func vcScrollViewDidScroll(_ scrollView: UIScrollView) {
        switchView.vcScrollViewDidScroll(scrollView)
    }

    func vcScrollViewDidEndScrollAnimation(_ scrollView: UIScrollView) {
        handlerEndScroll(scrollView: scrollView, byUser: false)
    }

    func vcScrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handlerEndScroll(scrollView: scrollView, byUser: true)
    }

    private func handlerEndScroll(scrollView: UIScrollView, byUser: Bool) {
        let count = switchView.buttonModels.count
        guard count > 0 else { return }
        let offsetX = scrollView.contentOffset.x
        let index = offsetX > 0 ? Int(round(offsetX / scrollView.bounds.width)) : 0
        if index != currentIndex {
           currentIndex = index
           if index >= 0, index < count {
               switchView.mockClickButton(tapId: switchView.buttonModels[index].identifier, byUser: byUser)
           }
       }
    }
}
