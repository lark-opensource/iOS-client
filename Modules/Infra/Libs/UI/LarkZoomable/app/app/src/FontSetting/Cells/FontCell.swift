//
//  FontCell.swift
//  LarkZoomableDev
//
//  Created by bytedance on 2021/4/26.
//

import Foundation
import UIKit
import LarkZoomable

class FontCell: UITableViewCell {

    func configure(with model: Font, zoom: Zoom) {
        textLabel?.font = model.font
        textLabel?.text = model.name
        detailTextLabel?.text = "字号: \(model.font.pointSize)   字重: \(model.weight)   FIGMA行高: \(model.font.figmaHeight)"
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
