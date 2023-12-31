//
//  PreviewDeviceView.swift
//  ByteView
//
//  Created by kiri on 2022/5/19.
//

import Foundation
import UIKit
import SnapKit
import ByteViewUI

/// 设置条，mic | camera | speaker
final class PreviewDeviceView: PreviewChildView {
    enum Layout {
        static let normalMicRatio: CGFloat = 1.0
        static let longMicRatio: CGFloat = 9.0 / 8.0
    }

    enum Style {
        case system
        case noConnect
        case callMe
        case room
        case webinarAttendee
    }

    var style: Style = .system {
        didSet {
            guard style != oldValue else { return }
            updateLayout()
        }
    }

    var isHorizontalStyle: Bool = false {
        didSet {
            guard isHorizontalStyle != oldValue else { return }
            micView.isHorizontalStyle = isHorizontalStyle
            cameraView.isHorizontalStyle = isHorizontalStyle
            speakerView.isHorizontalStyle = isHorizontalStyle
        }
    }

    var isLongMic: Bool = true {
        didSet {
            guard isLongMic != oldValue else { return }
            micView.shouldShowSwitchAudio = isLongMic
            updateLayout()
        }
    }

    private let contentLayoutGuide: UILayoutGuide = UILayoutGuide()

    private(set) lazy var micView = PreviewMicrophoneView(frame: .zero)
    private(set) lazy var cameraView = PreviewCameraView(frame: .zero)

    private(set) lazy var speakerView = PreviewSpeakerView(frame: .zero)
    private var minBtnWidth: CGFloat { Display.pad && VCScene.isLandscape && VCScene.isRegular ? 136 : 108 }

    init() {
        super.init(frame: .zero)
        addLayoutGuide(contentLayoutGuide)
        addSubview(micView)
        addSubview(cameraView)
        addSubview(speakerView)
        contentLayoutGuide.snp.makeConstraints { make in
            make.center.top.bottom.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        updateLayout()
    }

    func updateLayout() {
        micView.isHidden = [.webinarAttendee, .room].contains(style)
        cameraView.isHidden = style == .webinarAttendee
        speakerView.isHidden = style == .noConnect || style == .callMe || style == .room

        removeAllConstraints()

        if VCScene.isRegular, VCScene.isLandscape {
            updateLandscapeRegular()
        } else {
            switch style {
            case .noConnect, .callMe:
                let width = micView.btnTitle.vc.boundingWidth(height: 18, config: .tinyAssist) + 16 + 0.5
                micView.snp.remakeConstraints { make in
                    make.left.top.bottom.equalTo(contentLayoutGuide)
                    // 上图下字btn自适应的contentRect width给的偏大，故这里自己计算
                    if !isHorizontalStyle, width > minBtnWidth {
                        make.width.equalTo(width)
                    } else {
                        make.width.greaterThanOrEqualTo(minBtnWidth)
                    }
                }
                cameraView.snp.remakeConstraints { make in
                    make.top.bottom.right.equalTo(contentLayoutGuide)
                    make.left.equalTo(micView.snp.right).offset(12)
                    make.width.greaterThanOrEqualTo(minBtnWidth)
                }
            case .room:
                cameraView.snp.remakeConstraints { make in
                    make.edges.equalTo(contentLayoutGuide)
                    make.width.greaterThanOrEqualTo(minBtnWidth)
                }
            case .webinarAttendee:
                speakerView.snp.remakeConstraints { make in
                    make.edges.equalTo(contentLayoutGuide)
                    make.width.greaterThanOrEqualTo(minBtnWidth)
                }
            default:
                micView.snp.remakeConstraints { make in
                    make.top.bottom.left.equalToSuperview()
                    make.width.equalTo(speakerView).multipliedBy(isLongMic ? Layout.longMicRatio : Layout.normalMicRatio)
                }
                cameraView.snp.remakeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.left.equalTo(micView.snp.right).offset(12)
                    make.width.equalTo(speakerView)
                }
                speakerView.snp.remakeConstraints { make in
                    make.top.bottom.right.equalToSuperview()
                    make.left.equalTo(cameraView.snp.right).offset(12)
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateLandscapeRegular() {
        switch style {
        case .noConnect, .callMe:
            micView.snp.remakeConstraints { make in
                make.top.bottom.left.equalToSuperview()
                make.width.greaterThanOrEqualTo(minBtnWidth)
            }
            cameraView.snp.remakeConstraints { make in
                make.top.bottom.right.equalToSuperview()
                make.left.equalTo(micView.snp.right).offset(12)
                make.width.greaterThanOrEqualTo(minBtnWidth)
            }
        case .room:
            cameraView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
                make.width.greaterThanOrEqualTo(minBtnWidth)
            }
        case .webinarAttendee:
            speakerView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
                make.width.greaterThanOrEqualTo(minBtnWidth)
            }
        default:
            micView.snp.remakeConstraints { make in
                make.top.bottom.left.equalToSuperview()
                make.width.greaterThanOrEqualTo(minBtnWidth)
            }
            cameraView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(micView.snp.right).offset(12)
                make.width.greaterThanOrEqualTo(minBtnWidth)
            }
            speakerView.snp.remakeConstraints { make in
                make.top.bottom.right.equalToSuperview()
                make.left.equalTo(cameraView.snp.right).offset(12)
                make.width.greaterThanOrEqualTo(minBtnWidth)
            }
        }
    }

    private func removeAllConstraints() {
        for v in [micView, cameraView, speakerView] {
            v.snp.removeConstraints()
        }
    }
}
