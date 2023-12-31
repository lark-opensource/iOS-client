//
//  SearchPickerController.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/2/23.
//

import UIKit
import LarkModel
import LarkSDKInterface
import LarkContainer

final class SearchPickerController: UIViewController, SearchPickerType {
    let userResolver: LarkContainer.UserResolver
    weak var pickerDelegate: LarkModel.SearchPickerDelegate?

    let router: PickerRouterType
    let context: PickerContext
    var picker: SearchPickerView?
    var searchConfig = PickerSearchConfig() {
        didSet {
            self.picker?.searchConfig = searchConfig
        }
    }

    weak var parentVc: SearchPickerViewController?
    var didClosePickerHandler: (() -> Void)?

    var defaultView: PickerDefaultViewType?
    var headerView: UIView?
    var topView: UIView?
    weak var delegate: SearchPickerDelegate?
    // picker当前的持有vc, 用于代理回调时, 提供给业务方关闭整个Picker vc
    weak var ownerVc: SearchPickerControllerType?

    deinit {
        AttributeStringFactory.shared.clean()
        PickerLogger.shared.info(module: PickerLogger.Module.view, event: "\(self.self) deinit")
    }

    init(resolver: LarkContainer.UserResolver, context: PickerContext, router: PickerRouterType) {
        self.userResolver = resolver
        self.context = context
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    func add(to parentVc: SearchPickerViewController) {
        parentVc.addChild(self)
        view.frame = parentVc.view.bounds
        parentVc.view.addSubview(self.view)
        self.parentVc = parentVc
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.context.featureConfig.scene == .unknown {
            assertionFailure("please custom picker scene")
        }
        PickerLogger.shared.info(module: PickerLogger.Module.view, event: "setup picker") {
            do {
                let searchData = try JSONEncoder().encode(self.searchConfig)
                let searchString = String(data: searchData, encoding: .utf8) ?? ""
                let uiData = try JSONEncoder().encode(self.context.featureConfig)
                let uiString = String(data: uiData, encoding: .utf8) ?? ""
                return """
{"search": \(searchString), "ui" \(uiString)}
"""
            } catch {
                return "error: \(error.localizedDescription)"
            }
        }
        PickerBusinessParametersTracker.track(scene: self.context.featureConfig.scene,
                                              config: PickerDebugConfig(featureConfig: self.context.featureConfig,
                                                                        searchConfig: self.searchConfig))

        let picker = SearchPickerView(
            resolver: self.userResolver,
            context: context,
            searchConfig: self.searchConfig
        )
        picker.preloadItems(selects: getPreselectItems())
        picker.fromVC = self
        self.picker = picker
        picker.delegate = self
        picker.newDelegate = self.delegate
        picker.headerView = self.headerView
        picker.topView = topView
        view.addSubview(picker)
        picker.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaInsets.top)
            $0.leading.bottom.trailing.equalToSuperview()
        }

        if let defaultView = self.defaultView {
            if let recommandView = defaultView as? PickerRecommendListView {
                recommandView.featureConfig = self.context.featureConfig
                recommandView.searchConfig = self.searchConfig
                recommandView.didPresentTargetPreviewHandler = { [weak self] in
                    self?.presentTargetPreview(item: $0)
                }
            }
            defaultView.bind(picker: picker)
            picker.defaultView = defaultView
        }
        picker.didCloseHandler = { [weak self] in
            self?.dismiss()
        }
    }

    func reload(search: Bool, recommend: Bool) {
        picker?.reload(search: search, recommend: recommend)
    }

    func reload() {
        self.reload(search: true, recommend: true)
    }

    // MARK: - Action
    private func dismiss() {
        parentVc?.handleClosePicker()
    }

    private func presentTargetPreview(item: PickerItem) {
        router.presentToTargetPreviewPage(from: self, item: item)
    }

    private func getPreselectItems() -> [Option] {
        let items = context.featureConfig.multiSelection.preselectItems ?? []
        return items.compactMap {
            switch $0.meta {
            case .chatter(let i):
                return OptionIdentifier(type: OptionIdentifier.Types.chatter.rawValue, id: i.id, emailId: i.enterpriseMailAddress)
            case .chat(let i):
                return OptionIdentifier(type: OptionIdentifier.Types.chat.rawValue, id: i.id, emailId: i.enterpriseMailAddress)
            case .doc(_), .wiki(_), .wikiSpace(_), .mailUser(_):
                return $0
            default: return nil
            }
        }
    }
}

extension SearchPickerController: PickerDelegate {
    func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        let item = PickerItemFactory.shared.makeItem(option: option, currentTenantId: context.tenantId)
        if let ownerVc = self.ownerVc {
            return delegate?.pickerWillSelect(pickerVc: ownerVc, item: item, isMultiple: picker.isMultiple) ?? true
        }
        return true
    }
    func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        guard let ownerVc = self.ownerVc else { return }
        let item = PickerItemFactory.shared.makeItem(option: option, currentTenantId: context.tenantId)
        delegate?.pickerDidSelect(pickerVc: ownerVc, item: item, isMultiple: picker.isMultiple)
        if !picker.isMultiple {
            let canClose = delegate?.pickerDidFinish(pickerVc: ownerVc, items: [item]) ?? true
            if canClose {
                didClosePickerHandler?()
            }
        }
    }

    func unfold(_ picker: Picker) {
        guard let picker = self.picker, let ownerVc = self.ownerVc else { return }
        let tenantId = context.tenantId
        router.pushToMultiSelectedPage(from: self, picker: picker, context: self.context) { [weak self, weak ownerVc, weak picker] _ in
            guard let ownerVc = ownerVc, let picker = picker else { return }
            let items = picker.selected.map {
                PickerItemFactory.shared.makeItem(option: $0, currentTenantId: tenantId)
            }
            let canClose = self?.delegate?.pickerDidFinish(pickerVc: ownerVc, items: items) ?? true
            if canClose {
                self?.didClosePickerHandler?()
            }
        }
        PickerLogger.shared.info(module: PickerLogger.Module.view, event: "enter multi selected page")
    }
}
