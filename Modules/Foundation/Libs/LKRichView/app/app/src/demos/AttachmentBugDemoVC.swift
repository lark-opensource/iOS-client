//
//  AttachmentBugDemoVC.swift
//  LKRichViewDev
//
//  Created by 李勇 on 2023/9/26.
//

import Foundation
import UIKit
import LKRichView

class CustomTableViewCell: UITableViewCell {
    private var richView: LKRichView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let richView = LKRichView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
        self.contentView.addSubview(richView)
        self.richView = richView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupRichView(richElement: LKRichElement) {
        self.richView?.documentElement = richElement
    }
}

class AttachmentBugDemoVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private lazy var richElement: LKRichElement = {
        return LKAttachmentElement(attachment: LKAsyncRichAttachmentImp(size: CGSize(width: 50, height: 50)) {
            let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
            view.backgroundColor = UIColor.blue
            return view
        })
    }()
    private var tableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let tableView = UITableView(frame: CGRect(origin: CGPoint(x: 0, y: 200), size: CGSize(width: self.view.bounds.size.width, height: 200)))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.borderColor = UIColor.red.cgColor
        tableView.layer.borderWidth = 1
        self.view.addSubview(tableView)
        self.tableView = tableView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as? CustomTableViewCell ?? CustomTableViewCell(style: .default, reuseIdentifier: "CustomTableViewCell")
        tableViewCell.setupRichView(richElement: self.richElement)
        return tableViewCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.tableView?.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
}
