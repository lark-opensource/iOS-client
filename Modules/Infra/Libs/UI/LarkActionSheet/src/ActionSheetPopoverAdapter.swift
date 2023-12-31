//
//  ActionSheetPopoverAdapter.swift
//  LarkUIKit
//
//  Created by LUNNER on 2020/1/19.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import LarkTraitCollection

public final class ActionSheetPopoverAdapter {

    private var disposeBag = DisposeBag()
    private var maxTitleWidth: CGFloat = 0.0 {
        didSet {
            viewController?.preferredContentSize = CGSize(width: maxTitleWidth + 62, height: 120)
        }
    }
    var viewController: UIViewController?

    public init() {}

    public func create(sourceView: UIView? = nil, sourceRect: CGRect = .zero) -> UIViewController {
        let viewController: UIViewController
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let sourceView = sourceView,
                sourceView.traitCollection.horizontalSizeClass == .regular {
                viewController = ActionSheetForPopoverViewController()
                viewController.modalPresentationStyle = .popover
                viewController.preferredContentSize = CGSize(width: 180, height: 120)
                viewController.popoverPresentationController?.sourceView = sourceView
                viewController.popoverPresentationController?.sourceRect = sourceRect
            } else {
                viewController = ActionSheet()
            }
            observeTraitCollectionChange(for: viewController)
        } else {
            viewController = ActionSheet()
        }
        self.viewController = viewController
        return viewController
    }

    func observeTraitCollectionChange(for viewController: UIViewController) {
        disposeBag = DisposeBag()

        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: viewController)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] change in
                self?.dismissIfNeeded(traitCollectionChange: change)
            }).disposed(by: disposeBag)
    }

    func dismissIfNeeded(traitCollectionChange: TraitCollectionChange) {
        if traitCollectionChange.new.horizontalSizeClass != traitCollectionChange.old.horizontalSizeClass {
            self.disposeBag = DisposeBag()
            viewController?.dismiss(animated: false, completion: nil)
        }
    }

    public func addItem(
        title: String,
        textColor: UIColor? = nil,
        icon: UIImage? = nil,
        entirelyCenter: Bool = false,
        action: @escaping () -> Void
    ) {
        let width = ceil(title.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]).width)
        if width > maxTitleWidth {
            maxTitleWidth = width
        }
        if let actionSheet = viewController as? ActionSheet {
            actionSheet.addItem(title: title, textColor: textColor, icon: icon, entirelyCenter: entirelyCenter, action: action)
        } else if let popoverVC = viewController as? ActionSheetForPopoverViewController {
            let newItem = ActionSheetItem(title: title,
                                          textColor: textColor,
                                          icon: icon,
                                          entirelyCenter: entirelyCenter,
                                          isCancel: false, action: action)
            popoverVC.addItem(newItem)
        }
    }

    public func addCancelItem(
        title: String,
        textColor: UIColor? = nil,
        icon: UIImage? = nil,
        entirelyCenter: Bool = false,
        cancelAction: (() -> Void)? = nil
    ) {
        if let actionSheet = viewController as? ActionSheet {
            actionSheet.addCancelItem(
                title: title,
                textColor: textColor,
                icon: icon,
                entirelyCenter: entirelyCenter,
                cancelAction: cancelAction
            )
        }
    }
}

private final class ActionSheetItem {
    let isCancel: Bool
    let title: String
    let textColor: UIColor?
    let icon: UIImage?
    let entirelyCenter: Bool
    let action: () -> Void
    init(title: String, textColor: UIColor? = nil,
         icon: UIImage? = nil, entirelyCenter: Bool = true,
         isCancel: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.textColor = textColor
        self.icon = icon
        self.entirelyCenter = entirelyCenter
        self.isCancel = isCancel
        self.action = action
    }
}

private final class ItemCell: UITableViewCell {

    lazy var icon: UIImageView = {
        let view = UIImageView()
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    var item: ActionSheetItem? {
        didSet {
            guard let newItem = item else {
                icon.image = nil
                titleLabel.text = nil
                return
            }
            icon.image = newItem.icon
            titleLabel.text = newItem.title
            if let color = newItem.textColor {
                titleLabel.textColor = color
            }
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(icon)
        self.contentView.addSubview(titleLabel)
        icon.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(16)
            maker.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(icon.snp.trailing).offset(10)
            maker.trailing.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ActionSheetForPopoverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 56
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.register(ItemCell.self, forCellReuseIdentifier: "ItemCell")
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private var items = [ActionSheetItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.bottom.leading.right.equalToSuperview()
            make.height.equalTo(112)
        }
        tableView.reloadData()
    }

    func addItem(_ item: ActionSheetItem) {
        items.append(item)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        if let itemCell = cell as? ItemCell {
            itemCell.item = items[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        self.dismiss(animated: true) {
            item.action()
        }
    }

}
