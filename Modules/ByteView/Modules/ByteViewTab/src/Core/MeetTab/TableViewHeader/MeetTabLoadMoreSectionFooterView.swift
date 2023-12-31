//
//  MeetTabLoadMoreSectionFooterView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Action
import ByteViewUI

class MeetTabLoadMoreSectionFooterView: MeetTabSectionFooterView {

    lazy var loadingView: LoadingView = LoadingView(style: .blue)

    lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.attributedText = .init(string: I18n.View_VM_Loading, config: .bodyAssist, textColor: .ud.udtokenComponentTextDisabledLoading)
        return label
    }()

    lazy var reloadButton: VisualButton = {
        let reloadButton = VisualButton()
        reloadButton.setAttributedTitle(.init(string: I18n.View_MV_LoadingFailedClickContinue, config: .bodyAssist, textColor: .ud.textDisabled), for: .normal)
        return reloadButton
    }()

    lazy var contentStackView: UIStackView = {
        let contentStackView = UIStackView(arrangedSubviews: [loadingView, loadingLabel, reloadButton])
        contentStackView.axis = .horizontal
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        contentStackView.spacing = 4.0
        return contentStackView
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        paddingView.backgroundColor = UIColor.ud.bgBody
        lineView.isHidden = true

        paddingView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        loadingView.snp.makeConstraints {
            $0.width.height.equalTo(16.0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func bindTo(viewModel: MeetTabSectionViewModel) {
        super.bindTo(viewModel: viewModel)

        reloadButton.rx.action = CocoaAction { [weak self] _ in
            viewModel.loadAction?.execute()
            self?.updateStatus(.loading)
            return .empty()
        }

        updateStatus(viewModel.loadStatus)
    }

    func updateStatus(_ loadStatus: MeetTabResultStatus) {
        switch loadStatus {
        case .loading:
            loadingView.isHidden = false
            loadingLabel.isHidden = false
            reloadButton.isHidden = true
            loadingView.play()
        case .loadError:
            loadingView.stop()
            loadingView.isHidden = true
            loadingLabel.isHidden = true
            reloadButton.isHidden = false
        default:
            break
        }
    }
}
