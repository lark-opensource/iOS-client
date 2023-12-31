//
//  MailSendCalendarView.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/3/7.
//

import UIKit
import UniverseDesignButton
import UniverseDesignIcon

protocol MailSendCalendarViewDelegate: AnyObject {
    func deleteCalendarView()
    func clickCalenderView()
}

class MailSendCalendarView: UIView {
    
    var intrinsicContentHeight: CGFloat = 0
    let viewHeight: CGFloat = 64
    weak var delegate: MailSendCalendarViewDelegate?
    var isEditable: Bool = false
    var addSubViews = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        let tapGeture = UITapGestureRecognizer.init(target: self, action: #selector(viewClick))
        self.addGestureRecognizer(tapGeture)
        self.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric,
                      height: self.intrinsicContentHeight)
    }
    
    func setupUI(isHidden: Bool,
                        isEditable: Bool,
                        title: String = "",
                        summary: String? = nil) {
        self.isHidden = isHidden
        self.isEditable = isEditable
        if isHidden {
            self.intrinsicContentHeight = 0
        } else {
            if !addSubViews {
                addSubview(bottomSeparator)
                addSubview(calendarBgView)
                calendarBgView.addSubview(calendarIcon)
                addSubview(deleteIcon)
                addSubview(titleLabel)
                addSubview(summaryLabel)
                addSubViews = true
            }
            self.intrinsicContentHeight = viewHeight
            makeViewSnps(title: title, summary: summary)
        }
        invalidateIntrinsicContentSize()
    }
    
    func makeViewSnps(title: String,
                      summary: String? = nil) {
        bottomSeparator.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        calendarBgView.snp.remakeConstraints { make in
            make.width.height.equalTo(32)
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        calendarIcon.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }
        deleteIcon.snp.remakeConstraints { make in
            make.width.height.equalTo(14)
            make.right.equalToSuperview().offset(-21.5)
            make.centerY.equalTo(calendarBgView.snp.centerY)
        }
        deleteIcon.hitTestEdgeInsets = UIEdgeInsets(top: -22, left: -10, bottom: -22, right: -21.5)
        var oneline = true
        if let summary = summary, !summary.isEmpty {
            oneline = false
        }
        if oneline {
            // 一行
            summaryLabel.isHidden = true
            titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(calendarBgView.snp.right).offset(8)
                make.centerY.equalTo(calendarBgView.snp.centerY)
                make.right.equalTo(deleteIcon.snp.left).offset(-8)
            }
        } else {
            // 两行
            summaryLabel.isHidden = false
            titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(calendarBgView.snp.right).offset(8)
                make.centerY.equalTo(calendarBgView.snp.centerY).offset(-10)
                make.right.equalTo(deleteIcon.snp.left).offset(-8)
            }
            summaryLabel.snp.remakeConstraints { make in
                make.left.equalTo(calendarBgView.snp.right).offset(8)
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
                make.right.equalTo(deleteIcon.snp.left).offset(-8)
            }
        }
        titleLabel.text = title
        if let text = summary {
            summaryLabel.text = text
        }
    }
    
    lazy var calendarBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.O100
        view.layer.cornerRadius = 8
        return view
    }()
    
    lazy var calendarIcon: UIView = {
        let view = UIImageView.init(image: Resources.mail_send_calendar)
        return view
    }()
    
    lazy var bottomSeparator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.ud.lineDividerDefault//.withAlphaComponent(0.15)
        return separator
    }()
    lazy var deleteIcon: UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(UDIcon.closeBoldOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        view.tintColor = UIColor.ud.iconN3
        view.addTarget(self, action: #selector(deleteClick), for: .touchUpInside)
        return view
    }()
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textCaption
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    @objc
    func deleteClick() {
        self.delegate?.deleteCalendarView()
    }
    @objc
    func viewClick() {
        if isEditable {
            self.delegate?.clickCalenderView()
        } else {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_Event_EventCreatedViewInCalendar, on: self)
        }
    }
}
