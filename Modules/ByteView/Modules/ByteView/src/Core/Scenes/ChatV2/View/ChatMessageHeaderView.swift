//
// Created by maozhixiang.lip on 2022/4/20.
// Copyright (c) 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

class ChatMessageHeaderView: UITableViewHeaderFooterView {

    var labelText: String = "" {
        didSet(newLabelText) {
            headerLabel.attributedText = NSAttributedString(string: newLabelText, config: .bodyAssist, alignment: .center)
        }
    }

    private lazy var headerLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.numberOfLines = 3
        headerLabel.textColor = UIColor.ud.textPlaceholder
        return headerLabel
    }()


    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
