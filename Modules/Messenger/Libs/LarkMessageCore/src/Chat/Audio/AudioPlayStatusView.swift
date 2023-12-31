//
//  AudioPlayStatusView.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/5/19.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignToast

public enum AudioPlayStatus {
    case audioLowVolume
    case audioSpeaker
    case audioEarPhone
}

public final class AudioPlayStatusView: UIView {
    fileprivate var iconImagaView: UIImageView = .init(image: nil)
    fileprivate var noticeLabel: UILabel = .init()
    fileprivate var cancelButton: UIButton!

    fileprivate struct PlayStatusNoticeText {
        static var lowVolume: String {
            return BundleI18n.LarkMessageCore.Lark_Legacy_AudioPlayStatusLowVolume
        }
        static var speaker: String {
            return BundleI18n.LarkMessageCore.Lark_Legacy_AudioPlayStatusSpeaker
        }
        static var earPhone: String {
            return BundleI18n.LarkMessageCore.Lark_Legacy_Tipreceiver
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.functionInfoFillSolid02

        let iconImagaView = UIImageView()
        iconImagaView.tintColor = UIColor.ud.functionInfoContentDefault
        self.addSubview(iconImagaView)
        self.iconImagaView = iconImagaView
        iconImagaView.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }

        let noticeLabel = UILabel()
        noticeLabel.textColor = UIColor.ud.textTitle
        noticeLabel.textAlignment = .left
        noticeLabel.font = UIFont.systemFont(ofSize: 14)
        self.addSubview(noticeLabel)
        self.noticeLabel = noticeLabel
        noticeLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.iconImagaView.snp.right).offset(10)
        }

        let cancelButton = UIButton()
        cancelButton.setImage(Resources.close_notice, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.tintColor = UIColor.ud.iconN2
        self.cancelButton = cancelButton
        self.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (make) in
            make.right.equalTo(-15)
            make.width.height.equalTo(15)
            make.centerY.equalToSuperview()
            make.left.equalTo(self.noticeLabel.snp.right).offset(10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    fileprivate func cancelButtonTapped() {
        self.removeFromSuperview()
    }

    func showNoticeViewWithStatus(_ status: AudioPlayStatus, text: String?) {
        switch status {
        case .audioLowVolume:
            self.iconImagaView.image = Resources.mute_voice.withRenderingMode(.alwaysTemplate)
            self.noticeLabel.text = text ?? PlayStatusNoticeText.lowVolume
        case .audioSpeaker:
            self.iconImagaView.image = Resources.speaker_voice.withRenderingMode(.alwaysTemplate)
            self.noticeLabel.text = text ?? PlayStatusNoticeText.speaker
        case .audioEarPhone:
            self.iconImagaView.image = Resources.earphone_voice.withRenderingMode(.alwaysTemplate)
            self.noticeLabel.text = text ?? PlayStatusNoticeText.earPhone
        }
    }
}

extension AudioPlayStatusView {

    static let statusViewTag = 999_888

    /// 显示提示信息
    ///
    /// - Parameters:
    ///   - status: 听筒提示/扬声器提示/音量过低提示
    ///   - autoDissmiss: 提示信息是否自动消失
    ///   - duration: 显示时间, autoDissmiss == true 则自动消息
    class func showAudioPlayStatusOnView(_ view: UIView, status: AudioPlayStatus, autoDissmiss: Bool = true, duration: Int = 3) {
        let mainThread: (@escaping () -> Void) -> Void = { (block) in
            if Thread.isMainThread {
                block()
            } else {
                DispatchQueue.main.async {
                    block()
                }
            }
        }

        mainThread {
            if let view = view.viewWithTag(statusViewTag) {
                view.removeFromSuperview()
            }

            let noticeView = AudioPlayStatusView()
            noticeView.tag = statusViewTag
            noticeView.showNoticeViewWithStatus(status, text: nil)
            view.addSubview(noticeView)
            noticeView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(44)

                /// 首先判断外部是否已经设置了 top margin
                /// 如果没有则进行如下判断：
                /// 预期是想 StatusView 能出现在NavigationBar下方。而传入的view可能已经是在NavigationBar下发的情况。所以这里做一个判断
                /// view.frame.origin.y的位置
                if let topMargin = view.audioPlayStatusViewTopMarigin {
                    make.top.equalToSuperview().inset(topMargin)
                } else if view.frame.origin.y != 0 {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(44)
                }
            }

            /// dismiss
            if autoDissmiss {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
                    noticeView.removeFromSuperview()
                }
            }
        }
    }

    public class func hideAudioPlayStatusOn(view: UIView) {
        guard let view = view.viewWithTag(statusViewTag) else {
            return
        }
        view.removeFromSuperview()
    }

    public class func setAudioPlayStatusTopMargin(_ topMargin: CGFloat?, view: UIView) {
        view.audioPlayStatusViewTopMarigin = topMargin ?? 0
    }
}

// 设置 StatusView 距离 super view 的 top margin
fileprivate extension UIView {
    struct AssociatedKeys {
        static var key = "AudioPlayStatusView_key"
    }

    var audioPlayStatusViewTopMarigin: CGFloat? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.key) as? CGFloat
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

public class AudioPlayUtil {
    public static func showPlayStatusOnView(_ view: UIView, status: AudioPlayStatus) {
        DispatchQueue.main.async {
            switch status {
            case .audioLowVolume:
                UDToast.showCustom(with: BundleI18n.LarkMessageCore.Lark_Legacy_AudioPlayStatusLowVolume, icon: Resources.mute_voice.withRenderingMode(.alwaysTemplate), on: view)
            case .audioSpeaker:
                UDToast.showCustom(with: BundleI18n.LarkMessageCore.Lark_IM_PlayingThroughSpeaker_Toast, icon: Resources.speaker_voice.withRenderingMode(.alwaysTemplate), on: view)
            case .audioEarPhone:
                UDToast.showCustom(with: BundleI18n.LarkMessageCore.Lark_IM_PlayingThroughReceiver_Toast, icon: Resources.earphone_voice.withRenderingMode(.alwaysTemplate), on: view)
            }
        }
    }
}
