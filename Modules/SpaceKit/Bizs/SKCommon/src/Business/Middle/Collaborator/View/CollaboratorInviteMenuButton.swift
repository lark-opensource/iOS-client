//  Created by Songwen on 2018/9/14.

import UIKit

class CollaboratorInviteMenuButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.semanticContentAttribute = .forceRightToLeft
        self.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        self.setTitleColor(UIColor.ud.N900, for: .normal)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
