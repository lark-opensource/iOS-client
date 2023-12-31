//
//  SpaceFilterPanelController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/8/25.
//
import SKFoundation
import SKUIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import RxSwift
import RxCocoa


public protocol SpaceFilterPanelDelegate: AnyObject {
    func filterPanel(_ panel: SpaceFilterPanelController, didConfirmWith selection: FilterItem)
    func didClickResetFor(filterPanel: SpaceFilterPanelController)
}

public final class SpaceFilterPanelController: SKBlurPanelController {

    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.backgroundColor = .clear
        view.setTitle(BundleI18n.SKResource.Doc_List_Filter_By_Type)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgFloatOverlay
        view.layer.cornerRadius = 6
        view.clipsToBounds = true

        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 0
        return view
    }()

    private var currentIndex: Int
    public let options: [FilterItem]
    public weak var delegate: SpaceFilterPanelDelegate?
    private var itemViews: [FilterItemView] = []

    private let disposeBag = DisposeBag()

    public init(options: [FilterItem], initialSelection: Int?) {
        self.options = options
        currentIndex = initialSelection ?? 0
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Override
    public override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(16)
        }

        guard !options.isEmpty else {
            assertionFailure()
            return
        }

        options.enumerated().forEach { index, filterItem in
            let nextItemView = itemView(for: filterItem, at: index)
            itemViews.append(nextItemView)
            stackView.addArrangedSubview(nextItemView)
            nextItemView.snp.makeConstraints { make in
                make.height.equalTo(54)
                make.left.right.equalToSuperview()
            }
            if index < (options.count - 1) {
                let separator = UIView()
                separator.backgroundColor = UDColor.lineDividerDefault
                nextItemView.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                    make.left.equalToSuperview().inset(16)
                    make.bottom.right.equalToSuperview()
                }
            }
        }
    }

    private func itemView(for item: FilterItem, at index: Int) -> FilterItemView {
        let item = FilterItemView.Item(title: item.displayName,
                                       selected: index == currentIndex)
        let itemView = FilterItemView(item: item)
        itemView.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.didClick(index: index)
            })
            .disposed(by: disposeBag)
        return itemView
    }

    private func didClick(index: Int) {
        if index != currentIndex {
            itemViews[currentIndex].notifyDeselected()
        }
        let selectedView = itemViews[index]
        selectedView.notifySelected()
        // 考虑 delay 一下再 dismiss
        let selectedItem = options[index]
        delegate?.filterPanel(self, didConfirmWith: selectedItem)
        dismiss(animated: true)
    }

    public override func transitionToRegularSize() {
        super.transitionToRegularSize()
        headerView.toggleCloseButton(isHidden: true)
    }

    public override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        headerView.toggleCloseButton(isHidden: false)
    }
}

private class FilterItemView: UIControl {

    struct Item {
        let title: String
        var selected: Bool
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.fillPressed
            } else {
                backgroundColor = UDColor.bgFloat
            }
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = item.title
        label.textColor = UDColor.functionInfoContentDefault
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.doneOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UDColor.functionInfoContentDefault
        view.contentMode = .scaleAspectFit
        return view
    }()

    private(set) var item: Item

    init(item: Item) {
        self.item = item
        super.init(frame: .zero)
        setupUI()
        update()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgFloat
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
    }

    private func update() {
        guard item.selected else {
            iconView.isHidden = true
            titleLabel.textColor = UDColor.textTitle
            return
        }

        titleLabel.textColor = UDColor.functionInfoContentDefault
        iconView.isHidden = false
    }

    func notifySelected() {
        item.selected = true
        update()
    }

    func notifyDeselected() {
        item.selected = false
        update()
    }   
}
