//
//  EmailInviteContainer.swift
//  LarkContact
//
//  Created by SlientCat on 2019/6/6.
//

import Foundation
import SnapKit
import UIKit

final class EmailInviteContainer: BaseInviteMemberContainer {
    override var fieldListType: FieldListType {
        return .email
    }
}
