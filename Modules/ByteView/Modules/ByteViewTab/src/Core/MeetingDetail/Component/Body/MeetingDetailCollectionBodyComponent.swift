//
//  MeetingDetailCollectionBodyComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewTracker
import ByteViewCommon
import ByteViewUI

class MeetingDetailCollectionBodyComponent: MeetingDetailComponent {

    let containerView = UIView()

    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.image = UDIcon.getIconByKey(.arrangeFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 18, height: 18))
        return iconView
    }()

    lazy var indexTitle: UILabel = {
        let indexTitle = UILabel()
        indexTitle.attributedText = .init(string: I18n.View_G_HistoryMeetCollection,
                                          config: .boldBodyAssist,
                                          textColor: UIColor.ud.textPlaceholder)
        return indexTitle
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.numberOfTapsRequired = 1
        tapGesture.addTarget(self, action: #selector(didClickSubtitleButton))
        titleLabel.addGestureRecognizer(tapGesture)
        return titleLabel
    }()

    lazy var subtitleButton: VisualButton = {
        let subtitleButton = VisualButton()
        subtitleButton.edgeInsetStyle = .right
        subtitleButton.space = 4
        subtitleButton.setImage(UDIcon.getIconByKey(.rightSmallCcmOutlined, iconColor: UIColor.ud.textPlaceholder, size: CGSize(width: 16, height: 16)), for: .normal)
        subtitleButton.addTarget(self, action: #selector(didClickSubtitleButton), for: .touchUpInside)
        return subtitleButton
    }()

    override func setupViews() {
        super.setupViews()

        addSubview(containerView)
        containerView.addSubview(indexTitle)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleButton)

        let isRegular = Util.rootTraitCollection?.horizontalSizeClass == .regular
        containerView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(isRegular ? 28.0 : 16.0)
            $0.top.equalToSuperview().inset(24.0)
            $0.height.greaterThanOrEqualTo(48.0)
            $0.bottom.equalToSuperview()
        }

        indexTitle.snp.makeConstraints {
            $0.left.top.equalToSuperview()
            $0.height.equalTo(20.0)
        }

        iconView.snp.makeConstraints {
            $0.top.equalTo(indexTitle.snp.bottom).offset(9.0)
            $0.left.equalToSuperview()
            $0.width.height.equalTo(18.0)
        }

        titleLabel.snp.makeConstraints {
            $0.left.equalTo(iconView.snp.right).offset(8.0)
            $0.centerY.equalTo(iconView)
        }

        subtitleButton.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.right).offset(8.0)
            $0.centerY.equalTo(iconView)
            $0.right.lessThanOrEqualToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.collections.addObserver(self)
    }

    override var shouldShow: Bool {
        viewModel?.collections.value?.isEmpty == false && viewModel?.source != .collection
    }

    override func updateViews() {
        super.updateViews()
        guard let collection = viewModel?.collections.value?.first else {
            return
        }
        titleLabel.attributedText = .init(string: collection.titleContent,
                                          config: .bodyAssist,
                                          alignment: .left,
                                          lineBreakMode: .byTruncatingTail,
                                          textColor: UIColor.ud.textTitle)
        subtitleButton.setAttributedTitle(.init(string: I18n.View_G_NumberMeetings(collection.totalCount),
                                                config: .bodyAssist,
                                                alignment: .left,
                                                lineBreakMode: .byTruncatingTail,
                                                textColor: UIColor.ud.textPlaceholder),
                                          for: .normal)
    }

    @objc func didClickSubtitleButton() {
        guard let viewModel = viewModel,
              let hostViewController = viewModel.hostViewController,
              let collection = viewModel.collections.value?.first else { return }
        MeetTabTracks.trackMeetTabDetailOperation(.clickRecordCollection, meetingID: viewModel.meetingID)
        let vm = MeetingCollectionViewModel(tabViewModel: viewModel.tabViewModel, collection: collection)
        let vc = MeetingCollectionViewController(viewModel: vm)
        if Display.pad {
            if let from = hostViewController.presentingViewController as? UINavigationController {
                hostViewController.dismiss(animated: true)
                from.pushViewController(vc, animated: true)
            } else {
                // TODO: @huangtao.ht 都不要wrap?
                hostViewController.presentDynamicModal(vc,
                                                       regularConfig: .init(presentationStyle: .formSheet),
                                                       compactConfig: .init(presentationStyle: .pageSheet))
            }
        } else {
            hostViewController.navigationController?.pushViewController(vc, animated: true)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        let point = titleLabel.convert(point, from: self)
        if titleLabel.point(inside: point, with: event), !titleLabel.isHidden {
            return titleLabel
        }
        return result
    }
}

extension MeetingDetailCollectionBodyComponent: MeetingDetailCollectionInfoObserver {
    func didReceive(data: [CollectionInfo]) {
        updateViews()
    }
}
