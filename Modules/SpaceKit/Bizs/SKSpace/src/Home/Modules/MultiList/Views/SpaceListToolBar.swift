//
//  SpaceListToolBar.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/4.
//

import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import SKUIKit
import SKCommon
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor

class SpaceListToolBar: UIView {

    typealias ListTool = SpaceListTool

    // 是否展示排序按钮，通常而言排序按钮会单独展示，默认过滤掉
    var allowSortTool = false
    private let layoutAnimationTrigger = PublishRelay<Void>()
    var layoutAnimationSignal: Signal<Void> { layoutAnimationTrigger.asSignal() }

    private var reuseBag = DisposeBag()

    private lazy var containerView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 20
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        return view
    }()

    private lazy var placeHolderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func reset() {
        UIView.performWithoutAnimation {
            let toolViews = containerView.arrangedSubviews
            toolViews.forEach { $0.removeFromSuperview() }
        }
        reuseBag = DisposeBag()
    }

    func update(tools: [ListTool]) {
        UIView.performWithoutAnimation {
            if tools.isEmpty {
                setupPlaceHolderView()
                return
            }
            containerView.isLayoutMarginsRelativeArrangement = true
            tools.forEach { setup(tool: $0) }
        }
    }

    private func setup(tool: ListTool) {
        switch tool {
        case let .filter(stateRelay, isEnabled, clickHandler):
            setupFilterTool(stateRelay: stateRelay, isEnabled: isEnabled, clickHandler: clickHandler)
        case let .modeSwitch(modeRelay, clickHandler):
            setupModeSwitch(modeRelay: modeRelay, clickHandler: clickHandler)
        case let .sort(stateRelay, _, isEnabled, clickHandler):
            guard allowSortTool else { return }
            setupSortTool(stateRelay: stateRelay, isEnabled: isEnabled, clickHandler: clickHandler)
        case .more:
            assertionFailure("more item in toolbar not supported yet")
        case let .controlPanel(filterStateRelay, sortStateRelay, clickHandler):
            setupListControlTool(filterStateRelay: filterStateRelay, sortStateRelay: sortStateRelay, clickHandler: clickHandler)
        }
    }

    // 为了解决 list tools 为空时，stackView 无法正确计算宽度导致的布局问题，需要增加一个占位用的 view
    // 可能有更靠谱的解决方法，后续优化掉
    private func setupPlaceHolderView() {
        containerView.isLayoutMarginsRelativeArrangement = false
        containerView.addArrangedSubview(placeHolderView)
        placeHolderView.snp.makeConstraints { make in
            make.width.height.equalTo(0.1)
        }
    }
}

// MARK: - filter
extension SpaceListToolBar {
    private func setupFilterTool(stateRelay: BehaviorRelay<SpaceListFilterState>,
                                 isEnabled: Observable<Bool>,
                                 clickHandler: @escaping (UIView) -> Void) {
        let filterView = SpaceListFilterStateView()
        filterView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
        filterView.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -10, bottom: -8, right: -10)

        stateRelay.asDriver()
            .drive(onNext: { [weak self, weak filterView] state in
                guard let self, let filterView else { return }
                filterView.update(isActive: state.isActive)
                UIView.animate(withDuration: 0.3) {
                    self.containerView.layoutIfNeeded()
                }
                self.layoutAnimationTrigger.accept(())
            })
            .disposed(by: reuseBag)

        isEnabled.asDriver(onErrorJustReturn: false)
            .drive(filterView.rx.isEnabled)
            .disposed(by: reuseBag)

        filterView.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak filterView] _ in
                guard let view = filterView else { return }
                clickHandler(view)
            })
            .disposed(by: reuseBag)

        containerView.addArrangedSubview(filterView)
    }
}

// MARK: - mode switch
extension SpaceListToolBar {
    private func setupModeSwitch(modeRelay: BehaviorRelay<SpaceListDisplayMode>, clickHandler: @escaping (UIView) -> Void) {
        let switchView = SpaceListDisplayModeView()
        switchView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
        modeRelay.asDriver()
            .drive(onNext: { [weak switchView] newMode in
                switchView?.update(mode: newMode)
            })
            .disposed(by: reuseBag)
        switchView.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -10, bottom: -8, right: -10)
        switchView.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak switchView] _ in
                guard let view = switchView else { return }
                clickHandler(view)
            })
            .disposed(by: reuseBag)
        switchView.isUserInteractionEnabled = true
        containerView.addArrangedSubview(switchView)
    }
}

// MARK: - sort
extension SpaceListToolBar {
    private func setupSortTool(stateRelay: BehaviorRelay<SpaceListFilterState>,
                               isEnabled: Observable<Bool>,
                               clickHandler: @escaping (UIView) -> Void) {
        let sortView = SpaceListFilterStateView(iconKey: .sortOutlined)
        sortView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
        sortView.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -10, bottom: -8, right: -10)

        stateRelay.asDriver().drive(onNext: { [weak self, weak sortView] state in
            guard let self, let sortView else { return }
            sortView.update(isActive: state.isActive)
            UIView.animate(withDuration: 0.3) {
                self.containerView.layoutIfNeeded()
            }
            self.layoutAnimationTrigger.accept(())
        })
        .disposed(by: reuseBag)

        sortView.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak sortView] _ in
                guard let sortView else { return }
                clickHandler(sortView)
            })
            .disposed(by: reuseBag)

        isEnabled.asDriver(onErrorJustReturn: false)
            .drive(sortView.rx.isEnabled)
            .disposed(by: reuseBag)
        containerView.addArrangedSubview(sortView)
    }
}

extension SpaceListToolBar {
    private func setupListControlTool(filterStateRelay: BehaviorRelay<SpaceListFilterState>,
                                      sortStateRelay: BehaviorRelay<SpaceListFilterState>,
                                      clickHandler: @escaping ((UIView) -> Void)) {
        let controlView = SpaceListFilterStateView(iconKey: .listSettingOutlined, iconColor: UDColor.iconN1)
        containerView.addArrangedSubview(controlView)
        controlView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            //make.right.equalToSuperview()
        }
        controlView.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -10, bottom: -8, right: -10)
        
        Driver.combineLatest(filterStateRelay.asDriver(), sortStateRelay.asDriver())
            .drive(onNext: { [weak self, weak controlView] filterState, sortState in
                guard let self, let controlView else { return }
                controlView.update(isActive: filterState.isActive || sortState.isActive)
                UIView.animate(withDuration: 0.3) {
                    self.containerView.layoutIfNeeded()
                }
                self.layoutAnimationTrigger.accept(())
            })
            .disposed(by: reuseBag)
        
        controlView.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak controlView] _ in
                guard let controlView else { return }
                clickHandler(controlView)
            })
            .disposed(by: reuseBag)
        
    }
}
