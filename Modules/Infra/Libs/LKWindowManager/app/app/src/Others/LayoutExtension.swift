//
//  MeetExtension.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//
import Foundation
import UIKit

// swiftlint:disable all
extension FocusVC {
    func addSubViews() {
        self.view.addSubview(visualEffectView)
        self.view.addSubview(container)
        container.addSubview(tableView)
        self.view.addSubview(button)
    }

    func makeConstraints() {
        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        container.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(300)
            make.center.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        button.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(26)
            make.right.equalTo(view.safeAreaLayoutGuide).inset(26)
            make.width.equalTo(48)
            make.height.equalTo(36)
        }
    }

    func setAppearance() {
        visualEffectView.alpha = 0.8
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.white
        tableView.estimatedRowHeight = 0
        tableView.alwaysBounceVertical = false
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(FocusCell.self, forCellReuseIdentifier: "FocusCell")

        button.setTitle("关闭", for: .normal)
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(dissWindow), for: .touchUpInside)
    }

    @objc
    func dissWindow() {
        FocusWindow.shared.isHidden = true
    }
}

extension MeetingVC {
    func addSubViews() {
        self.view.addSubview(containerView)
        self.view.addSubview(shareButton)
        containerView.addSubview(leftView)
        containerView.addSubview(rightView)
        containerView.addSubview(textLabel)
        self.view.addSubview(exitButton)

    }
    func makeConstraints() {
        exitButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(26)
            make.right.equalTo(view.safeAreaLayoutGuide).inset(26)
            make.width.equalTo(48)
            make.height.equalTo(36)
        }

        containerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(50)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        leftView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().inset(50)
            make.width.equalTo(100)
        }

        textLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        rightView.snp.makeConstraints { make in
            make.left.equalTo(leftView.snp.right).offset(50)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().inset(50)
            make.right.equalToSuperview().inset(20)
        }

        shareButton.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(44)
            make.center.equalToSuperview()
        }
    }

    func setAppearance() {
        leftView.backgroundColor = .green
        rightView.backgroundColor = .orange

        exitButton.backgroundColor = UIColor.red
        exitButton.setTitle("退出", for: .normal)
        exitButton.addTarget(self, action: #selector(dismissMeet), for: .touchUpInside)

        shareButton.backgroundColor = UIColor.green
        shareButton.setTitle("分享文档", for: .normal)
        shareButton.layer.cornerRadius = 12
//        shareButton.layer.cornerCurve = .continuous
        shareButton.addTarget(self, action: #selector(showDoc), for: .touchUpInside)

        textLabel.text = "这是会议内容!!!!"
        textLabel.font = UIFont.systemFont(ofSize: 30)
        textLabel.textColor = .brown
        textLabel.backgroundColor = .yellow

        self.containerView.isHidden = true
        self.exitButton.isHidden = isLandmark
    }

    @objc
    func dismissMeet() {
        self.view.window?.isHidden = true
        self.isAutorotated = false
        dismissWindowBlock?()
    }

    @objc
    func showDoc() {
        self.isShowDoc = true
        self.shareButton.isHidden = true
        self.containerView.isHidden = false
        self.isAutorotated = true
        self.isLandmark = true
    }
}

extension FeedVC {
    func addSubViews() {
        self.view.addSubview(navi)
        self.view.addSubview(tableView)
        self.view.addSubview(focus)
//        self.view.addSubview(alertBtn)
    }
    func makeConstraints() {
        navi.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        focus.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(40)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navi.snp.bottom).offset(16)
        }
        alertBtn.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(60)
        }

    }
    func setAppearance() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.white
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.register(FeedCell.self, forCellReuseIdentifier: "FeedCell")

        focus.setTitle("Focus", for: .normal)
        focus.backgroundColor = .red
        focus.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        focus.addTarget(self, action: #selector(clickFocus), for: .touchUpInside)

//        alertBtn.setTitle("弹窗", for: .normal)
//        alertBtn.backgroundColor = .green
//        alertBtn.addTarget(self, action: #selector(popAlert), for: .touchUpInside)
    }


    @objc
    func clickFocus() {
        FocusWindow.shared.makeKeyAndVisible()
    }

//    @objc
//    func popAlert() {
//        let alert = UIAlertController(title: "弹窗", message: "弹窗", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
//        self.present(alert, animated: true)
//    }

}

extension FeedVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:FeedCell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedCell
        cell.messView.backgroundColor = .cyan
        return cell
    }
}


extension FocusVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:FocusCell = tableView.dequeueReusableCell(withIdentifier: "FocusCell", for: indexPath) as! FocusCell
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 46
    }
}
