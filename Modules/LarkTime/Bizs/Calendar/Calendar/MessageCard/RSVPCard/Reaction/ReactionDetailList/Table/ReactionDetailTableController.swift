//
//  ReactionDetailTableController.swift
//  LarkChat
//
//  Created by kongkaikai on 2018/12/11.
//

import Foundation
import UIKit
import RxSwift
import LarkPageController
import LarkUIKit
import LarkContainer
import LKCommonsLogging

final class ReactionDetailTableController: PageInnerTableViewController {
    private let logger = Logger.log(ReactionDetailTableController.self, category: "calendar.ReactionDetailTableController")

    internal var userResolver: UserResolver?
    
    var viewModel: ReactionDetailTableViewModel?
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.register(
            ReactionDetailTableViewCell.self,
            forCellReuseIdentifier: NSStringFromClass(ReactionDetailTableViewCell.self)
        )
        self.tableView.accessibilityIdentifier = "reation.detail.page.table"
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.chatters.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: NSStringFromClass(ReactionDetailTableViewCell.self),
            for: indexPath
        )

        if let detailCell = cell as? ReactionDetailTableViewCell,
            let chatterInfo = viewModel?.chatter(at: indexPath.row) {
            detailCell.chatterInfo = chatterInfo
        }
        cell.accessibilityIdentifier = "reaction.detail.page.cell.\(indexPath.row)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        guard let chatter = viewModel?.chatter(at: indexPath.row) else { return }
        
        if let calendarDependency = try? userResolver?.resolve(assert: CalendarDependency.self) {
            calendarDependency.jumpToProfile(chatterId: chatter.chatterId,
                                              eventTitle: "",
                                              from: self)
        } else {
            logger.error("jumpToProfile failed caused by userResolver failed")
        }
    }
}
