//
//  LocationSelectorView.swift
//  Calendar
//
//  Created by tuwenbo on 2022/11/27.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon

struct EventLocationCellData {
    var parsedLocation: Rust.ParsedEventLocationItem
    var onClick: ((_ location: Rust.ParsedEventLocationItem) -> Void)?
}

final class LocationSelectorView: UIView {
    private let cellIdentifier = "location_picker_cell"
    private lazy var tableView = UITableView(frame: .zero, style: .plain)

    private lazy var locations = [EventLocationCellData]()

    init(locations: [EventLocationCellData]) {
        super.init(frame: .zero)
        self.locations = locations
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.register(LocationItemCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
    }

    // 此方法用于提前计算 tableview 的高度，完全根据设计稿来，权宜之计. not elegant
    func estimateHeight() -> Int {
        var height = 0
        for location in locations {
            let textWidth = location.parsedLocation.locationContent.size(withAttributes: [.font: UIFont.ud.body2(.fixed)]).width
            // 48 是一行 text 时的长度，text 最多是两行，两行的话就要多加 22
            height += (48 + (textWidth > 246 ? 22 : 0))
        }
        return max(height, 48)
    }
}

extension LocationSelectorView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        locations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LocationItemCell,
              let location = locations[safeIndex: indexPath.row] else {
            return UITableViewCell()
        }
        cell.backgroundColor = UIColor.ud.bgFloat
        cell.updateContent(location: location)
        cell.needSeparator = indexPath.item < (locations.count - 1)
        return cell
    }
}

extension LocationSelectorView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = locations[indexPath.row]
        location.onClick?(location.parsedLocation)
    }
}

private final class LocationItemCell: UITableViewCell {

    private lazy var locationView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0(.fixed)
        label.numberOfLines = 2
        return label
    }()

    private lazy var rightImageView: UIImageView = {
        let image = UDIcon.getIconByKey(.rightOutlined, size: EventBasicCellLikeView.Style.iconSize).renderColor(with: .n3)
        let imageView = UIImageView(image: image)
        return imageView
    }()

    private lazy var separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return line
    }()

    var needSeparator = true {
        didSet {
            separatorLine.isHidden = !needSeparator
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupContentView()
    }

    private func setupContentView() {
        contentView.addSubview(locationView)
        locationView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.right.equalToSuperview().inset(72)
            make.height.greaterThanOrEqualTo(22)
            make.top.bottom.equalToSuperview().inset(13)
        }

        contentView.addSubview(rightImageView)
        rightImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(12)
        }

        contentView.addSubview(separatorLine)
        separatorLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func updateContent(location: EventLocationCellData) {
        locationView.text = location.parsedLocation.locationContent
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
