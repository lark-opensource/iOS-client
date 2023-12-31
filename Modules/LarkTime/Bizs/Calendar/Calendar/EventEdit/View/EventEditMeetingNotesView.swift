//
//  EventEditMeetingNotesView.swift
//  Calendar
//
//  Created by huoyunjie on 2023/5/26.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import CalendarFoundation
import LarkContainer

protocol EventEditMeetingNotesViewDataType {
    var viewStatus: MeetingNotesViewStatus { get }
    var showDeleteIcon: Bool { get }
    var shouldShowAIStyle: Bool { get }
}

final class EventEditMeetingNotesView: EventEditCellLikeView, ViewDataConvertible {

    var viewData: EventEditMeetingNotesViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            accessory = viewData.showDeleteIcon ? .type(.close) : .none

            icon = .customImage(iconImage)
            iconAlignment = .centerYEqualTo(refView: meetingNotesView.title)
            accessoryAlignment = .centerYEqualTo(refView: meetingNotesView.title)

            meetingNotesView.snp.updateConstraints {
                $0.bottom.equalToSuperview().inset(13)
                $0.trailing.equalToSuperview().offset(-2)
            }

            self.isHidden = false
            switch viewData.viewStatus {
            case .hidden:
                self.isHidden = true
            case .failed:
                iconAlignment = .centerYEqualTo(refView: meetingNotesView.permissionPromptView.warningIcon)
                accessoryAlignment = .centerYEqualTo(refView: meetingNotesView.permissionPromptView.warningIcon)
                accessory = .none
            case .loading:
                accessory = .none
            case .viewData:
                iconAlignment = .topByOffset(23)
                accessoryAlignment = .topEqualTo(refView: meetingNotesView.title)
            case .createEmpty:
                accessory = .none
            case .templateList:
                accessory = .none
                meetingNotesView.snp.updateConstraints {
                    $0.bottom.equalToSuperview()
                    $0.trailing.equalToSuperview().offset(16)
                }
            case .disabled:
                icon = .customImageWithoutN3(iconImage.renderColor(with: .n4))
                iconAlignment = .topByOffset(15.4)
                accessoryAlignment = .topByOffset(15.4)
            case .createMeetingNotes:
                accessory = .none
                iconAlignment = FG.myAI ? .topByOffset(16) : .topByOffset(15)
                meetingNotesView.snp.updateConstraints { make in
                    make.trailing.equalToSuperview().offset(3)
                }
            }
            // meetingNotesView.viewData 的刷新依赖当前最新的 UI 布局，所以要放在最后执行
            meetingNotesView.viewData = viewData.viewStatus
            meetingNotesView.updateAIContainerStyle(shouldShowAIStyle: viewData.shouldShowAIStyle)
            if viewData.showDeleteIcon {
                accessoryView.isHidden = viewData.shouldShowAIStyle
            }
        }
    }

    // doc 删除事件
    var deleteHandler: (() -> Void)? {
        didSet {
            onAccessoryClick = deleteHandler
        }
    }

    weak var delegate: MeetingNotesViewDelegate? {
        didSet {
            meetingNotesView.delegate = delegate
        }
    }

    let meetingNotesView: MeetingNotesView
    private lazy var iconImage: UIImage = UDIcon.fileLinkWordOutlined

    init(userResolver: UserResolver,
         bgColor: UIColor? = nil,
         needGuideView: Bool = true,
         createViewType: MeetingNotesCreateView.CreateViewType = .label) {
        self.meetingNotesView = MeetingNotesView(
            userResolver: userResolver,
            createViewType: createViewType,
            needGuideView: needGuideView
        )
        super.init(frame: .zero)
        if let bgColor = bgColor {
            backgroundColors = (bgColor, bgColor)
        }
        setupView()
    }

    private func setupView() {
        self.backgroundView.isUserInteractionEnabled = true
        backgroundView.gestureRecognizers?.forEach({ gestureRecognizer in
            backgroundView.removeGestureRecognizer(gestureRecognizer)
        })
        icon = .customImage(iconImage.renderColor(with: .n3))
        iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        let containerView = UIView()
        content = .customView(containerView)
        accessory = .none

        containerView.addSubview(meetingNotesView)
        meetingNotesView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(13)
            $0.leading.trailing.equalToSuperview()
        }
        iconAlignment = .centerYEqualTo(refView: meetingNotesView.title)
        accessoryAlignment = .centerYEqualTo(refView: meetingNotesView.title)

        meetingNotesView.guideView.snp.remakeConstraints { make in
            make.leading.top.equalToSuperview()
            make.trailing.equalTo(self.snp.trailing).inset(13)
        }

        accessoryClickableExpandView.snp.remakeConstraints {
            $0.size.equalTo(44)
            $0.center.equalTo(accessoryView)
            $0.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: EventEditUIStyle.Layout.singleLineCellHeight)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        /// guideView 超出父视图，同时需要 close 按钮响应事件
        let guideView = meetingNotesView.guideView
        let closeButton = guideView.closeButton
        let closeButtonPoint = self.convert(point, to: closeButton)
        if !guideView.isHidden,
           closeButton.point(inside: closeButtonPoint, with: event) {
            return closeButton
        }
        return super.hitTest(point, with: event)
    }

}
