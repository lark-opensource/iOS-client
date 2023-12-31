//
//  SpaceSortPanelController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/8/26.
//

import Foundation
import SKUIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import RxSwift
import RxCocoa

public protocol SpaceSortPanelDelegate: AnyObject {
    func sortPanel(_ panel: SpaceSortPanelController, didSelect selectionIndex: Int, descending: Bool)
    func sortPanelDidClickReset(_ panel: SpaceSortPanelController)
}

public final class SpaceSortPanelController: SKBlurPanelController {

    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.backgroundColor = .clear
        view.setTitle(BundleI18n.SKResource.Doc_List_SortBy)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        return view
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        let fontSize: CGFloat = 16
        button.setTitle(BundleI18n.SKResource.LarkCCM_NewCM_Default_Button, withFontSize: fontSize, fontWeight: .regular, color: UDColor.functionInfoContentDefault, forState: .normal)
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
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

    private let options: [SortItem]
    private let currentSelection: Int
    private let canReset: Bool
    public weak var delegate: SpaceSortPanelDelegate?
    private var itemViews: [ItemView] = []

    private let disposeBag = DisposeBag()

    public init(options: [SortItem], initialSelection: Int, canReset: Bool) {
        self.options = options
        currentSelection = initialSelection
        self.canReset = canReset
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func setupUI() {
        super.setupUI()

        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        if canReset {
            headerView.addSubview(resetButton)
            resetButton.snp.makeConstraints { make in
                make.centerY.equalTo(headerView.titleCenterY)
                make.trailing.equalToSuperview().inset(16)
            }
        }

        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(16)
        }

        guard !options.isEmpty else {
            assertionFailure()
            return
        }

        options.enumerated().forEach { (offset, sortItem) in
            let nextItemView = itemView(for: sortItem, at: offset)
            itemViews.append(nextItemView)
            stackView.addArrangedSubview(nextItemView)
            nextItemView.snp.makeConstraints { make in
                make.height.equalTo(52)
            }
            // 最后一个 item 不展示分隔线
            if offset == (options.count - 1) {
                nextItemView.separator.isHidden = true
            }
        }
    }

    public override func transitionToRegularSize() {
        super.transitionToRegularSize()
        headerView.toggleCloseButton(isHidden: true)
    }

    public override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        headerView.toggleCloseButton(isHidden: false)
    }

    private func itemView(for item: SortItem, at index: Int) -> ItemView {
        let item = Item(title: item.displayNameV2,
                        descendingDescription: item.descendingDescription,
                        ascendingDescription: item.ascendingDescription,
                        allowAscending: item.needShowUpArrow,
                        isDescending: !item.isUp,
                        selected: currentSelection == index)
        let itemView = ItemView(item: item)

        itemView.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.didClick(index: index)
            })
            .disposed(by: disposeBag)

        return itemView
    }

    private func didClick(index: Int) {
        if index != currentSelection {
            itemViews[currentSelection].notifyDeselected()
        }
        let selectedView = itemViews[index]
        selectedView.notifySelected()
        // 考虑 delay 一下再 dismiss
        delegate?.sortPanel(self, didSelect: index, descending: selectedView.item.isDescending)
        dismiss(animated: true)
    }

    @objc
    private func didClickReset() {
        delegate?.sortPanelDidClickReset(self)
        dismiss(animated: true)
    }
}

private extension SpaceSortPanelController {

    struct Item {
        let title: String
        let descendingDescription: String
        let ascendingDescription: String
        let allowAscending: Bool
        var isDescending: Bool
        var selected: Bool
    }

    class SeperatorView: UIView {

        var seperatorColor: UIColor? {
            get {
                colorView.backgroundColor
            }
            set {
                colorView.backgroundColor = newValue
            }
        }

        private lazy var colorView: UIView = {
            let view = UIView()
            view.backgroundColor = UDColor.lineDividerDefault
            return view
        }()

        var inset: CGFloat = 16 {
            didSet {
                colorView.snp.updateConstraints { make in
                    make.left.equalToSuperview().inset(inset)
                }
            }
        }

        init(inset: CGFloat) {
            self.inset = inset
            super.init(frame: .zero)
            setupUI()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupUI()
        }

        private func setupUI() {
            backgroundColor = .clear
            addSubview(colorView)
            colorView.snp.makeConstraints { make in
                make.top.right.bottom.equalToSuperview()
                make.left.equalToSuperview().inset(inset)
            }
        }
    }

    class ItemView: UIControl {

        private enum Layout {
            static var titleColor: UIColor { UDColor.textTitle }
            static var selectedTitleColor: UIColor { UDColor.functionInfoContentDefault }
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
            label.textColor = Layout.titleColor
            label.font = .systemFont(ofSize: 16)
            return label
        }()

        private lazy var descriptionLabel: UILabel = {
            let label = UILabel()
            label.textColor = Layout.selectedTitleColor
            label.font = .systemFont(ofSize: 14)
            return label
        }()

        private lazy var arrowImageView: UIImageView = {
            let view = UIImageView()
            view.image = UDIcon.spaceDownOutlined.withRenderingMode(.alwaysTemplate)
            view.tintColor = Layout.selectedTitleColor
            return view
        }()

        private(set) lazy var separator: SeperatorView = {
            let seperatorView = SeperatorView(inset: 16)
            return seperatorView
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
            addSubview(arrowImageView)
            arrowImageView.snp.makeConstraints { make in
                make.width.height.equalTo(16)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(16)
            }

            addSubview(descriptionLabel)
            descriptionLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalTo(arrowImageView.snp.left).offset(-4)
            }

            addSubview(separator)
            separator.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }

        private func update() {
            guard item.selected else {
                arrowImageView.isHidden = true
                descriptionLabel.isHidden = true
                titleLabel.textColor = Layout.titleColor
                return
            }

            titleLabel.textColor = Layout.selectedTitleColor
            arrowImageView.isHidden = false
            descriptionLabel.isHidden = false
            if item.isDescending {
                arrowImageView.image = UDIcon.spaceDownOutlined.withRenderingMode(.alwaysTemplate)
                descriptionLabel.text = item.descendingDescription
            } else {
                arrowImageView.image = UDIcon.spaceUpOutlined.withRenderingMode(.alwaysTemplate)
                descriptionLabel.text = item.ascendingDescription
            }
        }

        func notifySelected() {
            if item.selected {
                if item.allowAscending {
                    item.isDescending = !item.isDescending
                }
            } else {
                item.selected = true
                item.isDescending = true
            }
            update()
        }

        func notifyDeselected() {
            item.selected = false
            item.isDescending = true
            update()
        }
    }
}
