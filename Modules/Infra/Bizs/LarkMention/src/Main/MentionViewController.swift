//
//  MentionViewController.swift
//  LarkMention
//
//  Created by Yuri on 2019/3/3.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import SnapKit
import UniverseDesignShadow

final class MentionViewController: UIViewController, MentionType, UIPopoverPresentationControllerDelegate {
    func search(text: String) {
        provider?.search(text: text)
    }
    
    var dismissObserver: NSObjectProtocol?
    var defaultItems: [PickerOptionType]?
    
    var searchParameters: MentionSearchParameters
    
    let disposeBag = DisposeBag()
    
    var passthroughViews: [UIView]? {
        didSet {
            self.popoverPresentationController?.passthroughViews = passthroughViews
        }
    }
    internal var uiParameters: MentionUIParameters
    private var mentionTracker: MentionTraker
    
    private var fromVc: UIViewController?
    internal var sourceView: UIView?
    private var currentSizeClass: UIUserInterfaceSizeClass = .unspecified
    
    var contentView: MentionResultView
    private var layoutManager: MentionLayoutManager
    private var layout: MentionLayoutManager.MentionLayout {
        return layoutManager.layout
    }
    
    internal var provider: MentionDataProviderType?
    private var vm = MentionViewModel()
    weak var delegate: MentionPanelDelegate?
    
    var recommendItems: [PickerOptionType]? {
        didSet {
            vm.recommendItems = recommendItems
        }
    }
    
    var didDismssHandler: ((Bool) -> Void)?
    
    deinit {
        print(" " + "\("deinit")")
        if let dismissObserver = dismissObserver {
            NotificationCenter.default.removeObserver(dismissObserver)
        }
    }
    
    init(mentionTracker: MentionTraker,
        uiParameters: MentionUIParameters = MentionUIParameters(),
                searchParameters: MentionSearchParameters = MentionSearchParameters(),
                provider: MentionDataProviderType? = nil
                ) {
        self.uiParameters = uiParameters
        self.mentionTracker = mentionTracker
        self.searchParameters = searchParameters
        self.provider = provider
        self.contentView = MentionResultView(parameters: uiParameters, mentionTracker: mentionTracker)
        self.layoutManager = MentionLayoutManager(uiParam: uiParameters)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        view.addSubview(contentView)
    }
    
    private func addTableViewLoadMore() {
        contentView.tableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.provider?.loadMore()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindUIAction()
        
        dismissObserver = NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.onDismiss(false)
        }
        let tableView = contentView.tableView
        let cellId = String(describing: MentionItemCell.self)
        
        bindVMAction()
        
        provider?.didEventHandler = { [weak self] in
            guard let self = self else { return }
            self.vm.update(event: $0)
        }
        layoutManager.didLayoutUpdateHandler = { [weak self] layout in
            guard let self = self else { return }
            if self.layoutManager.style == .pad {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.preferredContentSize = CGSize(width: layout.width, height: layout.height)
                CATransaction.commit()
            } else {
                self.contentView.snp.updateConstraints {
                    $0.top.equalTo(self.view.snp.bottom).offset(-layout.height)
                    $0.height.equalTo(layout.contentHeight)
                }
            }
        }

        setLayout()
    }
    
    // 设置布局
    private func setLayout() {
        // 计算布局 SlideOver (Screen.h - VC.h) / 2
        let vh = UIApplication.shared.keyWindow?.bounds.size.height ?? 0
        layoutManager.screenHeight = vh
        if let keyboardHeight = layoutManager.uiParam.keyboardHeight {
            let sh = UIScreen.main.bounds.height
            let height = ((sh - vh) / 2)
            layoutManager.keyboardHeight = keyboardHeight - height
        }
        layoutManager.compute()
        // 设置布局
        if layoutManager.style == .pad {
            self.preferredContentSize = CGSize(width: layout.width, height: layout.height ?? 0)
        } else {
            
        }
    }
    
    private func bindVMAction() {
        vm.didStartLoadHandler = { [weak self] (items, state) in
            guard let self = self else { return }
            self.contentView.reloadTable(items: items, isSkeleton: state.isShowSkeleton)
            self.contentView.updateTableScroll()
            self.addTableViewLoadMore()
        }
        vm.didEndLoadHandler = { [weak self] (items, state) in
            guard let self = self else { return }
            self.contentView.reloadTable(items: items, isSkeleton: state.isShowSkeleton)
            self.contentView.tableView.endBottomLoadMore(hasMore: state.hasMore)
        }
        vm.didSwitchMultiSelectHandler = { [weak self] (items, state) in
            guard let self = self else { return }
            self.contentView.reloadTable(items: items, isSkeleton: state.isShowSkeleton)
        }
        vm.didReloadItemAtRowHandler = { [weak self] (items, rows) in
            guard let self = self else { return }
            self.contentView.reloadTableAtRows(items: items, rows: rows)
        }
        vm.didCompleteHandler = { [weak self] in
            self?.onDismiss(true)
        }
        // 绑定加载状态
        vm.state.map { $0.isLoading }.distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.contentView.isLoading = $0
            }).disposed(by: disposeBag)
        // 绑定骨架屏状态
        vm.state.map { $0.isShowSkeleton }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.contentView.isUserInteractionEnabled = !$0
            }).disposed(by: disposeBag)
        // 绑定错误状态
        vm.state.map { $0.error }
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                guard let error = $0 as? MentionViewModel.VMError else {
                    self.contentView.error = nil
                    return
                }
                switch error {
                case .noResult:
                    if let noResultText = self.uiParameters.noResultText, !noResultText.isEmpty {
                        self.contentView.error = noResultText
                    } else {
                        self.contentView.error = BundleI18n.LarkMention.Lark_Mention_NoResultsFound_Mobile
                    }
                case .network(_):
                    self.contentView.error = BundleI18n.LarkMention.Lark_Mention_ErrorUnableToLoad_Mobile
                }
            }).disposed(by: disposeBag)
    }
    
    private func bindUIAction() {
        contentView.didSwitchMulitSelectHandler = { [weak self] in
            self?.vm.switchMultiSelect(isOn: $0)
        }
        contentView.didSelectRowHandler = { [weak self] in
            guard let self = self else { return }
            self.vm.selectItem(at: $0)
        }
        contentView.didSwitchGlobalCheckBoxHandler = { [weak self] in
            self?.vm.switchGlobalCheckBox(isSelected: $0)
            self?.mentionTracker.mentionTrakerPost(action: .checkboxClick, targer: "none",
                                                   isCheckSelected: $0)
        }
        contentView.didUpdateHeightHandler = { [weak self] in
            self?.layoutManager.updateHeight($0)
        }
    }
    
    @objc func onDismiss(_ animated: Bool = true) {
        if self.popoverPresentationController == nil {
            self.updateSelfViewHeight(0) { [weak self] in
                guard let self = self else { return }
                self.view.removeFromSuperview()
                self.removeFromParent()
                self.handleDismiss()
            }
        } else {
            self.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.handleDismiss()
            }
        }
        self.mentionTracker.mentionTrakerPost(action: .close, targer: "none")
    }
    
    private func handleDismiss() {
        let isSelected = self.vm.currentState.isGlobalCheckBoxSelected ?? false
        self.didDismssHandler?(isSelected)
        let items = vm.currentItems.filter { $0.isMultipleSelected }
        delegate?.panel(didFinishWith: items)
        if let isGlobalSelected = vm.currentState.isGlobalCheckBoxSelected {
            delegate?.panel(didDismissWithGlobalCheckBox: isGlobalSelected)
        }
    }
    
    func show(from vc: UIViewController, sourceView: UIView? = nil) {
        self.fromVc = vc
        self.sourceView = sourceView
        setup()
        setupVC(horizontalSizeClass: vc.traitCollection.horizontalSizeClass)
        self.mentionTracker.mentionTrakerPost(action: .show)
    }
    
    // MARK: Private - UI control
    private func setupVC(horizontalSizeClass: UIUserInterfaceSizeClass) {
        guard let fromVc = fromVc else { return }
        let isRegular = horizontalSizeClass == .regular
        layoutManager.style = isRegular ? .pad : .phone
        if layoutManager.style == .pad {
            showPopoverController(sourceView, fromVc)
        } else {
            addToSuperController(fromVc)
        }
        currentSizeClass = horizontalSizeClass
    }
    
    fileprivate func showPopoverController(_ sourceView: UIView?, _ fromVc: UIViewController) {
        self.modalPresentationStyle = .popover
        let popoverPresentationController = self.popoverPresentationController
        popoverPresentationController?.delegate = self
        popoverPresentationController?.sourceView = sourceView
        popoverPresentationController?.popoverLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        fromVc.present(self, animated: true) {
            
        }
        contentView.insetsLayoutMarginsFromSafeArea = true
        contentView.snp.makeConstraints {
            $0.edges.equalTo(UIEdgeInsets.zero)
        }
    }
    
    private func addToSuperController(_ fromVc: UIViewController) {
        fromVc.addChild(self)
        fromVc.view.addSubview(view)
        let contentH = layout.contentHeight
        let height = layout.height
        let keyboardH = max(0, height - contentH)
        view.snp.makeConstraints {
           $0.edges.equalTo(UIEdgeInsets.zero)
        }
        
        contentView.layer.ud.setShadow(type: .s3Up)
        contentView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(contentH)
            $0.top.equalTo(view.snp.bottom).offset(-contentH)
        }
        let alphaView = UIView()
        view.addSubview(alphaView)
        alphaView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.bottom.equalTo(contentView.snp.top)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onDismiss(_:)))
        alphaView.addGestureRecognizer(tap)
        
        fromVc.view.layoutIfNeeded()
        updateSelfViewHeight(layout.height) {}
    }
    
    private func updateSelfViewHeight(_ height: CGFloat, completion: @escaping (() -> Void)) {
        contentView.snp.updateConstraints {
            $0.top.equalTo(view.snp.bottom).offset(-height)
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            completion()
        }
    }
    
    private func amendPopoverLayout() {
        if let direction = popoverPresentationController?.arrowDirection {
            let left: CGFloat = direction == .left ? 16 : 0
            let right: CGFloat = direction == .right ? 16 : 0
            let up: CGFloat = direction == .up ? 16 : 0
            let down: CGFloat = direction == .down ? 16 : 0
            var insets = UIEdgeInsets(top: up, left: left, bottom: down, right: right)
            self.contentView.contentInsets = insets
            popoverPresentationController?.permittedArrowDirections = direction
        }
    }
    
    // MARK: - Private
    private var currentSize = CGSize.zero
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        amendPopoverLayout()
        let size = UIApplication.shared.keyWindow?.bounds.size ?? .zero
        if currentSize == .zero || currentSize == size {
            currentSize = size
            return
        }
        onDismiss(false)
        currentSize = size
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        handleDismiss()
    }
}
