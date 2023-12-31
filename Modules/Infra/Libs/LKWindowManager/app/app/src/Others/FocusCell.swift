//
//  FocusCell.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit

// swiftlint:disable all
class FocusCell: UITableViewCell {
    public var roundedView: UIView = UIView()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubViews()
        makeConstraints()
        setAppearance()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubViews() {
        self.contentView.addSubview(roundedView)
    }
    func makeConstraints() {
        roundedView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().offset(-2)
        }
        
    }
    func setAppearance() {
        backgroundColor = .clear
        layer.masksToBounds = true
        layer.cornerRadius = 10
        selectionStyle = .none
        
        roundedView.backgroundColor = .white
        roundedView.layer.cornerRadius = 10
    }
}
