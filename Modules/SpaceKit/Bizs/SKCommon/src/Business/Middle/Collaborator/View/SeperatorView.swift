//
//  OrganizationSelectionPanel.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/23.
//

import UIKit
import SnapKit
import SKResource

class SeperatorView: UIView {

    /// 分割View
    private lazy var topSeprateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()
    private lazy var bottomSeprateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = UIColor.ud.N100
        addSubview(topSeprateLine)
        topSeprateLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.3)
            make.top.equalToSuperview()
        }
        addSubview(bottomSeprateLine)
        bottomSeprateLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.3)
            make.bottom.equalToSuperview()
        }
    }

    func updateTopSeprateLine(isHidden: Bool) {
        topSeprateLine.isHidden = isHidden
    }

    func updateBottomSeprateLine(isHidden: Bool) {
        bottomSeprateLine.isHidden = isHidden
    }
}
