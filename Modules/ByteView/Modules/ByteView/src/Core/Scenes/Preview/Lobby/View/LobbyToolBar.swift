//
//  LobbyToolBar.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/6/13.
//

import Foundation
import UniverseDesignIcon
import ByteViewUI

class LobbyToolBar: UIView {

    struct Layout {
        static let phoneIconSize = CGSize(width: 22, height: 22)
        static let padIconSize = CGSize(width: 20, height: 20)
        static let padSpeakerHandupSize = CGSize(width: 40, height: 40)

        static let padLeftRightPadding: CGFloat = 20
        static let padSpacing: CGFloat = 16
    }

    let containerView = UIView()

    lazy var micItemView = LobbyToolBarItemView()
    lazy var cameraItemView = LobbyToolBarItemView()
    lazy var speakerItemView = LobbyToolBarItemView()

    private(set) lazy var hangupButton: UIButton = {
        var btn = UIButton()
        btn.isExclusiveTouch = true
        btn.vc.setBackgroundColor(UIColor.ud.functionDangerFillDefault, for: .normal)
        btn.vc.setBackgroundColor(UIColor.ud.functionDangerFillPressed, for: .highlighted)
        let image = UDIcon.getIconByKey(.callEndFilled, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 20, height: 20))
        btn.setImage(image, for: .normal)
        btn.setImage(image, for: .highlighted)
        btn.layer.cornerRadius = 8
        btn.layer.masksToBounds = true
        return btn
    }()

    var isSpeakerItemHidden: Bool = false {
        didSet {
            if oldValue != isSpeakerItemHidden {
                updateSpeakerItemVisibility()
            }
        }
    }

    let isCamMicHidden: Bool

    init(isCamMicHidden: Bool, output: AudioOutputManager?) {
        self.isCamMicHidden = isCamMicHidden
        super.init(frame: .zero)
        self.setupView()
        self.updateAudioOutput(output)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.clear
        addSubview(containerView)
        if !isCamMicHidden {
            containerView.addSubview(micItemView)
            containerView.addSubview(cameraItemView)
        }
        containerView.addSubview(speakerItemView)
        containerView.addSubview(hangupButton)

        micItemView.title = I18n.View_G_MicAbbreviated
        cameraItemView.title = I18n.View_VM_Camera

        if Display.phone {
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            if !isCamMicHidden {
                micItemView.style = .phone
                micItemView.image = UDIcon.getIconByKey(.micFilled, iconColor: .ud.iconN1, size: Layout.phoneIconSize)
                micItemView.titleColor = UIColor.ud.textCaption
                micItemView.snp.makeConstraints { make in
                    make.top.bottom.left.equalToSuperview()
                }

                cameraItemView.style = .phone
                cameraItemView.image = UDIcon.getIconByKey(.videoFilled, iconColor: .ud.iconN1, size: Layout.phoneIconSize)
                cameraItemView.titleColor = UIColor.ud.textCaption
                cameraItemView.snp.makeConstraints { make in
                    make.left.equalTo(micItemView.snp.right)
                    make.top.bottom.equalTo(micItemView)
                    make.width.equalTo(micItemView)
                }
            }

            speakerItemView.style = .phone
            speakerItemView.snp.makeConstraints { make in
                if isCamMicHidden {
                    make.top.bottom.left.equalToSuperview()
                } else {
                    make.left.equalTo(cameraItemView.snp.right)
                    make.top.bottom.equalTo(micItemView)
                    make.width.equalTo(micItemView)
                }
                make.right.equalToSuperview()
            }

            hangupButton.isHidden = true
        } else {
            containerView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            if !isCamMicHidden {
                micItemView.style = .padExpand
                micItemView.image = UDIcon.getIconByKey(.micFilled, iconColor: .ud.iconN2, size: Layout.padIconSize)
                micItemView.titleColor = UIColor.ud.textTitle
                micItemView.snp.makeConstraints { make in
                    make.left.top.bottom.equalToSuperview()
                }

                cameraItemView.style = .padExpand
                cameraItemView.image = UDIcon.getIconByKey(.cameraFilled, iconColor: .ud.iconN2, size: Layout.padIconSize)
                cameraItemView.titleColor = UIColor.ud.textTitle
                cameraItemView.snp.makeConstraints { make in
                    make.left.equalTo(micItemView.snp.right).offset(Layout.padSpacing)
                    make.centerY.equalTo(micItemView)
                }
            }

            speakerItemView.style = .padExpand
            speakerItemView.snp.makeConstraints { make in
                if isCamMicHidden {
                    make.left.top.bottom.equalToSuperview()
                } else {
                    make.left.equalTo(cameraItemView.snp.right).offset(Layout.padSpacing)
                    make.centerY.equalTo(micItemView)
                }
            }

            hangupButton.isHidden = false
            updateHangupButton()
        }
    }

    func updatePadLayout() {
        guard Display.pad else { return }
        let sceneWidth = VCScene.bounds.width
        var widths = [Layout.padSpeakerHandupSize.width]
        if !isCamMicHidden {
            widths.append(micItemView.calTotalWidth(.padExpand))
            widths.append(cameraItemView.calTotalWidth(.padExpand))
        }
        if !isSpeakerItemHidden {
            widths.append(speakerItemView.calTotalWidth(.padExpand))
        }
        let itemWidth = 2 * Layout.padLeftRightPadding + widths.reduce(0, +) + CGFloat(widths.count - 1) * Layout.padSpacing

        if sceneWidth < itemWidth {
            micItemView.style = .padCollapse
            cameraItemView.style = .padCollapse
            speakerItemView.style = .padCollapse
        } else {
            micItemView.style = .padExpand
            cameraItemView.style = .padExpand
            speakerItemView.style = .padExpand
        }
        updateHangupButton()
    }

    private func updateHangupButton() {
        hangupButton.snp.remakeConstraints { make in
            make.size.equalTo(Layout.padSpeakerHandupSize)
            if !speakerItemView.isHidden {
                make.left.equalTo(speakerItemView.snp.right).offset(Layout.padSpacing)
            } else if !cameraItemView.isHidden {
                make.left.equalTo(cameraItemView.snp.right).offset(Layout.padSpacing)
            } else {
                make.left.equalTo(micItemView.snp.right).offset(Layout.padSpacing)
            }
            make.right.equalToSuperview()
            make.centerY.equalTo(speakerItemView)
        }
    }

    private func updateSpeakerItemVisibility() {
        speakerItemView.isHidden = isSpeakerItemHidden
        if Display.phone && !isCamMicHidden {
            if isSpeakerItemHidden {
                cameraItemView.snp.remakeConstraints { make in
                    make.left.equalTo(micItemView.snp.right)
                    make.top.bottom.equalTo(micItemView)
                    make.right.equalToSuperview()
                    make.width.equalTo(micItemView)
                }
            } else {
                cameraItemView.snp.remakeConstraints { make in
                    make.left.equalTo(micItemView.snp.right)
                    make.top.bottom.equalTo(micItemView)
                    make.width.equalTo(micItemView)
                }
            }
        } else {
            updatePadLayout()
        }
    }

    private var helper = PreviewSpeakerIconHelper(normalColor: Display.phone ? .ud.iconN1 : .ud.iconN2)

    func updateAudioOutput(_ output: AudioOutputManager?) {
        guard let output = output else { return }

        let images = helper.image(for: output)
        if output.isPadMicSpeakerDisabled {
            speakerItemView.button.isEnabled = false
            speakerItemView.titleColor = UIColor.ud.textDisabled
            speakerItemView.imageView.image = images.disabled
        } else {
            speakerItemView.button.isEnabled = !Util.isiOSAppOnMacSystem
            speakerItemView.titleColor = Display.phone ? UIColor.ud.textCaption : UIColor.ud.textTitle
            speakerItemView.imageView.image = images.normal
        }

        let title = helper.buttonTitle(audioOutput: output)
        if title != speakerItemView.title {
            speakerItemView.title = title
            updatePadLayout()
        }
    }
}
