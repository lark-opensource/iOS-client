//
//  CCMSearchFilterConfigView.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/5/17.
//

#if MessengerMod
import LarkSearchCore
import LarkModel
import SKUIKit
import SKResource
import SnapKit
import UniverseDesignColor
import RxSwift
import RxCocoa
import RxRelay
import EENavigator
import LarkUIKit

enum CCMSearchAction {
    case update(searchConfig: PickerSearchConfig)
    case present(controller: UIViewController)
    case push(controller: UIViewController)
    case showDetail(controller: UIViewController)

    case presentBody(_ body: any EENavigator.Body)
    /// 按 showDetail 的方式处理
    case openURL(url: URL)
}

protocol CCMSearchFilterViewModelType: SearchPickerDelegate {
    var actionSignal: Signal<CCMSearchAction> { get }
    var resetInput: PublishRelay<Void> { get }
    func createItems() -> [CCMSearchFilterItemView]
    func generateSearchConfig() -> PickerSearchConfig
}

final class CCMSearchFilterConfigView: UIView {
    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.setTitle(SKResource.BundleI18n.SKResource.Doc_Search_Reset, for: .normal)
        button.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
    }()

    private lazy var gradientMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        // 从左往右的渐变遮罩
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    private lazy var filterContainerView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.clipsToBounds = true
        view.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        return view
    }()

    private lazy var filterStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .fill
        view.spacing = 12
        return view
    }()

    private var containerButtonContraint: Constraint?

    private var itemViews: [CCMSearchFilterItemView] = []
    private let viewModel: CCMSearchFilterViewModelType

    weak var hostController: SearchPickerControllerType?

    private let disposeBag = DisposeBag()

    init(viewModel: CCMSearchFilterViewModelType) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        backgroundColor = UDColor.bgBody
        addSubview(filterContainerView)
        addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
        resetButton.layer.insertSublayer(gradientMaskLayer, at: 0)
        gradientMaskLayer.ud.setColors([
            UDColor.bgBody.withAlphaComponent(0),
            UDColor.bgBody,
            UDColor.bgBody
        ])
        gradientMaskLayer.locations = [0, 0.05, 1]
        filterContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(8)
            make.right.equalToSuperview().priority(.low)
            containerButtonContraint = make.right.equalTo(resetButton.snp.left).offset(8).constraint
        }

        resetButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        filterContainerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        resetButton.isHidden = true
        containerButtonContraint?.deactivate()

        filterContainerView.addSubview(filterStackView)
        filterStackView.snp.makeConstraints { make in
            make.top.bottom.equalTo(filterContainerView.frameLayoutGuide)
            make.left.right.equalTo(filterContainerView.contentLayoutGuide)
        }

        viewModel.actionSignal.emit(onNext: { [weak self] action in
            self?.handle(action: action)
        })
        .disposed(by: disposeBag)
        setupItems()
    }

    private func handle(action: CCMSearchAction) {
        guard var hostController else { return }
        switch action {
        case let .update(searchConfig):
            hostController.searchConfig = searchConfig
            hostController.reload()
        case let .present(controller):
            Navigator.shared.present(controller, from: hostController)
        case let .presentBody(body):
            Navigator.shared.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: hostController,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        case let .push(controller):
            Navigator.shared.push(controller, from: hostController)
        case let .showDetail(controller):
            Navigator.shared.docs.showDetailOrPush(controller, from: hostController)
        case let .openURL(url):
            Navigator.shared.docs.showDetailOrPush(url, from: hostController)
        }
    }

    private func setupItems() {
        itemViews = viewModel.createItems()
        itemViews.forEach { itemView in
            filterStackView.addArrangedSubview(itemView)
            itemView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
            }
        }
        Driver.combineLatest(itemViews.map(\.activeUpdated)) { activeStates in
            activeStates.contains(true)
        }
        .distinctUntilChanged()
        .drive(onNext: { [weak self] isActive in
            self?.updateResetButton(filterActive: isActive)
        })
        .disposed(by: disposeBag)
    }

    private func updateResetButton(filterActive: Bool) {
        if filterActive {
            resetButton.isHidden = false
            containerButtonContraint?.activate()
        } else {
            resetButton.isHidden = true
            containerButtonContraint?.deactivate()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientMaskLayer.frame = resetButton.bounds
        let gradientPivot = 8 / resetButton.frame.width
        gradientMaskLayer.locations = [
            0,
            NSNumber(value: min(gradientPivot, 1)),
            1
        ]
    }

    @objc
    private func didClickReset() {
        viewModel.resetInput.accept(())
    }
}

extension CCMSearchFilterConfigView: CCMSearchFilterViewType {
    var pickerDelegate: SearchPickerDelegate {
        viewModel
    }

    func didActive() {
        let config = viewModel.generateSearchConfig()
        handle(action: .update(searchConfig: config))
    }
}
#endif
