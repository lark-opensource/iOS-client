//
//  MinutesClipTitleView.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/6.
//

import UIKit
import MinutesFoundation
import UniverseDesignTag
import MinutesNetwork

protocol MinutesClipTitleViewDelegate: AnyObject {
    func goToOriginalMinutes()
}

class MinutesClipTitleView: UIView {

    weak var delegate: MinutesClipTitleViewDelegate?

    private lazy var audioIcon: UIImageView = UIImageView(image: BundleResources.Minutes.minutes_audio)

    private lazy var titleView: MinutesClipTitleInnerView = {
        let tv = MinutesClipTitleInnerView()
        return tv
    }()

    private lazy var subtitleView: MinutesClipSubTitleInnerView = {
        let l = MinutesClipSubTitleInnerView()
        l.delegate = self
        return l
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.addArrangedSubview(titleView)
        stack.setCustomSpacing(4, after: titleView)
        stack.addArrangedSubview(subtitleView)
        return stack
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.distribution = .fill
        stack.addArrangedSubview(audioIcon)
        audioIcon.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }
        stack.setCustomSpacing(12, after: audioIcon)
        stack.addArrangedSubview(contentStack)
        return stack
    }()

    var headerHeight: CGFloat = 76


    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.top.equalTo(16)
            make.right.equalTo(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with info: BasicInfo?) {
        var w = frame.width - 32
        audioIcon.isHidden = true
        titleView.preferredMaxLayoutWidth = w
        titleView.text = info?.topic ?? ""
        if let time = info?.duration {
            subtitleView.preferredMaxLayoutWidth = w
            subtitleView.update(duration: timeString(from: time / 1000), isContinue: info?.clipInfo?.continuous ?? false)
        }
        headerHeight = titleView.viewHeight + subtitleView.viewHeight + 28
    }

    private func timeString(from duration: Int) -> String {
        var timeStr: String = ""
        let hours: Int = duration / 3600

        let minutes = duration % 3600 / 60

        let seconds = duration % 3600 % 60

        if hours == 0 && minutes == 0 {
            return BundleI18n.Minutes.MMWeb_MV_SecondUnit(seconds)
        } else if hours == 0 {
            return BundleI18n.Minutes.MMWeb_MV_MinuteSecondUnit(minutes, seconds)
        } else {
            return BundleI18n.Minutes.MMWeb_MV_HourMinuteSecondUnit(hours, minutes, seconds)
        }
    }
}

extension MinutesClipTitleView: MinutesClipSubTitleInnerViewDelegate {
    func tapLinkClosure() {
        self.delegate?.goToOriginalMinutes()
    }
}
