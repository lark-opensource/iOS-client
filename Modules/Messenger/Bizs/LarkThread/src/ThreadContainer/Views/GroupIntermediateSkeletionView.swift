//
//  GroupIntermediateSkeletionView.swift
//  LarkThread
//
//  Created by lizhiqiang on 2020/3/24.
//

import UIKit
import Foundation
import LarkUIKit
import SkeletonView

private final class HeaderView: UIView {
    var backButtonClickedBlock: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.ud.N00

        let backgroundView = GradientView()
        backgroundView.direction = .vertical
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.locations = [0.0, 1.0]
        backgroundView.colors = [UIColor.ud.N400.withAlphaComponent(0.7), UIColor.ud.N400.withAlphaComponent(1)]
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo((Display.iPhoneXSeries ? 44 : 20) + 159)
            make.bottom.equalTo(-10)
        }

        let segementView = UIView()
        segementView.layer.cornerRadius = 8
        segementView.clipsToBounds = true
        segementView.backgroundColor = UIColor.ud.N00
        addSubview(segementView)
        segementView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        let segementLeftButton = UIView()
        segementLeftButton.layer.cornerRadius = 2
        segementLeftButton.clipsToBounds = true
        segementLeftButton.backgroundColor = UIColor.ud.N200
        segementView.addSubview(segementLeftButton)
        segementLeftButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(16)
            make.width.equalTo(32.5)
            make.height.equalTo(16)
        }

        let segementRightButton = UIView()
        segementRightButton.layer.cornerRadius = 2
        segementRightButton.clipsToBounds = true
        segementRightButton.backgroundColor = UIColor.ud.N200
        segementView.addSubview(segementRightButton)
        segementRightButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(segementLeftButton)
            make.leading.equalTo(segementLeftButton.snp.trailing).offset(32)
            make.width.equalTo(32.5)
            make.height.equalTo(16)
        }

        let rightButton = UIView()
        rightButton.backgroundColor = UIColor.ud.N200
        rightButton.layer.cornerRadius = 12
        rightButton.clipsToBounds = true
        addSubview(rightButton)
        rightButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(13)
            make.trailing.equalTo(-12)
            make.width.height.equalTo(24)
        }

        let backButton = UIButton(type: .custom)
        backButton.setImage(LarkUIKit.Resources.navigation_back_light
           .lu.colorize(color: UIColor.ud.N00), for: .normal)
        backButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
           make.centerY.equalTo(rightButton)
           make.leading.equalTo(16)
        }

        let avatar = UIView()
        avatar.backgroundColor = UIColor.ud.N200
        let width: CGFloat = 50
        avatar.layer.cornerRadius = width / 2.0
        avatar.clipsToBounds = true
        addSubview(avatar)
        avatar.snp.makeConstraints { (make) in
            make.bottom.equalTo(segementView.snp.top).offset(-15)
            make.leading.equalTo(backButton)
            make.width.height.equalTo(width)
        }

        let titleLabel = UIView()
        titleLabel.layer.cornerRadius = 2
        titleLabel.clipsToBounds = true
        titleLabel.backgroundColor = UIColor.ud.N200
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatar).offset(4.5)
            make.leading.equalTo(avatar.snp.trailing).offset(11)
            make.height.equalTo(16)
            make.width.equalTo(110.5)
        }

        let desLabel = UIView()
        desLabel.layer.cornerRadius = 2
        desLabel.clipsToBounds = true
        desLabel.backgroundColor = UIColor.ud.N200
        addSubview(desLabel)
        desLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(11)
            make.leading.equalTo(titleLabel)
            make.height.equalTo(10)
            make.width.equalTo(56)
        }
    }

    @objc
    private func backButtonClicked() {
        backButtonClickedBlock?()
    }
}

final class GroupIntermediateSkeletionView: UIView {
    private let headerView = HeaderView()
    private let tableView = TopicsSkeletonTableView()
    private let backButtonClickedBlock: () -> Void

    private let gradient = SkeletonGradient(
        baseColor: SkeletonViewConfig.baseColor,
        secondaryColor: SkeletonViewConfig.secondaryColor
    )

    init(backButtonClickedBlock: @escaping () -> Void) {
        self.backButtonClickedBlock = backButtonClickedBlock
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startLoading() {
        self.tableView.startLoading()
    }

    func stopLoading() {
        self.tableView.stopLoading()
        self.isHidden = true
    }

    private func setupUI() {
        addSubview(headerView)
        addSubview(tableView)

        setupHeaderView()
        setupTableView()
    }

    private func setupHeaderView() {
        headerView.backButtonClickedBlock = backButtonClickedBlock
        headerView.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalToSuperview()
        }
    }

    private func setupTableView() {
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.headerView.snp.bottom)
            make.bottom.leading.trailing.equalToSuperview()
        }
    }
}
