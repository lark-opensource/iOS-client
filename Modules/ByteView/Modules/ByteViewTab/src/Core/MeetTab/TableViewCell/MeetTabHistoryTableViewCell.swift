//
//  MeetTabHistoryTableViewCell.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignIcon
import UniverseDesignTheme
import UIKit
import ByteViewUI
import ByteViewCommon

class MeetTabHistoryTableViewCell: MeetTabBaseTableViewCell {

    lazy var iconStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [docIcon, linkIcon])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }()
    lazy var docIcon = UIImageView(image: UDIcon.getIconByKey(.spaceFilled, iconColor: .ud.colorfulBlue.dynamicColor, size: CGSize(width: 14, height: 14)))
    lazy var linkIcon = UIImageView(image: UDIcon.getIconByKey(.likeFilled, iconColor: .ud.colorfulBlue.dynamicColor, size: CGSize(width: 14, height: 14)))

    var iconLinedView: UIView?
    var tagLinedView: UIView?

    lazy var previewView = FilePreviewView(frame: .zero)

    lazy var row2TagStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [row2WebinarLabel, row2ExternalLabel])
        stackView.spacing = 6
        stackView.axis = .horizontal
        stackView.isHidden = true
        return stackView
    }()

    lazy var row2WebinarLabel: UILabel = {
        let webinarLabel = PaddingLabel()
        webinarLabel.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        webinarLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        webinarLabel.attributedText = .init(string: I18n.View_G_Webinar, config: .assist, alignment: .center, lineBreakMode: .byWordWrapping, textColor: UIColor.ud.udtokenTagTextSBlue)
        webinarLabel.layer.cornerRadius = 4.0
        webinarLabel.layer.masksToBounds = true
        webinarLabel.backgroundColor = UIColor.ud.udtokenTagBgBlue
        webinarLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        webinarLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
        webinarLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return webinarLabel
    }()

    lazy var row2ExternalLabel: UILabel = {
        let externalLabel = PaddingLabel()
        externalLabel.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        externalLabel.isHidden = true
        externalLabel.textColor = UIColor.ud.udtokenTagTextSBlue
        externalLabel.attributedText = .init(string: I18n.View_G_ExternalLabel, config: .assist, alignment: .center)
        externalLabel.layer.cornerRadius = 4.0
        externalLabel.layer.masksToBounds = true
        externalLabel.backgroundColor = UIColor.ud.udtokenTagBgBlue
        externalLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        externalLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
        externalLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return externalLabel
    }()

    lazy var collectionTagView: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        label.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    lazy var collectionPadTagView: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        label.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    private var imageRequest: ImageRequest?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentStackView.insertArrangedSubview(previewView, aboveArrangedSubview: iconView)
        previewView.snp.makeConstraints {
            if Display.pad {
                $0.width.equalTo(96.0)
                $0.height.equalTo(54.0).priority(.high)
            } else {
                $0.width.equalTo(115.0)
                $0.height.equalTo(66.0).priority(.high)
            }
            $0.top.bottom.equalToSuperview().inset(10.0).priority(.low)
        }
        if Display.pad {
            previewView.iconDimension = 24.0
        } else {
            previewView.iconDimension = 30.0
        }
        iconView.isHidden = true

        iconLinedView = descStackView.addSeparatedSubview(iconStackView)
        iconLinedView?.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
        }
        [docIcon, linkIcon].forEach {
            $0.snp.makeConstraints { (make) in
                make.width.height.equalTo(14.0)
            }
        }

        containerView.addSubview(row2TagStackView)
        row2TagStackView.snp.makeConstraints {
            $0.left.equalTo(titleStackView)
            $0.right.lessThanOrEqualToSuperview()
            $0.top.equalTo(titleStackView.snp.bottom).offset(2.0)
            $0.height.equalTo(0)
        }

        tagLinedView = descStackView.addSeparatedSubview(collectionPadTagView)
        tagLinedView?.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
        }

        containerView.addSubview(collectionTagView)
        collectionTagView.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.top.equalTo(descStackView.snp.bottom).offset(4.0)
            $0.height.equalTo(16.0)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageRequest?.cancel()
        previewView.reset()
    }

    override func bindTo(viewModel: MeetTabCellViewModel) {
        guard let viewModel = viewModel as? MeetTabMeetCellViewModel else {
            return
        }

//      同步LM和DM
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.userInterfaceStyle
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }

        var callCount: NSAttributedString?
        if viewModel.isAggregated {
            callCount = .init(string: viewModel.callCountText, config: .body, textColor: viewModel.topicColor)
        }
        let topic = NSAttributedString(string: viewModel.topic, config: .body, lineBreakMode: .byTruncatingTail, textColor: viewModel.topicColor)
        configTitle(topic: topic,
                    callCount: callCount,
                    tagType: viewModel.meetingTagType,
                    webinarMeeting: viewModel.isWebinar)
        let isRegular = MeetTabTraitCollectionManager.shared.isRegular
        let config: VCFontConfig = isRegular ? .tinyAssist : .bodyAssist
        let textColor: UIColor = isRegular ? .ud.textCaption : .ud.textPlaceholder
        timeLabel.attributedText = .init(string: viewModel.timing, config: config, textColor: textColor)

        disposeBag = DisposeBag()
        viewModel.meetingTagTypeRelay.asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] tagType in
                self?.configTitle(topic: topic,
                                  callCount: callCount,
                                  tagType: tagType,
                                  webinarMeeting: viewModel.isWebinar)
            })
            .disposed(by: disposeBag)

        let isDocHidden = viewModel.isIconHidden(with: .msCcm) && viewModel.isIconHidden(with: .notes)
        let isLinkHidden = viewModel.isIconHidden(with: .msURL)

        docIcon.isHidden = isDocHidden
        linkIcon.isHidden = isLinkHidden
        let isIconViewHidden = isDocHidden && isLinkHidden
        descStackView.setSubviewHidden(for: iconLinedView, hidden: isIconViewHidden)

        if let url = viewModel.coverUrl {
            imageRequest = previewView.vc.setImage(url: url, accessToken: viewModel.accessToken, placeholder: viewModel.previewBgImage)
        } else {
            previewView.image = viewModel.previewBgImage
        }
        previewView.previewIconView.image = viewModel.previewImage
        previewView.previewBadgeView.backgroundColor = viewModel.previewBadgeShadowColor
        previewView.previewBadgeView.iconView.image = viewModel.previewBadgeImage
        previewView.previewBadgeView.showIcon = viewModel.previewBadgeImage != nil
        previewView.previewBadgeView.showLabel = viewModel.minutesNumber > 1
        previewView.showBadge = previewView.previewBadgeView.showIcon || previewView.previewBadgeView.showLabel
        previewView.previewBadgeView.text = "\(viewModel.minutesNumber)"

        let isCollectionTagHidden = !viewModel.hasCollectionInfo
        [collectionTagView, collectionPadTagView].forEach {
            $0.attributedText = .init(string: viewModel.collectionTag, config: .boldTiniestAssist, textColor: UIColor.ud.textCaption)
        }
        collectionTagView.isHidden = isCollectionTagHidden || Display.pad
        collectionPadTagView.isHidden = isCollectionTagHidden || Display.phone
        tagLinedView?.isHidden = collectionPadTagView.isHidden

        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configTitle(topic: NSAttributedString, callCount: NSAttributedString?, tagType: MeetingTagType, webinarMeeting: Bool) {
        meetingTagType = tagType
        isWebinarMeeting = webinarMeeting

        topicLabel.attributedText = topic
        callCountLabel.isHidden = (callCount == nil)
        webinarLabel.isHidden = !isWebinarMeeting
        row2WebinarLabel.isHidden = !isWebinarMeeting
        externalLabel.isHidden = !meetingTagType.hasTag
        row2ExternalLabel.isHidden = !meetingTagType.hasTag
        if let tagText = meetingTagType.text {
            externalLabel.attributedText = .init(string: tagText, config: .assist, alignment: .center, lineBreakMode: .byWordWrapping)
            row2ExternalLabel.attributedText = .init(string: tagText, config: .assist, alignment: .center, lineBreakMode: .byWordWrapping)
        }

        if let callCount = callCount {
            callCountLabel.attributedText = callCount
        }

        let isRegular = MeetTabTraitCollectionManager.shared.isRegular

        if isRegular {
            row2TagStackView.isHidden = true
            if isWebinarMeeting || meetingTagType.hasTag {
                tagStackView.isHidden = false
            } else {
                tagStackView.isHidden = true
            }
        } else {
            if isWebinarMeeting {
                row2TagStackView.isHidden = false
                tagStackView.isHidden = true
            } else {
                row2TagStackView.isHidden = true
                if meetingTagType.hasTag {
                    tagStackView.isHidden = false
                } else {
                    tagStackView.isHidden = true
                }
            }
        }
    }

    override func updateCompactLayout() {
        super.updateCompactLayout()
        if isWebinarMeeting {
            containerView.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview().inset(10.0)
            }
            row2TagStackView.snp.remakeConstraints {
                $0.left.equalTo(titleStackView)
                $0.right.lessThanOrEqualToSuperview()
                $0.top.equalTo(titleStackView.snp.bottom).offset(2.0)
                $0.height.equalTo(18)
            }
            descStackView.snp.remakeConstraints {
                $0.left.equalTo(titleStackView)
                $0.right.lessThanOrEqualToSuperview()
                descStackViewTopConstaint = $0.top.equalTo(row2TagStackView.snp.bottom).offset(4.0).priority(.low).constraint
                $0.height.equalTo(20.0).priority(.low)
                $0.bottom.equalTo(extStackView.snp.top)
            }
            descStackViewTopConstaint?.update(offset: 4.0)
        } else {
            descStackView.snp.remakeConstraints {
                $0.left.equalTo(titleStackView)
                $0.right.lessThanOrEqualToSuperview()
                descStackViewTopConstaint = $0.top.equalTo(titleStackView.snp.bottom).offset(4.0).priority(.low).constraint
                $0.height.equalTo(20.0).priority(.low)
                $0.bottom.equalTo(extStackView.snp.top)
            }
            if Display.pad {
                containerView.snp.remakeConstraints {
                    $0.top.bottom.equalToSuperview().inset(15.0)
                }
                descStackViewTopConstaint?.update(offset: 8.0)
            } else if collectionTagView.isHidden {
                containerView.snp.remakeConstraints {
                    $0.top.bottom.equalToSuperview().inset(16.0)
                }
                descStackViewTopConstaint?.update(offset: 12.0)
            } else {
                containerView.snp.remakeConstraints {
                    $0.top.bottom.equalToSuperview().inset(10.0)
                }
                descStackViewTopConstaint?.update(offset: 4.0)
            }
        }
    }

    override func updateRegularLayout() {
        super.updateRegularLayout()
        containerView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview().inset(17.0)
        }
        descStackView.snp.remakeConstraints {
            $0.left.equalTo(titleStackView)
            $0.right.lessThanOrEqualToSuperview()
            descStackViewTopConstaint = $0.top.equalTo(titleStackView.snp.bottom).offset(4.0).priority(.low).constraint
            $0.height.equalTo(20.0).priority(.low)
            $0.bottom.equalTo(extStackView.snp.top)
        }
        descStackViewTopConstaint?.update(offset: 4.0)
    }
}
