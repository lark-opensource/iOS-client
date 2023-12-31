//
//  SetLabelNameViewModel.swift
//  LarkSpaceKit
//
//  Created by zhangxingcheng on 2021/7/27.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import Swinject

/**SetLabelNameController的ViewModel*/
public final class SetLabelNameViewModel {

    /**（1）数据源数组*/
    public var setLabelDataArray = [AnyObject]()

    public let chat: Chat?

    public init(sendDocModel: SendDocModel, chat: Chat) {
        //(1)
        let setLabelNameTitleModel1 = SetLabelNameTitleModel(title: BundleI18n.CCMMod.Lark_Groups_SelectedDocument)
        //(2)
        let setLabelNameDocModel = SetLabelNameDocModel(sendDocModel: sendDocModel)
        //(3)
        let setLabelNameTitleModel2 = SetLabelNameTitleModel(title: BundleI18n.CCMMod.Lark_Groups_DocumentName)
        //(4)
        let setLabelNameInputModel = SetLabelNameInputModel(textViewInputString: sendDocModel.title)
        self.setLabelDataArray.append(setLabelNameTitleModel1)
        self.setLabelDataArray.append(setLabelNameDocModel)
        self.setLabelDataArray.append(setLabelNameTitleModel2)
        self.setLabelDataArray.append(setLabelNameInputModel)
        self.chat = chat
    }
}

/**（1）SetLabelNameTitleCell的Model*/
class SetLabelNameTitleModel {

    public var title: String

    public init(title: String) {
        self.title = title
    }
}

/**（2）SetLabelNameDocCell的Model*/
class SetLabelNameDocModel {

    public var sendDocModel: SendDocModel

    public init(sendDocModel: SendDocModel) {
        self.sendDocModel = sendDocModel
    }
}

/**（3）SetLabelNameInputCell的Model*/
class SetLabelNameInputModel {

    public var textViewInputString: String

    public init(textViewInputString: String) {
        self.textViewInputString = textViewInputString
    }
}
