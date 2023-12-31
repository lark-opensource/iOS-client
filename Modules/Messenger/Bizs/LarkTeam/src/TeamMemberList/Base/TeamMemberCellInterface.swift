//
//  TeamMemberCellInterface.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2022/8/3.
//

import Foundation
import UIKit
import LarkListItem

protocol TeamMemberCellInterface: UITableViewCell {
    var isCheckboxHidden: Bool { get set }
    var isCheckboxSelected: Bool { get set }
    var infoView: ListItem { get }
    var item: TeamMemberItem? { get }
    var isTeamOpenChat: Bool { get }
    func set(_ item: TeamMemberItem, filterKey: String?, from: UIViewController, teamId: String)
    func setCellSelect(canSelect: Bool,
                       isSelected: Bool,
                       isCheckboxHidden: Bool)
}
