//
//  BasePicker.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/8/9.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkCore
import SnapKit
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import UniverseDesignToast
import LarkModel
import UniverseDesignColor
import LarkListItem
import LarkContainer

// 通用Picker组件，接口需要兼容ObjC, 公开属性需要支持KVO

//注意后续from的调整可能对调用处产生影响
public protocol PickerDelegate: AnyObject {
    // MARK: Optional
    /// 选中前调用，不可选中应返回false
    func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool
    /// 选中后调用
    func picker(_ picker: Picker, didSelected option: Option, from: Any?)
    /// 取消选中前调用，不可选中应返回false
    func picker(_ picker: Picker, willDeselected option: Option, from: Any?) -> Bool
    /// 取消选中后调用
    func picker(_ picker: Picker, didDeselected option: Option, from: Any?)
    /// 是否禁止选择并展示禁止选择的样式
    func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool
    /// 是否强制选中
    func picker(_ picker: Picker, forceSelected option: Option, from: Any?) -> Bool
    /// 展开所选数据源
    func unfold(_ picker: Picker)
}

/// Picker通用初始化参数打包，防止init参数过长, 都有默认值

/// 抽象Picker，不应该直接使用
/// 该类是UI类，不保证线程安全，应该只在主线程使用
@objc(LarkPicker)
public class Picker: UIView, SelectionDataSource, PickerItemBehavior, SearchOptionSDKConvertable, UITextFieldDelegate, UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var serviceContainer: PickerServiceContainer?
    lazy var userService = self.serviceContainer?.userService
    lazy var serverNTPTimeService = self.serviceContainer?.serverNTPTimeService
    public var itemDisableBehavior: ((SearchOption) -> Bool)?
    public var itemDisableSelectedToastBehavior: ((SearchOption) -> String?)?
    /// 联系人行为
    public final class ContactPickerBehaviour {
        public typealias ContactPickerBoolCallback = ((PickerItemType) -> Bool)
        public typealias ContactPickerStringCallback = ((PickerItemType) -> String?)
        /// 选项是否置灰, 返回false时置灰
        public var pickerItemCanSelect: ContactPickerBoolCallback?
        /// 选项置灰时, 点击后的提示文案
        public var pickerItemDisableReason: ContactPickerStringCallback?
        public init(
            pickerItemCanSelect: ContactPickerBoolCallback? = nil,
            pickerItemDisableReason: ContactPickerStringCallback? = nil) {
                self.pickerItemCanSelect = pickerItemCanSelect
                self.pickerItemDisableReason = pickerItemDisableReason
        }
    }
    enum UI {
        static var defaultBottomPadding: Int { 8 }
    }
    public class InitParam: NSObject {
        /// 是否多选，之后可在picker上切换
        public var isMultiple = false
        public weak var delegate: PickerDelegate?
        public var preSelects: [Option] = []
        /// 默认选中项，推荐使用具体的模型，包含头像租户等信息，这样不用到远端拉取
        public var `default`: [Option] = []
        /// 禁止选择项, 禁止选择加默认选中，等于强制选中
        public var disabled: [Option] = []
        // Picker 的使用场景
        public var scene: String?
        // 是否支持目标预览
        public var targetPreview: Bool = false
        // pick距离底部的距离(使用时，剔除安全距离)
        public var bottomInset: CGFloat?
        /// 我管理的群组item行为, 初始化一个Picker.ContactPickerBehaviour对象进行配置
        public var myGroupContactBehavior: ContactPickerBehaviour?
        /// 外部联系人item行为, 初始化一个Picker.ContactPickerBehaviour对象进行配置
        public var externalContactBehavior: ContactPickerBehaviour?

        public var includeMyAi: Bool = false
        /// 仅当与MyAi有过聊天时才能搜索出MyAi
        public var myAiMustTalked: Bool = false
    }
    /// 是否可多选，可切换
    @objc public dynamic var isMultiple: Bool {
        didSet {
            if !_selected.isEmpty {
                self.selected = []
            }
        }
    }

    // Picker 的使用场景
    public var scene: String?
    // WIP: Picker搜索内容配置, 使用相应实体进行配置
    public var contentConfigrations: [PickerContentConfigType] = []
    // 是否支持目标预览
    public var targetPreview: Bool
    public weak var fromVC: UIViewController?

    // 修改时需要同步selectedIndex状态, 不包含强制选中的数据(和state返回有一定差异)
    private var _selected: [Option] {
        // NOTE: accessor wraper will cause array copy when set, even not use it..
        didSet {
            assert(Thread.isMainThread, "should occur on main thread!")
            _selectedChangeObservable.onNext(self)
        }
    }
    /// 当前的选中项，单选时最多一个
    public var selected: [Option] {
        get { _selected }
        set {
            selectedIndex = newValue.reduce(into: [:], { $0[$1.optionIdentifier] = $1 })
            _selected = newValue
        }
    }

    public weak var delegate: PickerDelegate?
    let container = PickerHandlerContainer()
    // pick距离底部的距离(使用时，剔除安全距离)
    private var bottomInset: CGFloat?
    let bag = DisposeBag()
    public let preloadService: PickerPreloadService
    var featureGating: PickerFeatureGating

    let disabled: Set<OptionIdentifier>
    let forceSelected: Set<OptionIdentifier> // 强制选中项不在selected里
    /// 选中项索引，方便快速定位，且可以取得原始数据.
    /// 修改时要先改索引，再改selected，保证通知时索引一致性
    private(set) var selectedIndex: [OptionIdentifier: Option]
    /// 只给OptionIdentifier时，一些需要额外信息的数据拉取后会缓存在这个字典里
    public private(set) lazy var optionCache: [OptionIdentifier: Option] = [:]

    private var searchBarMaskView: UIView?
    private var searchTextValueCount: Int = 0

    public init(resolver: LarkContainer.UserResolver, frame: CGRect, params: InitParam) {
        self.userResolver = resolver
        self.featureGating = PickerFeatureGating(resolver: resolver)
        PickerItemFactory.shared.isUseDocIcon = featureGating.isEnable(name: .corePickerDocicon)
        isMultiple = params.isMultiple
        delegate = params.delegate
        scene = params.scene
        targetPreview = params.targetPreview
        bottomInset = params.bottomInset

        let disabled = Set(params.disabled.map { $0.optionIdentifier })
        self.disabled = disabled

        let group = Dictionary(grouping: params.default, by: { disabled.contains(option: $0) })
        self.forceSelected = Set(group[true]?.map { $0.optionIdentifier } ?? [])

        let selected = group[false] ?? []
        self._selected = selected
        self.selectedIndex = _selected.reduce(into: [:], { $0[$1.optionIdentifier] = $1 })
        let userService = try? resolver.resolve(assert: PassportUserService.self)
        self.preloadService = PickerPreloadService(resolver: resolver, tenantId: userService?.userTenant.tenantID ?? "")
        super.init(frame: frame)
        #if DEBUG
        assert(type(of: self) != Picker.self, "should use concrete picker subclass")
        #endif

        // view 埋点（加在基类里不需要重复加很多遍）
        SearchTrackUtil.trackPickerSelectView(scene: scene)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardDismiss), name: UIApplication.keyboardWillHideNotification, object: nil)
        // 注入通用observer
        container.register(observer: PickerBlockUserHandler(picker: self))
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    private func isSearchPicker() -> Bool {
        return self is SearchPickerView
    }
    /// return true for Option to be removed
    func removeAllSelected(where shouldBeRemoved: (Option) -> Bool) {
        _selected.removeAll {
            let v = shouldBeRemoved($0)
            if v { selectedIndex.removeValue(forKey: $0.optionIdentifier) }
            return v
        }
    }

    // MARK: SelectionDataSource
    public var isMultipleChangeObservable: Observable<Bool> {
        self.rx.observeWeakly(Bool.self, "isMultiple", options: .new).compactMap { $0 }
    }

    private let _selectedChangeObservable = PublishSubject<SelectionDataSource>()
    public var selectedObservable: Observable<[Option]> { selectedChangeObservable.map { $0.selected } }
    public var selectedChangeObservable: Observable<SelectionDataSource> { _selectedChangeObservable.asObservable() }

    public func state(for option: Option, from: Any?, category: PickerItemCategory) -> SelectState {
        assert(Thread.isMainThread, "should occur on main thread!")
        let tenantId = userService?.userTenant.tenantID ?? ""
        let item = PickerItemFactory.shared.makeItem(option: option, currentTenantId: tenantId)
        for observer in container.observers {
            if observer.pickerDisableItem(item) { return .disabled }
        }
        let identifier = option.optionIdentifier
        if let searchPicker = self as? SearchPickerView,
           let nd = searchPicker.newDelegate {
            if nd.pickerForceSelectedItem(item) {
                return .forceSelected
            }
            if nd.pickerDisableItem(item) { return .disabled }
            if selectedIndex[identifier] != nil { return .selected }
            return .normal
        }

        if forceSelected.contains(option: option) || (delegate?.picker(self, forceSelected: option, from: from) == true) { return .forceSelected }
        if disabled.contains(option: option)
            || delegate?.picker(self, disabled: option, from: from) == true { return .disabled }
        if let res = convert(option: option), itemDisableBehavior?(res) == true { return .disabled }
        if selectedIndex[identifier] != nil { return .selected }
        return .normal
    }

    public func state(for option: Option, from: Any?) -> SelectState {
        state(for: option, from: from, category: .unknown)
    }

    public func select(option: Option, from: Any?) -> Bool {
        assert(Thread.isMainThread, "should occur on main thread!")
        let v = option.optionIdentifier
        let state = self.state(for: option, from: from)

        // 现在单选和之前一样可以一直选，不排重。多选可以取消，需要排重，保证状态一致
        if isMultiple, state.selected { return true }

        for handler in container.observers {
            let tenantId = userService?.userTenant.tenantID ?? ""
            let item = PickerItemFactory.shared.makeItem(option: option, currentTenantId: tenantId)
            if handler.pickerWillSelect(item: item, isMultiple: isMultiple) == false { return false }
        }
        if delegate?.picker(self, willSelected: option, from: from) == false { return false }
        // 始终校验状态.. 调用者可以不校验状态
        let disabled = state.disabled
        if disabled, let res = convert(option: option),
           let toast = itemDisableSelectedToastBehavior?(res), !toast.isEmpty {
            UDToast.showTips(with: toast, on: self)
            return false
        }
        if state.disabled { return false }

        defer {
            delegate?.picker(self, didSelected: option, from: from)
        }

        if let searchPicker = self as? SearchPickerView,
           let result = option as? LarkSDKInterface.Search.Result {
            let tenantId = searchPicker.context.tenantId
            var item = option
            if result.type == .doc ||
                result.type == .wiki ||
                result.type == .workspace {
                item = PickerItemFactory.shared.makeItem(option: option, currentTenantId: tenantId)
            }
            if isMultiple {
                selectedIndex[v] = item
                _selected.append(item)
            } else {
                // 单选直接替换选中项
                self.selected = [item]
            }
            return true
        }

        if isMultiple {
            selectedIndex[v] = option
            _selected.append(option)
        } else {
            // 单选直接替换选中项
            self.selected = [option]
        }
        return true
    }

    public func deselect(option: Option, from: Any?) -> Bool {
        assert(Thread.isMainThread, "should occur on main thread!")
        let v = option.optionIdentifier

        let state = self.state(for: option, from: from)
        if !state.selected { return true }

        if let searchPicker = self as? SearchPickerView,
           let nd = searchPicker.newDelegate {
            let tenantId = searchPicker.context.tenantId
            let item = PickerItemFactory.shared.makeItem(option: option, currentTenantId: tenantId)
            if nd.pickerWillDeselect(item: item) == false { return false }
            if state.disabled { return false }
            nd.pickerDidDeselect(item: item)
            selectedIndex.removeValue(forKey: v)
            _selected.removeAll(where: { $0.optionIdentifier == v })
            return true
        }

        if delegate?.picker(self, willDeselected: option, from: from) == false { return false }
        if state.disabled { return false }
        defer { delegate?.picker(self, didDeselected: option, from: from) }

        selectedIndex.removeValue(forKey: v)
        _selected.removeAll(where: { $0.optionIdentifier == v })

        return true
    }

    public func batchSelect(options: [Option], from: Any?) {
        assert(Thread.isMainThread, "should occur on main thread!")
        guard isMultiple else { return }

        var addOptions = [Option]()

        for option in options {
            let identifier = option.optionIdentifier
            let state = self.state(for: option, from: from)

            if state.selected { continue }

            if delegate?.picker(self, willSelected: option, from: from) == false { continue }
            // 始终校验状态.. 调用者可以不校验状态
            if state.disabled { continue }

            delegate?.picker(self, didSelected: option, from: from)

            selectedIndex[identifier] = option
            addOptions.append(option)
        }

        if _selected.isEmpty, let first = addOptions.first {
            _selected.append(first)
            DispatchQueue.main.async {
                self._selected = addOptions
            }
        } else {
            _selected += addOptions
        }
    }

    public func batchDeselect(options: [Option], from: Any?) {
        assert(Thread.isMainThread, "should occur on main thread!")
        guard isMultiple else { return }

        var tempSelected = _selected

        for option in options {
            let identifier = option.optionIdentifier

            let state = self.state(for: option, from: from)
            if !state.selected {
                continue
            }

            if delegate?.picker(self, willDeselected: option, from: from) == false { continue }
            if state.disabled { continue }

            delegate?.picker(self, didDeselected: option, from: from)

            selectedIndex.removeValue(forKey: identifier)
            tempSelected.removeAll(where: { $0.optionIdentifier == identifier })
        }
        _selected = tempSelected
    }

    // MARK: Helper Methods
    static let logger = Logger.log(Picker.self, category: "SearchPicker")

    /// common Picker layout and bind. NOTE: ui will not be retain
    /// see also the caller at subclass
    func bind<T>(ui: T) -> [Disposable] where T: PickerCommonUI {
        let selectedView = ui.selectedView
        let defaultView = ui.defaultView
        let resultView = ui.resultView
        let searchBar = ui.searchBar
        let topContainerView = UIStackView()
        let filterBottomPadding = ui.searchVM.filterBottomPadding

        topContainerView.axis = .vertical
        var bag: [Disposable] = []
        func addViews() {
            self.addSubview(defaultView)
            self.addSubview(resultView) // over defaultView, so when hide, show below defaultView
            addSubview(searchBar)
            self.addSubview(topContainerView)
        }
        func layout(filterBottomPadding: Int = UI.defaultBottomPadding) {
            searchBar.snp.makeConstraints {
                $0.top.left.right.equalToSuperview()
                $0.height.equalTo(54)
            }
            topContainerView.snp.makeConstraints { make in
                make.top.equalTo(searchBar.snp.bottom)
                make.left.right.equalToSuperview()
            }
            topContainerView.lu.addBottomBorder()
            topContainerView.spacing = 8
            topContainerView.addArrangedSubview(selectedView)

            selectedView.snp.makeConstraints {
                // NOTE: 如果改高度, 首个选择不显示... contentSize还是0. 改用切换bottom位置来实现
                $0.height.equalTo(56)
            }
            topContainerView.lu.addBottomBorder()

            defaultView.snp.makeConstraints {
                $0.top.equalTo(topContainerView.snp.bottom).offset(filterBottomPadding)
                $0.left.right.equalToSuperview()
                if let bottomInset = bottomInset {
                    $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-bottomInset)
                } else {
                    $0.bottom.equalToSuperview()
                }
            }
            // resultView 盖在上面，隐藏时显示下面的默认视图
            resultView.snp.makeConstraints {
                // NOTE: subclass may insert view between selectedView and contentView.
                $0.top.equalTo(topContainerView.snp.bottom).offset(filterBottomPadding)
                $0.left.right.equalToSuperview()
                if let bottomInset = bottomInset {
                    $0.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-bottomInset)
                } else {
                    $0.bottom.equalToSuperview()
                }
            }
        }
        func configure() {
            // selectedView hidden toggle and reload
            let emptyObservable = selectedObservable
                .do(onNext: { [selectedView] (_) in
                    UIView.performWithoutAnimation {
                        selectedView.reloadData()
                    }
                    selectedView.scrollToLastest(animated: true)
                }).startWith(_selected).map { $0.isEmpty }
            bag.append(Observable.combineLatest(
                isMultipleChangeObservable.startWith(isMultiple),
                emptyObservable)
            .map { (isMultiple, isEmpty) -> Bool in
                return !isMultiple || isEmpty
            }.distinctUntilChanged()
            .subscribe(onNext: { [selectedView](hidden) in
                selectedView.isHidden = hidden
            }))
            searchBar.searchUITextField.returnKeyType = .search
            bag.append(searchBar.searchUITextField.rx.controlEvent(.editingChanged).subscribe(onNext: { [weak ui](_) in
                ui?.search()
            }))

            let table = resultView.tableview
            table.separatorStyle = .none
            table.rowHeight = 68 // 现在普遍用的都是这个高度，这做为默认值，注意子类影响。不一样的高度需要自己覆盖判断
            table.delegate = ui
            table.dataSource = ui

            bag.append(ui.bindResultView())
            bag.append(selectedObservable.subscribe(onNext: { _ in table.reloadData() }))
            bag.append(isMultipleChangeObservable.subscribe(onNext: { _ in table.reloadData() }))
        }

        if !isSearchPicker() {
            addViews()
            layout(filterBottomPadding: filterBottomPadding)
        }
        configure()

        return bag
    }

    public func cache(option: Option?) {
        assert(Thread.isMainThread, "should occur on main thread!")
        if let option = option {
            optionCache[option.optionIdentifier] = option
        }
    }
    // MARK: Selection
    final func avatar(for option: Option, bag: DisposeBag, callback: @escaping (SelectedOptionInfo?) -> Void) {
        assert(Thread.isMainThread, "should occur on main thread!")

        let identifier = option.optionIdentifier
        if let raw = selectedIndex[identifier] as? SelectedOptionInfoConvertable {
            return callback(raw.asSelectedOptionInfo())
        }
        if let raw = option as? SelectedOptionInfoConvertable {
            return callback(raw.asSelectedOptionInfo())
        }
        if let raw = optionCache[identifier] as? SelectedOptionInfoConvertable {
            return callback(raw.asSelectedOptionInfo())
        }

        // FIXME: 现在的子类型都提供了信息。只有外部设置的需要获取数据。暂时不支持chatter以外的获取avatar信息(没发现使用场景)
        // TODO: 优化缓存，没必要每次都拿
        switch identifier.type {
        case "chatter":
            self.serviceContainer?.getChatter(id: identifier.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                           self?.cache(option: $0)
                           callback($0)
                       }).disposed(by: bag)
        case "chat":
            self.serviceContainer?.getChat(id: identifier.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                           self?.cache(option: $0)
                           callback($0)
                       }).disposed(by: bag)
        case "mailContact":
            callback(BackupSelectedOptionInfo(name: identifier.id, backupImage: nil)) // id is mail address, use it as name
        case "department":
            callback(BackupSelectedOptionInfo(name: "", backupImage: BundleResources.LarkSearchCore.department_avatar))
        case "userGroup", "userGroupAssign", "newUserGroup":
            callback(BackupSelectedOptionInfo(name: identifier.name, backupImage: BundleResources.LarkSearchCore.Picker.user_group))
        case "doc", "wiki", "workspace":
            if let item = option as? PickerItem { // 处理doc, wiki, wikiSpace的头像
                var image = ListItemNode.Icon.local(nil)
                var name = ""
                switch item.meta {
                case .doc(let meta):
                    image = IconTransformer.transform(meta: meta)
                    name = meta.title ?? ""
                case .wiki(let meta):
                    image = IconTransformer.transform(meta: meta)
                    name = meta.title ?? ""
                case .wikiSpace(let meta):
                    image = IconTransformer.transform(meta: meta)
                    name = meta.title ?? ""
                default: break
                }
                if case .local(let img) = image {
                    callback(BackupSelectedOptionInfo(name: name, backupImage: img))
                } else {
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        case "mailUser":
            callback(BackupSelectedOptionInfo(name: identifier.name, selectedOptionDescription: identifier.description, avatarImageURLStr: identifier.avatarImageURLStr))
        default:
            assertionFailure("not supported option type \(option), for show on selected View")
            callback(nil)
        }
        struct BackupSelectedOptionInfo: SelectedOptionInfo {
            var avaterIdentifier: String { "" } /// avatar identifier for option, return "" to mean invalid
            var avatarKey: String { "" } /// avatar image key for option, return "" to mean invalid
            var name: String
            var selectedOptionDescription: String?
            var backupImage: UIImage?
            var avatarImageURLStr: String?
        }
    }

    private var selectedSearchBar: SearchUITextFieldWrapperView?
    private var textFieldTintColor: UIColor = .clear
    func setSearchBarSelectAllMode(searchBar: SearchUITextFieldWrapperView) {
        guard isMultiple else { return }
        guard searchBarMaskView == nil else { return } // 当前不是选中态
        guard searchBar.searchUITextField.isEditing else { return } // 输入框正在编辑时才会触发选中态
        self.selectedSearchBar = searchBar
        let attributes = [NSAttributedString.Key.foregroundColor: UDColor.textColor,
                          NSAttributedString.Key.backgroundColor: imMessageBgReactionBlue]
        searchTextValueCount = searchBar.searchUITextField.text?.count ?? 0
        searchBar.searchUITextField.attributedText = NSAttributedString(string: searchBar.searchUITextField.text ?? "", attributes: attributes)
        textFieldTintColor = searchBar.searchUITextField.tintColor
        searchBar.searchUITextField.tintColor = .clear
        let searchBarMaskView = UIView()
        self.searchBarMaskView = searchBarMaskView
        searchBar.addSubview(searchBarMaskView)
        searchBarMaskView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalTo(searchBar.searchUITextField.snp.left)
            $0.right.equalTo(searchBar.searchUITextField.snp.right).offset(-20)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(touchSearchUITextField))
        searchBarMaskView.addGestureRecognizer(tapGesture)
        searchBar.searchUITextField.delegate = self
    }

    @objc
    func touchSearchUITextField() {
        guard let searchBar = selectedSearchBar else { return }
        resetSearchBarStyle()
        searchBar.searchUITextField.selectAll(nil)
        selectedSearchBar = nil
    }

    @objc
    private func onKeyboardDismiss() {
        resetSearchBarStyle()
    }

    func resetSearchBarStyle() {
        guard let searchBar = selectedSearchBar else { return }
        searchBar.searchUITextField.tintColor = textFieldTintColor
        let text = searchBar.searchUITextField.attributedText?.string
        searchBar.searchUITextField.attributedText = nil
        searchBar.searchUITextField.text = text
        searchBar.searchUITextField.typingAttributes = nil
        searchBarMaskView?.removeFromSuperview()
        searchBarMaskView = nil
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if searchBarMaskView != nil, let searchBar = selectedSearchBar { // 当前是选中中间态
            // 清除数据再接受输入
            resetSearchBarStyle()
            searchBar.searchUITextField.attributedText = nil
            searchBar.searchUITextField.text = ""
        }
        return true
    }
}

/// SelectedViewControllerDelegate protocol
extension Picker: SelectedViewControllerDelegate {
    public func configureInfo(for option: Option, callback: @escaping (SelectedOptionInfo?) -> Void) {
        avatar(for: option, bag: bag, callback: callback)
    }
}

// common picker ui, with a searchBar, selectedView, defaultView, and search view
protocol PickerCommonUI: SearchResultViewListBindDelegate, UITableViewDelegate, UITableViewDataSource {
    var scene: String? { get }
    var searchBar: SearchUITextFieldWrapperView { get }
    var resultView: SearchResultView { get }
    var selectedView: SelectedView { get }
    var defaultView: UIView { get }
    var searchVM: SearchSimpleVM<Item> { get }
}

extension PickerCommonUI {
    func search() {
        guard searchBar.searchUITextField.markedTextRange == nil else { return }
        SearchTrackUtil.trackPickerSelectClick(scene: scene, clickType: .searchBar)
        searchVM.query.text.accept(searchBar.searchUITextField.text ?? "")
    }
}

public extension PickerDelegate {
    /// 选中前调用，不可选中应返回false
    func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool { true }
    /// 选中后调用
    func picker(_ picker: Picker, didSelected option: Option, from: Any?) {}
    /// 取消选中前调用，不可选中应返回false
    func picker(_ picker: Picker, willDeselected option: Option, from: Any?) -> Bool { true }
    /// 取消选中后调用
    func picker(_ picker: Picker, didDeselected option: Option, from: Any?) {}
    /// 是否禁止选择
    func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool { false }
    /// 是否强制选中
    func picker(_ picker: Picker, forceSelected option: Option, from: Any?) -> Bool { false }

    func unfold(_ picker: Picker) {}
}
