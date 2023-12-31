//
//  CollaborationSearchResultViewController.swift
//  LarkContact
//
//  Created by Nix Wang on 2022/11/23.
//

import Foundation
import UIKit
import RxSwift
import LKCommonsLogging
import UniverseDesignToast
import LarkCore
import LarkUIKit
import RustPB
import LarkLocalizations

protocol CollaborationSearchResultDelegate: AnyObject {
    func searchResult(_ searchResult: CollaborationSearchResultViewController, didSelect tenant: Contact_V1_CollaborationTenant)
}

final class CollaborationSearchResultViewController: UIViewController, ContactSearchable {

    static let logger = Logger.log(CollaborationSearchResultViewController.self, category: "Module.IM.Message")
    static let defaultPagecount = 30
    static let cellHeight = 68.0

    weak var delegate: CollaborationSearchResultDelegate?

    private lazy var resultView: SearchResultView = {
        return SearchResultView()
    }()
    private let vm: CollaborationSearchResultViewModel
    private let disposeBag = DisposeBag()

    init(vm: CollaborationSearchResultViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = BundleI18n.LarkContact.Lark_B2B_Tab_SearchResults
        view.backgroundColor = UIColor.ud.N00

        // NOTE: must set delegate before reloadData, else the result top have 35 pixel padding..
        resultView.tableview.delegate = self
        resultView.tableview.dataSource = self
        resultView.tableview.lu.register(cellSelf: DepartmentTableViewCell.self)
        resultView.tableview.separatorStyle = .none
        resultView.tableview.addBottomLoadMoreView { [weak self] in
            Self.logger.info("n_action_collaboration_search_load_more")
            self?.vm.loadMore()
        }
        self.view.addSubview(resultView)
        resultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        vm.state
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }

                Self.logger.info("n_action_collaboration_search_state: \(state)")

                self.resultView.isHidden = false
                switch state {
                case .idle:
                    self.resultView.isHidden = true
                case .loading:
                    self.resultView.status = .loading
                case .loadingMore:
                    break
                case .noResults(let query):
                    self.resultView.status = .noResult(query)
                case .success(let model):
                    self.resultView.tableview.endBottomLoadMore(hasMore: model.hasMore)
                    self.resultView.tableview.enableBottomLoadMore(model.hasMore)
                    self.resultView.status = .result
                case .failure(let error):
                    self.resultView.status = .failed(error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)

        vm.result
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.resultView.tableview.reloadData()
            })
            .disposed(by: disposeBag)
    }

    var isPublic: Bool = false

    func reloadData() {
        Self.logger.info("n_action_collaboration_search_reload_data")
        resultView.tableview.reloadData()
    }

    func search(text: String) {
        Self.logger.info("n_action_collaboration_search_text")
        vm.query.accept(text)
    }
}

extension CollaborationSearchResultViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        resultView.tableview.deselectRow(at: indexPath, animated: true)
        let item = vm.result.value.tenants[indexPath.row]
        Self.logger.info("n_action_collaboration_search_select: \(item.tenantID)")
        delegate?.searchResult(self, didSelect: item)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.result.value.tenants.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let identifier = String(describing: DepartmentTableViewCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? DepartmentTableViewCell else {
            return UITableViewCell()
        }
        let item = vm.result.value.tenants[row]
        cell.set(departmentName: item.tenantName, userCount: item.tenantUserCount, isShowMemberCount: false)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Self.cellHeight
    }
}
