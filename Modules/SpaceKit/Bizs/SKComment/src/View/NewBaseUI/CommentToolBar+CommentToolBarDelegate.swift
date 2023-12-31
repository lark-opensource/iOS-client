//
//  CommentToolBar+CommentToolBarDelegate.swift
//  SKCommon
//
//  Created by zhangzhiheng on 2022/11/17.
//  


import Foundation
import SKCommon

protocol CommentToolBarDelegate: AnyObject {
    var supportLandscapeConstraint: Bool { get }
    var supportPic: Bool { get } // 场景是否支持图片
    /// 场景支持插入图片前提下,是否受到了条件访问控制(CAC),如果被管控则图片按钮置灰,但可以响应点击
    @available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
    var enabledWhenPictureSupported: Bool { get }
    var supportVoice: Bool? { get } // 场景是否支持语音，nil表示使用默认配置
    func selectBoxButton() -> UIButton? // Drive 自定义选择框

    func didClickSendIcon(select: Bool) // 点击send按钮
    func didClickAtIcon(select: Bool) // 点击at按钮
    func didClickInsertImageIcon(select: Bool) // 点击插入图片按钮框
    func didClickVoiceIcon(_ gesture: UITapGestureRecognizer) // 点击语音Icon
    func didLongPressVoiceBtn(_ gesture: UILongPressGestureRecognizer) // 长按语音
    func didClickResignKeyboardBtn(select: Bool) // 点击收起键盘
    func willResignActive() // 到后台
}

extension CommentToolBarDelegate {
    func selectBoxButton() -> UIButton? {
        return nil
    }
    var supportVoice: Bool? { return nil }
    @available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
    var enabledWhenPictureSupported: Bool {
        let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmAttachmentUpload,
                                                           fileBizDomain: .ccm,
                                                           docType: .file,
                                                           token: nil)
        return result.allow
    }
}
