//
//  CCMSearchFilterSegmentView.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/6/5.
//
#if MessengerMod
import LarkSearchCore
import LarkModel
import EENavigator
import Foundation
import SnapKit
import UniverseDesignTabs
import UniverseDesignColor
import RxSwift
import RxCocoa
import RxRelay

protocol CCMSearchFilterViewType: UIView {
    var hostController: SearchPickerControllerType? { get set }
    var pickerDelegate: SearchPickerDelegate { get }
    func didActive()
}

protocol CCMSearchSegmentViewModelType: AnyObject {
    var segmentTitles: [String] { get }
    func segmentView(at index: Int) -> CCMSearchFilterViewType
    func didSwitch(at index: Int)
}

class CCMSearchFilterSegmentView: UIView {

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 0
        return view
    }()

    private lazy var subContentViews: [CCMSearchFilterViewType] = []

    private lazy var tabsView: UDTabsTitleView = {
        let view = UDTabsTitleView()
        view.backgroundColor = UDColor.bgBody
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        view.indicators = [indicator]
        view.delegate = self
        let config = view.getConfig()
        config.layoutStyle = .average
        config.itemSpacing = 0
        config.isItemSpacingAverageEnabled = false
        view.setConfig(config: config)
        return view
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private let viewModel: CCMSearchSegmentViewModelType
    private weak var hostController: SearchPickerControllerType?

    private var currentIndex = 0

    private let disposeBag = DisposeBag()

    init(viewModel: CCMSearchSegmentViewModelType) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.addArrangedSubview(tabsView)
        tabsView.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        stackView.addArrangedSubview(divider)
        divider.snp.makeConstraints { make in
            make.height.equalTo(0.5)
        }

        let titles = viewModel.segmentTitles
        tabsView.titles = titles
        for index in 0..<titles.count {
            let contentView = viewModel.segmentView(at: index)
            stackView.addArrangedSubview(contentView)
            subContentViews.append(contentView)
            contentView.isHidden = true
        }
        select(index: currentIndex)

        // 仅有一个选项时，不展示选项卡
        if subContentViews.count <= 1 {
            stackView.removeFromSuperview()
        }
    }

    func bind(searchController: SearchPickerControllerType) {
        hostController = searchController
        subContentViews.forEach { contentView in
            contentView.hostController = searchController
        }
        select(index: currentIndex)
    }

    private func select(index: Int) {
        guard index < subContentViews.count else { return }
        if currentIndex < subContentViews.count {
            let currentView = subContentViews[currentIndex]
            currentView.isHidden = true
        }
        currentIndex = index
        let currentView = subContentViews[currentIndex]
        currentView.isHidden = false
        hostController?.pickerDelegate = currentView.pickerDelegate
        currentView.didActive()
        viewModel.didSwitch(at: index)
    }
}

extension CCMSearchFilterSegmentView: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        select(index: index)
    }
}

#endif
