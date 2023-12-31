//
// Created by duanxiaochen.7 on 2020/7/20.
// Affiliated with SKBrowser.
//
// Description: Sheets 编辑、新增工作表所用到的 VC

import SKBrowser
import SKFoundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon

protocol SheetTabOperationDelegate: AnyObject {
    var hostView: UIView? { get }
    var tabSwitcher: SheetTabSwitcherView? { get }
    func didClickBackgroundToDismiss()
    func didClickOperation(identifier: String, tableID: String?, rightIconID: String?)
}

class SheetTabOperationViewController: SKPanelController, SKOperationViewDelegate {

    weak var delegate: SheetTabOperationDelegate?

    private var params: SheetTabOperationParams

    private lazy var model: [[ToolBarItemInfo]] = params.toolbarItemInfos()

    // MARK: - Subviews

    private lazy var titleView = SKPanelHeaderView()

    private lazy var operationList = SKOperationView(frame: .zero,
                                                     displayIcon: shouldShowLeftIcons).construct { it in
        it.delegate = self
    }

    // MARK: - Configurations

    var isInPopover: Bool {
        modalPresentationStyle == .popover
    }

    var hasNoticedDismissal = false

    private var shouldShowLeftIcons: Bool = false

    // MARK: - Life Cycle Events

    init(params: SheetTabOperationParams, delegate: SheetTabOperationDelegate) {
        self.delegate = delegate
        self.params = params
        super.init(nibName: nil, bundle: nil)
        titleView.setCloseButtonAction(#selector(didClickMask), target: self)
        titleView.setTitle(params.title)
        transitioningDelegate = panelTransitioningDelegate
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()

        containerView.addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }
        titleView.backgroundColor = .clear

        if let item = params.items.first, item.isShowLeftIcon {
            shouldShowLeftIcons = true
        }

        containerView.addSubview(operationList)
        operationList.setCollectionViewBackgroundColor(color: .clear)
        let estimateHeight = SKOperationView.estimateContentHeight(infos: model) // 可能需要一个高度上限
        operationList.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(estimateHeight)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom)
        }
        operationList.refresh(infos: model)
    }

    override func transitionToRegularSize() {
        super.transitionToRegularSize()
        titleView.toggleCloseButton(isHidden: true)
        operationList.refresh(infos: model) // 刷新 cell 底色
    }

    override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        titleView.toggleCloseButton(isHidden: false)
        operationList.refresh(infos: model) // 刷新 cell 底色
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            self.operationList.relayout()
        }
    }

    @objc
    override func didClickMask() {
        delegate?.didClickBackgroundToDismiss()
    }

    deinit {
        if !hasNoticedDismissal {
            delegate?.didClickBackgroundToDismiss()
        }
    }

    // MARK: - Delegate Methods SheetOperationViewDelegate {
    func didClickItem(identifier: String, finishGuide: Bool, itemIsEnable: Bool, disableReason: OperationItemDisableReason, at view: SKOperationView) {
        guard itemIsEnable else { return }
        delegate?.didClickOperation(identifier: identifier,
                                    tableID: params.items.first(where: { $0.id.rawValue == identifier })?.tableId,
                                    rightIconID: nil)
    }

    func shouldDisplayBadge(identifier: String, at view: SKOperationView) -> Bool { false }
}
