//
//  BTFilterValueLinksController.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/27.
//  


import UIKit
import RxSwift
import SKFoundation
import SKResource

final class BTFilterValueLinksController: BTFilterValueBaseController {
    
    private var initValue: [BTLinkRecordModel]
    
    let filterContentView: BTFilterLinksView
    var viewModel: BTFilterValueLinkViewModel
    
    private let disposeBag = DisposeBag()
    // 是否从筛选过来的，如果不是需要保持原来的逻辑
    private var isFromNewFilter: Bool = false
    
    init(title: String,
         btViewModel: BTFilterValueLinkViewModel) {
        filterContentView = BTFilterLinksView(isAllowMultipleSelect: btViewModel.isAllowMultipleSelect)
        initValue = filterContentView.selecteds
        viewModel = btViewModel
        super.init(title: title, shouldShowDragBar: false, shouldShowDoneButton: true)
    }
    
    init(title: String,
         items: [BTLinkRecordModel], allowMultipleSelect: Bool = true) {
        self.filterContentView = BTFilterLinksView(datas: items, isAllowMultipleSelect: allowMultipleSelect)
        self.initValue = items
        self.isFromNewFilter = true
        viewModel = BTFilterValueLinkViewModel(fieldId: "", selectedRecordIds: [], isAllowMultipleSelect: true, btDataService: nil)
        super.init(title: title, shouldShowDragBar: false, shouldShowDoneButton: true)
        self.filterContentView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        initViewHeight = maxViewHeight
        super.setupUI()
        setupContentView()
        bindActions()
        if !isFromNewFilter {
            getFilterValueDataTypeLinks(isInitial: true)
        }
    }
    
    override func getValuesWhenFinish() -> [AnyHashable] {
        return self.filterContentView.selecteds.compactMap { $0.id }
    }
    
    override func isValueChange() -> Bool {
        return initValue != self.filterContentView.selecteds
    }
    
    func update(_ datas: [BTLinkRecordModel]) {
        self.initValue = datas
        self.filterContentView.setData(data: datas)
    }
    
    private func setupContentView() {
        contentView.addSubview(filterContentView)
        filterContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func bindActions() {
        filterContentView.searchView.searchTextField.rx.text.orEmpty.changed
            .subscribe(onNext: { [weak self] keywords in
                guard let self = self else { return }
                if self.isFromNewFilter {
                    self.delegate?.search(keywords)
                } else {
                    self.getFilterValueDataTypeLinks(isInitial: false)
                }
            }).disposed(by: disposeBag)
    }
    
    private func getFilterValueDataTypeLinks(isInitial: Bool) {
        DocsLogger.btInfo("[BTFilterValueLinksController] getFieldLinkOptionsByIds isInitial:\(isInitial)")
        let getFilterValueDataTypeLinksBlock = { [weak self] in
            guard let self = self else { return }
            self.viewModel.getFilterValueDataTypeLinks(keywords: self.filterContentView.searchText) { result in
                self.filterContentView.hideLoading()
                self.handleAsyncResponse(result: result, isInitial: isInitial)
            } resultHandler: { result in
                 if case let .failure(_) = result {
                    self.filterContentView.hideLoading()
                    self.handleRequestFailed(isInitial: isInitial)
                }
            }
        }
        
        filterContentView.startLoadingTimer()
        if isInitial, viewModel.selectedRecordIds.isEmpty == false {
            viewModel.getFieldLinkOptionsByIds(recordIds: viewModel.selectedRecordIds, responseHandler: { [weak self] result in
                switch result {
                case .success(let selectedModels):
                    let models = selectedModels.compactMap({ model in
                        var newModel = model
                        newModel.isSelected = true
                        return newModel
                    })
                    
                    self?.viewModel.updateSelectedRecordModel(models)
                case .failure(let error):
                    DocsLogger.btError("[BTFilterValueLinksController] getFieldLinkOptionsByIds failed error:\(error.description)")
                }
                
                getFilterValueDataTypeLinksBlock()
            }, resultHandler: { [weak self] result in
                if case let .failure(_) = result {
                    getFilterValueDataTypeLinksBlock()
                }
            })
        } else {
            getFilterValueDataTypeLinksBlock()
        }
    }
    
    ///前端异步请求回调
    private func handleAsyncResponse(result: Result<[BTLinkRecordModel], BTAsyncRequestError>, isInitial: Bool) {
        DocsLogger.btInfo("[BTFilterValueLinksController] handleAsyncResponse")
        switch result {
        case .success(let data):
            filterContentView.handleData(data: viewModel.joinAndUpdate(data))
        case .failure(let error):
            DocsLogger.btError("[BTFilterValueLinksController] [BTAsyncRequest] async request failed error:\(error.description)")
            handleRequestFailed(isInitial: isInitial)
        }
    }
    
    private func handleRequestFailed(isInitial: Bool) {
        DocsLogger.btInfo("[BTFilterValueLinksController] handleRequestFailed isInitial:\(isInitial)")
        filterContentView.showTryAgainEmptyView(text: BundleI18n.SKResource.Bitable_SingleOption_ReloadTimeoutRetry(BundleI18n.SKResource.Bitable_Common_ButtonRetry),
                                                      type: .searchFailed) { [weak self] in
            //重新发起请求
            self?.getFilterValueDataTypeLinks(isInitial: isInitial)
        }
    }
}

extension BTFilterValueLinksController: BTFilterLinksViewDelegate {
    func valueChanged(_ value: BTLinkRecordModel, selected: Bool) {
        self.delegate?.valueSelected(value, selected: selected)
    }
}
