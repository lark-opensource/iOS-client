//
//  SceneDetailCellViewModel.swift
//  LarkAI
//
//  Created by Zigeng on 2023/10/10.
//

import Foundation
import EENavigator
import ByteWebImage
import UniverseDesignToast

class SceneDetailInputCellViewModel: SceneDetailCellViewModel {
    var paramType: SceneDetailParamType
    weak var cellVMDelegate: SceneDetailCellDelegate?

    let placeHolder: String
    let limit: Int
    var inputText: String = ""
    var needShowError: Bool = false
    var rowHeight: CGFloat = 100

    var trimmedinputText: String {
        return inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum Status {
        case focus
        case error
        case plain
    }

    init(paramType: SceneDetailParamType,
         placeHolder: String,
         inputText: String?,
         limit: Int,
         rowHeight: CGFloat = 100
    ) {
        self.paramType = paramType
        self.placeHolder = placeHolder
        self.inputText = inputText ?? ""
        self.limit = limit
        self.rowHeight = rowHeight
    }

    // 输入为空或超过limit则不允许上传
    func checkBeforeSubmit() -> Bool {
        needShowError = true
        if inputText.count > limit || trimmedinputText.isEmpty {
            return false
        }
        return true
    }
}

class SceneDetailTextFieldCellViewModel: SceneDetailCellViewModel {
    var paramType: SceneDetailParamType
    weak var cellVMDelegate: SceneDetailCellDelegate?

    let placeHolder: String
    let canRemove: Bool
    var inputText: String
    var needShowError: Bool = false

    enum Status {
        case error
        case plain
        case focus
    }

    var trimmedinputText: String {
        return inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var limit: Int

    /// SceneDetail的单行输入框ViewModel
    /// - Parameters:
    ///   - limit: 字数最长限制
    ///   - canRemove: 是否支持移除自己，支持的话左侧会添加一个红色删除按钮
    init(paramType: SceneDetailParamType,
         placeHolder: String,
         limit: Int,
         inputText: String?,
         canRemove: Bool = false
    ) {
        self.paramType = paramType
        self.placeHolder = placeHolder
        self.limit = limit
        self.inputText = inputText ?? ""
        self.canRemove = canRemove
    }

    // 移除该textFiled
    lazy var removeSelf: () -> Void = { [weak self] in
        guard let self = self, self.canRemove else { return }
        self.cellVMDelegate?.removeCell(cellVM: self)
    }

    // 输入为空或超过limit则不允许上传
    func checkBeforeSubmit() -> Bool {
        needShowError = true
        if inputText.count > limit || trimmedinputText.isEmpty {
            return false
        }
        return true
    }
}

class SceneDetailAddTextCellViewModel: SceneDetailCellViewModel {
    var paramType: SceneDetailParamType
    weak var cellVMDelegate: SceneDetailCellDelegate?
    var cellTapAction: (() -> Void)?
    var enable: Bool
    let title: String

    init(paramType: SceneDetailParamType,
         title: String,
         enable: Bool = true,
         tapAction: @escaping ((SceneDetailAddTextCellViewModel) -> Void)
    ) {
        self.paramType = paramType
        self.title = title
        self.enable = enable
        self.cellTapAction = { [weak self] in
            guard let self = self else { return }
            tapAction(self)
        }
    }
}

class SceneDetailSwitchCellViewModel: SceneDetailCellViewModel {
    var paramType: SceneDetailParamType
    weak var cellVMDelegate: SceneDetailCellDelegate?

    let title: String
    let subTitle: String
    var isSelected: Bool

    init(paramType: SceneDetailParamType,
         title: String,
         subTitle: String,
         isSelected: Bool
    ) {
        self.paramType = paramType
        self.title = title
        self.subTitle = subTitle
        self.isSelected = isSelected
    }
}

class SceneDetailSelectorCellViewModel: SceneDetailCellViewModel {
    typealias TapAction = (NavigatorFrom) -> Void
    enum Preview {
        case text(String)
        case icons([UIImage])
    }

    var paramType: SceneDetailParamType
    weak var cellVMDelegate: SceneDetailCellDelegate?

    let title: String
    var preview: Preview? {
        return .text((model?.name) ?? "")
    }

    var model: AgentModel?
    let tapAction: TapAction
    init(paramType: SceneDetailParamType,
         title: String,
         model: AgentModel?,
         tapAction: @escaping TapAction
    ) {
        self.paramType = paramType
        self.title = title
        self.model = model
        self.tapAction = tapAction
    }

    /// 如果没有选择模型，则弹toast报错提示给用户
    func checkBeforeSubmit() -> Bool {
        if model == nil {
            if let view = cellVMDelegate?.view {
                UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_Senario_EditCreateScenario_ModelEmpty_Toast, on: view)
            }
            return false
        }
        return true
    }
}

class SceneDetailIconCellViewModel: SceneDetailCellViewModel {
    /// 图片可以是直接从「服务端拉下来」/「根据Setting生成的默认图」的ImagePassThrough。也可以是一个uiImage
    enum Image {
        case passThrough(ImagePassThrough)
        case uiimage(UIImage)
    }

    var rowHeight: CGFloat = 85

    var paramType: SceneDetailParamType
    weak var cellVMDelegate: SceneDetailCellDelegate?

    var image: Image
    init(paramType: SceneDetailParamType,
         image: Image
    ) {
        self.paramType = paramType
        self.image = image
    }
}
