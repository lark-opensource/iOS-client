//
//  BTFilterValueMembersController.swift
//  SKBitable
//
//  Created by X-MAN on 2023/1/29.
//

import SKFoundation
import SKUIKit
import SKCommon
import SKBrowser
import RxSwift
import SKResource
import UniverseDesignColor
import LarkSetting
import LarkNavigator
import EENavigator
import UniverseDesignToast

final class BTFilterValueChattersController: BTFilterValueBaseController, BTSelectedChatterCollectionViewDelegate {
    
    private var initValue: [MemberItem]
    
    let filterContentView: BTFilterChattersView
    
    private var viewModel: BTFilterValueChatterViewModel
    
    private let disposeBag = DisposeBag()
    // 是否从筛选过来的，如果不是需要保持原来的逻辑
    private var isFromNewFilter: Bool = false
        
    init(title: String,
         viewModel: BTFilterValueChatterViewModel) {
        filterContentView = BTFilterChattersView(viewModel: viewModel, isAllowMultipleSelect: viewModel.isAllowMultipleSelect)
        self.viewModel = viewModel
        initValue = filterContentView.selecteds
        super.init(title: title, shouldShowDragBar: false, shouldShowDoneButton: true)
    }
    
    init(title: String, datas:[MemberItem], isAllowMultipleSelect: Bool = true) {
        self.filterContentView = BTFilterChattersView(datas: datas, isAllowMultipleSelect: isAllowMultipleSelect)
        self.initValue = datas
        self.isFromNewFilter = true
        // 假的
        self.viewModel = BTFilterValueChatterViewModel(fieldId: "", selectedMembers: [], isAllowMultipleSelect: true, chatterType: .group, btDataService: nil)
        super.init(title: title, shouldShowDragBar: false, shouldShowDoneButton: true)
        self.filterContentView.delegate = self
    }
    
    func setData(datas:[MemberItem], isAllowMultipleSelect: Bool = true) {
        self.initValue = datas
        self.filterContentView.handleData(data: datas)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        initViewHeight = maxViewHeight
        super.setupUI()
        setupContentView()
    }
    
    override func getValuesWhenFinish() -> [AnyHashable] {
        return self.filterContentView.selecteds.map {
            var values = ["name": $0.title,
                          "enName": $0.detail ?? "",
                          "avatarUrl": $0.imageURL ?? ""]
            switch viewModel.chatterType {
            case .group:
                values["id"] = $0.identifier
                values["linkToken"] = $0.token
            case .user:
                values["userId"] = $0.identifier
            }
            return values
        }
    }
    
    override func isValueChange() -> Bool {
        return initValue != self.filterContentView.selecteds
    }
    
    func update(_ datas:[MemberItem]) {
        self.initValue = datas
        self.filterContentView.setData(data: datas)
    }
    
    private func setupContentView() {
        filterContentView.selectedMemberListView.btDelegate = self
        contentView.addSubview(filterContentView)
        filterContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        if !isFromNewFilter {
            fetchMemberData(isInitial: true)
        }
        bindActions()
    }
    
    func didClickItem(with model: SKBrowser.BTCapsuleModel, fileName: String?) {
        
        switch viewModel.chatterType {
        case .group:
            // 筛选里群不跳转
            DocsLogger.info("[BTFilterMemberView] clickItem")
        case .user:
            HostAppBridge.shared.call(ShowUserProfileService(userId: model.userID, fileName: fileName, fromVC: self))
        }
    }
    
    func bindActions() {
        filterContentView.selectedMemberListView.didClose
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                self.filterContentView.searchView.searchTextField.endEditing(true)
                self.filterContentView.deselected(at: index, isHandleAll: false)
            }).disposed(by: disposeBag)
        
        filterContentView.searchView.searchTextField.rx.text.orEmpty.changed
            .subscribe(onNext: { [weak self] content in
                guard let self = self else { return }
                if self.isFromNewFilter {
                    self.delegate?.search(content)
                } else {
                    self.fetchMemberData(isInitial: false)
                }
            }).disposed(by: disposeBag)
    }
    
    private func fetchMemberData(isInitial: Bool) {
        DocsLogger.btInfo("[BTFilterMemberView] type: \(self.viewModel.chatterType.logDesc) fetchUserData isInitial:\(isInitial)")
        filterContentView.startLoadingTimer()
        viewModel.getFilterValueDataTypeChatter(keywords: filterContentView.searchText) { [weak self] result in
            self?.filterContentView.hideLoading()
            self?.handleAsyncResponse(result: result, isInitial: isInitial)
        } resultHandler: { [weak self] result in
            if case .failure(_) = result {
                self?.filterContentView.hideLoading()
                self?.handleRequestFailed(isInitial: isInitial)
            }
        }
    }
    
    ///前端异步请求回调
    private func handleAsyncResponse(result: Result<[MemberItem], BTAsyncRequestError>, isInitial: Bool) {
        DocsLogger.btInfo("[BTFilterChatterView] handleAsyncResponse")
        switch result {
        case .success(let data):
            filterContentView.handleData(data: data)
        case .failure(let error):
            DocsLogger.btError("[BTFilterChatterView] [BTAsyncRequest] BTFilterMemberView async request failed error:\(error.description) type: \(self.viewModel.chatterType.logDesc)")
            handleRequestFailed(isInitial: isInitial)
        }
    }
    
    private func handleRequestFailed(isInitial: Bool) {
        DocsLogger.btInfo("[BTFilterChatterView] handleRequestFailed isInitial:\(isInitial) type: \(self.viewModel.chatterType.logDesc)")
        filterContentView.showTryAgainEmptyView(text: BundleI18n.SKResource.Bitable_SingleOption_ReloadTimeoutRetry(BundleI18n.SKResource.Bitable_Common_ButtonRetry),
                                                      type: .searchFailed) { [weak self] in
            //重新发起请求
            self?.fetchMemberData(isInitial: isInitial)
        }
    }
}

extension BTFilterValueChattersController: BTFilterChattersViewDelegate {
    func valueChanged(_ value: SKCommon.MemberItem, selected: Bool) {
        self.delegate?.valueSelected(value, selected: selected)
    }
}
