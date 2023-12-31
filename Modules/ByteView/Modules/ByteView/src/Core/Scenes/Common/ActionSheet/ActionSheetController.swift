//
//  ActionSheetViewController.swift
//  ByteView
//
//  Created by LUNNER on 2019/1/6.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RxDataSources
import ByteViewUI

protocol ActionSheetControllerDelegate: AnyObject {
    func viewWillDisappear()
    func viewWillAppear()
}

class ActionSheetController: PuppetPresentedViewController, UITableViewDelegate {

    enum Style {
        case actionSheet
        case pan
    }

    enum ModalStyle {
        case formSheet
        case popover
        case alwaysPopover
    }

    let appearance: ActionSheetAppearance
    let tableView: BaseTableView = BaseTableView(frame: CGRect.zero, style: .plain)

    struct Layout {
        static let actionSheetRowHeight: CGFloat = 48.0
        static let panRowHeight: CGFloat = 48.0

        static let regularHorizontalPadding: CGFloat = 0.0
        static let compactHorizontalPadding: CGFloat = 12.0

        static let actionSheetTitleTopOffset: CGFloat = 13.0
        static let panTitleTopOffset: CGFloat = 8.0
        static let titleBottomOffset: CGFloat = 13.0

        static let actionSheetTitleHorizontalOffset: CGFloat = 20.0
        static let panTitleHorizontalOffset: CGFloat = 16.0

        static let cancelHeight: CGFloat = 48.0
        static let cancelTopOffset: CGFloat = 15.0
        static let bottomOffset: CGFloat = 12.0

        static let landscapeBottomOffset: CGFloat = Display.iPhoneXSeries ? 0.0 : 8.0
        static let landscapeMaxWidth: CGFloat = 375.0
    }

    lazy var visualEffectView: UIView = {
        let visualEffectView = UIView(frame: VCScene.bounds)
        visualEffectView.clipsToBounds = true
        visualEffectView.layer.cornerRadius = appearance.tableViewCornerRadius
        return visualEffectView
    }()

    lazy var cancelButton: UIButton = {
        var button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_CancelButton, for: .normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = appearance.tableViewCornerRadius
        button.adjustsImageWhenHighlighted = false
        button.isAccessibilityElement = true
        button.accessibilityIdentifier = "ActionsheetController.cancelButton.accessibilityIdentifier"
        return button
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0

        if let title = titleString {
            let config = appearance.titleTextStyleConfig
            label.attributedText = NSAttributedString(string: title, config: config, alignment: appearance.titleAlignment)
        }

        return label
    }()

    lazy var headerVisualEffectView: UIView = {
        let visualEffectView = UIView(frame: VCScene.bounds)
        let line = UIView()
        line.backgroundColor = appearance.separatorColor
        visualEffectView.addSubview(line)
        line.snp.makeConstraints { (maker) in
            maker.height.equalTo(0.5)
            maker.left.right.bottom.equalToSuperview()
        }
        return visualEffectView
    }()

    var viewModel: ActionSheetViewModel = ActionSheetViewModel()
    var defaultActions: [SheetAction] {
        return viewModel.defaultActions.value.map { $0.items[0] }
    }

    var cancelAction: SheetAction? {
        return viewModel.cancelAction.value?.items.first
    }

    var modalPresentation: ModalStyle = .formSheet
    var regularPopoverWidth: CGFloat = 375.0

    private let usePadStyle = BehaviorRelay<Bool>(value: false)

    private let titleString: String?
    // 如果设置了titleString，则该变量可以控制title的显隐，但是不会改变popover整体高度
    var shouldHideTitle: Bool = false {
        didSet {
            setupTitleView()
        }
    }

    var isIPadLayout: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    weak var delegate: ActionSheetControllerDelegate?

    private var titleSize: CGSize {
        guard titleString != nil else {
            return CGSize.zero
        }
        let width: CGFloat
        if VCScene.rootTraitCollection?.horizontalSizeClass == .regular {
            width = regularPopoverWidth - (appearance.titleHorizontalOffset + Layout.regularHorizontalPadding) * 2
        } else {
            width = VCScene.bounds.width - (appearance.titleHorizontalOffset + Layout.compactHorizontalPadding) * 2
        }
        return self.titleLabel.sizeThatFits(CGSize(width: width, height: 0))
    }

    var padContentSize: CGSize {
        let headerHeight: CGFloat
        if titleString?.isEmpty ?? true {
            headerHeight = 0
        } else {
            headerHeight = titleSize.height + appearance.titleTopOffset + Layout.titleBottomOffset
        }
        return CGSize(width: regularPopoverWidth, height: headerHeight + intrinsicHeight)
    }

    var padContentSizeWithoutTitle: CGSize {
        return CGSize(width: regularPopoverWidth, height: intrinsicHeight)
    }

    var maxIntrinsicWidth: CGFloat {
        defaultActions.map { $0.intrinsicWidth }.max() ?? 0.0
    }

    var intrinsicHeight: CGFloat {
        var height: CGFloat = 0
        defaultActions.forEach { action in
            if action.sheetStyle == .withContent {
                if let titleMargin = action.titleMargin {
                    height += CGFloat(titleMargin.top)
                }
                height += action.titleHeight
                if let contentMargin = action.contentMargin {
                    height += CGFloat(contentMargin.top)
                    height += CGFloat(contentMargin.bottom)
                }
                height += action.contentHeight
            } else {
                height += appearance.textHeight
            }
        }
        return height
    }

    var headerHeight: CGFloat {
        return self.titleSize == CGSize.zero ? 0 : self.titleSize.height + appearance.titleTopOffset + Layout.titleBottomOffset
    }

    init(title: String? = nil, appearance: ActionSheetAppearance) {
        self.titleString = title
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.viewWillDisappear()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.viewWillAppear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleView()
        setupTableView()
        setupCancelButton()
        self.view.backgroundColor = .clear

        self.isIPadLayout
            .subscribe(onNext: { [weak self] isIPad in
                self?.remakeConstraints(usePadStyle: isIPad)
                self?.tableView.reloadData()
            })
            .disposed(by: rx.disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.ui.info("[ActionSheetController] count:\(self.defaultActions.count), frame:\(self.view.frame), tableView-frame:\(self.tableView.frame), appearance:\(self.appearance)")
    }

    func remakeConstraints(usePadStyle: Bool) {
        let tableWidth: CGFloat = self.isIPadLayout.value ?
                regularPopoverWidth : VCScene.bounds.width - Layout.compactHorizontalPadding * 2
        let headerViewHeight: CGFloat
        let horizontalPadding: CGFloat

        switch (modalPresentation, appearance.style) {
        case (.alwaysPopover, _), (_, .pan):
            horizontalPadding = 0
        default:
            horizontalPadding = usePadStyle ? Layout.regularHorizontalPadding : Layout.compactHorizontalPadding
        }

        if self.titleLabel.superview != nil {
            self.titleLabel.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview().inset(UIEdgeInsets(
                    top: appearance.titleTopOffset,
                    left: appearance.titleHorizontalOffset,
                    bottom: Layout.titleBottomOffset,
                    right: appearance.titleHorizontalOffset))
            }
            let headerSize = self.headerVisualEffectView
                .systemLayoutSizeFitting(CGSize(width: tableWidth, height: 0),
                                         withHorizontalFittingPriority: .required,
                                         verticalFittingPriority: .defaultLow)
            self.headerVisualEffectView.frame = CGRect(x: 0, y: 0, width: tableWidth, height: headerSize.height)
            headerViewHeight = headerSize.height
            self.tableView.tableHeaderView = self.headerVisualEffectView
        } else {
            headerViewHeight = 0
            self.tableView.tableHeaderView = nil
        }

        let defaultActionHeight: CGFloat = self.intrinsicHeight
        self.tableView.snp.remakeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(horizontalPadding + appearance.tableViewInsets.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-(horizontalPadding + appearance.tableViewInsets.right))
            make.top.equalToSuperview().offset(appearance.tableViewInsets.top)
            if appearance.tableViewScrollable {
                if #available(iOS 12.0, *) {
                    make.bottom.lessThanOrEqualToSuperview().offset(appearance.tableViewInsets.bottom)
                } else {
                    make.bottom.equalToSuperview().offset(appearance.tableViewInsets.bottom)
                }
            } else {
                make.height.equalTo(headerViewHeight + defaultActionHeight)
            }
        }


        self.visualEffectView.isHidden = usePadStyle
        self.cancelButton.isHidden = usePadStyle

        if self.visualEffectView.superview != nil && !self.visualEffectView.isHidden {
            self.visualEffectView.snp.remakeConstraints { (make) in
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(horizontalPadding)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-horizontalPadding)
                make.top.equalTo(self.tableView.snp.bottom).offset(Layout.cancelTopOffset)
                make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
                if let customRowHeight = appearance.customTextHeight {
                    make.height.equalTo(customRowHeight)
                } else {
                    make.height.equalTo(Layout.cancelHeight)
                }
            }
        }
    }

    /// 仅有1个Action时，修改点击高亮区域，使其在水平方向相对于ActionSheet无缩进
    func modifyUniqueActionIfNeeded() {
        if self.defaultActions.count == 1, var action = self.defaultActions.first {
            action.isSelectedIndent = false
            viewModel.defaultActions.accept([ActionSheetSectionModel(items: [action])])
        }
    }

    private func setupTitleView() {
        guard let title = self.titleString else {
            return
        }
        if shouldHideTitle {
            tableView.tableHeaderView = nil
            titleLabel.removeFromSuperview()
        } else {
            titleLabel.textColor = appearance.titleColor
            titleLabel.text = title

            headerVisualEffectView.backgroundColor = appearance.backgroundColor
            headerVisualEffectView.frame = CGRect(x: 0, y: 0, width: VCScene.bounds.width - 20, height: headerHeight)
            tableView.tableHeaderView = headerVisualEffectView

            headerVisualEffectView.addSubview(titleLabel)
        }
    }

    private func setupCancelButton() {
        guard let cancelAction = self.cancelAction else {
            return
        }

        self.cancelButton.setBackgroundImage(UIImage.vc.fromColor(appearance.backgroundColor), for: .normal)
        self.cancelButton.setBackgroundImage(UIImage.vc.fromColor(appearance.highlightedColor), for: .highlighted)

        self.cancelButton.setAttributedTitle(NSAttributedString(string: cancelAction.title, config: .body), for: .normal)
        self.cancelButton.setTitleColor(cancelAction.titleColor, for: .normal)

        visualEffectView.backgroundColor = appearance.backgroundColor
        self.view.addSubview(self.visualEffectView)

        self.view.addSubview(self.cancelButton)
        self.cancelButton.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalTo(self.visualEffectView)
        }
        self.cancelButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.cancelButtonTapped()
            })
            .disposed(by: rx.disposeBag)
    }

    private func cancelButtonTapped() {
        self.dismiss(animated: true, completion: { [weak self] in
            guard let item = self?.cancelAction else {
                return
            }
            item.handler(item)
        })
    }

    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.bounces = false
        tableView.backgroundColor = appearance.backgroundColor
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = appearance.tableViewCornerRadius
        tableView.register(ActionSheetCell.self, forCellReuseIdentifier: String(describing: ActionSheetCell.self))
        tableView.isAccessibilityElement = true
        tableView.accessibilityLabel = "ActionsheetController.tableView.accessibilityLabel"
        tableView.accessibilityIdentifier = "ActionsheetController.tableView.accessibilityIdentifier"
        tableView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        self.view.addSubview(tableView)
        setupCellConfiguration()
        setupCellTapHandling()
    }

    private func setupCellConfiguration() {
        let dataSource = RxTableViewSectionedReloadDataSource<ActionSheetSectionModel> { [weak self] (_, tableView, indexPath, item) -> UITableViewCell in
            guard let self = self, let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ActionSheetCell.self)) as? ActionSheetCell else {
                return UITableViewCell()
            }
            cell.configure(with: item, apperance: self.appearance)

            var hideLastItemSeparator: Bool
            if VCScene.rootTraitCollection?.horizontalSizeClass == .regular {
                hideLastItemSeparator = true
            } else {
                hideLastItemSeparator = self.appearance.style == .actionSheet
            }
            if indexPath.section == self.defaultActions.count - 1 && hideLastItemSeparator {
                cell.bottomSeparator.isHidden = true
            }
            return cell
        }

        viewModel.defaultActions.asObservable()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)

        viewModel.cancelAction.asDriver()
            .drive(onNext: { [weak self] action in
                guard let action = action?.items.first else { return }
                self?.cancelButton.setAttributedTitle(NSAttributedString(string: action.title, config: .body), for: .normal)
                self?.cancelButton.setTitleColor(action.titleColor, for: .normal)
            })
            .disposed(by: rx.disposeBag)
    }
    // swiftlint:enable force_cast

    private func setupCellTapHandling() {
        tableView.rx.modelSelected(SheetAction.self)
            .subscribe(onNext: { [weak self] (item) in
                self?.dismiss(animated: true, completion: {
                    item.handler(item)
                })
            })
            .disposed(by: rx.disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: rx.disposeBag)
    }

    func addAction(_ action: SheetAction) {
        self.viewModel.addAction(action)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section <= viewModel.defaultActions.value.count else { return 0 }
        let section = viewModel.defaultActions.value[indexPath.section]
        let actions = section.items
        guard indexPath.row <= actions.count else { return 0 }
        let action = actions[indexPath.row]
        if action.sheetStyle == .withContent {
            var height: CGFloat = 0.0
            if let titleMargin = action.titleMargin {
                height += CGFloat(titleMargin.top)
            }
            height += action.titleHeight
            if let contentMargin = action.contentMargin {
                height += CGFloat(contentMargin.top)
                height += CGFloat(contentMargin.bottom)
            }
            height += action.contentHeight
            return height
        }
        return appearance.textHeight
    }
}
