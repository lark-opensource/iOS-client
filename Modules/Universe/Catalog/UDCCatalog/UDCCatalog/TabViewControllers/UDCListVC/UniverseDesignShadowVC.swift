//
//  UniverseDesignShadowVC.swift
//  UDCCatalog
//
//  Created by Siegfried on 2021/9/10.
//  Copyright © 2021 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignShadow
import UniverseDesignButton

class UniverseDesignShadowVC: UIViewController {
    // MARK: UIComponents
    private lazy var viewS1 = UIView()
    private lazy var viewS2 = UIView()
    private lazy var viewS3 = UIView()
    private lazy var viewS4 = UIView()
    private lazy var viewS5 = UIView()

    private lazy var downButton = UIButton()
    private lazy var upButton = UIButton()
    private lazy var leftButton = UIButton()
    private lazy var rightButton = UIButton()
    private lazy var downPriButton = UIButton()

    private lazy var s1Label = UILabel()
    private lazy var s2Label = UILabel()
    private lazy var s3Label = UILabel()
    private lazy var s4Label = UILabel()
    private lazy var s5Label = UILabel()

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

    }
    // MARK: func
    private func setup() {
        setupSubViews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubViews() {
        self.view.addSubview(viewS1)
        self.view.addSubview(viewS2)
        self.view.addSubview(viewS3)
        self.view.addSubview(viewS4)
        self.view.addSubview(viewS5)

        self.view.addSubview(downButton)
        self.view.addSubview(upButton)
        self.view.addSubview(leftButton)
        self.view.addSubview(rightButton)
        self.view.addSubview(downPriButton)

        viewS1.addSubview(s1Label)
        viewS2.addSubview(s2Label)
        viewS3.addSubview(s3Label)
        viewS4.addSubview(s4Label)
        viewS5.addSubview(s5Label)

    }

    private func setupConstraints() {
        viewS1.snp.makeConstraints { make in
            make.width.height.equalTo(84)
            make.top.equalToSuperview().offset(100)
            make.centerX.equalToSuperview().offset(40)
        }
        viewS2.snp.makeConstraints { make in
            make.width.height.equalTo(84)
            make.top.equalTo(viewS1.snp.bottom).offset(30)
            make.centerX.equalToSuperview().offset(40)
        }
        viewS3.snp.makeConstraints { make in
            make.width.height.equalTo(84)
            make.top.equalTo(viewS2.snp.bottom).offset(30)
            make.centerX.equalToSuperview().offset(40)
        }
        viewS4.snp.makeConstraints { make in
            make.width.height.equalTo(84)
            make.top.equalTo(viewS3.snp.bottom).offset(30)
            make.centerX.equalToSuperview().offset(40)
        }
        viewS5.snp.makeConstraints { make in
            make.width.height.equalTo(84)
            make.top.equalTo(viewS4.snp.bottom).offset(30)
            make.centerX.equalToSuperview().offset(40)
        }

        downButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(100)
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(80)
        }

        upButton.snp.makeConstraints { make in
            make.top.equalTo(downButton.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(80)
        }

        leftButton.snp.makeConstraints { make in
            make.top.equalTo(upButton.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(80)
        }

        rightButton.snp.makeConstraints { make in
            make.top.equalTo(leftButton.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(80)
        }

        downPriButton.snp.makeConstraints { make in
            make.top.equalTo(rightButton.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(15)
            make.width.equalTo(80)
        }

        s1Label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        s2Label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        s3Label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        s4Label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        s5Label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBase
        viewS1.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS2.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS3.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS4.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS5.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        viewS1.layer.cornerRadius = 8
        viewS2.layer.cornerRadius = 8
        viewS3.layer.cornerRadius = 8
        viewS4.layer.cornerRadius = 8
        viewS5.layer.cornerRadius = 8

        viewS1.layer.ud.setShadow(type: .s1Down)
        viewS2.layer.ud.setShadow(type: .s2Down)
        viewS3.layer.ud.setShadow(type: .s3Down)
        viewS4.layer.ud.setShadow(type: .s4Down)
        viewS5.layer.ud.setShadow(type: .s5Down)

        downButton.setTitle("Down", for: .normal)
        upButton.setTitle("Up", for: .normal)
        leftButton.setTitle("Left", for: .normal)
        rightButton.setTitle("Right", for: .normal)
        downPriButton.setTitle("DownPri", for: .normal)

        downButton.backgroundColor = UIColor.ud.primaryContentLoading
        upButton.backgroundColor = UIColor.ud.primaryContentDefault
        leftButton.backgroundColor = UIColor.ud.primaryContentDefault
        rightButton.backgroundColor = UIColor.ud.primaryContentDefault
        downPriButton.backgroundColor = UIColor.ud.primaryContentDefault

        downButton.layer.cornerRadius = 4
        upButton.layer.cornerRadius = 4
        leftButton.layer.cornerRadius = 4
        rightButton.layer.cornerRadius = 4
        downPriButton.layer.cornerRadius = 4

        downButton.addTarget(self, action: #selector(clickDown), for: .touchUpInside)
        upButton.addTarget(self, action: #selector(clickUp), for: .touchUpInside)
        leftButton.addTarget(self, action: #selector(clickLeft), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(clickRight), for: .touchUpInside)
        downPriButton.addTarget(self, action: #selector(clickDownPri), for: .touchUpInside)

        s1Label.text = "S1"
        s2Label.text = "S2"
        s3Label.text = "S3"
        s4Label.text = "S4"
        s5Label.text = "S5"

        s1Label.textColor = UIColor.ud.staticBlack
        s2Label.textColor = UIColor.ud.staticBlack
        s3Label.textColor = UIColor.ud.staticBlack
        s4Label.textColor = UIColor.ud.staticBlack
        s5Label.textColor = UIColor.ud.staticBlack
    }

    @objc
    private func clickDown() {
        viewS1.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS2.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS3.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS4.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS5.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        viewS1.layer.ud.setShadow(type: .s1Down)
        viewS2.layer.ud.setShadow(type: .s2Down)
        viewS3.layer.ud.setShadow(type: .s3Down)
        viewS4.layer.ud.setShadow(type: .s4Down)
        viewS5.layer.ud.setShadow(type: .s5Down)

        downButton.backgroundColor = UIColor.ud.primaryContentLoading
        upButton.backgroundColor = UIColor.ud.primaryContentDefault
        leftButton.backgroundColor = UIColor.ud.primaryContentDefault
        rightButton.backgroundColor = UIColor.ud.primaryContentDefault
        downPriButton.backgroundColor = UIColor.ud.primaryContentDefault
    }

    @objc
    private func clickUp() {
        viewS1.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS2.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS3.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS4.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS5.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        viewS1.layer.ud.setShadow(type: .s1Up)
        viewS2.layer.ud.setShadow(type: .s2Up)
        viewS3.layer.ud.setShadow(type: .s3Up)
        viewS4.layer.ud.setShadow(type: .s4Up)
        viewS5.layer.ud.setShadow(type: .s5Up)

        downButton.backgroundColor = UIColor.ud.primaryContentDefault
        upButton.backgroundColor = UIColor.ud.primaryContentLoading
        leftButton.backgroundColor = UIColor.ud.primaryContentDefault
        rightButton.backgroundColor = UIColor.ud.primaryContentDefault
        downPriButton.backgroundColor = UIColor.ud.primaryContentDefault
    }

    @objc
    private func clickLeft() {
        viewS1.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS2.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS3.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS4.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS5.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        viewS1.layer.ud.setShadow(type: .s1Left)
        viewS2.layer.ud.setShadow(type: .s2Left)
        viewS3.layer.ud.setShadow(type: .s3Left)
        viewS4.layer.ud.setShadow(type: .s4Left)
        viewS5.layer.ud.setShadow(type: .s5Left)

        downButton.backgroundColor = UIColor.ud.primaryContentDefault
        upButton.backgroundColor = UIColor.ud.primaryContentDefault
        leftButton.backgroundColor = UIColor.ud.primaryContentLoading
        rightButton.backgroundColor = UIColor.ud.primaryContentDefault
        downPriButton.backgroundColor = UIColor.ud.primaryContentDefault
    }

    @objc
    private func clickRight() {
        viewS1.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS2.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS3.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS4.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        viewS5.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        viewS1.layer.ud.setShadow(type: .s1Right)
        viewS2.layer.ud.setShadow(type: .s2Right)
        viewS3.layer.ud.setShadow(type: .s3Right)
        viewS4.layer.ud.setShadow(type: .s4Right)
        viewS5.layer.ud.setShadow(type: .s5Right)

        downButton.backgroundColor = UIColor.ud.primaryContentDefault
        upButton.backgroundColor = UIColor.ud.primaryContentDefault
        leftButton.backgroundColor = UIColor.ud.primaryContentDefault
        rightButton.backgroundColor = UIColor.ud.primaryContentLoading
        downPriButton.backgroundColor = UIColor.ud.primaryContentDefault
    }

    @objc
    private func clickDownPri() {
        viewS1.backgroundColor = UIColor.ud.primaryContentDefault
        viewS2.backgroundColor = UIColor.ud.primaryContentDefault
        viewS3.backgroundColor = UIColor.ud.primaryContentDefault
        viewS4.backgroundColor = UIColor.ud.primaryContentDefault
        viewS5.backgroundColor = UIColor.ud.primaryContentDefault

        viewS1.layer.ud.setShadow(type: .s1DownPri)
        viewS2.layer.ud.setShadow(type: .s2DownPri)
        viewS3.layer.ud.setShadow(type: .s3DownPri)
        viewS4.layer.ud.setShadow(type: .s4DownPri)
        viewS5.layer.ud.setShadow(type: .s5DownPri)

        downButton.backgroundColor = UIColor.ud.primaryContentDefault
        upButton.backgroundColor = UIColor.ud.primaryContentDefault
        leftButton.backgroundColor = UIColor.ud.primaryContentDefault
        rightButton.backgroundColor = UIColor.ud.primaryContentDefault
        downPriButton.backgroundColor = UIColor.ud.primaryContentLoading
    }

}
