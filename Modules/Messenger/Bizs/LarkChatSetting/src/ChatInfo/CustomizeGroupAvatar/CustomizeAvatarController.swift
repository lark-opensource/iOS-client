//
//  CustomizeAvatarController.swift
//  LarkChatSetting
//
//  Created by bytedance on 2020/4/21.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import UniverseDesignToast
import EENavigator
import LarkAvatar
import ByteDanceKit
import LarkModel
import LarkAssetsBrowser
import LarkActionSheet
import RustPB
import UniverseDesignActionPanel
import LarkImageEditor
import ByteWebImage

/// 定制头像
final class CustomizeAvatarController: AvatarBaseSettingController {
    private let viewModel: CustomizeAvatarViewModel
    var savedCallback: ((UIImage, RustPB.Basic_V1_AvatarMeta, UIViewController, UIView) throws -> Void)?
    private let disposeBag = DisposeBag()
    /**埋点使用Chat参数*/
    var extraInfo: [String: Any] = [:]
    /// 头部头像视图
    private lazy var topAvatarView: GroupAvatarView = {
        let view = GroupAvatarView()
        view.setAvatar(type: self.viewModel.initAvatarType)
        view.cameraButtonClick = { [weak self] sender in
            self?.onCameraButtonClick(sender: sender)
        }
        return view
    }()

    /// 中间选择文字视图
    private lazy var centerTextView: GroupTextView = {
        let view = GroupTextView()
        view.extraInfo = self.extraInfo
        view.textChangedHandler = { [weak self] text in
            guard let `self` = self else { return }
            self.setRightButtonItemEnable(enable: true)
            // 如果当前用户没有选中任何颜色，则随机选择一个
            if self.bottomColorView.currSelectColor() == nil { self.bottomColorView.selectRandomColor() }
            let selectColor = self.bottomColorView.currSelectColor() ?? .clear
            // 对text进行预处理，清除前后的空格&换行
            let fixText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let textColor = self.viewModel.drawStyle == .soild ? UIColor.ud.primaryOnPrimaryFill : selectColor
            let backgroundColor: UIColor? = self.viewModel.drawStyle == .soild ? selectColor : nil
            let viewModel = self.viewModel
            // 如果text为空，则显示color对应的默认图片
            if fixText.isEmpty {
                let colorImage = viewModel.drawStyle == .soild ? viewModel.defaultCenterIcon : self.bottomColorView.getImageFor(originImage: viewModel.defaultCenterIcon, color: selectColor)
                let contentMode: UIView.ContentMode = viewModel.drawStyle == .soild ? .scaleAspectFit : .center
                self.topAvatarView.setAvatar(type: .imageColor(image: colorImage,
                                                               contentMode: contentMode,
                                                               color: selectColor,
                                                               backgroundColor: backgroundColor))
            } else {
                self.topAvatarView.setAvatar(type: .text(text: fixText,
                                                         textColor: textColor,
                                                         borderColor: selectColor,
                                                         backgroundColor: backgroundColor))
            }
        }
        return view
    }()
    /// 底部选择颜色视图
    private lazy var bottomColorView: GroupColorView = {
        let view = GroupColorView()
        view.extraInfo = self.extraInfo
        view.selectColorChangeHandler = { [weak self] color in
            guard let `self` = self else { return }
            self.setRightButtonItemEnable(enable: true)
            // 对text进行预处理，清除前后的空格&换行
            let fixText = self.centerTextView.currSelectOrInputText().trimmingCharacters(in: .whitespacesAndNewlines)
            let textColor = self.viewModel.drawStyle == .soild ? UIColor.ud.primaryOnPrimaryFill : color
            let backgroundColor: UIColor? = self.viewModel.drawStyle == .soild ? color : nil
            // 如果text为空，则显示color对应的默认图片
            if fixText.isEmpty {
                let colorImage = self.viewModel.drawStyle == .soild ? self.viewModel.defaultCenterIcon : self.bottomColorView.getImageFor(originImage: self.viewModel.defaultCenterIcon, color: color)
                let contentMode: UIView.ContentMode = self.viewModel.drawStyle == .soild ? .scaleAspectFit : .center
                self.topAvatarView.setAvatar(type: .imageColor(image: colorImage,
                                                               contentMode: contentMode,
                                                               color: color,
                                                               backgroundColor: backgroundColor))
            } else {
                let textColor = self.viewModel.drawStyle == .soild ? UIColor.ud.primaryOnPrimaryFill : color
                self.topAvatarView.setAvatar(type: .text(text: fixText,
                                                         textColor: textColor,
                                                         borderColor: color,
                                                         backgroundColor: backgroundColor))
            }
        }
        return view
    }()

    init(viewModel: CustomizeAvatarViewModel) {
        self.viewModel = viewModel
        super.init(userResolver: viewModel.userResolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 创建视图
        self.createSubViews()
        // 配置视图
        self.configSubViews()
    }

    override func closeBtnTapped() {
        ChatSettingTracker.trackGroupProfileCancel(chatInfo: self.extraInfo)
        super.closeBtnTapped()
    }

    /// 配置视图
    private func configSubViews() {
        // 获取群昵称分词结果 && avatarMeta
        self.viewModel.fetchRemoteData().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (texts, meta) in
            guard let `self` = self else { return }
            guard let meta = meta else {
                self.centerTextView.setupWithData(textArray: texts)
                self.view.setNeedsLayout()
                return
            }

            var texts = texts
            switch meta.type {
            // 用户自己上传的头像, 没有数据/错误数据/系统错误降级
            case .upload, .collage, .unknown: break
            // 用户选了颜色未指定name或者选中推荐文字
            case .random:
                self.bottomColorView.setSelectColor(color: UIColor.ud.rgb(UInt32(meta.color)))
            // 用户选了颜色且指定name或者选中推荐文字
            case .words:
                self.bottomColorView.setSelectColor(color: UIColor.ud.rgb(UInt32(meta.color)))
                // 保证meta.text唯一texts中第一个
                texts.lf_remove(object: meta.text)
                if texts.isEmpty {
                    texts = [meta.text]
                } else {
                    texts.insert(meta.text, at: 0)
                }
            @unknown default: break
            }
            // 填充推荐文字
            self.centerTextView.setupWithData(textArray: texts)
            // 选中用户创建/修改头像时指定的文字
            if meta.type == .words { self.centerTextView.setSelctText(text: meta.text) }
            // 需要重新布局
            self.view.setNeedsLayout()
        }).disposed(by: self.disposeBag)
    }

    /// 创建视图
    private func createSubViews() {
        contentView.addSubview(self.topAvatarView)
        self.topAvatarView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        contentView.addSubview(self.centerTextView)
        self.centerTextView.snp.makeConstraints { (make) in
            make.top.equalTo(self.topAvatarView.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
        }
        contentView.addSubview(self.bottomColorView)
        self.bottomColorView.snp.makeConstraints { (make) in
            make.top.equalTo(self.centerTextView.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
    }

    /// 保存用户定制的群头像
    override func saveGroupAvatar() {
        let meta = self.avatarMeta()
        try? self.savedCallback?(self.topAvatarView.getAvatarImage(), meta, self, self.centerTextView)
    }

    private func onCameraButtonClick(sender: UIView) {
        let extraInfo = self.extraInfo
        ChatSettingTracker.trackGroupProfileUploadAvatarPictures(chatInfo: extraInfo)
        self.view.endEditing(true)
        self.showSelectActionSheet(sender: sender, navigator: self.viewModel.navigator, finish: { [weak self] image in
            guard let `self` = self else { return }
            self.setRightButtonItemEnable(enable: true)
            // 设置头像为选择的图片，清空颜色和文字
            self.topAvatarView.setAvatar(type: .image(image: image))
            self.centerTextView.clearSelectAndInput()
            self.bottomColorView.clearSelectColor()
        })

    }

    /// 获取当前用户设置的群meta信息
    private func avatarMeta() -> RustPB.Basic_V1_AvatarMeta {
        var meta = RustPB.Basic_V1_AvatarMeta()
        // 自己拍照/相册选择的图片
        if self.bottomColorView.currSelectColor() == nil, self.centerTextView.currSelectOrInputText().isEmpty {
            meta.type = .upload
        }
        // 用户选了颜色未指定name或者选中推荐文字
        if let color = self.bottomColorView.currSelectColor(), self.centerTextView.currSelectOrInputText().isEmpty {
            meta.type = .random
            // color -> int32
            var uint32Value: UInt32 = 0
            Scanner(string: (color.hex6 ?? "").replacingOccurrences(of: "#", with: "")).scanHexInt32(&uint32Value)
            meta.color = Int32(uint32Value)
        }
        // 用户选了颜色且指定name或者选中推荐文字
        if let color = self.bottomColorView.currSelectColor(), !self.centerTextView.currSelectOrInputText().isEmpty {
            meta.type = .words
            // color -> int32
            var uint32Value: UInt32 = 0
            Scanner(string: (color.hex6 ?? "").replacingOccurrences(of: "#", with: "")).scanHexInt32(&uint32Value)
            meta.color = Int32(uint32Value)
            meta.text = self.centerTextView.currSelectOrInputText()
        }
        return meta
    }
}
