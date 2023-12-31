//
//  MeetingRoomCheckInView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/20.
//

import UIKit
import LarkTimeFormatUtils
import RxRelay

private final class MeetingRoomCountDownView: UIView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.body2
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        return label
    }()

    var progress: CGFloat = 0 {
        didSet {
            if !(0.0...1.0).contains(progress) {
                progress = min(max(progress, 0.0), 1.0)
            }
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        layer.cornerRadius = 8
        layer.masksToBounds = true

        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(6)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let (slice, remainer) = rect.divided(atDistance: progress * rect.width, from: .minXEdge)

        let slicePath = UIBezierPath(roundedRect: slice, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: .zero)
        UIColor.ud.N1000.withAlphaComponent(0.1).setFill()
        slicePath.fill()

        let remainerPath = UIBezierPath(roundedRect: remainer, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: .zero)
        UIColor.ud.textTitle.withAlphaComponent(0.2).setFill()
        remainerPath.fill()
    }
}

final class MeetingRoomCheckInView: UIView, ViewDataConvertible {

    private var remain: TimeInterval = 0
    private var total: TimeInterval = 100 {
        didSet {
            if total == 0 {
                assertionFailure()
                total = 100
            }
        }
    }

    private var responseModel: MeetingRoomCheckInResponseModel?

    var viewData: (remain: Int64, responseModel: MeetingRoomCheckInResponseModel)? {
        didSet {
            guard let viewData = viewData else {
                assertionFailure()
                return
            }
            self.responseModel = viewData.responseModel
            tipsLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_ReleasedDescription(time: viewData.responseModel.strategy.durationAfterCheckIn / 60)
            timer?.invalidate()
            remain = TimeInterval(viewData.remain)
            total = TimeInterval(viewData.responseModel.strategy.durationBeforeCheckIn + viewData.responseModel.strategy.durationAfterCheckIn)

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                self.remain -= 1
                self.countdownView.progress = CGFloat(self.remain / self.total)
                if let remainString = self.formatter.string(from: self.remain) {
                    self.countdownView.label.text = BundleI18n.Calendar.Calendar_MeetingRoom_ToBeReleased(time: remainString)
                }

                if self.remain <= 0 {
                    timer.invalidate()
                    self.remainTimeUpRelay.accept(())
                }
            }
            timer?.tolerance = 0.05
        }
    }

    private lazy var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    private(set) lazy var checkInButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.Calendar.Calendar_MeetingRoom_CheckInButton, for: .normal)
        button.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        button.titleLabel?.font = UIFont.heading3
        button.setTitleColor(UIColor.ud.staticBlack, for: .normal)
        button.addTarget(self, action: #selector(checkIn), for: .touchUpInside)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }()

    private lazy var countdownView: MeetingRoomCountDownView = {
        let view = MeetingRoomCountDownView()
        return view
    }()

    private(set) lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.body2
        label.numberOfLines = 0
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        return label
    }()

    private var timer: Timer?

    var checkInButtonClickedRelay = PublishRelay<MeetingRoomCheckInResponseModel>()
    var remainTimeUpRelay = PublishRelay<Void>()

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true

        addSubview(checkInButton)
        addSubview(countdownView)
        addSubview(tipsLabel)

        checkInButton.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(88)
            make.leading.equalTo(snp.leadingMargin)
            make.top.equalTo(snp.topMargin)
        }

        countdownView.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.centerXWithinMargins.equalToSuperview()
            make.top.equalTo(checkInButton.snp.bottom).offset(24)
            make.height.equalTo(32)
        }

        tipsLabel.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.trailing.equalTo(snp.trailingMargin)
            make.top.equalTo(countdownView.snp.bottom).offset(8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func checkIn() {
        if let model = responseModel {
            checkInButtonClickedRelay.accept(model)
        }
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}
