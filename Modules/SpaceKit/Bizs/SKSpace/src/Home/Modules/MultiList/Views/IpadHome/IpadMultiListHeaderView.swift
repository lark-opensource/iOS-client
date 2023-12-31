//
//  IpadMultiListHeaderView.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/26.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit
import SKFoundation
import RxCocoa
import RxSwift


public class IpadMultiListHeaderView: UICollectionReusableView {
    
    public static let height: CGFloat = 80
    
    private lazy var toolBar: SpaceListToolBar = {
        let toolBar = SpaceListToolBar()
        toolBar.allowSortTool = true
        return toolBar
    }()
    
    private lazy var pickerView: IpadMultiListHeaderPickerView = {
        let pickerView = IpadMultiListHeaderPickerView()
        return pickerView
    }()
    
    private lazy var listHeaderView: IpadSpaceSubListHeaderView = {
        let view = IpadSpaceSubListHeaderView()
        return view
    }()
    
    private var sectionChangedRelay = PublishRelay<Int>()
    public var sectionChangedSignal: Signal<Int> { sectionChangedRelay.asSignal() }
    
    public let listToolConfigInput = PublishRelay<[SpaceListTool]>()
    public var ipadListHeaderConfigInput = PublishRelay<IpadListHeaderSortConfig?>()

    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bindAction()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        bindAction()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        pickerView.cleanUp()
        listHeaderView.cleanUp()
        toolBar.reset()
        sectionChangedRelay = PublishRelay<Int>()
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        
        addSubview(toolBar)
        toolBar.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.height.equalTo(24)
            make.right.equalToSuperview().inset(24)
        }
        
        addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.left.equalToSuperview()
            make.height.equalTo(28)
            make.right.equalTo(toolBar.snp.left)
        }
        
        toolBar.setContentHuggingPriority(.required, for: .horizontal)
        pickerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pickerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        toolBar.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        
        addSubview(listHeaderView)
        listHeaderView.snp.makeConstraints { make in
            make.top.equalTo(pickerView.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(36)
        }
    }
    
    private func bindAction() {
        listToolConfigInput.asSignal()
            .emit(onNext: { [weak self] newTools in
                self?.toolBar.reset()
                self?.toolBar.update(tools: newTools)
            })
            .disposed(by: disposeBag)

        toolBar.layoutAnimationSignal
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.3) {
                    self.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        ipadListHeaderConfigInput.asSignal()
            .emit(onNext: { [weak self] config in
                self?.listHeaderView.setup(config: config)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.Docs.notifySelectedListChange)
            .observeOn(scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let userInfo = notification.userInfo as? [String: Any],
                      let index = userInfo["index"] as? Int,
                      let isPad = userInfo["isPad"] as? Bool else {
                    return
                }
                // 仅订阅处理Phone样式列表发送的信号
                guard !isPad else { return }
                self?.sectionChangedRelay.accept(index)
            })
            .disposed(by: disposeBag)
    }
    
    public func update(items: [SpaceMultiListPickerItem], currentIndex: Int, shouldUseNewestStyle: Bool = false) {
        pickerView.update(items: items, currentIndex: currentIndex, shouldUseNewestStyle: shouldUseNewestStyle)
        pickerView.clickHandler = { [weak self] index in
            self?.sectionChangedRelay.accept(index)
            // 处理ipad列表与phone列表的tab切换同步
            let userInfo: [String: Any] = ["index": index, "isPad": true]
            NotificationCenter.default.post(name: .Docs.notifySelectedListChange, object: nil, userInfo: userInfo)
        }
    }
}

extension IpadMultiListHeaderView: SpaceMultiSectionHeaderView {
    public static func height(mode: SpaceListDisplayMode) -> CGFloat {
        return mode == .list ? height : height - 36
    }
}

class IpadMultiListHeaderPickerView: UIView {
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 16
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 16)
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    private var itemViews: [ItemView] = []
    
    private var currentItemIndex = 0
    private var currentItemView: ItemView { itemViews[currentItemIndex] }
    
    public var clickHandler: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    public func cleanUp() {
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews = []
        currentItemIndex = 0
    }
    
    public func update(items: [SpaceMultiListPickerItem], currentIndex: Int, shouldUseNewestStyle: Bool = false) {
        guard !items.isEmpty else {
            DocsLogger.error("space.multi-list.header --- sub sections is empty when setup")
            return
        }
        
        self.stackView.spacing = shouldUseNewestStyle ? 10 : 20
        setup(items: items, shouldUseNewestStyle: shouldUseNewestStyle)
        currentItemIndex = currentIndex
        if currentIndex >= items.count {
            assertionFailure("space.multi-list.header --- current index out of bounds!")
            currentItemIndex = 0
        }
        if items.count == 1 {
            // 只有一个Item时不高亮
            currentItemView.update(isSelected: false)
            currentItemView.update(textColor: UDColor.textTitle)
        } else {
            currentItemView.update(isSelected: true)
        }
    }
    
    private func setup(items: [SpaceMultiListPickerItem], shouldUseNewestStyle: Bool = false) {
        for (index, item) in items.enumerated() {
            let itemView = ItemView(item: item) { [weak self] in
                self?.didClick(index: index)
            }
            itemViews.append(itemView)
            stackView.addArrangedSubview(itemView)
            if shouldUseNewestStyle {
                let itemW  = itemView.innerLabelWidth + 24
                let itemH = itemView.innerLabelHeight + 14
                itemView.snp.remakeConstraints { make in
                    make.width.equalTo(itemW)
                    make.height.equalTo(itemH)
                }
            }else{
                itemView.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                }
            }
        }
    }

    private func didClick(index: Int) {
        guard index < itemViews.count else {
            assertionFailure("section index out of range!")
            return
        }
        
        if currentItemIndex == index { return }
        DocsLogger.info("space.multi-list.header --- did click at index: \(index)")
        currentItemView.update(isSelected: false)
        currentItemIndex = index
        currentItemView.update(isSelected: true)
        clickHandler?(index)
    }
}

private extension IpadMultiListHeaderPickerView {
    typealias Item = SpaceMultiListPickerItem
    class ItemView: UIView {
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.textAlignment = .center
            label.textColor = UDColor.textCaption
            label.isUserInteractionEnabled = true
            return label
        }()
        
        var innerLabelWidth : CGFloat = 0.0
        var innerLabelHeight : CGFloat = 0.0
        
        private var clickHandler: () -> Void
        
        init(item: Item, handler: @escaping () -> Void) {
            self.clickHandler = handler
            super.init(frame: .zero)
            
            setupUI(item: item)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI(item: Item) {
            addSubview(titleLabel)
            
            titleLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            titleLabel.text = item.title
            let clickGesture = UITapGestureRecognizer(target: self, action: #selector(didClick))
            titleLabel.addGestureRecognizer(clickGesture)
            
            titleLabel.docs.addHighlight(with: UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4), radius: 4)
        }
        
        @objc
        private func didClick() {
            clickHandler()
        }
        
        func update(isSelected: Bool) {
            if isSelected {
                titleLabel.textColor = UDColor.functionInfoContentDefault
            } else {
                titleLabel.textColor = UDColor.textCaption
            }
        }
        
        func update(textColor: UIColor) {
            titleLabel.textColor = textColor
        }
    }
}


//MARK: ipad子列表表头view: 所有者---排序---排序
public class IpadSpaceSubListHeaderView: UIView {
    
    public enum Index {
        case first
        case second
        case thrid
        case single
        case selected
    }
    
    private lazy var firstItemView: ItemView = {
        let view = ItemView(index: .first)
        return view
    }()
    
    private lazy var secondItemView: ItemView = {
        let view = ItemView(index: .second)
        return view
    }()
    
    private lazy var thridItemView: ItemView = {
        let view = ItemView(index: .thrid)
        return view
    }()
    
    private lazy var singleItemView: ItemView = {
        let view = ItemView(index: .single)
        return view
    }()
    
    private lazy var selectItemView: ItemView = {
        let view = ItemView(index: .selected)
        view.isHidden = true
        return view
    }()
    
    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private var itemViews = [ItemView]()
    var ipadListHeaderConfigInput = PublishRelay<IpadListHeaderSortConfig?>()
    var selectOptionInput = PublishRelay<(Index, SpaceSortHelper.SortOption)>()
    private var listModeRelay = BehaviorRelay<SpaceListDisplayMode>(value: .list)
    
    var listMode: SpaceListDisplayMode {
        listModeRelay.value
    }
    
    private var disposeBag = DisposeBag()
    
    public init() {
        super.init(frame: .zero)
        itemViews = [firstItemView, secondItemView, thridItemView]
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard listMode == .list else {
            // 宫格模式下全部隐藏
            firstItemView.isHidden = true
            secondItemView.isHidden = true
            thridItemView.isHidden = true
            singleItemView.isHidden = true
            selectItemView.isHidden = true
            return
        }
        if frame.width < 780, frame.width >= 600 {
            // 该尺寸下只展示名称和当前的排序时间
            secondItemView.isHidden = true
            thridItemView.isHidden = true
            singleItemView.isHidden = true
            
            selectItemView.isHidden = false
            firstItemView.isHidden = false
        } else if frame.width < 600 {
            // 尺寸不够时只展示单个排序提示
            firstItemView.isHidden = true
            secondItemView.isHidden = true
            thridItemView.isHidden = true
            selectItemView.isHidden = true
            
            singleItemView.isHidden = false
        } else {
            firstItemView.isHidden = false
            secondItemView.isHidden = false
            thridItemView.isHidden = false
            
            singleItemView.isHidden = true
            selectItemView.isHidden = true
        }
    }
    
    private func setupUI() {
        addSubview(firstItemView)
        addSubview(secondItemView)
        addSubview(thridItemView)
        addSubview(indicatorView)
        addSubview(singleItemView)
        addSubview(selectItemView)
        
        indicatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(0.5)
        }

        thridItemView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(76)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(160)
        }

        secondItemView.snp.makeConstraints { make in
            make.right.equalTo(thridItemView.snp.left).offset(-16)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(160)
        }

        firstItemView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(24)
            make.right.lessThanOrEqualTo(secondItemView.snp.left).offset(-16)
            make.top.bottom.equalToSuperview()
        }

        singleItemView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(24)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.top.bottom.equalToSuperview()
        }
        
        selectItemView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(76)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(160)
        }
    }
    
    private func updateUI(mode: SpaceListDisplayMode) {
        if mode == .list {
            indicatorView.snp.remakeConstraints { make in
                make.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(24)
                make.height.equalTo(0.5)
            }
            
        } else {
            indicatorView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(24)
                make.height.equalTo(0.5)
                make.top.equalToSuperview()
            }
        }
    }
    
    func setup(config: IpadListHeaderSortConfig?) {
        guard let config else { return }
        
        setup(items: config.sortOptions)
        
        config.selectSortOptionDriver?
            .drive(onNext: { [weak self] index, sortOption in
                self?.update(index: index, sortOption: sortOption)
                self?.updateSingleView(sortOption: sortOption)
            })
            .disposed(by: disposeBag)
        
        config.displayModeRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] mode in
                self?.updateUI(mode: mode)
            })
            .disposed(by: disposeBag)
        config.displayModeRelay.bind(to: listModeRelay).disposed(by: disposeBag)
    }
    
    private func setup(items: [SpaceSortHelper.SortOption]) {
        
        for (index, item) in items.enumerated() {
            guard index < itemViews.count else { break }
            itemViews[index].update(description: item.type.displayName)
            itemViews[index].update(descending: nil)
        }
    }
    
    private func update(index: IpadSpaceSubListHeaderView.Index, sortOption: SpaceSortHelper.SortOption) {
        itemViews.forEach { view in
            if view.index == index {
                view.update(description: sortOption.type.displayName)
                view.update(descending: sortOption.descending)
            } else {
                // 非选中的排序不展示箭头
                view.update(descending: nil)
            }
        }
    }
    
    private func updateSingleView(sortOption: SpaceSortHelper.SortOption) {
        singleItemView.update(description: sortOption.legacyItem.fullDescription)
        singleItemView.update(descending: sortOption.descending)
        
        if sortOption.type == .title {
            selectItemView.update(description: SpaceSortHelper.SortType.lastModifiedTime.displayName)
            selectItemView.update(descending: nil)
        } else {
            selectItemView.update(description: sortOption.type.displayName)
            selectItemView.update(descending: sortOption.descending)
        }
    }
    
    func cleanUp() {
        disposeBag = DisposeBag()
    }
}

private extension IpadSpaceSubListHeaderView {
    class ItemView: UIView {
        
        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 1
            label.textColor = UDColor.textCaption
            label.font = .systemFont(ofSize: 14, weight: .medium)
            return label
        }()
        
        private lazy var arrowIcon: UIImageView = {
            let view = UIImageView()
            view.isHidden = true
            return view
        }()
        
        var index: IpadSpaceSubListHeaderView.Index
        
        init(index: IpadSpaceSubListHeaderView.Index) {
            self.index = index
            super.init(frame: .zero)
            setupUI()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupUI() {
            addSubview(titleLabel)
            addSubview(arrowIcon)
            
            titleLabel.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            
            arrowIcon.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(titleLabel.snp.right).offset(2)
                make.width.height.equalTo(12)
            }
        }
        
        func update(description: String) {
            titleLabel.text = description
        }
        
        func update(descending: Bool?) {
            guard let descending else {
                arrowIcon.isHidden = true
                return
            }
            arrowIcon.isHidden = false
            if descending {
                arrowIcon.setImage(UDIcon.spaceDownOutlined, tintColor: UDColor.iconN2)
            } else {
                arrowIcon.setImage(UDIcon.spaceUpOutlined, tintColor: UDColor.iconN2)
            }
        }
    }
}
