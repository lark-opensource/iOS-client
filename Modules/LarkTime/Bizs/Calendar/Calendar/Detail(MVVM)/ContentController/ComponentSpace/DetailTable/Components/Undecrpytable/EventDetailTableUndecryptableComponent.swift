//
//  EventDetailTableUndecryptableComponent.swift
//  Calendar
//
//  Created by ByteDance on 2022/9/26.
//

import UIKit
import LarkCombine
import LarkContainer
import UniverseDesignEmpty
import CalendarFoundation
import FigmaKit
import UniverseDesignFont

final class EventDetailTableUndecryptableComponent: Component {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(undecryptableView)
        undecryptableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private lazy var undecryptableView: EventDetailTableUndecryptableView = {
        return EventDetailTableUndecryptableView()
    }()
}

final class EventDetailTableUndecryptableView: UIView {
    init() {
        super.init(frame: .zero)
        layoutUI()
    }

    private func layoutUI() {
        let image = UDEmptyType.ccmDocumentKeyUnavailable.defaultImage()
        let imageView = UIImageView(image: image)

        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(250)
        }

        let label = UILabel()
        label.textAlignment = .center
        label.text = I18n.Calendar_NoKeyNoView_GreyText
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.body2(.fixed)

        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
            make.height.equalTo(16)
            make.left.right.equalToSuperview().inset(16)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
