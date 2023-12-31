//
//  BaseTableCell.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/8.
//

import Foundation
import UIKit

public class BaseTableCell: UITableViewCell {

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupBackgroundViews()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupBackgroundViews()
    }
}

final class BaseCellSelectView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.fillHover
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BaseCellBackgroundView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UITableViewCell {

    func setupBackgroundViews() {
        backgroundView = BaseCellBackgroundView()
        selectedBackgroundView = BaseCellSelectView()
    }
}
