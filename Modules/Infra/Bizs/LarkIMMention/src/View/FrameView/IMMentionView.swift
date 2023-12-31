//
//  IMMentionResultView.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignIcon

final class IMMentionView: UIView {
    private let contentView = UIView()
    var headerView = IMMentionHeaderView()
    private var searchWrapper = SearchUITextFieldWrapperView()
    var selectedView = IMMentionSelecdView()
    private var lineView = UIView()
    private var count = 0
    private var lastSearch = ""
    var tabsView: IMMentionTabsView
    var searchTextField: SearchUITextField
    private let disposeBag = DisposeBag()
    
    var didSwitchMulitSelectHandler: ((Bool) -> Void)?
    var didSearchTextChangeHandler: ((String) -> Void)?
    var didUnfoldSelectedItems: (() -> Void)?
    var didSwitchSingleHandle: (() -> Void)?
    var didDismiss: (() -> Void)?
    var didChangeHeightHandler: ((CGFloat, UIGestureRecognizer.State) -> Void)?
    
    private var headerHeight: CGFloat = 60
    
    init() {
        searchTextField = searchWrapper.searchUITextField
        tabsView = IMMentionTabsView()
        super.init(frame: CGRect.zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI() {
        setupContentUI()
        setupHeaderUI()
        setupSearchView()
        setupSelectedViews()
        setupLineView()
        setupTabsView()
        setupUIAction()
    }
    
    private func setupContentUI() {
        self.backgroundColor = UIColor.ud.bgBody
        addSubview(contentView)
        contentView.snp.makeConstraints {
           $0.edges.equalTo(UIEdgeInsets.zero)
        }
    }
    
    private func setupHeaderUI() {
        contentView.addSubview(headerView)
        if self.traitCollection.horizontalSizeClass == .regular {
            headerView.lineView.isHidden = true
            headerHeight = 48
        }
        headerView.snp.makeConstraints {
            $0.leading.top.trailing.equalToSuperview()
            $0.height.equalTo(headerHeight)
        }
    }
    
    private func setupSearchView() {
        contentView.addSubview(searchWrapper)
        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_Placeholder
        searchWrapper.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(2)
            $0.height.equalTo(42)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
        }
        searchTextField.rx.text.asDriver().skip(1)
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2
            })
            .debounce(.milliseconds(150))
            .drive(onNext: { [weak self] (text) in
                guard self?.lastSearch != text else { return }
                self?.lastSearch = text ?? ""
                self?.didSearchTextChangeHandler?(text ?? "")
            }).disposed(by: disposeBag)
        
    }
    
    private func setupSelectedViews() {
        contentView.addSubview(selectedView)
        selectedView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(searchWrapper.snp.bottom).offset(8)
            $0.height.equalTo(52)
        }
        selectedView.isHidden = true
    }
    
    private func setupLineView() {
        lineView.backgroundColor = UIColor.ud.bgBase
        contentView.addSubview(lineView)
        lineView.snp.makeConstraints {
            $0.top.equalTo(searchWrapper.snp.bottom).offset(8)
            $0.height.equalTo(8)
            $0.leading.trailing.equalToSuperview()
        }
    }
    
    private func setupTabsView() {
        contentView.addSubview(tabsView)
        tabsView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(lineView.snp.bottom)
        }
    }
    
    private func setupUIAction() {
        headerView.multiBtn.addTarget(self, action: #selector(onMultiSelectClick(btn:)), for: .touchUpInside)
        selectedView.unfoldButton.addTarget(self, action: #selector(unfoldSelectedItems), for: .touchUpInside)
        headerView.closeBtn.addTarget(self, action: #selector(closeView), for: .touchUpInside)
        if self.traitCollection.horizontalSizeClass != .regular {
            contentView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:))))
        }
        tabsView.didEndEditing = { [weak self] in
            guard let self = self else { return }
            self.stopEditing()
        }
        for item in tabsView.tabItems {
            item.didEndEditing = { [weak self] in
                guard let self = self else { return }
                self.stopEditing()
            }
        }
    }
    
    @objc private func onMultiSelectClick(btn: UIButton) {
        btn.isSelected = !btn.isSelected
        didSwitchMulitSelectHandler?(btn.isSelected)
        if btn.isSelected {
            updateSelectedCount(numbers: self.count)
            headerView.changeToLeftBtn()
            stopEditing()
        }
    }
    
    @objc func stopEditing() {
        self.searchTextField.endEditing(true)
    }
    
    @objc func unfoldSelectedItems() {
        didUnfoldSelectedItems?()
    }
    
    @objc func closeView() {
        if headerView.isCloseBtn {
            didDismiss?()
        } else {
            headerView.changeToCloseBtn()
            headerView.multiClear()
            headerView.multiBtn.isSelected = !headerView.multiBtn.isSelected
            selectedViewHidden()
            didSwitchSingleHandle?()
        }
    }
    
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .changed:
            let changeY = pan.translation(in: self).y
            if changeY > 0 {
                didChangeHeightHandler?(changeY,pan.state)
            }
        case .ended:
            let changeY = pan.translation(in: self).y
            didChangeHeightHandler?(changeY,pan.state)
        default:
            break
        }
    }
    
    func updateSelectedCount(numbers: Int) {
        self.count = numbers
        if numbers == 0 {
            headerView.multiBtn.isUserInteractionEnabled = false
            headerView.multiBtn.alpha = 0.4
            headerView.multiBtn.setTitleColor(UIColor.ud.N400, for: .normal)
            headerView.multiBtn.setTitleColor(UIColor.ud.N400, for: .selected)
            headerView.multiBtn.setTitle(BundleI18n.LarkIMMention.Lark_Legacy_Sure, for: .selected)
            headerView.multiBtn.setTitle(BundleI18n.LarkIMMention.Lark_Legacy_Sure, for: [.selected, .highlighted])
        } else {
            headerView.multiEnableClick()
            headerView.multiBtn.setTitle("\(BundleI18n.LarkIMMention.Lark_Legacy_Sure)(\(numbers))", for: .selected)
            headerView.multiBtn.setTitle("\(BundleI18n.LarkIMMention.Lark_Legacy_Sure)(\(numbers))", for: [.selected, .highlighted])
            selectedViewShow()
        }
    }
    
    func setError(error: String?, index: Int) {
        tabsView.tabItems[index].error = error
    }

    func reloadTable(result: IMMentionReuslt, isSkeleton: Bool, index: Int, nameIndex: [String]? = nil, nameIndexForm: Int = 0, nameDict: [Int: Int] = [:], isMultiSelect: Bool = false) {
        tabsView.tabItems[index].reloadTable(result: result, isSkeleton: isSkeleton, nameIndex: nameIndex,nameIndexForm: nameIndexForm,nameDict: nameDict, isMultiSelect: isMultiSelect)
    }
    
    func reloadTableAtRows(result: IMMentionReuslt, index: Int, indexPath: [IndexPath]) {
        tabsView.tabItems[index].reloadTableAtRows(result: result, indexPath: indexPath)
    }
    
    func updateTableScroll() {
        for item in tabsView.tabItems {
            item.updateTableScroll()
        }
    }
    
    func reloadCollect(items: [IMMentionOptionType]) {
        if items.isEmpty {
            selectedViewHidden()
        } else {
            selectedViewShow()
        }
        selectedView.reloadCollect(items: items)
    }
    
    func selectedViewHidden() {
        selectedView.isHidden = true
        lineView.snp.remakeConstraints {
            $0.top.equalTo(searchWrapper.snp.bottom).offset(8)
            $0.height.equalTo(8)
            $0.leading.trailing.equalToSuperview()
        }
    }
    
    func selectedViewShow() {
        selectedView.isHidden = false
        lineView.snp.remakeConstraints {
            $0.top.equalTo(selectedView.snp.bottom)
            $0.height.equalTo(8)
            $0.leading.trailing.equalToSuperview()
        }
    }
}

