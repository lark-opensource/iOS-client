//
//  AuthTypeViewController.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/26.
//

import Foundation
import Homeric
import RxSwift
import LKCommonsLogging

class AuthTypeViewController: BaseViewController {
    let vm: AuthTypeViewModel
    static let logger = Logger.log(AuthTypeViewController.self)

    lazy var tableView: UITableView = {
        let tb = UITableView(frame: .zero, style: .grouped)
        tb.lu.register(cellSelf: AuthTypeCell.self)
        tb.backgroundColor = .clear
        tb.separatorStyle = .none
        tb.sectionHeaderHeight = UITableView.automaticDimension
        tb.estimatedSectionHeaderHeight = 0.01
        tb.dataSource = self
        tb.delegate = self
        tb.showsHorizontalScrollIndicator = false
        tb.showsVerticalScrollIndicator = false
        return tb
    }()

    lazy var bodyVStackView: UIStackView = {
        let bodyVStackView = UIStackView()
        bodyVStackView.distribution = .fillEqually
        bodyVStackView.axis = .vertical
        return bodyVStackView
    }()

    init(vm: AuthTypeViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        SuiteLoginTracker.track(Homeric.SWITCH_CHOOSE_VERIFICATION_SHOW, params: [:])

        //删除BaseVC中无关的UIView
        centerInputView.removeFromSuperview()
        switchButtonContainer.removeFromSuperview()
        inputAdjustView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        detailLabel.removeFromSuperview()
        bottomView.removeFromSuperview()
        
        //设置headerView(title&subtitle)
        configTopInfo(vm.title, detail: vm.detailString)
        let headerView = UIView()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        //添加SubView
        bodyVStackView.addSubview(headerView)
        bodyVStackView.addSubview(tableView)
        moveBoddyView.addSubview(bodyVStackView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(detailLabel)

        //重新调整moveBoddyView Layout
        moveBoddyView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        bodyVStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(Layout.headerTitleTop)
            make.left.right.equalToSuperview()
            make.height.equalTo(BaseLayout.titleLabelHeight)
        }
        detailLabel.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleSpace)
            make.bottom.equalToSuperview()
        }
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.marginTopForTableView)
            make.left.right.equalToSuperview().inset(Layout.marginForTableView)
        }
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).offset(Layout.headerToTable)
            make.left.right.equalToSuperview().inset(Layout.marginForTableView)
            make.bottom.equalToSuperview()
        }
    

    }
}

extension AuthTypeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.cellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = tableView.cellForRow(at: indexPath)
        if let cell = c as? AuthTypeCell {
            let cellData = self.vm.dataSource[indexPath.row]
            self.showLoading()
            cellData.action()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {
                    cell.updateSelection(false)
                    self.stopLoading()
                }, onError: {  (err) in
                    cell.updateSelection(false)
                    self.stopLoading()
                    Self.logger.error("enter operation items failed at row: \(indexPath.row + 1)")
                }).disposed(by: self.disposeBag)
        }
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? AuthTypeCell
        cell?.updateSelection(true)
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? AuthTypeCell
        cell?.updateSelection(false)
    }
}

extension AuthTypeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < vm.dataSource.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AuthTypeCell.lu.reuseIdentifier,
                                                           for: indexPath) as? AuthTypeCell else {
                return UITableViewCell()
            }

            cell.data = self.vm.dataSource[indexPath.row]
            return cell
        }
        return UITableViewCell()
    }
}

extension AuthTypeViewController {
    fileprivate struct Layout {
        static let tableHeaderHeight: CGFloat = 130
        static let headerTitleTop: CGFloat = 32
        static let titleSpace:CGFloat = 12
        static let titleHorizonalAdjust: CGFloat = 4
        static let marginForTableView: CGFloat = 16
        static let marginTopForTableView: CGFloat = 80
        static let cellHeight: CGFloat = 102
        static let headerToTable = 20
    }
}

