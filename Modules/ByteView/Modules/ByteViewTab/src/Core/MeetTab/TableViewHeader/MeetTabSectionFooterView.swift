//
//  MeetTabSectionFooterView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

class MeetTabSectionFooterView: UITableViewHeaderFooterView, MeetTabSectionConfigurable {

    lazy var paddingView: UIView = {
        let paddingView = UIView()
        paddingView.backgroundColor = .ud.bgBody
        return paddingView
    }()

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.vcTokenMeetingDivider
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear

        contentView.addSubview(paddingView)
        paddingView.addSubview(lineView)

        paddingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        lineView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindTo(viewModel: MeetTabSectionViewModel) {
        if traitCollection.isCompact {
            lineView.isHidden = !viewModel.showSeparator
        }
    }
}
