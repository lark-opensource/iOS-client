//
//  NetworkInfoCell.swift
//  PassportDebug
//
//  Created by ZhaoKejie on 2023/4/4.
//

import Foundation
import SnapKit

class NetworkInfoCell: UITableViewCell {

    var hostLabel = UILabel()

    var pathLabel = UILabel()

    var timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(hostLabel)
        hostLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(6)
        }

        self.contentView.addSubview(pathLabel)
        pathLabel.snp.makeConstraints { make in
            make.top.equalTo(hostLabel.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(6)
        }

        self.contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(6)
            make.left.equalToSuperview().offset(6)
        }
    }

    func setCell(isSucc: Bool, host: String, path: String, time: String) {
        // set view
        self.hostLabel.text = host
        self.hostLabel.font = UIFont.systemFont(ofSize: 10).bold

        self.pathLabel.text = path
        self.pathLabel.font = UIFont.systemFont(ofSize: 10)
        if !isSucc {
            self.pathLabel.textColor = .red
        }

        self.timeLabel.text = time
        self.timeLabel.font = UIFont.systemFont(ofSize: 8).italic
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
