//
//  SearchMainTabManagerViewController.swift
//  LarkSearch
//
//  Created by SolaWing on 2021/4/9.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignToast
import UniverseDesignIcon
import LarkContainer
import RxSwift
import RxCocoa
import RustPB
import RxDataSources
import FigmaKit

/// PRD: https://bytedance.feishu.cn/docs/doccnV7mRuViQirm5figVh6UXPc
final class SearchMainTabManagerViewController: BaseUIViewController, UITableViewDelegate, UserResolverWrapper {
    lazy var tableView = InsetTableView(frame: .zero)
    @ScopedInjectedLazy var service: SearchMainTabService?
    let bag = DisposeBag()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // 右上保存按钮
    private lazy var saveButtonItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: nil, title: BundleI18n.LarkSearch.Lark_Legacy_Save)
        item.setProperty(font: UIFont.systemFont(ofSize: 16, weight: .medium), alignment: .center)
        item.addTarget(self, action: #selector(save), for: .touchUpInside)
        item.setBtnColor(color: UIColor.ud.primaryContentDefault)
        item.button.setTitleColor(UIColor.ud.fillDisable, for: .disabled)
        return item
    }()

    private var enableCapsule = false

    let state = BehaviorRelay(value: [
    Section(header: BundleI18n.LarkSearch.Lark_Search_MyCategory, items: []),
    Section(header: BundleI18n.LarkSearch.Lark_Search_MoreCategory, items: [])
    ])
    func modifyState(action: (inout [SearchMainTabManagerViewController.Section]) -> Void) {
        var state = self.state.value
        action(&state)
        self.state.accept(state)
    }
    func move(from: IndexPath, to: IndexPath) {
        modifyState { (state) in
            let item = state[from.section].items.remove(at: from.row)
            state[to.section].items.insert(item, at: to.row)
        }
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkSearch.Lark_Search_SearchCategorySettings
        self.addCancelItem()
        self.navigationItem.rightBarButtonItem = self.saveButtonItem

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)

        // bind tableView source
        tableView.rowHeight = FilterCell.Config.cellHeight
        tableView.register(FilterCell.self, forCellReuseIdentifier: "FilterCell")
        tableView.register(FilterDisableRemoveCell.self, forCellReuseIdentifier: "FilterDisableRemoveCell")

        tableView.delegate = self

        self.enableCapsule = Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: "search.redesign.capsule")

        modifyState { (sections) in
            // 过滤掉不支持的tab
            var tabs = service?.currentTabs() ?? []
            if self.enableCapsule {
                tabs = tabs.filter { SearchTab.main != $0 }
            }
            sections[0].items = tabs
        }
        service?.available().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.modifyState { [weak self] (sections) in
                guard let self = self else { return }
                var saw = Set(sections[0].items)
                saw.formUnion(sections[1].items)

                let currentAvailableTabs: [SearchTab] = self.service?.currentAvailableTabs() ?? []
                sections[1].items.append(contentsOf: currentAvailableTabs.filter({ saw.insert($0).inserted }))
            }
        }).disposed(by: bag)

        state
        .bind(to: tableView.rx.items(dataSource: source))
        .disposed(by: bag)

        tableView.rx.itemDeleted.bind { [weak self]indexPath in
            self?.move(from: indexPath, to: IndexPath(row: 0, section: 1))
        }.disposed(by: bag)
        tableView.rx.itemInserted.bind { [weak self]indexPath in
            self?.modifyState { (state) in
                let item = state[indexPath.section].items.remove(at: indexPath.row)
                state[0].items.append(item)
            }
        }.disposed(by: bag)
        tableView.rx.itemMoved.bind { [weak self] from, to in
            guard let self = self else { return }
            self.move(from: from, to: to)
            // 触发editingStyle更新
            self.tableView.reloadData()
        }.disposed(by: bag)

        tableView.isEditing = true
    }
    // MARK: Action
    @objc
    func save() {
        saveButtonItem.isEnabled = false
        weak var ws = self
        service?.shouldClearJumpTabSubject.onNext(true)
        service?.put(tabs: source[0].items)
        .timeout(.seconds(5), scheduler: MainScheduler.instance)
        .observeOn(MainScheduler.instance) // 不timeout时不会走调度器，所以还得dispatch main
        .subscribe(onNext: { _ in
            guard let self = ws else { return }
            self.closeBtnTapped()
            self.saveButtonItem.isEnabled = true
        }, onError: { (_) in
            guard let self = ws else { return }
            UDToast.showFailure(with: BundleI18n.LarkSearch.Lark_Legacy_NetworkOrServiceError, on: self.view)
            self.saveButtonItem.isEnabled = true
        }).disposed(by: bag)
    }

    private lazy var source = RxTableViewSectionedAnimatedDataSource<Section>(
        configureCell: { (_, tableView, indexPath, item) -> UITableViewCell in
            var identifier = "FilterDisableRemoveCell"
            if case .open = item {
                identifier = "FilterCell"
            }
            // 邮箱日程有特化，能增不能删
            if item.isOpenSearchEmail || item.isOpenSearchCalendar {
                if indexPath.section == 0 {
                    identifier = "FilterDisableRemoveCell"
                } else {
                    identifier = "FilterCell"
                }
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? FilterCell else { return UITableViewCell() }
            cell.titleLabel.text = item.title
            return cell
        },
        titleForHeaderInSection: { source, index in return source.sectionModels[index].header },
        canEditRowAtIndexPath: { _, _ in true },
        canMoveRowAtIndexPath: { _, indexPath in
            // 胶囊去除综合，都可以移动
            if self.enableCapsule {
                return true
            } else {
                return !(indexPath.section == 0 && indexPath.row < 1) // 综合不可移动，不可编辑
            }
        }
    )
    // MARK: TableView Delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let service = self.service else { return 0 }
        return service.isSupportTab(tab: source[indexPath]) ? FilterCell.Config.cellHeight : 0
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 {
            return .delete
        }
        return .insert
    }
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return BundleI18n.LarkSearch.Lark_Feed_Remove
    }
    // 预判断move的cell将要停留的位置，如果是在section1或者section0的row0，那么就返回原位置。反之，则返回目标位置
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section == 0 && proposedDestinationIndexPath.row < 1 {
            return sourceIndexPath
        }
        if sourceIndexPath.section == 0 && proposedDestinationIndexPath.section == 1 {
            // 非开放搜索和开放搜索中的日程邮箱不让删除
            guard case .open = source[sourceIndexPath] else { return sourceIndexPath }
            guard !(source[sourceIndexPath].isOpenSearchEmail || source[sourceIndexPath].isOpenSearchCalendar) else { return sourceIndexPath }
        }
        return proposedDestinationIndexPath
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36.0
    }

    struct Section: AnimatableSectionModelType {
        var identity: String { return header }
        init(header: String, items: [SearchTab]) {
            self.header = header
            self.items = items
        }
        init(original: SearchMainTabManagerViewController.Section, items: [SearchTab]) {
            self = original
            self.items = items
        }

        var header: String
        var items: [SearchTab]
    }
}

class FilterCell: UITableViewCell {
    struct Config {
        static let cellHeight: CGFloat = 48
    }
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.backgroundColor = UIColor.ud.bgFloat
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(9.38)
        }
        self.clipsToBounds = true // 高度为0的不可见
    }
}

final class FilterDisableRemoveCell: FilterCell {

    lazy var disableView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UDIcon.getIconByKey(.deleteDisableColorful, size: CGSize(width: 25, height: 25))
        return imageView
     }()

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        for subviewOfCell in subviews {
            guard subviewOfCell.classForCoder.description() == "UITableViewCellEditControl",
                  let control = subviewOfCell as? UIControl,
                  let imageView = control.subviews.last as? UIImageView else { continue }
            control.isUserInteractionEnabled = false
            if !imageView.subviews.contains(disableView) {
                imageView.addSubview(disableView)
                disableView.snp.makeConstraints { (make) in
                    if #available(iOS 13.0, *) {
                        make.width.equalTo(imageView)
                        make.height.equalTo(imageView)
                    } else {
                        make.width.equalTo(imageView).offset(3)
                        make.height.equalTo(imageView).offset(3)
                    }
                    make.center.equalTo(imageView)
                }
            }
            break
        }
    }
}

extension SearchTab: IdentifiableType {
    public var identity: SearchTab.Identity { id }
}
