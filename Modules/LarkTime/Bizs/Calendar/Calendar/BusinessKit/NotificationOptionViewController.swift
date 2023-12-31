//
//  NotificationOptionViewController.swift
//  Calendar
//
//  Created by zhouyuan on 2019/1/15.
//  Copyright © 2019 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import PresentContainerController
import LarkUIKit

final class NotificationOptionViewController: UIViewController {
    private let contentView = NotificationOptionView()

    // 只涉及编辑，且含有新增参与人的场景
    var checkBoxListValsCallBack: (([Bool], EventEdit.NotiOptionCheckBoxType) -> Void)?
    var trackInvitedGroupCheckStatus: ((Bool) -> Void)?
    var trackMinutesCheckStatus: ((Bool) -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgFloat
        self.view.layer.masksToBounds = true
        self.view.layer.cornerRadius = 5

        self.view.addSubview(contentView)
        contentView.snp.remakeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        configTrackCallBack()
    }

    func show(offset: CGPoint = CGPoint(x: 0, y: 0), controller: UIViewController?) {
        let container = PresentContainerController(subViewController: self,
                                                   animate: PresentFromCenter())
        container.clickDismissEnable = false
        container.show(in: controller)

        let padding: CGFloat = 36
        view.snp.makeConstraints { make in
            make.center.equalToSuperview()

            if Display.pad {
                make.width.equalTo(375)
            } else {
                make.leading.equalToSuperview().offset(padding)
            }
        }
    }

    func setTitles(titleText: String, subTitleText: String? = nil, showSubtitleCheckButton: Bool = false, subTitleMailText: String? = nil, checkBoxTitleList: [String] = [], checkBoxType: EventEdit.NotiOptionCheckBoxType = .unknown) {
        if !checkBoxTitleList.isEmpty {
            contentView.setCheckBoxTitleList(titleText: titleText, checkBoxTitleList: checkBoxTitleList, checkBoxType: checkBoxType)
        } else {
            contentView.setTitles(titleText: titleText,
                                  subTitleText: subTitleText,
                                  showSubtitleCheckButton: showSubtitleCheckButton,
                                  subTitleMailText: subTitleMailText)
        }
    }

    func addAction(actionButton: ActionButton) {
        contentView.addAction(actionButton: actionButton) { [weak self] (completion) in
            self?.disappear(completion)
        }

        contentView.checkBoxListCallBack = { [weak self] (checkVals, type) in
            self?.checkBoxListValsCallBack?(checkVals, type)
        }
    }

    private func configTrackCallBack() {
        contentView.trackInvitedGroupCheckStatus = { [weak self] isSelected in
            guard let self = self else { return }
            self.trackInvitedGroupCheckStatus?(isSelected)
        }

        contentView.trackMinutesCheckStatus = { [weak self] isSelected in
            guard let self = self else { return }
            self.trackMinutesCheckStatus?(isSelected)
        }
    }

    func disappear(_ completion: (() -> Void)? = nil) {
        PresentContainerController.presentContainer(for: self)?.dismiss(animated: true, completion: completion)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct PresentFromCenter: PresentContainerController.Animation {

    public var duration: TimeInterval
    public var offset: CGPoint
    public init(offset: CGPoint = .zero, duration: TimeInterval = 0.15) {
        self.duration = duration
        self.offset = offset
    }

    public func update(superVC: UIViewController, subVC: UIViewController, animation: Bool) {
        subVC.view.snp.remakeConstraints({ (make) in
            make.centerX.equalToSuperview().offset(offset.x)
            make.centerY.equalToSuperview().offset(offset.y)
        })
        if animation {
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.layoutIfNeeded()
            })
        }
    }

    public func appear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        if !animation {
            superVC.view.alpha = 1
            subVC.view.transform = CGAffineTransform.identity
            subVC.view.snp.remakeConstraints({ (make) in
                make.centerX.equalToSuperview().offset(offset.x)
                make.centerY.equalToSuperview().offset(offset.y)
            })
        } else {
            superVC.view.alpha = 0
            subVC.view.snp.remakeConstraints({ (make) in
                make.centerX.equalToSuperview().offset(offset.x)
                make.centerY.equalToSuperview().offset(offset.y)
            })
            subVC.view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            superVC.view.layoutIfNeeded()
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 1
                subVC.view.transform = CGAffineTransform.identity
            })
        }
    }

    public func disappear(
        superVC: UIViewController,
        subVC: UIViewController,
        animation: Bool,
        completion: (() -> Void)?) {
        if !animation {
            completion?()
        } else {
            superVC.view.layoutIfNeeded()
            UIView.animate(withDuration: self.duration, animations: {
                superVC.view.alpha = 0
                subVC.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }, completion: { (_) in
                completion?()
            })
        }
    }
}
