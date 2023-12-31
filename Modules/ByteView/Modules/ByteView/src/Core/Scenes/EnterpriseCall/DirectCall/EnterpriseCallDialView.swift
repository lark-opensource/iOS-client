//
//  EnterpriseCallDialView.swift
//  ByteView
//
//  Created by wangpeiran on 2022/7/5.
//

import Foundation
import SnapKit
import ByteViewCommon
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewMeeting
import ByteViewUI

class EnterpriseCallDialView: UIView {

    lazy var phoneButtonView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var phoneButtons: [EnterpriseKeyPadButton] = {
        [
            ("1", "", "1", nil),
            ("2", "ABC", "2", nil),
            ("3", "DEF", "3", nil),
            ("4", "GHI", "4", nil),
            ("5", "JKL", "5", nil),
            ("6", "MNO", "6", nil),
            ("7", "PQRS", "7", nil),
            ("8", "TUV", "8", nil),
            ("9", "WXYZ", "9", nil),
            ("*", "", "*", nil),
            ("0", "+", "0", "+"),
            ("#", "", "#", nil)
        ].map {
            let style: EnterpriseKeyPadButton.Style = Display.typeIsLike < Display.DisplayType.iPhone6 ? .tiny : (Display.iPhoneMaxSeries ? .max : .default)
            let button = EnterpriseKeyPadButton(style: style,
                                                title: $0.0, subtitle: $0.1, mainText: $0.2, subText: $0.3)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(appendNumber(gesture:)))
            tapGesture.numberOfTapsRequired = 1
            button.addGestureRecognizer(tapGesture)
            return button
        }
    }()

    var dialTotalNumber = ""
    var buttonWidth, horizontalSpacing, verticalSpacing, viewHeight: CGFloat
    var viewModel: EnterpriseCallViewModel
    var tapBlock: ((String, String) -> Void)?

    init(viewModel: EnterpriseCallViewModel) {
        self.viewModel = viewModel

        if let meeting = viewModel.meeting, let identifier = viewModel.calledParticpant?.identifier {
            dialTotalNumber = meeting.participantDialData.saveData[identifier] ?? ""
        }

        let displayType = Display.typeIsLike
        if displayType < Display.DisplayType.iPhone6 {
            buttonWidth = 64.0
            horizontalSpacing = 20.0
            verticalSpacing = 10.0
        } else if displayType < Display.DisplayType.iPhoneX {
            buttonWidth = 72.0
            horizontalSpacing = 32.0
            verticalSpacing = 20.0
        } else if Display.iPhoneMaxSeries {
            buttonWidth = 82.0
            horizontalSpacing = 32.0
            verticalSpacing = 20.0
        } else {
            buttonWidth = 72.0
            horizontalSpacing = 32.0
            verticalSpacing = 20.0
        }
        viewHeight = 4 * buttonWidth + 3 * verticalSpacing

        super.init(frame: CGRect(x: 0, y: 0, width: 375, height: viewHeight))
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(phoneButtonView)
        phoneButtonView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.equalTo(3 * buttonWidth + 2 * horizontalSpacing)
            $0.height.equalTo(4 * buttonWidth + 3 * verticalSpacing)
        }

        let leftOffset: CGFloat = buttonWidth + horizontalSpacing
        let topOffset: CGFloat = buttonWidth + verticalSpacing
        phoneButtons.enumerated().forEach { [weak phoneButtonView] in
            let button = $0.element
            let idx = $0.offset
            let leftOffset = CGFloat(idx % 3) * leftOffset
            let topOffset = CGFloat(floor(Double(idx) / 3)) * topOffset
            phoneButtonView?.addSubview(button)
            button.snp.makeConstraints { make in
                make.width.height.equalTo(buttonWidth)
                make.left.equalTo(leftOffset)
                make.top.equalTo(topOffset)
            }
        }
    }

    @objc func appendNumber(gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? EnterpriseKeyPadButton, let number = button.mainText else { return }
        dialTotalNumber = dialTotalNumber.appending(number)
        tapBlock?(number, dialTotalNumber)
        Logger.enterpriseCall.info("dialNumber count: \(dialTotalNumber.count)")
        requestDTMF(num: number, seqId: dialTotalNumber.count)
    }

    func requestDTMF(num: String, seqId: Int) {
        guard !num.isEmpty else { return }
        let meetingId = viewModel.session.meetingId
        var userId = ""
        if let user = viewModel.calledParticpant {
            userId = user.user.id
        }
        Logger.enterpriseCall.info("ApplyDTMF \(meetingId)---\(userId)--\(seqId)")
        let httpClient = viewModel.session.httpClient
        let request = ApplyDTMFRequest(dtmfCmd: num, seqId: Int64(seqId), userId: userId, meetingId: meetingId)
        httpClient.send(request) { result in
            Logger.participant.info("ApplyDTMF Request finished: isSuccess = \(result.isSuccess)")
        }
    }
}
