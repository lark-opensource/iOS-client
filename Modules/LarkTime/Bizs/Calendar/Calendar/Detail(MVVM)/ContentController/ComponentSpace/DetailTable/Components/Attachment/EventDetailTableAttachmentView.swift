//
//  EventDetailTableAttachmentView.swift
//  Calendar
//
//  Created by Rico on 2021/4/21.
//

import UIKit
import SnapKit
import CalendarFoundation
import LarkUIKit
import UniverseDesignIcon
import RustPB

protocol EventDetailTableAttachmentViewDataType {
    var items: [AttachmentUIData] { get }
    var source: Rust.CalendarEventSource? { get }
}

final class EventDetailTableAttachmentView: DetailCell, ViewDataConvertible {

    var viewData: EventDetailTableAttachmentViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            attchmentView.updateData(data: viewData.items, source: viewData.source)
        }
    }

    private let selectedAction: (Int) -> Void

    init(selectedAction: @escaping (Int) -> Void) {
        self.selectedAction = selectedAction
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))

        layoutUI()
    }

    private func layoutUI() {

        addSubview(icon)
        addSubview(attchmentView)

        icon.snp.makeConstraints { (make) in
            make.centerY.equalTo(20)
            make.leading.equalTo(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        attchmentView.snp.remakeConstraints { (make) in
            make.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
            make.trailing.equalTo(-16)
            make.leading.equalTo(48)
        }

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard Display.pad else {
            return
        }
        attchmentView.onWidthChange(width: self.bounds.width)
    }

    private lazy var attchmentView: AttachmentList = {
        let view = AttachmentList()
        view.delegate = self
        return view
    }()

    private lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.image = UDIcon.getIconByKeyNoLimitSize(.attachmentOutlined).renderColor(with: .n3)
        return icon
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EventDetailTableAttachmentView: AttachmentListDelegate {
    func attachmentList(_ attachmentList: AttachmentList, didSelectAttachAt index: Int) {
        CalendarTracer.shareInstance.calAttachmentOperation(sourceType: .detail)
        selectedAction(index)
    }
}
