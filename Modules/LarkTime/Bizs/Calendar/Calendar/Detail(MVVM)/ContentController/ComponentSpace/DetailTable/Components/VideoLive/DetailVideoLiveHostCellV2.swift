//
//  DetailVideoLiveHostCellV2.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/12.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import RxSwift

protocol DetailVideoLiveHostCellContent {
    // 直播是否正在进行中
    var isLiveInProgress: Bool { get }
    var durationTime: Int { get }
    var url: String? { get }
}

final class DetailVideoLiveHostCellV2: UIView {
    private let liveStatusIconView = UIImageView()

    private lazy var liveNotStartIcon: UIImage = UDIcon.getIconByKeyNoLimitSize(.livestreamOutlined).renderColor(with: .n3).withRenderingMode(.alwaysOriginal)
    private lazy var liveStartedIcon: UIImage = UDIcon.getIconByKeyNoLimitSize(.livestreamFilled).ud.withTintColor(UIColor.ud.functionSuccessFillDefault)

    private lazy var durationTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body0(.fixed)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private let videoMeetingStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2(.fixed)
        label.textColor = UIColor.ud.functionSuccessContentPressed
        label.isUserInteractionEnabled = false
        label.text = BundleI18n.Calendar.Calendar_Edit_EnterLivestream
        return label
    }()

    private lazy var videoMeetingStatusBGView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 4
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(didVideoMeetingStatusClick))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    private lazy var durationTimeView = initDurationTimeView()

    private var durationTime: Int = 0

    private var originalTime: Int = -1

    private var disposeBag: DisposeBag?

    // title 被点击
    var tapAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        liveStatusIconView.image = liveNotStartIcon
        addSubview(liveStatusIconView)
        liveStatusIconView.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.left.equalToSuperview().offset(16)
        }

        let topStackView = UIStackView()

        topStackView.axis = .horizontal
        topStackView.alignment = .center

        videoMeetingStatusBGView.addSubview(videoMeetingStatusLabel)
        videoMeetingStatusBGView.sendSubviewToBack(videoMeetingStatusLabel)
        videoMeetingStatusLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        topStackView.addArrangedSubview(videoMeetingStatusBGView)
        topStackView.addArrangedSubview(durationTimeView)

        addSubview(topStackView)

        topStackView.snp.makeConstraints {
            $0.centerY.equalTo(liveStatusIconView)
            $0.height.equalTo(36)
            $0.top.equalToSuperview().offset(10)
            $0.left.equalTo(liveStatusIconView.snp.right).offset(16)
            $0.right.lessThanOrEqualToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-10)
        }

        videoMeetingStatusBGView.snp.makeConstraints {
            $0.height.equalToSuperview()
        }

        durationTimeView.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didVideoMeetingStatusClick() {
        tapAction?()
    }

    func updateContent(_ content: DetailVideoLiveHostCellContent) {
        if content.isLiveInProgress {
            liveStatusIconView.image = liveStartedIcon
            videoMeetingStatusLabel.textColor = UIColor.ud.functionSuccessContentDefault
            videoMeetingStatusBGView.layer.ud.setBorderColor(UIColor.ud.functionSuccessContentDefault)
            startTimerIfNeeded(startTime: content.durationTime)
        } else {
            liveStatusIconView.image = liveNotStartIcon
            durationTimeView.isHidden = true
            videoMeetingStatusLabel.textColor = UIColor.ud.B700
            videoMeetingStatusBGView.layer.ud.setBorderColor(UIColor.ud.B700)
            stopTimer()
        }
    }

    private func stopTimer() {
        durationTime = 0
        disposeBag = nil
        durationTimeView.isHidden = true
    }

    private func startTimerIfNeeded(startTime: Int) {
        guard startTime != originalTime else { return }
        originalTime = startTime
        durationTime = originalTime

        durationTimeView.isHidden = false
        durationTimeLabel.text = formatTime(durationTime: durationTime)
        let disposeBag = DisposeBag()
        Observable<Int>.timer(.seconds(1), period: .seconds(1), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .bind { [weak self] (_) in
                guard let self = self else { return }
                self.durationTime += 1
                self.durationTimeLabel.text = self.formatTime(durationTime: self.durationTime)
            }.disposed(by: disposeBag)
        self.disposeBag = disposeBag
    }

    func formatTime(durationTime: Int) -> String {
        let hour = durationTime / 3600
        let minute = (durationTime % 3600) / 60
        let second = durationTime % 60
        return hour > 0 ? String(format: "%02d:%02d:%02d", hour, minute, second) : String(format: "%02d:%02d", minute, second)
    }

    func initDurationTimeView() -> UIView {
        let view = UIView()

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault

        view.addSubview(lineView)
        lineView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(16)
            $0.width.equalTo(1)
        }

        view.addSubview(durationTimeLabel)
        durationTimeLabel.snp.makeConstraints {
            $0.left.equalTo(lineView).offset(12)
            $0.right.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
        }

        return view
    }

}
