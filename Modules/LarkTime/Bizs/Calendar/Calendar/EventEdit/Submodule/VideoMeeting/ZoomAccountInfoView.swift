//
//  ZoomAccountInfoView.swift
//  Calendar
//
//  Created by pluto on 2022-10-25.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignLoading

/*
    ZoomAccountStatus 状态解读
         .normal  ->   正常的Zoom会议 有会议号和密码
  .normalOneLine  ->   正常的Zoom会议 只有会议号
        .loading  ->   加载态
        .initial  ->   初始状态，表示首次进入，同时会议类型非Zoom
       .datafail  ->   有Zoom账号 创建Zoom会议失败
.expired .unbind  ->   Zoom账号过期、未绑定 重新绑定
 */

enum ZoomAccountStatus {
    case normal
    case normalOneLine
    case unbind
    case expired
    case datafail
    case loading
    case inital
}

protocol ZoomAccountInfoViewDelegate: AnyObject {
    func updateItemLayout(isZoomType: Bool, height: CGFloat)
}

final class ZoomAccountInfoView: UIView {

    var tapErrorTipsCallBack: (() -> Void)?
    let singleLineHeight: CGFloat = 22.0
    weak var delegate: ZoomAccountInfoViewDelegate?

    var status: ZoomAccountStatus = .loading {
        didSet {
            statusUIPicker(status: status)
        }
    }

    var forAccountManage: Bool = false {
        didSet {
            if forAccountManage {
                errorIcon.isHidden = false
                errorDesLabel.textColor = UIColor.ud.textPlaceholder
                errorDesLabel.font = UIFont.systemFont(ofSize: 14)
                errorLinkerBtn.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
                errorLinkerBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
                updateErrorViewLayout(fontSize: 14)
            } else {
                errorIcon.isHidden = true
                errorDesLabel.textColor = UIColor.ud.functionDangerContentDefault
                errorDesLabel.font = UIFont.systemFont(ofSize: 16)
                errorLinkerBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
                errorLinkerBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
                updateErrorViewLayout(fontSize: 16)
            }
        }
    }

    var viewHeight: CGFloat {
        if status == .normal {
            return singleLineHeight * 2
        }
        return singleLineHeight
    }

    private lazy var accountView: UIView = {
       let view = UIView()
        view.isHidden = true
        view.backgroundColor = .clear
        return view
    }()

    private lazy var meetingNoLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var meetingPasswordLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var errorView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var errorDesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.numberOfLines = 0
        return label
    }()

    private lazy var errorIcon: UIImageView = {
       let img = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.warningOutlined).ud.withTintColor(UIColor.ud.functionDangerContentDefault))
        img.isHidden = true
        return img
    }()

    lazy var errorLinkerBtn: UIButton = {
        let btn = UIButton()
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.addTarget(self, action: #selector(tapToGetAccountInfo), for: .touchUpInside)
        btn.titleLabel?.textAlignment = .left
        btn.isUserInteractionEnabled = true
        return btn
    }()

    private let loadingView = UDLoading.presetSpin(
        color: .primary,
        loadingText: I18n.Calendar_Edit_FindTimeLoading,
        textDistribution: .horizonal
    )
    
    override var isHidden: Bool {
        didSet{
            if isHidden {
                delegate?.updateItemLayout(isZoomType: false, height: singleLineHeight)
            } else {
                delegate?.updateItemLayout(isZoomType: true, height: self.bounds.height)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutLoadingView()
        layoutErrorView()
        layoutMeetingDescInfo()
        loadingView.isHidden = true

        snp.makeConstraints { $0.height.equalTo(44) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func statusUIPicker(status: ZoomAccountStatus) {
        switch status {
        case .loading:
            loadingView.isHidden = false
            errorView.isHidden = true
            accountView.isHidden = true
            snp.updateConstraints { $0.height.equalTo(singleLineHeight) }
            delegate?.updateItemLayout(isZoomType: true, height: singleLineHeight)
        case .normal:
            accountView.isHidden = false
            errorView.isHidden = true
            loadingView.isHidden = true
            snp.updateConstraints { $0.height.equalTo(singleLineHeight * 2) }
            delegate?.updateItemLayout(isZoomType: true, height: singleLineHeight * 2)
        case .normalOneLine:
            accountView.isHidden = false
            errorView.isHidden = true
            loadingView.isHidden = true
            snp.updateConstraints { $0.height.equalTo(singleLineHeight) }
            delegate?.updateItemLayout(isZoomType: true, height: singleLineHeight)
        case .datafail, .unbind, .expired:
            errorView.isHidden = false
            accountView.isHidden = true
            loadingView.isHidden = true
            configErrorLabel(status: status)
        default: break
        }
    }

    private func layoutLoadingView() {
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(singleLineHeight)
        }
    }

    private func layoutErrorView() {
        addSubview(errorView)
        errorView.addSubview(errorIcon)
        errorView.addSubview(errorDesLabel)
        errorView.addSubview(errorLinkerBtn)

        errorView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(singleLineHeight)
        }

        errorIcon.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        errorDesLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        errorLinkerBtn.snp.makeConstraints { make in
            make.left.equalTo(errorDesLabel.snp.right).offset(8)
            make.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-8)
            make.width.equalTo(50)
        }
    }

    private func configErrorLabel(status: ZoomAccountStatus) {
        switch status {
        case .unbind:
            errorDesLabel.text = I18n.Calendar_Zoom_PleaseBind
            errorLinkerBtn.setTitle(I18n.Calendar_Zoom_BindAcct, for: .normal)
        case .expired:
            errorDesLabel.text = I18n.Calendar_Zoom_Invalid
            errorLinkerBtn.setTitle(I18n.Calendar_Zoom_BindAgain, for: .normal)
        case .datafail:
            errorDesLabel.text = I18n.Calendar_Zoom_FailLoadData
            errorLinkerBtn.setTitle(I18n.Calendar_Zoom_RetryClick, for: .normal)
        default: break
        }
        updateErrorViewLayout(fontSize: 16)
        errorLinkerBtn.becomeFirstResponder()
    }

    private func updateErrorViewLayout(fontSize: CGFloat) {
        let desWidth = errorDesLabel.text?.getWidth(font: UIFont.systemFont(ofSize: fontSize)) ?? 134
        let linBtnWidth = errorLinkerBtn.titleLabel?.text?.getWidth(font: UIFont.systemFont(ofSize: fontSize)) ?? 0
        updateErrorViewHeight(desWidth: desWidth, linBtnWidth: linBtnWidth)

        errorDesLabel.snp.updateConstraints {
            $0.left.equalToSuperview().offset(fontSize == 14 ? 20 : 0)
        }
        
        errorLinkerBtn.snp.updateConstraints {
            $0.width.equalTo(linBtnWidth)
        }
        
    }
    
    private func updateErrorViewHeight(desWidth: CGFloat, linBtnWidth: CGFloat) {
        if desWidth + linBtnWidth > self.bounds.width - 8 - 16 && !forAccountManage {
            snp.updateConstraints { $0.height.equalTo(singleLineHeight * 2) }
            errorView.snp.updateConstraints{ $0.height.equalTo(singleLineHeight * 2)}
            delegate?.updateItemLayout(isZoomType: true, height: singleLineHeight * 2)
        } else {
            snp.updateConstraints { $0.height.equalTo(singleLineHeight) }
            errorView.snp.updateConstraints{ $0.height.equalTo(singleLineHeight)}
            delegate?.updateItemLayout(isZoomType: true, height: singleLineHeight)
        }
    }

    private func layoutMeetingDescInfo() {
        addSubview(accountView)
        accountView.addSubview(meetingNoLabel)
        accountView.addSubview(meetingPasswordLabel)

        accountView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }

        meetingNoLabel.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(22)
        }

        meetingPasswordLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(22)
            make.top.equalTo(meetingNoLabel.snp.bottom)
        }
    }

    func configMeetingDescInfo(meetingNo: Int64, password: String, fontSize: CGFloat) {
        meetingNoLabel.text = BundleI18n.Calendar.Calendar_Zoom_MeetIDWith + "\(meetingNo)".formatZoomMeetingNumber()
        meetingPasswordLabel.isHidden = password.isEmpty
        meetingPasswordLabel.text = BundleI18n.Calendar.Calendar_Zoom_MeetPasscode + " \(password)"
        meetingNoLabel.font = UIFont.systemFont(ofSize: fontSize)
        meetingPasswordLabel.font = UIFont.systemFont(ofSize: fontSize)
    }

    @objc
    private func tapToGetAccountInfo() {
        self.tapErrorTipsCallBack?()
    }
}
