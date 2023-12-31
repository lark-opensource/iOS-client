//
//  SegmentTableViewController.swift
//  LarkUIKitDemo
//
//  Created by Crazy凡 on 2019/1/22.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

class TCell: UITableViewCell {
    let segment: StandardSegment
    let segmentView: SegmentView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        segment = StandardSegment()
        segment.lineStyle = .adjust
        segmentView = SegmentView(segment: segment)
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let view = segmentView
        contentView.addSubview(view)
        view.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(80)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SegmentTableViewController: UITableViewController {
    private lazy var titles: [[(String, UIView)]] = (2...6)
        .map { Array(0..<$0).map { _ in item() } }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.lu.register(cellSelf: TCell.self)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return titles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TCell.lu.reuseIdentifier, for: indexPath)

        if let cell_ = cell as? TCell, indexPath.row < titles.count {
            cell_.segmentView.set(views: titles[indexPath.row])
        }

        return cell
    }

    private func item() -> (String, UIView) {
        let view = UIView()
        view.backgroundColor = UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
        let title: [Character] = (0..<Int.random(in: 0...12))
            .compactMap { _ in "1234567890QWERTYUIOPASDFGHJKLZXCVBNM".randomElement() }
        return (String(title), view)
    }
}
