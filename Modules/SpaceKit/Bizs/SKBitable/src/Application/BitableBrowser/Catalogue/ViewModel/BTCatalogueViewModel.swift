//
//  BTCatalogueViewModel.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/22.
//  


import RxSwift
import RxCocoa
import SKFoundation
import SKUIKit

protocol CatalogueServiceAPI: AnyObject {
    func request(callback: String, params: [String: Any])
    func shouldPopoverDisplay() -> Bool
}

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    associatedtype Model
    
    func transform(input: Input) -> Output
}

final class BTCatalogueViewModel: ViewModelType {
    
    typealias Model = BTCatalogueModel
    
    struct Input {
        var trigger: PublishRelay<[String: Any]>
        var eventDrive: Driver<BTCatalogueViewController.Event>
    }

    struct Output {
        var title: PublishRelay<String>
        var catalogue: PublishRelay<BTCatalogueView.State>
        var bottomData: PublishRelay<CatalogueCreateViewData?>
        var bottomDatas: PublishRelay<[CatalogueCreateViewData]?>
        var close: PublishRelay<Void>
    }
    
    typealias OriginData = (Model, [String: Any])
    
    private var originData: OriginData?
    
    private var disposeBag = DisposeBag()
    
    fileprivate var _output: Output?
    
    fileprivate var _result: [[BitableCatalogueData]] = []
    fileprivate var _bottomDatas: [CatalogueCreateViewData] = []
    
    weak var api: CatalogueServiceAPI?
    
    /// 记录展开的table, 前端会时不时刷新，需要全局记录下
    private var expandingTables: [String: Bool] = [:]
    
    init(api: CatalogueServiceAPI) {
        self.api = api
    }
    
    func transform(input: Input) -> Output {
        
        let titleRelay = PublishRelay<String>()
        let catalogueRelay = PublishRelay<BTCatalogueView.State>()
        let bottomDataRelay = PublishRelay<CatalogueCreateViewData?>()
        let bottomDatasRelay = PublishRelay<[CatalogueCreateViewData]?>()
        let closeRelay = PublishRelay<Void>()
        
        input.trigger
             .subscribe(onNext: { [weak self] (parameters) in
                guard let self = self else { return }
                if let model = Model.deserialize(from: parameters) {
                    let isUpdate = self.originData != nil
                    self.originData = (model, parameters)
                    if model.data.isEmpty {
                        closeRelay.accept(())
                    } else {
                        self._result = self.constructData(with: model, isInit: true)
                        self._bottomDatas = model.bottomFixedDatas ?? []
                        titleRelay.accept(model.title)
                        catalogueRelay.accept(.reload(self._result, autoAdjust: !isUpdate))
                        bottomDataRelay.accept(model.bottomFixedData)
                        bottomDatasRelay.accept(model.bottomFixedDatas)
                    }
                } else {
                    DocsLogger.btError("BTCatalogue Model deserialize fail")
                }
           }).disposed(by: disposeBag)
        
        handleViewEvent(event: input.eventDrive)
        
        let output = Output(title: titleRelay,
                            catalogue: catalogueRelay,
                            bottomData: bottomDataRelay,
                            bottomDatas: bottomDatasRelay,
                            close: closeRelay)
        _output = output
        return output
    }
}

// MARK: - internal func

extension BTCatalogueViewModel {
 
    /// 是否可以弹出VC
    static func isCanShow(_ parameters: [String: Any]) -> Bool {
        if let model = Model.deserialize(from: parameters), model.data.isEmpty == false {
            return true
        }
        return false
    }
    
    var bottomViewsHeight: CGFloat {
        BTCatalogueCreateStackView.height(_bottomDatas.count)
    }
}

// MARK: - 数据处理

extension BTCatalogueViewModel {
    
    private func constructData(with model: Model, isInit: Bool = false) -> [[BitableCatalogueData]] {
        var result: [[BitableCatalogueData]] = []
        for node in model.data {
            var sectionData: [BitableCatalogueData] = []
            sectionData.append(node)
            if isInit, let value = expandingTables[node.id] {
                node.isExpand = value
            }
            if node.isExpand {
                sectionData.append(contentsOf: node.views)
            }
            if isInit == false {
               expandingTables[node.id] = node.isExpand
            }
            result.append(sectionData)
        }
        return result
    }
    
    /// 点击展开和收起时对数据源的更新。收起时移除分组下的子节点；展开时添加分组下的子节点
    private func updateData(_ model: Model, data: BTCatalogueModel.CatalogueDataModel, _ indexPath: IndexPath, isExpand: Bool) -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        for idx in 0..<data.views.count {
            indexPaths.append(IndexPath(row: indexPath.row + idx + 1, section: indexPath.section))
        }
        _result = self.constructData(with: model)
        return indexPaths
    }
}

// MARK: - 业务交互

extension BTCatalogueViewModel {
    
    /// 处理UI事件
    private func handleViewEvent(event: Driver<BTCatalogueViewController.Event>) {
        event.drive(onNext: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case let .choose(indexPath):
                self.chooseAction(indexPath)
            case let .add(sourceView, data):
                self.addAction(sourceView: sourceView, data: data)
            case let .slide(indexPath, action, sourceView):
                self.slideAction(indexPath, action, sourceView)
            case .dismiss:
                self.dismissAction()
            default:
                DocsLogger.btInfo("BTCatalogue \(event) is not supported")
            }
        }).disposed(by: disposeBag)
    }
    
    /// 选中一级目录和二级目录
    /// - Parameter indexPath: 现在有多组， 即 section 不一定等于 0
    private func chooseAction(_ indexPath: IndexPath) {
        guard indexPath.section < _result.count else {
            assertionFailure()
            return
        }
        guard indexPath.row < _result[indexPath.section].count else {
            assertionFailure()
            return
        }
        let item = self._result[indexPath.section][indexPath.row]
        if let model = item as? BTCatalogueModel.CatalogueDataModel { // 一级
            guard let parentModel = originData?.0 else {
                return
            }
            guard let data = self.originData?.0 else { return }
            if model.canExpand {
                model.isExpand = !model.isExpand
                var idxs = updateData(parentModel, data: model, indexPath, isExpand: model.isExpand )
                if model.isExpand {
                    if !UserScopeNoChangeFG.ZJ.tableViewUpdateFixDisable {
                        //crash 防护 剔除不符合预期的indexPath
                        idxs = idxs.filter({ $0.section < _result.count && $0.row < _result[$0.section].count })
                    }
                    _output?.catalogue.accept(.add(_result, idxs))
                } else {
                    _output?.catalogue.accept(.delete(_result, idxs))
                }
                let oprationId: CatalogueOprationId = model.isExpand ? .unfoldTable : .foldTable
                self.api?.request(callback: data.callback, params: ["blockId": model.id,
                                                                    "id": oprationId.rawValue])
            } else {
                model.isExpand = true
                self.api?.request(callback: data.callback, params: ["blockId": model.id,
                                                                    "id": CatalogueOprationId.switch.rawValue])
                DocsLogger.btInfo("BTCatalogue can not expand")
            }
            
        } else if let model = item as? BTCatalogueModel.CatalogueDataViewModel { // 二级
            model.active = true
            guard let data = self.originData?.0 else { return }
            self.api?.request(callback: data.callback, params: ["blockId": model.tableId,
                                                                "viewId": model.id,
                                                                "id": CatalogueOprationId.switch.rawValue])
        }
    }
    
    /// 底部添加事件
    func addAction(sourceView: Weak<UIView>? = nil, data: CatalogueCreateViewData? = nil) {
        guard let originData = self.originData?.0 else { return }
        var params = [String: Any]()
        if api?.shouldPopoverDisplay() == true, let sourceView = sourceView?.value {
            params["sourceViewID"] = BTPanelService.weakBindSourceView(view: sourceView)
        }
        params["id"] = data?.id?.rawValue
        self.api?.request(callback: originData.callback, params: params)
    }
    
    /// 左滑事件
    private func slideAction(_ indexPath: IndexPath, _ action: BTCatalogueContextualAction.ActionType, _ sourceView: Weak<UIView>?) {
        guard let data = self.originData?.0 else { return }
        guard indexPath.section < _result.count else {
            assertionFailure()
            return
        }
        guard indexPath.row < _result[indexPath.section].count else {
            assertionFailure()
            return
        }
        var params = [String: Any]()
        if api?.shouldPopoverDisplay() == true, let sourceView = sourceView?.value {
            params["sourceViewID"] = BTPanelService.weakBindSourceView(view: sourceView)
        }
        let item = self._result[indexPath.section][indexPath.row]
        if let model = item as? BTCatalogueModel.CatalogueDataModel { // 一级
            let oprationId: CatalogueOprationId = (action == .add ? .addView : .more)
            params["blockId"] = model.id
            params["id"] = oprationId.rawValue
            self.api?.request(callback: data.callback, params: params)
        } else if let model = item as? BTCatalogueModel.CatalogueDataViewModel { // 二级
            let oprationId: CatalogueOprationId = (action == .add ? .addView : .more)
            params["blockId"] = model.tableId
            params["viewId"] = model.id
            params["id"] = oprationId.rawValue
            self.api?.request(callback: data.callback, params: params)
        }
    }
    
    func dismissAction() {
        guard let model = self.originData?.0 else { return }
        DocsLogger.btInfo("BTCatalogue: dismiss VC")
        self.api?.request(callback: model.callback,
                          params: ["id": CatalogueOprationId.exit.rawValue])
    }
}
