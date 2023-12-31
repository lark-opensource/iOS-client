//
//  CustomSubTopContainer.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/9/7.
//

import Foundation
import UniverseDesignColor
import SKResource
import SKCommon
import UniverseDesignButton

// MARK: - History CustomSubTopContainer
class RestoreHistoryView: UIView {
    private let action: () -> Void
    private let restoreEnable: Bool
    private lazy var restoreHistoryBtn: UIButton = {
        let btn = UDButton.primaryBlue
        btn.config.normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                             backgroundColor: restoreEnable ? UIColor.ud.primaryContentDefault : UDColor.fillDisabled,
                                                             textColor: UIColor.ud.primaryOnPrimaryFill)
        btn.config.pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                              backgroundColor: restoreEnable ? UIColor.ud.primaryContentPressed : UDColor.fillDisabled,
                                                              textColor: UIColor.ud.primaryOnPrimaryFill)
        btn.setTitle(BundleI18n.SKResource.CreationMobile_Common_VersionHistory_Restore, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        btn.docs.addStandardHighlight()
        btn.sizeToFit()
        return btn
    }()

    init(frame: CGRect, restoreEnable: Bool, title: String?, action: @escaping () -> Void) {
        self.action = action
        self.restoreEnable = restoreEnable
        super.init(frame: frame)
        addSubview(restoreHistoryBtn)
        restoreHistoryBtn.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        restoreHistoryBtn.addTarget(self, action: #selector(didClickRestoreBtn), for: .touchUpInside)
        if let showTitle = title {
            restoreHistoryBtn.setTitle(showTitle, for: .normal)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClickRestoreBtn() {
        self.action()
    }
}

extension RestoreHistoryView: CustomSubTopContainer {
    func currentLayout() -> CGSize {
        return CGSize(width: restoreHistoryBtn.frame.width, height: 36)
    }
}

class HistoryTopCRightView: UIView {

    private lazy var leftLineView = UIView().construct { view in
        view.backgroundColor = UDColor.N300
    }

    private lazy var bottomLineView = UIView().construct { view in
        view.backgroundColor = UDColor.N300
    }

    private lazy var textView = UILabel().construct { label in
        label.textColor = UDColor.textTitle
        label.font = UIFont(name: "PingFangSC-Regular", size: 17)
        label.text = BundleI18n.SKResource.Doc_More_History
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(leftLineView)
        addSubview(bottomLineView)
        addSubview(textView)
        leftLineView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(1)
        }
        bottomLineView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        textView.snp.makeConstraints { make in
            make.left.equalTo(leftLineView.snp.right).offset(12)
            make.bottom.equalTo(bottomLineView.snp.top).offset(-21)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HistoryTopCRightView: CustomSubTopContainer {
    func currentLayout() -> CGSize {
        return CGSize(width: 294, height: 0)
    }
}
