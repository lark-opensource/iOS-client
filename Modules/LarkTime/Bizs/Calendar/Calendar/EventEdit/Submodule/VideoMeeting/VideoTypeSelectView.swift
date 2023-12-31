//
//  VideoTypeSelectView.swift
//  Calendar
//
//  Created by zhuheng on 2021/4/9.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import UniverseDesignLoading

protocol VideoTypeSelectViewDataType {
    var isVisible: Bool { get }
    var isSelectFeishu: Bool { get }
    var selectedVideoType: VideoItemType { get }
    var zoomInfo: ZoomInfo { get }
}

enum VideoItemType {
    case feishu
    case zoom
    case custom
    case unknown
}

final class VideoTypeSelectView: UIView, ViewDataConvertible {
    private let feishuVideoItem = SignleCheckItem(title: BundleI18n.Calendar.Calendar_Edit_FeishuVC(),
                                                  isSelected: false)
    private let customVideoItem = SignleCheckItem(title: BundleI18n.Calendar.Calendar_Edit_OtherVC,
                                                  isSelected: false)
    private let zoomVideoItem = SignleCheckItem(title: BundleI18n.Calendar.Calendar_Settings_ZoomMeet,
                                                isSelected: false)

    var onItemSelected: ((VideoItemType) -> Void)?
    var onClickRefreshOrRebindCallBack: ((ZoomAccountStatus) -> Void)?
    var viewData: VideoTypeSelectViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            isHidden = !viewData.isVisible
            feishuVideoItem.checkBox.isSelected = viewData.selectedVideoType == .feishu
            zoomVideoItem.checkBox.isSelected = viewData.selectedVideoType == .zoom
            customVideoItem.checkBox.isSelected = viewData.selectedVideoType == .custom
            zoomVideoItem.selectedType = viewData.selectedVideoType

            if viewData.selectedVideoType == .zoom {
                zoomVideoItem.configAccountInfo(status: viewData.zoomInfo.zoomStatus, accountInfo: viewData.zoomInfo.zoomMeetingConfig)
                zoomVideoItem.isHidden = false
            }
            // 在「视频会议设置页」展开时上报
            // https://bytedance.feishu.cn/sheets/shtcn2R033o2O9eRylHTbiA5hbJ
            if viewData.isSelectFeishu {
                CalendarTracerV2.EventVCSetting.traceView()
            }
        }
    }

    init() {
        zoomVideoItem.isHidden = !FG.shouldEnableZoom

        super.init(frame: .zero)
        setupView()
        setupCallBack()
    }

    private func setupView() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(feishuVideoItem)
        stackView.addArrangedSubview(zoomVideoItem)
        stackView.addArrangedSubview(customVideoItem)

        feishuVideoItem.onItemSelected = { [unowned self] in
            self.onItemSelected?(.feishu)
        }

        zoomVideoItem.onItemSelected = { [unowned self] in
            self.onItemSelected?(.zoom)
        }

        customVideoItem.onItemSelected = { [unowned self] in
            self.onItemSelected?(.custom)
        }
    }

    private func setupCallBack() {
        zoomVideoItem.onClickRefreshOrRebindCallBack = { [weak self] status in
            guard let self = self else { return}
            self.onClickRefreshOrRebindCallBack?(status)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

final class SignleCheckItem: UIView {
    var onItemSelected: (() -> Void)?
    var onClickRefreshOrRebindCallBack: ((ZoomAccountStatus) -> Void)?

    let checkBox: LKCheckbox
    private let titleLable: UILabel = UILabel()
    private let bgBtn: UIButton = UIButton()

    var selectedType: VideoItemType = .unknown {
        didSet {
            /// 控制 选中/非选中态 ZoomItem 的Layout和内容
            let isZoomType: Bool = selectedType == .zoom
            accountInfoView.isHidden = !isZoomType
        }
    }

    var status: ZoomAccountStatus = .inital {
        didSet {
            accountInfoView.status = status
        }
    }

    private lazy var accountInfoView: ZoomAccountInfoView = {
        let view = ZoomAccountInfoView()
        view.isHidden = true
        view.delegate = self
        return view
    }()

    init(title: String, isSelected: Bool) {
        self.checkBox = LKCheckbox(boxType: .single, isEnabled: true, iconSize: CGSize(width: 20, height: 20))
        super.init(frame: .zero)

        addSubview(bgBtn)
        bgBtn.backgroundColor = .clear
        bgBtn.addTarget(self, action: #selector(contentTapped), for: .touchUpInside)
        bgBtn.snp.makeConstraints { $0.edges.equalToSuperview() }

        backgroundColor = UIColor.ud.bgFloat

        checkBox.isSelected = isSelected
        checkBox.isUserInteractionEnabled = false
        addSubview(checkBox)
        checkBox.snp.makeConstraints {
            $0.left.equalToSuperview().offset(EventBasicCellLikeView.Style.leftInset)
            $0.width.height.equalTo(20)
            $0.centerY.equalToSuperview()
        }

        titleLable.font = UIFont.cd.regularFont(ofSize: 16)
        titleLable.textColor = UIColor.ud.textTitle
        titleLable.text = title
        titleLable.textAlignment = .left

        addSubview(titleLable)
        titleLable.snp.makeConstraints {
            $0.left.equalTo(checkBox.snp.right).offset(12)
            $0.right.equalToSuperview().inset(EventBasicCellLikeView.Style.rightInset)
            $0.centerY.equalToSuperview()
        }

        layoutAccountInfoView()
        snp.makeConstraints { $0.height.equalTo(48) }
        setupCallBack()
    }

    @objc func contentTapped() {
        checkBox.isSelected = true
        onItemSelected?()
    }

    private func layoutAccountInfoView() {
        addSubview(accountInfoView)
        accountInfoView.snp.makeConstraints { make in
            make.left.equalTo(titleLable.snp.left)
            make.top.equalTo(titleLable.snp.bottom).offset(12)
            make.right.equalToSuperview()
        }
    }

    private func setupCallBack() {
        accountInfoView.tapErrorTipsCallBack = { [weak self] in
            guard let self = self else { return }
            switch self.accountInfoView.status {
            case .unbind, .expired, .datafail:
                // 账号过期 -》 重新绑定  // 有账号 创建Zoom会议失败 -》重试
                self.onClickRefreshOrRebindCallBack?(self.accountInfoView.status)
                self.traceBindingActions(status: self.accountInfoView.status)
                self.status = .loading
            default: break
            }
        }
    }

    func configAccountInfo (status: ZoomAccountStatus, accountInfo: Server.ZoomVideoMeetingConfigs?) {
        if let info = accountInfo {
            accountInfoView.configMeetingDescInfo(meetingNo: info.meetingNo, password: info.password, fontSize: 16)
            if info.password.isEmpty {
                self.status = .normalOneLine
                return
            }
        }
        self.status = status
    }

    private func traceBindingActions (status: ZoomAccountStatus) {
        var clickParams: String = ""
        switch status {
        case .expired:
            clickParams = "rebind_zoom_account"
        case .unbind:
            clickParams = "bind_zoom_account"
        default: break
        }

        if clickParams.isEmpty { return }
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click(clickParams).target("vchat_tripartite_manage_view")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SignleCheckItem: ZoomAccountInfoViewDelegate {
    func updateItemLayout(isZoomType: Bool, height: CGFloat) {
        snp.remakeConstraints { $0.height.equalTo(isZoomType ? 48 + 12 + height : 48) }
        checkBox.snp.updateConstraints { $0.centerY.equalToSuperview().offset(isZoomType ? -6 - height / 2 : 0) }
        titleLable.snp.updateConstraints { $0.centerY.equalToSuperview().offset(isZoomType ? -6 - height / 2 : 0) }
    }
}
