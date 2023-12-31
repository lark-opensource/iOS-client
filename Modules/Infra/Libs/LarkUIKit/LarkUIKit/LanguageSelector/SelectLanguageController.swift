//
//  SelectLanguageController.swift
//  LarkUIKit
//
//  Created by Miaoqi Wang on 2020/6/8.
//

import Foundation
import UIKit
import LKCommonsLogging
import LarkLocalizations
import FigmaKit
import RxSwift

public typealias ChangeLanguageHandler = (_ model: LanguageModel, _ from: UIViewController) -> Void

public final class SelectLanguageController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    /// 表格视图cell被点击后多少时间后再执行其他操作，给足时间展示cell被点击的背景色
    private static let tableDidSelectSpaceValue = 0.04

    static var logger = Logger.log(SelectLanguageController.self, category: "LarkUIKit")

    private lazy var tableView: UITableView = self.createTableView()
    private var rightItem: LKBarButtonItem?
    private var dataSource: [LanguageModel] = []
    // 初始进来时候的选中的 Model
    private var initSelectedModel: LanguageModel?

    private let changeLanguageHandler: ChangeLanguageHandler?
    private let resetTitle: String?

    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    public init(title: String? = nil, changeLanguageHandler: ChangeLanguageHandler? = nil) {
        self.resetTitle = title
        self.changeLanguageHandler = changeLanguageHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        if let tt = resetTitle {
            title = tt
        } else {
            title = BundleI18n.LarkUIKit.Lark_Login_LanguageSettingTitle
        }
        view.addSubview(self.tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
        }
        tableView.contentInsetAdjustmentBehavior = .automatic

        setNavigationBarRightItem()
        addCancelItem()
        observeContentSizeForPopoverMode()
        loadData()
        Self.logger.info("in SelectLanguageController: \(Self.languageSettingLogInfo())")
    }

    // MARK: - Adjust popover size

    private let disposeBag = DisposeBag()

    /// Change popover size according to tableview content dynamically.
    /// Reference:
    /// https://developer.apple.com/documentation/uikit/uiviewcontroller/1619323-contentsizeforviewinpopover
    private func observeContentSizeForPopoverMode() {
        guard needObserveUpdatePopoverContentSize() else { return }
        tableView.rx
            .observe(CGSize.self, "contentSize")
            .distinctUntilChanged()
            .compactMap { $0 }
            .debounce(.milliseconds(3), scheduler: MainScheduler.instance)
            .map { contentSize in
                CGSize(width: contentSize.width, height: min(Display.height, contentSize.height))
            }.subscribe(onNext: { [weak self] contentSize in
                self?.preferredContentSize = contentSize
                self?.navigationController?.preferredContentSize = contentSize
            }).disposed(by: disposeBag)
    }

    private func needObserveUpdatePopoverContentSize() -> Bool {
        guard Display.pad, presentingViewController != nil else { return false }

        var isPopOver = modalPresentationStyle == .popover
        if !isPopOver, let navi = self.navigationController, navi.viewControllers.firstIndex(of: self) == 0 {
            // 是 Navi 的root 则看下Navi 是不是 popOver
            isPopOver = navigationController?.modalPresentationStyle == .popover
        }
        return isPopOver
    }

    // MARK: -

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 16)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 8)))
        tableView.estimatedRowHeight = 52
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 8
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellSelf: LanguageTableViewCell.self)
        return tableView
    }

    private func loadData() {
        let isSelectSystem = LanguageManager.isSelectSystem
        let supportLanguages = LanguageManager.supportLanguages

        if let local = LanguageManager.systemLanguage, supportLanguages.contains(local) {
            let model = LanguageModel(
                name: BundleI18n.LarkUIKit.Lark_Legacy_LanguageSystem(local.displayName),
                language: local,
                isSelected: isSelectSystem,
                isSystem: true
            )
            dataSource.append(model)
            if isSelectSystem {
                initSelectedModel = model
            }
        }

        // 非系统语言的起始位置
        let firstIndex = dataSource.count

        for language in supportLanguages {
            let isSelected = LanguageManager.currentLanguage == language && !isSelectSystem
            let model = LanguageModel(
                name: language.displayName,
                language: language,
                isSelected: isSelected
            )

            if isSelected {
                // 将选中语言放在非系统语言的起始位置
                dataSource.insert(model, at: firstIndex)
                initSelectedModel = model
            } else {
                dataSource.append(model)
            }
        }
    }

    private func setNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkUIKit.Lark_Legacy_Completed)
        rightItem.setBtnTitleColor(color: UIColor.ud.primaryContentDefault, state: .normal)
        rightItem.setBtnTitleColor(color: UIColor.ud.textDisabled, state: .disabled)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        rightItem.isEnabled = false
        self.rightItem = rightItem
        self.navigationItem.rightBarButtonItem = rightItem
    }

    @objc
    private func navigationBarRightItemTapped() {
        guard let index = self.dataSource.firstIndex(where: { $0.isSelected }) else {
            return
        }
        let model = dataSource[index]

        Self.logger.info("before switch lan to \(model.language): \(Self.languageSettingLogInfo())")

        trackerClick(
            oldLang: LanguageManager.currentLanguage,
            lang: model.language,
            oldIsSelectSystem: LanguageManager.isSelectSystem,
            isSelectSystem: model.isSystem
        )

        if model.language == LanguageManager.currentLanguage {
            LanguageManager.isSelectSystem = model.isSystem
            Self.logger.info("after switch lan to \(model.language): \(Self.languageSettingLogInfo())")
            close()
        } else {
            if let handler = changeLanguageHandler {
                handler(model, self) // handler里有退出程序的逻辑，所以日志在里边打印
            } else {
                LanguageManager.setCurrent(language: model.language, isSystem: model.isSystem)
                Self.logger.info("after switch lan to \(model.language): \(Self.languageSettingLogInfo())")
                close()
            }
        }
    }

    private static func languageSettingLogInfo() -> String {
        let (sysLang, curLang, isSelectSystem) = LanguageManager.getLanguageSettings()
        return "language setting: sysLanguage: \(sysLang) currentLanguage: \(curLang) isSelectSystem: \(isSelectSystem)"
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LanguageTableViewCell.lu.reuseIdentifier)
            as? LanguageTableViewCell else {
            return UITableViewCell()
        }
        let model = dataSource[indexPath.row]
        cell.set(title: model.name, isSelected: model.isSelected)
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        var selectedModel: LanguageModel?
        dataSource.enumerated().forEach { (index, model) in
            model.isSelected = (index == indexPath.row)
            if model.isSelected {
                selectedModel = model
            }
        }

        self.rightItem?.isEnabled = selectedModel != initSelectedModel
        DispatchQueue.main.asyncAfter(deadline: .now() + SelectLanguageController.tableDidSelectSpaceValue) {
            tableView.reloadData()
        }
    }

    func close() {
        if hasBackPage {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension LKBarButtonItem {
    func setBtnTitleColor(color: UIColor, state: UIControl.State) {
        button.setTitleColor(color, for: state)
    }
}
