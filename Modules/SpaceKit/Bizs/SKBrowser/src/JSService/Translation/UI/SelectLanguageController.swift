//
//  LanguageChangeViewcontroller.swift
//  SKCommon
//
//  Created by LiZeChuang on 2020/7/2.
//

import Foundation
import LarkUIKit
import SKCommon
import SKResource
import SKUIKit
import RxSwift
import LarkTraitCollection
import UniverseDesignColor
import SKFoundation
import UniverseDesignIcon

protocol SelectLanuageControllerDelegate: AnyObject {
    func didSelectDiffLanguage(language: String, displayLanguage: String)
}

typealias SelectLanguageActionBlock = () -> Void
class SelectLanguageController: SKTranslucentPanelController, UITableViewDelegate, UITableViewDataSource {
    
    public var supportOrentations: UIInterfaceOrientationMask = .portrait {
        didSet {
            if SKDisplay.phone && supportOrentations != .portrait {
                dismissalStrategy = []
            } else {
                dismissalStrategy = [.larkSizeClassChanged]
            }
        }
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrentations
    }

    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.backgroundColor = .clear
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.setTitle(BundleI18n.SKResource.Doc_Translate_TranslateTo)
        return view
    }()
    private lazy var tableView: UITableView = {
        return self.createTableView()
    }()

    private enum Const {
        static let titleHeight: CGFloat = 40
        static let itemHeight = 52.0
        static let heightRatio = 0.83
        static let safeArea: Double = 48
        static let estimatedRowHeight: CGFloat = 52
        static let sectionHeaderHeight: CGFloat = 40
        static let separatorHeight: CGFloat = 16
    }
    
    private var languages: [String]?
    private var displayLanguages: [String]?
    private var displayIndex: Int?
    private var recentSelectLanguages: [[String: String]]?
    private var isVersion: Bool?

    weak var delegate: SelectLanuageControllerDelegate?
    let bag = DisposeBag()

    private var displayBlock: SelectLanguageActionBlock?
    private var dismissBlock: SelectLanguageActionBlock?

    public required init(languages: [String], displayLanguages: [String], displayIndex: Int?, recentSelectLanguages: [[String: String]], isFromVersion: Bool? = false) {
        super.init(nibName: nil, bundle: nil)
        self.languages = languages
        self.displayLanguages = displayLanguages
        self.displayIndex = displayIndex
        self.isVersion = isFromVersion
//        self.recentSelectLanguages = recentSelectLanguages
        dismissalStrategy = [.larkSizeClassChanged]
        transitioningDelegate = panelFormSheetTransitioningDelegate
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateContentSize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayBlock?()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissBlock?()
    }
    
    @objc
    private func orientationDidChange() {
        updateContentSize()
    }
    
    private func updateContentSize() {
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            containerView.snp.remakeConstraints { (make) in
                make.centerX.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
                make.height.equalToSuperview().inset(14)
            }
        } else {
            containerView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }
        }
    }

    public func setUpSelectLanguage(displayBlock: SelectLanguageActionBlock?, dismissBlock: SelectLanguageActionBlock?) {
        self.displayBlock = displayBlock
        self.dismissBlock = dismissBlock
    }

    private func estimateTableHeight() -> CGFloat {
        var titleHeight: CGFloat = Const.titleHeight
        var itemsHeight: CGFloat = CGFloat(displayLanguages?.count ?? 0) * Const.itemHeight
        if let curRecentSelectLanguages = recentSelectLanguages, curRecentSelectLanguages.count > 0 {
            titleHeight += Const.titleHeight
            itemsHeight += CGFloat(curRecentSelectLanguages.count) * Const.itemHeight
        }
        return titleHeight + itemsHeight
    }

    override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(headerView.intrinsicContentSize.height)
        }
        containerView.addSubview(tableView)

        self.tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(estimateTableHeight())
            make.bottom.equalToSuperview().inset(16)
        }
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // 只有 iphone 中需要处理。
        guard SKDisplay.phone || !self.isMyWindowRegularSize() else {
            return
        }
        // 这里的 0.63 的比例是参照目录获取的。
        var tableMaxHeight = (self.view.frame.height * Const.heightRatio) - Const.safeArea - self.view.safeAreaInsets.bottom
        tableMaxHeight = max(tableMaxHeight, 0)
        let tableHeight = min(tableMaxHeight, estimateTableHeight())
        self.tableView.snp.updateConstraints {
            $0.height.equalTo(tableHeight)
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

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = Const.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderHeight = Const.sectionHeaderHeight
        tableView.sectionFooterHeight = 0
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.separatorColor = UDColor.lineBorderCard
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(SelectLanguageTableViewCell.self, forCellReuseIdentifier: SelectLanguageTableViewCell.reuseIdentifier)
        return tableView
    }
// MARK: UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        if let curRecentSelectLanguages = recentSelectLanguages, curRecentSelectLanguages.count > 0 {
            return 2
        }
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0, let curRecentSelectLanguages = recentSelectLanguages, curRecentSelectLanguages.count > 0 {
            return curRecentSelectLanguages.count
        }
        return displayLanguages?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rows = self.tableView(tableView, numberOfRowsInSection: indexPath.section)
        let rawCell = tableView.dequeueReusableCell(withIdentifier: SelectLanguageTableViewCell.reuseIdentifier, for: indexPath)
        guard let cell = rawCell as? SelectLanguageTableViewCell else {
            assertionFailure()
            return rawCell
        }
        cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
        cell.updateSeparator(Const.separatorHeight)
        if indexPath.section == 0, let curRecentSelectLanguages = recentSelectLanguages, curRecentSelectLanguages.count > 0 {
            cell.set(title: curRecentSelectLanguages[indexPath.row]["displayLanguage"] ?? "", isSelected: (indexPath.row == 0) && (displayIndex != nil))
            return cell
        }

        guard let displayLanguages = displayLanguages else {
            return cell
        }
        guard let curDisplayIndex = displayIndex else {
            cell.set(title: displayLanguages[indexPath.row], isSelected: false)
            return cell
        }
        cell.set(title: displayLanguages[indexPath.row], isSelected: indexPath.row == curDisplayIndex)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0, let curRecentSelectLanguages = recentSelectLanguages, curRecentSelectLanguages.count > 0 {
            if let curLanguage = curRecentSelectLanguages[indexPath.row]["language"], let curDisplayLanguage = curRecentSelectLanguages[indexPath.row]["displayLanguage"] {
                self.delegate?.didSelectDiffLanguage(language: curLanguage, displayLanguage: curDisplayLanguage)
                self.reportSpaceTranslateClick("recent", language: curLanguage, isVersion: self.isVersion ?? false)
            }
        } else {
            if let curLanguages = languages, let curDisplayLanguages = displayLanguages {
                self.delegate?.didSelectDiffLanguage(language: curLanguages[indexPath.row], displayLanguage: curDisplayLanguages[indexPath.row])
                self.reportSpaceTranslateClick("all", language: curLanguages[indexPath.row], isVersion: self.isVersion ?? false)
            }
        }
        self.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var headerText: String = BundleI18n.SKResource.Doc_Translate_AllLanguage
        if section == 0, let curRecentSelectLanguages = recentSelectLanguages, curRecentSelectLanguages.count > 0 {
            headerText = BundleI18n.SKResource.Doc_Translate_RecentLanguage
        }
        let headerView = UIView()
        let titleLabel = UILabel()
        titleLabel.text = headerText
        titleLabel.textColor = UDColor.textCaption
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.sizeToFit()
        let rawFrame = titleLabel.frame
        titleLabel.frame = CGRect(x: 16, y: 16, width: rawFrame.size.width, height: 16)
        headerView.addSubview(titleLabel)
        return headerView
    }
}

extension SelectLanguageController {
    private func reportSpaceTranslateClick(_ moduleType: String, language: String, isVersion: Bool) {
        let params = ["app_form": "null",
                      "module": "doc",
                      "sub_module": "none",
                      "container_id": "null",
                      "container_type": "null",
                      "sub_file_type": "null",
                      "file_id": "null",
                      "file_type": "null",
                      "click": language,
                      "target": "ccm_docs_page_view",
                      "is_shortcut": "false",
                      "shortcut_id": "null",
                      "module_type": moduleType,
                      "is_version": isVersion ? "true" : "false"]
        DocsTracker.log(enumEvent: .spaceTranslateClick, parameters: params)
    }
}
