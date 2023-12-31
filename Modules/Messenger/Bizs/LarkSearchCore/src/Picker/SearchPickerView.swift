//
//  SearchPickerView.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/2/20.
//

import UIKit
import SnapKit
import UniverseDesignColor
import EENavigator
import LarkModel
import LarkContainer

final public class SearchPickerView: ChatterPicker, SearchPickerType {
    weak public var pickerDelegate: LarkModel.SearchPickerDelegate?

    public var searchConfig = PickerSearchConfig()

    var navigationBar: PickerSearchBar?
    var contentView: PickerContentView?
    var headerView: UIView?
    var topView: UIView?

    var didCloseHandler: (() -> Void)?

    let context: PickerContext

    override func createSelectedView(frame: CGRect, delegate: SelectedViewDelegate) -> SelectedView {
        let multiSelection = context.featureConfig.multiSelection
        let view = PickerSelectedView(style: multiSelection.selectedViewStyle,
                                      delegate: self,
                                      supportUnfold: multiSelection.supportUnfold)
        view.scene = scene
        view.userId = context.userId
        view.isUseDocIcon = self.featureGating.isEnable(name: .corePickerDocicon)
        return view
    }

    init(resolver: LarkContainer.UserResolver, context: PickerContext = PickerContext(), searchConfig: PickerSearchConfig) {
        self.context = context
        let featureConfig = context.featureConfig
        let param = ChatterPicker.InitParam()
        param.supportUnfold = true
        param.targetPreview = featureConfig.targetPreview.isOpen
        let multiSelection = featureConfig.multiSelection
        param.isMultiple = multiSelection.isOpen && multiSelection.isDefaultMulti
        if let permissions = searchConfig.permissions {
            param.permissions = permissions
        }
        super.init(resolver: resolver, frame: .zero, params: param)
        self.searchConfig = searchConfig
        self.defaultView = UIView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        searchBar.backgroundColor = .clear
        let navigationBar = PickerSearchBar(context: self.context, searchBar: self.searchBar)
        self.navigationBar = navigationBar
        let contentView = PickerContentView(context: self.context,
                                            navigationBar: navigationBar,
                                            headerView: self.headerView,
                                            selectionView: getMultiSelectionView(),
                                            topView: self.topView,
                                            defaultView: defaultView, listView: resultView)
        self.contentView = contentView
        if let placeholder = context.featureConfig.searchBar.placeholder {
            searchBar.searchUITextField.placeholder = placeholder
        }
        addSubview(contentView)
        navigationBar.snp.makeConstraints {
            $0.height.equalTo(52)
        }
        contentView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.trailing.leading.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        searchBar.searchUITextField.snp.remakeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.height.equalTo(36)
            $0.centerY.equalToSuperview()
        }

        navigationBar.didCancelHandler = { [weak self] in
            self?.didCloseHandler?()
        }
    }

    override func viewLoaded() {
        super.viewLoaded()
        render()
        if context.featureConfig.searchBar.autoFocus {
            self.searchBar.searchUITextField.becomeFirstResponder()
        }
        self.searchBar.searchUITextField.autocorrectionType = context.featureConfig.searchBar.autoCorrect ? .default : .no

        // 清除现有Picker的默认设置
        var searchContext = searchVM.query.context.value
        searchContext[SearchRequestIncludeOuterTenant.self] = nil
        searchContext[AuthPermissionsKey.self] = searchConfig.permissions
        searchContext[SearchRequestExcludeTypes.chat] = nil
        searchContext[SearchRequestExcludeTypes.department] = nil
        searchContext[SearchRequestExcludeTypes.local] = nil
        searchVM.query.context.accept(searchContext)
    }

    public func reload(search: Bool, recommend: Bool) {
        if search {
            let query = self.searchVM.query.text.value
            searchVM.rebind(result: makeListVM())
            bindResultView().disposed(by: self.bag)
            self.searchVM.query.text.accept(query)
        }
        if recommend, let recommendView = defaultView as? PickerRecommendListView {
            recommendView.featureConfig = self.context.featureConfig
            recommendView.searchConfig = self.searchConfig
            recommendView.reload()
        }
    }

    public func reload() {
        reload(search: true, recommend: true)
    }

    // MARK: - Private
    override func configure(vm: SearchSimpleVM<Item>) {}
    override func makeListVM() -> SearchListVM<Item> {
        SearchListVM<Item>(source: makeSource(), pageCount: Self.defaultPageCount)
    }
    override func makeSource() -> SearchSource {
        // 构造搜索器
        let maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.addChatChatters))
        return maker.makeSource(config: searchConfig)
    }

    private func getMultiSelectionView() -> UIView? {
        if context.featureConfig.multiSelection.isOpen {
            let selectionView = self.selectedView
            selectionView.snp.remakeConstraints {
                $0.height.equalTo(56)
            }
            return selectionView
        }
        return nil
    }
}
