//
//  MailTagViewController+PopoverDisplay.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/12/10.
//

import UIKit

extension MailTagViewController {

    func changeDisplayMode(mode: DisplayMode) {
        displayMode = mode
        setupViews()
    }

    func setupViews() {
        if displayMode == .normalMode {
            setupViewForNormalMode()
        } else {
            setupViewForPopMode()
        }
    }

    func setupViewForPopMode() {
        view.backgroundColor = .clear
        contentView.snp.removeConstraints()
        contentView.removeFromSuperview()
        bgMask.snp.removeConstraints()
        bgMask.removeFromSuperview()
        bgView.snp.removeConstraints()
        bgView.removeFromSuperview()
        view.addSubview(mainTableView)
        view.addSubview(settingView)
//        view.addSubview(subTableView)
        if loadingView.superview != nil {
            view.bringSubviewToFront(loadingView)
        }
        if loadFailView.superview != nil {
            view.bringSubviewToFront(loadFailView)
        }
        mainTableView.snp.remakeConstraints { (make) in
            make.top.equalTo(25)
            make.bottom.equalToSuperview().offset(-54)
            make.leading.equalToSuperview()
            make.width.equalToSuperview()
        }
        settingView.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.leading.equalTo(mainTableView.snp.leading)
            make.width.equalTo(mainTableView.snp.width)
            make.height.equalTo(54)
        }
//        subMenuManager.tableView = subTableView
    }

    func setupViewForNormalMode() {
        if let size = UIApplication.shared.keyWindow?.frame.size {
            view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        } else if let size = self.delegate?.delegateViewSize() {
            view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        view.backgroundColor = .clear
        bgMask.backgroundColor = .clear
        view.addSubview(bgView)
        bgView.addSubview(bgMask)
        bgView.addSubview(contentView)
        contentView.addSubview(mainTableView)
        contentView.addSubview(settingView)
//        contentView.addSubview(subTableView)
        if loadingView.superview != nil {
            contentView.bringSubviewToFront(loadingView)
        }
        if loadFailView.superview != nil {
            contentView.bringSubviewToFront(loadFailView)
        }

        bgView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).inset(naviHeight)
            make.bottom.equalToSuperview()
        }
        bgMask.snp.remakeConstraints { (make) in
           make.edges.equalToSuperview()
        }
        contentView.transform = Layout.menuHideTransform
        if Display.pad {
            contentView.snp.remakeConstraints { (make) in
               make.top.equalTo(-16)
               make.leading.trailing.equalToSuperview()
               make.height.equalToSuperview().dividedBy(2)
            }
        } else {
            contentView.snp.remakeConstraints { (make) in
               make.top.equalTo(-16)
               make.leading.trailing.equalToSuperview()
               make.bottom.equalTo(-Layout.bottomSpace)
            }
        }

        mainTableView.snp.remakeConstraints { (make) in
           make.top.equalTo(16)
           make.leading.equalToSuperview()
           make.width.equalToSuperview()
           make.bottom.equalToSuperview().offset(-54)
        }
        settingView.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.leading.equalTo(mainTableView.snp.leading)
            make.width.equalTo(mainTableView.snp.width)
            make.height.equalTo(54)
        }
//        subTableView.snp.remakeConstraints { (make) in
//           make.top.equalTo(16)
//           make.trailing.equalToSuperview()
//           make.width.equalToSuperview().dividedBy(2)
//           make.bottom.equalToSuperview()
//        }
//        subMenuManager.tableView = subTableView
    }
}
