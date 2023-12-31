//
//  DocFilterContentView.swift
//  LarkSearch
//
//  Created by SuPeng on 5/5/19.
//

import Foundation
import UIKit
import LarkModel
import LarkSDKInterface

public protocol DocFilterContentViewDelegate: AnyObject {
    func contentView(_ contentView: DocFilterContentView, didClickFilter: DocFormatType)
}

public final class DocFilterContentView: UIView {
    public weak var delegate: DocFilterContentViewDelegate?

    private let filterButtons: [DocFilterButton]

    public init(enableMindnote: Bool, enableBitable: Bool, enableNewSlides: Bool) {
        var types = DocFormatType.allCases.filter { $0 != .slide }
        if !enableMindnote {
            types.lf_remove(object: .mindNote)
        }
        if !enableBitable {
            types.lf_remove(object: .bitale)
        }
        if !enableNewSlides {
            types.lf_remove(object: .slides)
        } else {
            types.lf_remove(object: .all)
        }
        filterButtons = types.map { DocFilterButton(filter: $0) }

        super.init(frame: .zero)

        filterButtons.enumerated().forEach { (index, button) in
            let colIndex = index % 3
            let rowIndex = index / 3
            addSubview(button)
            button.snp.makeConstraints { (make) in
                make.left.equalTo(colIndex * 112)
                make.top.equalTo(rowIndex * 90)
                make.height.equalTo(90)
                make.width.equalTo(112)
            }

            // config self view prefered contentSize
            if index == 0 {
                button.snp.makeConstraints { (make) in
                    make.left.top.equalToSuperview()
                }
            } else if index == 2 {
                button.snp.makeConstraints { (make) in
                    make.right.equalToSuperview()
                }
            } else if index == filterButtons.count - 1 {
                button.snp.makeConstraints { (make) in
                    make.bottom.equalToSuperview()
                }
            }

            button.docFilterDidClickBlock = { [weak self] filter in
                guard let self = self else { return }
                self.delegate?.contentView(self, didClickFilter: filter)
            }
        }

        let totalRows = ceil(Double(filterButtons.count) / 3)
        let totalCol = 3
        snp.makeConstraints { (make) in
            make.width.equalTo(totalCol * 112)
            make.height.equalTo(totalRows * 90)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
