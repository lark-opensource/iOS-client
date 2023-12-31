//
//  SubtitleSearchBottomView.swift
//  ByteView
//
//  Created by fakegourmet on 2020/11/9.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewTracker
import UniverseDesignIcon

class SubtitleSearchBottomView: UIView {
    private var prevButton = UIButton(type: .custom)
    private var nextButton = UIButton(type: .custom)

    private var isNextButtonEnabled = false {
        didSet {
            let color = isNextButtonEnabled ? UIColor.ud.iconN1 : UIColor.ud.iconDisabled
            self.nextButton.setImage(UDIcon.getIconByKey(.downOutlined, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        }
    }

    private var isPrevButtonEnabled = false {
        didSet {
            let color = isPrevButtonEnabled ? UIColor.ud.iconN1 : UIColor.ud.iconDisabled
            self.prevButton.setImage(UDIcon.getIconByKey(.upOutlined, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        }
    }

    var viewModel: SubtitlesViewModel? {
        didSet {
            updateViewModel()
        }
    }

    var transcriptViewModel: TranscriptViewModel? {
        didSet {
            transcriptViewModel?.addListener(self)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
        self.layer.shadowOffset = CGSize(width: 0, height: -6)
        self.layer.shadowRadius = 24
        self.layer.shadowOpacity = 1

        prevButton.adjustsImageWhenDisabled = false
        prevButton.setImage(UDIcon.getIconByKey(.upOutlined, iconColor: .ud.iconDisabled, size: CGSize(width: 24, height: 24)), for: .normal)
        prevButton.setImage(UDIcon.getIconByKey(.upOutlined, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24)), for: .highlighted)
        nextButton.adjustsImageWhenDisabled = false
        nextButton.setImage(UDIcon.getIconByKey(.downOutlined, iconColor: .ud.iconDisabled, size: CGSize(width: 24, height: 24)), for: .normal)
        nextButton.setImage(UDIcon.getIconByKey(.downOutlined, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24)), for: .highlighted)

        addSubview(prevButton)
        addSubview(nextButton)

        nextButton.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(24)
            maker.top.equalToSuperview().inset(8)
            maker.right.equalToSuperview().inset(16)
        }
        prevButton.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(24)
            maker.top.equalTo(nextButton)
            maker.right.equalTo(nextButton.snp.left).offset(-24)
        }

        prevButton.addTarget(self, action: #selector(didClickPrev(_:)), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didClickNext(_:)), for: .touchUpInside)
    }

    private func updateViewModel() {
        guard let vm = viewModel else {
            return
        }

        vm.bottomHighlightObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] isHighlighted in
            guard let `self` = self else { return }
            self.isNextButtonEnabled = isHighlighted
        }).disposed(by: rx.disposeBag)

        vm.topHighlightObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] isHighlighted in
            guard let `self` = self else { return }
            self.isPrevButtonEnabled = isHighlighted
        }).disposed(by: rx.disposeBag)
    }

    @objc func didClickPrev(_ sender: Any) {
        if isPrevButtonEnabled {
            VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "search_up"])
            self.viewModel?.updateTop()
            transcriptViewModel?.goToLast()
        }
    }

    @objc func didClickNext(_ sender: Any) {
        if isNextButtonEnabled {
            VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "search_down"])
            self.viewModel?.updateBottom()
            transcriptViewModel?.goToNext()
        }
    }
}

extension SubtitleSearchBottomView: TranscriptViewModelDelegate {

    func searchPrevButtonEnabledDidChanged() {
        isPrevButtonEnabled = transcriptViewModel?.isPrevButtonEnabled ?? false
    }

    func searchNextButtonEnabledDidChanged() {
        isNextButtonEnabled = transcriptViewModel?.isNextButtonEnabled ?? false
    }
}
