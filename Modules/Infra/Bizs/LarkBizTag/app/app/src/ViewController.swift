//
//  ViewController.swift
//  LarkBizTagDev
//
//  Created by 白镜吾 on 2022/11/22.
//

import Foundation
import UIKit
import SnapKit
import LarkBizTag
import UniverseDesignIcon

class ViewController: UIViewController {

    /// B2B 关联企业标签
    var tagItem1 = TagDataItem(text: "华住",
                               tagType: .relation,
                               priority: 0)

    /// 群主
    var tagItem2 = TagDataItem(tagType: .groupOwner,
                               priority: 3)

    lazy var builder = ChatTagViewBuilder().addTagItems(with: [.officialOncall, .homeSchool])

    lazy var tagView = builder.build()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        self.view.addSubview(tagView)
        tagView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        builder.isOfficial(false).isRobot(false).isSuperChat(true).refresh()
    }
}
