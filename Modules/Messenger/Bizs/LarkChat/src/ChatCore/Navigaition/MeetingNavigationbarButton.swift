//
//  MeetingNavigationbarButton.swift
//  Action
//
//  Created by Prontera on 2019/8/5.
//

import Foundation
import UIKit
import Lottie
import RxSwift
import SnapKit

public enum MeetingNavigationbarButtonStyle {
    case light, dark
}

public final class MeetingNavigationbarButton: UIButton {

    init(tintColor: UIColor?, disableTintColor: UIColor?, inMeetingTintColor: UIColor?, style: MeetingNavigationbarButtonStyle = .light) {
        self.meetingTintColor = tintColor
        self.unableJoinTintColor = disableTintColor
        self.inMeetingTintColor = inMeetingTintColor
        self.unableJoin = false
        self.isInMeeting = false
        self.style = style
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var isInMeeting: Bool {
        didSet {
            updateImageViews()
        }
    }

    public var unableJoin: Bool {
        didSet {
            updateImageViews()
        }
    }

    var meetingTintColor: UIColor? {
        didSet {
            if let image = noMeetingImageView.image {
                noMeetingImageView.image = image.chatTintColor(meetingTintColor)
            }
        }
    }
    private var unableJoinTintColor: UIColor?
    private var inMeetingTintColor: UIColor?
    private var style: MeetingNavigationbarButtonStyle

    struct Layout {
        static let buttonSize = CGSize(width: 24, height: 24)
    }

    private func setUpUI() {
        addSubview(noMeetingImageView)
        addSubview(unableJoinImageView)
        addSubview(inMeetingImageView)
    }

    lazy private var noMeetingImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.meeting_end_large.chatTintColor(meetingTintColor))
        imageView.isHidden = isInMeeting || unableJoin
        return imageView
    }()

    lazy private var unableJoinImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.meeting_end_large.chatTintColor(unableJoinTintColor))
        imageView.isHidden = isInMeeting || !unableJoin
        return imageView
    }()

    lazy private var inMeetingImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.meeting_ing.chatTintColor(inMeetingTintColor))
        imageView.isHidden = !isInMeeting
        return imageView
    }()

    private func updateImageViews() {
        noMeetingImageView.isHidden = isInMeeting || unableJoin
        unableJoinImageView.isHidden = isInMeeting || !unableJoin
        inMeetingImageView.isHidden = !isInMeeting
    }
}

private extension UIImage {
    func chatTintColor(_ color: UIColor?) -> UIImage? {
        if let tintColor = color {
            let tintImage = self.ud.withTintColor(tintColor, renderingMode: .alwaysOriginal)
            return tintImage
        }
        return self
    }
}
