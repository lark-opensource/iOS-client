//
//  InterpreterManageViewController.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/10/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxDataSources
import Action
import RxSwift
import ByteViewUI
import ByteViewCommon

class InterpreterManageViewController: VMViewController<InterpreterManageViewModel> {

    private let cellIdentifier: String = "InterpreterChannelCell"

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: .zero)
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.bounces = false
        tableView.register(InterpreterManageCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.showsVerticalScrollIndicator = true
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    lazy var bottomView: InterpreterManageBottomView = {
        return InterpreterManageBottomView()
    }()

    lazy var tableViewHeaderView: InterpreterManageHeaderView = {
        return InterpreterManageHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width,
                                                         height: InterpreterManageHeaderView.Layout.topGap
                                                         + InterpreterManageHeaderView.Layout.buttonHeight
                                                         + InterpreterManageHeaderView.Layout.bottomGap))
    }()

    lazy var dataSource: RxTableViewSectionedReloadDataSource<InterpreterSectionModel> = {
        let dataSource = RxTableViewSectionedReloadDataSource<InterpreterSectionModel>(
            configureCell: { [weak self] (_, tableView, indexPath, item) -> UITableViewCell in
                guard let self = self else { return UITableViewCell() }
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: self.cellIdentifier,
                    for: indexPath
                )
                if let cellView = cell as? InterpreterManageCell {
                    cellView.config(with: item, httpClient: self.viewModel.httpClient)
                    cellView.closeButton.rx.action = CocoaAction { [weak self] _ in
                        self?.viewModel.removeInterpreter(info: item)
                        return .empty()
                    }

                    cellView.interpreterView.rx.action = CocoaAction { [weak self] _ in
                        self?.viewModel.selectInterpreter(info: item)
                        return .empty()
                    }

                    cellView.firstLanguageView.rx.action = CocoaAction { [weak self, weak cellView] _ in
                        guard let self = self, let cellView = cellView else { return .empty() }
                        self.viewModel.selectLanguage(info: item, isFirstLang: true)
                        return .empty()
                    }

                    cellView.secondLanguageView.rx.action = CocoaAction { [weak self, weak cellView] _ in
                        guard let self = self, let cellView = cellView else { return .empty() }
                        self.viewModel.selectLanguage(info: item, isFirstLang: false)
                        return .empty()
                    }
                }
                return cell
        })
        return dataSource
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBase
        setNavigationBarBgColor(UIColor.ud.bgBase)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = I18n.View_G_Interpretation
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        InterpreterTrackV2.trackEnterInterpereterPage()
    }

    override func setupViews() {
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.bottom.equalTo(bottomView.snp.top)
            maker.left.equalTo(view.safeAreaLayoutGuide)
            maker.right.equalToSuperview()
        }

        tableView.tableHeaderView = tableViewHeaderView
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func bindViewModel() {
        viewModel.hostVC = self
        bottomView.style = viewModel.isMeetingOpenInterpretation ? .manage : .start
        bottomView.resetLayout(isRegular: traitCollection.horizontalSizeClass == .regular)

        viewModel.allInterpreters
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)

        tableViewHeaderView.addButton.rx.action = viewModel.addInterpreterAction
        bottomView.startButton.rx.action = viewModel.startInterpretationAction
        bottomView.stopButton.rx.action = viewModel.stopInterpretationAction
        bottomView.saveButton.rx.action = viewModel.saveChangesAction

        viewModel.startButtonEnabled
            .drive(bottomView.startButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)

        viewModel.saveButtonEnabled
            .drive(bottomView.saveButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged || oldContext.layoutType != newContext.layoutType {
            self.bottomView.resetLayout(isRegular: newContext.layoutType.isRegular)
        }
    }

    private func getNavHeight() -> CGFloat {
        return UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.intrinsicContentSize.height ?? 0)
    }
}
