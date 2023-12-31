//
//  RadiusView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

final class GestureView: UIView {
    var longGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
    var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    private let icon: UIImageView = UIImageView()
    private let isRadius: Bool

    enum Cons {
        static let RadiusSide: CGFloat = 108
        static let iconSide: CGFloat = 32

        static let smallRadiusSize: CGFloat = 88
        static let smallIconSide: CGFloat = 24

        static let squareLayer: CGFloat = 8
        static let squareIconSize: CGFloat = 22
        static let squareHeight: CGFloat = 48
        static let squareSpacing: CGFloat = 8
    }

    enum RadiusGestureState {
        case `default`
        case audioUnpressed
        case audioPressing
        case audioCancel
        case textIdle
        case textPressedRecording
        case textTapRecording
        case textEnd
        case audioWithTextUnpressed
        case audioWithTextPressing
    }

    var gestureState: RadiusGestureState = .default {
        didSet {
            switch gestureState {
            case .default: break
                // 语音加文字
            case .audioWithTextUnpressed:
                self.backgroundColor = UDColor.primaryContentDefault
                icon.image = UDIcon.voice2textCnOutlined.ud.withTintColor(UIColor.ud.staticWhite)
            case .audioWithTextPressing:
                self.backgroundColor = UDColor.functionInfoContentPressed
                icon.image = UDIcon.voice2textCnOutlined.ud.withTintColor(UIColor.ud.staticWhite)

                // 录音
            case .audioUnpressed:
                self.backgroundColor = UDColor.primaryContentDefault
                icon.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.staticWhite)
            case .audioPressing:
                self.backgroundColor = UDColor.functionInfoContentPressed
                icon.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.staticWhite)
            case .audioCancel:
                self.backgroundColor = UDColor.bgBody
                icon.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.functionInfoContentDefault)

                // 语音转文字
            case .textIdle:
                self.backgroundColor = UDColor.primaryContentDefault
                icon.image = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.staticWhite)
                if isRadius {
                    self.layer.cornerRadius = Cons.RadiusSide / 2
                    icon.snp.updateConstraints { make in
                        make.size.equalTo(Cons.iconSide)
                    }
                }
            case .textPressedRecording:
                self.backgroundColor = UDColor.functionInfoContentPressed
                icon.image = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.staticWhite)
                if isRadius {
                    self.layer.cornerRadius = Cons.RadiusSide / 2
                    icon.snp.updateConstraints { make in
                        make.size.equalTo(Cons.iconSide)
                    }
                }
            case .textTapRecording:
                self.backgroundColor = UDColor.functionInfoContentPressed
                icon.image = UDIcon.pauseFilled.ud.withTintColor(UIColor.ud.staticWhite)
                if isRadius {
                    self.layer.cornerRadius = Cons.RadiusSide / 2
                    icon.snp.updateConstraints { make in
                        make.size.equalTo(Cons.iconSide)
                    }
                }
            case .textEnd:
                self.backgroundColor = UDColor.primaryContentDefault
                icon.image = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.staticWhite)
                if isRadius {
                    self.layer.cornerRadius = Cons.smallRadiusSize / 2
                    icon.snp.updateConstraints { make in
                        make.size.equalTo(Cons.smallIconSide)
                    }
                }
            }
        }
    }

    init(isRadius: Bool) {
        self.isRadius = isRadius
        super.init(frame: .zero)
        self.addSubview(icon)
        longGesture.minimumPressDuration = 0.1
        self.addGestureRecognizer(longGesture)
        self.addGestureRecognizer(tapGesture)
        if isRadius {
            self.layer.cornerRadius = Cons.RadiusSide / 2
            icon.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(Cons.iconSide)
            }
        } else {
            self.layer.cornerRadius = Cons.squareLayer
            icon.snp.makeConstraints { make in
                make.width.height.equalTo(Cons.squareIconSize)
                make.center.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
