//
//  MinutesHomeAudioRecordCircleView.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/3/18.
//

import UIKit
import Foundation

class MinutesHomeAudioRecordCircleView: UIView {

    var onClickCircleButton: (() -> Void)?

    lazy var circleButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(BundleResources.Minutes.minutes_home_audio_record, for: .normal)
        button.addTarget(self, action: #selector(onClickCircleRecoderButton(_:)), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear

        addSubview(circleButton)
        layoutSubviewsManually()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSubviewsManually() {
        circleButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    @objc
    private func onClickCircleRecoderButton(_ sender: UIButton) {
        onClickCircleButton?()
    }
}
