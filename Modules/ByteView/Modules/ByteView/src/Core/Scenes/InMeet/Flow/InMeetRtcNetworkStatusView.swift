//
//  InMeetRtcNetworkStatusView.swift
//  ByteView
//
//  Created by Shuai Zipei on 2023/3/17.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignIcon
import ByteViewCommon
import UIKit
import ByteViewNetwork
import ByteViewTracker

final class InMeetRtcNetworkStatusViewModel: InMeetRtcNetworkListener {
    let meeting: InMeetMeeting
    let context: InMeetViewContext

    private let netWorkStatusRelay: BehaviorRelay<RtcNetworkStatus>
    private(set) lazy var netWorkStatusObservable: Observable<RtcNetworkStatus> = netWorkStatusRelay.distinctUntilChanged().asObservable()
    private let disposeBag = DisposeBag()

    init(meeting: InMeetMeeting, context: InMeetViewContext, breakoutRoom: BreakoutRoomManager?) {
        self.meeting = meeting
        self.context = context
        self.netWorkStatusRelay = .init(value: meeting.rtc.network.localNetworkStatus)
        meeting.rtc.network.addListener(self)
    }

    func didChangeLocalNetworkStatus(_ status: RtcNetworkStatus, oldValue: RtcNetworkStatus, reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        self.netWorkStatusRelay.accept(status)
    }
}

class InMeetRtcNetworkStatusView: UIView {
    var isFullScreen = false
    private var isEnable = false

    private var disposeBag = DisposeBag()

    let weakNetworkImageView: UIImageView = {
        var imageView = UIImageView()
        imageView.snp.makeConstraints { (maker) in
            maker.size.equalTo(12)
        }
        return imageView
    }()

    private var viewModel: InMeetRtcNetworkStatusViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(weakNetworkImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InMeetRtcNetworkStatusView {
    func bindViewModel(_ viewModel: InMeetRtcNetworkStatusViewModel) {
        self.viewModel = viewModel
        disposeBag = DisposeBag()
        //  网络状态
        viewModel.netWorkStatusObservable
            .map { status -> (UIImage?, Bool) in
                status.networkIcon()
            }
            .startWith((nil, false))
            .asDriver(onErrorJustReturn: (nil, false))
            .drive(onNext: { [weak self] (icon, isEnabled) in
                self?.weakNetworkImageView.image = icon
                self?.isEnable = isEnabled
                self?.updateStatus()
            }).disposed(by: disposeBag)

        viewModel.netWorkStatusObservable
            .filter { $0.networkShowStatus == .weak }
            .subscribe(onNext: { _ in
                let params: TrackParams = [.from_source: "self",
                                             .action_name: "unstable",
                                             "network_status": "weak"]
                VCTracker.post(name: .vc_voip_connection, params: params)
            })
            .disposed(by: disposeBag)
    }

    func updateStatus() {
        if !isEnable || !isFullScreen {
            weakNetworkImageView.isHidden = true
            self.superview?.isHidden = true
        } else if isEnable && isFullScreen {
            weakNetworkImageView.isHidden = false
            self.superview?.isHidden = false
        }
    }
}
