//
//  ProfileSectionTab.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/12/28.
//

import Foundation
import FigmaKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignEmpty
import ThreadSafeDataStructure
import UIKit
import EENavigator
import LarkContainer

public protocol ProfileSectionItem {}

public protocol ProfileSectionProvider {
    init?(item: ProfileSectionItem)
    var fromVC: UIViewController? { get set }
    func update(item: ProfileSectionItem)
    func numberOfRows() -> Int
    func cellTypesForSection() -> [ProfileSectionTabCell.Type]
    func cellForRowAt(index: Int) -> ProfileSectionTabCell
}

public class ProfileSectionTabCell: BaseTableViewCell {
    public var navigator: EENavigator.Navigatable?
    private lazy var separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    public func didTap(_ fromVC: UIViewController) { }

    public func addDividingLine() {
        separatorLine.isHidden = false
    }

    public func removeDividingLine() {
        separatorLine.isHidden = true
    }

    func commonInit() {
        contentView.addSubview(separatorLine)

        separatorLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
        }
    }

    func updateSeparatorLine(left loffset: Int = 0, right roffset: Int = 0) {
        separatorLine.snp.remakeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(loffset)
            make.right.equalToSuperview().offset(roffset)
        }
    }
}

public class ProfileSectionTab: UIViewController, ProfileTab, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    public weak var profileVC: UIViewController?

    public var contentViewDidScroll: ((UIScrollView) -> Void)?

    private var tabTitle: String

    private var providers: SafeArray<ProfileSectionProvider> = [] + .readWriteLock

    private var sectionItems: SafeArray<ProfileSectionItem> = [] + .readWriteLock

    private var emptyConfig: UDEmptyConfig = UDEmptyConfig(type: .initial)

    private var errorConfig: UDEmptyConfig = UDEmptyConfig(type: .initial)

    var errorLoad: (() -> Void)?

    lazy var tableView: InsetTableView = {
        let tableView = InsetTableView()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 64
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()

    private lazy var emptyView: UDEmpty = {
        return UDEmpty(config: UDEmptyConfig(type: .initial))
    }()

    public init(resolver: UserResolver,
                title: String,
                sectionItems: [ProfileSectionItem] = []) {
        self.userResolver = resolver
        self.tabTitle = title
        self.sectionItems = sectionItems + .readWriteLock
        self.providers = ProfileSectionFactory.createWithItems(sectionItems, fromVC: nil) + .readWriteLock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBase

        self.view.addSubview(tableView)
        self.view.addSubview(emptyView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = self
        tableView.delegate = self

        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 24))
        tableView.tableFooterView = footerView

        emptyView.isHidden = true
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(80)
            make.width.lessThanOrEqualToSuperview().offset(-20)
        }

        let config = UDEmptyConfig(
            title: nil,
            description: .init(descriptionText: BundleI18n.LarkProfile.Lark_Profile_NoOrgDetail_EmptyState),
            type: .noContent
        )
        emptyConfig = config
        emptyView.update(config: config)

        let content = NSMutableAttributedString(string: BundleI18n.LarkProfile.Lark_NewContacts_FailedToLoadComma)
        let retry = NSMutableAttributedString(string: BundleI18n.LarkProfile.Lark_NewContacts_RefreshToTryAagin,
                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentDefault])
        content.append(retry)

        let range = content.mutableString.range(of: BundleI18n.LarkProfile.Lark_NewContacts_RefreshToTryAagin,
                                                options: .caseInsensitive)

        errorConfig = UDEmptyConfig(title: nil,
                                    description: .init(descriptionText: content,
                                                       operableRange: range),
                                    type: .loadingFailure,
                                    labelHandler: { [weak self] in
            self?.errorLoad?()
        })

        registerCells()
    }

    public func updateSections(_ sectionItems: [ProfileSectionItem], isError: Bool = false) {
        DispatchQueue.main.async {
            self.sectionItems.removeAll()
            self.providers.removeAll()

            for item in sectionItems {
                self.sectionItems.append(item)
            }
            let factoryProviders = ProfileSectionFactory.createWithItems(sectionItems, fromVC: self.profileVC)
            for item in factoryProviders {
                self.providers.append(item)
            }
            self.registerCells()
            self.reloadData()
            self.emptyView.isHidden = !sectionItems.isEmpty && !isError
            self.emptyView.update(config: isError ? self.errorConfig : self.emptyConfig)

        }
    }

    public func reloadData() {
        self.tableView.reloadData()
    }

    private func registerCells() {
        for provider in self.providers.getImmutableCopy() {
            let cells = provider.cellTypesForSection()
            for cellType in cells {
                tableView.register(cellType, forCellReuseIdentifier: String(describing: cellType))
            }
        }
    }
}

extension ProfileSectionTab {

    public static var tabId: String {
        return "ProfileSectionTab"
    }

    public var itemId: String {
        return "ProfileSectionTab"
    }

    public func listView() -> UIView {
        return view
    }

    public var segmentTitle: String {
        return tabTitle
    }

    public var scrollableView: UIScrollView {
        return self.tableView
    }
}

extension ProfileSectionTab: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.providers.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < providers.count else {
            return 0
        }
        return self.providers[section].numberOfRows()
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < providers.count else {
            return UITableViewCell()
        }

        let cell = providers[indexPath.section].cellForRowAt(index: indexPath.row)
        cell.navigator = self.userResolver.navigator
        // 移除最后一个 Cell 的分割线
        if indexPath.row == self.providers[indexPath.section].numberOfRows() - 1 {
            cell.removeDividingLine()
        } else {
            cell.addDividingLine()
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath) as? ProfileSectionTabCell
        if let fromVC = self.profileVC {
            cell?.didTap(fromVC)
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.contentViewDidScroll?(self.tableView)
    }
}

extension ProfileSectionTab {

    enum Cons {
        static let hMargin: CGFloat =  16
        static let topMargin: CGFloat = 12
        static let bottomMargin: CGFloat = 30
        static let cornerRadius: CGFloat = 0
    }
}
