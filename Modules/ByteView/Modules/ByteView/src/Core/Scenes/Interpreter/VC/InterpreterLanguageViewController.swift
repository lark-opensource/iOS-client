//
//  InterpreterLanguageViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Action
import RxSwift
import RxCocoa
import SnapKit
import ByteViewUI
import RxDataSources
import ByteViewCommon
import CoreGraphics

class InterpreterLanguageViewController: VMViewController<InterpreterLanguageViewModel>, UITableViewDelegate, UIGestureRecognizerDelegate {

    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_CancelButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.addTarget(self, action: #selector(doBack), for: .touchUpInside)
        return button
    }()

    lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy var searchView: SearchBarView = {
        let searchView = SearchBarView(frame: CGRect.zero, isNeedCancel: true)
        searchView.iconImageDimension = 16
        searchView.clipsToBounds = true
        searchView.setPlaceholder(I18n.View_G_ChangesShare)
        searchView.textField.accessibilityIdentifier =
            "InterpreterLanguageViewController.searchView.accessibilityIdentifier"
        searchView.textField.accessibilityLabel =
            "InterpreterLanguageViewController.searchView.accessibilityLabel"
        searchView.textField.isAccessibilityElement = true
        searchView.cancelButton.accessibilityIdentifier =
            "InterpreterLanguageViewController.cancelButton.accessibilityIdentifier"
        searchView.cancelButton.isAccessibilityElement = true
        return searchView
    }()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.showsVerticalScrollIndicator = true
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 48
        tableView.sectionHeaderHeight = 40
        tableView.sectionFooterHeight = 12
        let footerView = UIView()
        footerView.backgroundColor = .clear
        footerView.frame = CGRect(x: 0, y: 0, width: 100, height: 16)
        tableView.tableFooterView = footerView
        tableView.isAccessibilityElement = true
        tableView.accessibilityLabel =
            "InterpreterLanguageViewController.inMeetingTableView.accessibilityLabel"
        tableView.accessibilityIdentifier =
            "InterpreterLanguageViewController.inMeetingTableView.accessibilityIdentifier"
        tableView.register(
            InterpreterLanguageCell.self,
            forCellReuseIdentifier: String(describing: InterpreterLanguageCell.self)
        )
        return tableView
    }()

    lazy var dataSource: RxTableViewSectionedReloadDataSource<InterpreterLanguagInfoSectionModel> = {
        let dataSource = RxTableViewSectionedReloadDataSource<InterpreterLanguagInfoSectionModel>(
            configureCell: { [weak self] (_, tableView, indexPath, item) -> UITableViewCell in
            guard let self = self else { return UITableViewCell() }
                let identifier = String(describing: InterpreterLanguageCell.self)
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: identifier,
                    for: indexPath
                    ) as? InterpreterLanguageCell
                cell?.config(with: item)
                return cell ?? UITableViewCell()
        })
        return dataSource
    }()

    var titleLabelMarginTop: CGFloat {
        if Display.pad || currentLayoutContext.layoutType.isCompact {
            return (20 - Layout.topGap)
        } else {
            return (12 - Layout.topGap)
        }
    }

    override func setupViews() {
        edgesForExtendedLayout = .bottom
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        title = I18n.View_G_SelectLanguage
        layoutTopArea()
    }

    override func bindViewModel() {
        setupTableView()
        bindSearchView()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    func layoutTopArea() {
        view.addSubview(line)
        view.addSubview(searchView)
        view.addSubview(tableView)

        line.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            maker.height.equalTo(Layout.lineHeight)
            maker.left.right.equalToSuperview()
        }

        searchView.setContentCompressionResistancePriority(
            UILayoutPriority.required,
            for: NSLayoutConstraint.Axis.vertical
        )
        searchView.snp.makeConstraints { (make) in
            make.top.equalTo(self.line).offset(Layout.searchViewMarginLine)
            make.height.equalTo(Layout.searchViewHeight)
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(Layout.marginLeft)
            make.right.equalTo(self.view.safeAreaLayoutGuide).offset(-Layout.marginRight)
        }
        tableView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(searchView.snp.bottom).offset(Layout.tableViewMarginSearchView)
            make.width.equalTo(view)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
        tableView.sectionFooterHeight = Layout.tableViewMarginSearchView
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged {
            self.line.snp.updateConstraints { (maker) in
                maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            }
            self.searchView.snp.remakeConstraints { (maker) in
                maker.top.equalTo(self.line).offset(Layout.searchViewMarginLine)
                maker.height.equalTo(Layout.searchViewHeight)
                maker.left.equalTo(self.view.safeAreaLayoutGuide).offset(Layout.marginLeft)
                maker.right.equalTo(self.view.safeAreaLayoutGuide).offset(-Layout.marginRight)
            }
            self.tableView.snp.updateConstraints { (maker) in
                maker.top.equalTo(self.searchView.snp.bottom).offset(Layout.tableViewMarginSearchView)
            }
            self.tableView.sectionFooterHeight = Layout.tableViewMarginSearchView
        }
    }

    func bindSearchView() {
        let searchObserver = viewModel.searchObserver
        searchView.resultTextObservable
            .bind(to: searchObserver)
            .disposed(by: rx.disposeBag)
    }

    func setupTableView() {
        self.tableView.rx.contentOffset
            .map({ [weak self] (offset) -> Bool in
                return offset.y <= self?.tableView.contentInset.top ?? 0
            })
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] forbidden in
                self?.tableView.bounces = !forbidden
            })
            .disposed(by: rx.disposeBag)

        setupCellConfiguration()
        setupCellTapHandling()
    }

    func setupCellConfiguration() {
        tableView.rx
            .setDelegate(self)
            .disposed(by: rx.disposeBag)

        viewModel.languageDataSource
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
    }

    func setupCellTapHandling() {
        Observable.zip(
                tableView.rx.modelSelected(InterpreterLanguageInfo.self),
                tableView.rx.itemSelected
            )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] language, _ in
                self?.viewModel.selectionBlock(language.languageType)
                self?.doBack()
            })
            .disposed(by: rx.disposeBag)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section < tableView.numberOfSections - 1 {
            return Layout.tableViewMarginSearchView
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        return footerView
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.tableView.bounds.contains(gestureRecognizer.location(in: self.tableView)) {
            return self.tableView.contentOffset.y <= 1.0 + self.tableView.contentInset.top
        } else {
            return true
        }
    }
}

extension InterpreterLanguageViewController {

    enum Layout {

        static var topGap: CGFloat = 12.0

        static let regularTopGap: CGFloat = 12.0

        static let sheetTop: CGFloat = 18.0

        static var titleLabelHeight: CGFloat {
            return 24
        }

        static var lineHeight: CGFloat {
            return 1
        }

        static var searchViewHeight: CGFloat {
            return 36.0
        }

        static var searchViewMarginLine: CGFloat = 8

        static var tableViewMarginSearchView: CGFloat = 8

        static var marginRight: CGFloat = 16

        static var marginLeft: CGFloat = 16
    }
}
