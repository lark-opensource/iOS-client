//
//  LarkNaviBar.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit
import SnapKit

// swiftlint:disable all
class NaviBar: UIView {
    
    lazy var avatarView: UIImageView = UIImageView(image: UIImage(named: "Image"))
    lazy var titleLabel: UILabel = UILabel()
    lazy var buttonContainer: UIStackView = UIStackView()
    lazy var meetBtn = UIButton()
    var meetingWindow: MeetingWindow?
    
    init() {
        super.init(frame: .zero)
        addSubViews()
        makeConstraints()
        setAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubViews() {
        buttonContainer.addArrangedSubview(meetBtn)
        addSubview(avatarView)
        addSubview(titleLabel)
        addSubview(buttonContainer)
    }
    func makeConstraints() {
        
        meetBtn.snp.makeConstraints { make in
            make.width.equalTo(60)
            make.height.equalTo(45)
        }

        avatarView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(56)
            make.left.equalToSuperview().offset(16)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(34)
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.right.lessThanOrEqualTo(buttonContainer.snp.left).offset(-20)
        }

        buttonContainer.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-6)
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(25).priority(.high)
        }

        self.snp.makeConstraints { (make) in
            make.height.equalTo(76)
        }
        
    }
    func setAppearance() {
        self.backgroundColor = .red
        
        titleLabel.text = "消息"
        titleLabel.font = UIFont.systemFont(ofSize: 30)
        titleLabel.textColor = UIColor.black
        
        meetBtn.setTitle("Meet", for: .normal)
        meetBtn.backgroundColor = .red
        meetBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        meetBtn.addTarget(self, action: #selector(clickMeeting), for: .touchUpInside)
        
        buttonContainer.axis = .horizontal
        buttonContainer.alignment = .center
        buttonContainer.distribution = .fill
        buttonContainer.spacing = 20
        buttonContainer.layoutMargins = UIEdgeInsets(top: 10,
                                                     left: 10,
                                                     bottom: 10,
                                                     right: 10)
        buttonContainer.isLayoutMarginsRelativeArrangement = true
    }
    
    @objc
    func clickMeeting() {
        meetingWindow = MeetingWindow(frame: UIScreen.main.bounds, dismissWindowBlock: { [weak self] in
            self?.meetingWindow = nil
        })
        meetingWindow?.makeKeyAndVisible()
    }
}

