//
//  StatusMockerService.swift
//  LarkListItemDemo
//
//  Created by Yuri on 2023/10/9.
//

import UIKit
import SnapKit
import RustPB
import LarkListItem
class StatusMockerService: ItemStatusServiceType {
    func generateStatusView(status: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?) -> UIView? {
        guard status != nil else { return nil }
        let view = UIView()
        view.backgroundColor = .red
        view.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }
        return view
    }


}
