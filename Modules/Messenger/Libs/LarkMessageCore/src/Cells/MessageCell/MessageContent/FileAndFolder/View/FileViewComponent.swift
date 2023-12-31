//
//  FileViewComponent.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/13.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import RichLabel
import LarkModel
import LarkSetting
import LarkMessengerInterface

public final class FileViewComponent<C: Context>: ASComponent<FileViewComponent.Props, EmptyState, FileView, C> {
    final public class Props: ASComponentProps {
        // 最大宽度
        public var preferMaxWidth: CGFloat = 0
        // 是否限制最大宽度
        public var limitMaxWidth: Bool = false
        // 文件名称
        public var fileName: String = ""
        //传输速率
        public var rate: String = ""
        // 文件大小
        public var size: String = ""
        // 最新修改时间 + 最新修改人
        public var lastEditInfoString: String?
        // 文件图标
        public var icon: UIImage = UIImage()
        // 文件状态
        public var statusText: String = ""
        // 上传进度
        public var progress: Float = 0
        // 进度是否带动画
        public var progressAnimated: Bool = false
        // 是否显示顶部的线(有回复的时候显示)
        public var showTopBorder: Bool = false
        // 是否显示底部的线（有点赞的时候不显示)
        public var showBottomBorder: Bool = true
        // 点击之后的行为
        public var tapAction: ((FileView) -> Void)?
        // UI距离底部的距离
        public var bottomSpaceHeight: CGFloat = 12.0
        // 是否显示局域网传输icon
        public var isShowLanTransIcon: Bool = false
        // 是否有预览权限
        public var permissionPreview: (Bool, ValidateResult?) = (true, nil)
        // 动态权限
        public var dynamicAuthorityEnum: DynamicAuthorityEnum = .loading
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    private let fileViewLayout = FileViewLayout()
    private var fileViewlayoutResults = FileViewLayoutResult()
    /**
     这里使用 os_unfair_lock(忙等锁)效率高些 iOS10以上可用
     对fileViewlayoutResults的各个属性赋值和使用过程 进行加锁
    */
    private var lock = os_unfair_lock_s()

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        //fileViewLayout 根据需要去更新布局
        fileViewLayout.layoutConfig.bottomSpaceHeight = props.bottomSpaceHeight
        fileViewLayout.layoutConfig.preferMaxWidth = min(FileViewLayout.fileViewMaxWidth, props.preferMaxWidth)
        fileViewLayout.layoutConfig.fileName = props.fileName
        fileViewLayout.layoutConfig.statusText = props.statusText
        fileViewLayout.layoutConfig.sizeText = props.size
        fileViewLayout.layoutConfig.lastEditInfoText = props.lastEditInfoString ?? ""
        fileViewLayout.layoutConfig.rate = props.rate
        fileViewLayout.layoutConfig.fitSize = size
        fileViewLayout.layoutConfig.hasPermissionPreview = props.permissionPreview.0
        fileViewLayout.layoutConfig.dynamicAuthorityEnum = props.dynamicAuthorityEnum
        let size = fileViewLayout.layoutViewIfNeed()
        os_unfair_lock_lock(&lock)
        fileViewLayout.copyLayoutResultTo(&fileViewlayoutResults)
        os_unfair_lock_unlock(&lock)
        return size
    }

    public override func update(view: FileView) {
        super.update(view: view)
        view.set(
            fileName: props.fileName,
            sizeLabelContent: props.size,
            lastEditInfoString: props.lastEditInfoString,
            icon: props.icon,
            isShowLanTransIcon: props.isShowLanTransIcon,
            statusText: props.statusText,
            dynamicAuthorityEnum: props.dynamicAuthorityEnum,
            hasPermissionPreview: props.permissionPreview.0
        )
        os_unfair_lock_lock(&lock)
        fileViewLayout.layoutConfig.dynamicAuthorityEnum = props.dynamicAuthorityEnum
        fileViewLayout.copyLayoutResultTo(&fileViewlayoutResults)
        view.updateLayout(layoutResult: fileViewlayoutResults)
        os_unfair_lock_unlock(&lock)
        view.showTopBorder = props.showTopBorder
        view.showBottomBorder = props.showBottomBorder
        view.setProgress(props.progress, animated: props.progressAnimated)
        view.setRate(props.rate)
        view.tapAction = props.tapAction
        view.backgroundColor = UIColor.ud.bgFloat
    }
    public override func create(_ rect: CGRect) -> FileView {
        return FileView()
    }
}
