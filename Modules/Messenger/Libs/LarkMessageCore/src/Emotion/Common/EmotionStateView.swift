//
//  EmotionStateView.swift
//  LarkUIKit
//
//  Created by huangjianming on 2019/8/13.
//
import UIKit
import Foundation
import SnapKit
import RxSwift
import LarkMessengerInterface
import UniverseDesignColor

enum EmotionStateViewStyle {
    case empty
    case full
    case forEmotionPackageDetail
}

final class EmotionStateView: UIView {
    // MARK: - property
    var style: EmotionStateViewStyle = .full
    var disposeBag = DisposeBag()
    public lazy var addedBtn: UIButton = {
        let addedBtn = UIButton()
        addedBtn.setTitle(BundleI18n.LarkMessageCore.Lark_Chat_StickerPackAdded, for: .normal)
        addedBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        addedBtn.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .normal)
        addedBtn.layer.cornerRadius = 4
        addedBtn.clipsToBounds = true
        addedBtn.isHidden = true
        addedBtn.backgroundColor = UIColor.ud.fillDisabled
        addedBtn.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        return addedBtn
    }()

    public lazy var addBtn: UIButton = {
        let addBtn = UIButton()
        addBtn.layer.cornerRadius = 4
        addBtn.layer.borderWidth = 1
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        addBtn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        addBtn.backgroundColor = UIColor.ud.primaryContentDefault
        addBtn.setTitle(BundleI18n.LarkMessageCore.Lark_Chat_StickerPackAdd, for: .normal)
        addBtn.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        addBtn.isHidden = true
        return addBtn
    }()

    lazy var progressView: EmotionProgressView = {
        let progressView = EmotionProgressView()
        progressView.isHidden = true
        return progressView
    }()

    // MARK: - public method
    public func setStyle(style: EmotionStateViewStyle) {
        switch style {
        case .full:
            self.addBtn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
            self.addBtn.backgroundColor = UIColor.ud.primaryContentDefault
            addBtn.layer.borderWidth = 0
        case .empty:
            self.addBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            self.addBtn.layer.borderColor = UIColor.ud.colorfulBlue.cgColor
            self.addBtn.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
            self.addBtn.backgroundColor = UIColor.ud.bgBody
            addBtn.layer.borderWidth = 1
        case .forEmotionPackageDetail:
            self.addBtn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
            self.addBtn.backgroundColor = UIColor.ud.primaryContentDefault
            addBtn.layer.borderWidth = 0
            self.addedBtn.setTitle(BundleI18n.LarkMessageCore.Lark_Chat_StickerPackUse, for: .normal)
            self.addedBtn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
            self.addedBtn.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
            self.addedBtn.backgroundColor = UIColor.ud.primaryContentDefault
            self.addedBtn.layer.borderWidth = 0
        }
    }

    func setHasPaid(hasPaid: Bool) {
        if hasPaid {
            addBtn.setTitle(BundleI18n.LarkMessageCore.Lark_Chat_StickerPackAdd, for: .normal)
        } else {
            addBtn.setTitle(BundleI18n.LarkMessageCore.Lark_Chat_StickerPackBuy, for: .normal)
        }
    }

    public func update(percent: Double) {
        self.progressView.update(percent: percent)
    }

    public func setState(state: Observable<EmotionStickerSetState>) {
        self.disposeBag = DisposeBag()
        //设置默认值
        state.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (state) in
            self?.setCurrentState(state: state)
        }).disposed(by: self.disposeBag)
    }

    public func setCurrentState(state: EmotionStickerSetState) {
        self.addBtn.isHidden = true
        self.addedBtn.isHidden = true
        self.progressView.isHidden = true

        if state.hasAdd {
            switch state.downloadState {
            case .notDownload, .fail:
                //用户已添加表情,本地文件未下载或者下载失败,展示"已添加"按钮
                self.addedBtn.isHidden = false
            case .downloading(let progress):
                self.progressView.isHidden = false
                self.update(percent: progress)
            case .readyDownload, .userTrigerDownload:
                self.progressView.isHidden = false
                self.update(percent: 0)
            case .downloaded:
                //用户已添加表情,本地文件已下载的情况下,展示"已添加"按钮
                self.addedBtn.isHidden = false
            }
        } else {
            switch state.downloadState {
            case .notDownload, .fail:
                //用户未添加表情,本地文件未下载或者下载失败,展示"可添加"按钮
                self.addBtn.isHidden = false
            case .downloading(let progress):
                self.progressView.isHidden = false
                self.update(percent: progress)
            case .readyDownload, .userTrigerDownload:
                self.progressView.isHidden = false
                self.update(percent: 0)
            case .downloaded:
                //用户未添加表情,本地文件已下载的情况下,展示"可添加"按钮
                self.addBtn.isHidden = false
            }
        }
        self.layout()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.addBtn)
        self.addSubview(self.addedBtn)
        self.addSubview(self.progressView)
        self.setCurrentState(state: EmotionStickerSetState(hasAdd: false, downloadState: .notDownload))
        self.setStyle(style: .empty)
        self.layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout() {
        if addBtn.isHidden == false {
            self.addedBtn.snp.removeConstraints()
            self.addBtn.snp.remakeConstraints { (make) in
                make.width.greaterThanOrEqualTo(60)
                make.height.equalTo(28)
                make.left.equalTo(0)
                make.right.equalTo(0)
                make.centerY.equalToSuperview()
            }
        }

        if addedBtn.isHidden == false {
            self.addBtn.snp.removeConstraints()
            self.addedBtn.snp.remakeConstraints { (make) in
                make.width.greaterThanOrEqualTo(60)
                make.height.equalTo(28)
                make.left.equalTo(0)
                make.right.equalTo(0)
                make.centerY.equalToSuperview()
            }
        }

        self.progressView.snp.remakeConstraints { (make) in
            make.height.equalTo(3)
            make.width.equalTo(50)
            make.center.equalToSuperview()
        }
    }
}
