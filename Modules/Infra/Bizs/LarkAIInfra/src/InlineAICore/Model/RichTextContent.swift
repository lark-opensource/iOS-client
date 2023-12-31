//
//  RichTextContent.swift
//  LarkAIInfra
//
//  Created by chensi(陈思) on 2023/11/8.
//  


import Foundation

public struct RichTextContent {
    
    public enum DataType {
        /// 快捷指令
        case quickAction(InlineAIPanelModel.QuickAction)
        /// 自由输入
        case freeInput(components: [InlineAIPanelModel.ParamContentComponent])
    }

    public var data: DataType

    /// 输入框原始富文本
    public var attributedString: NSAttributedString
    
}

extension RichTextContent {
    
    /// 获取编码后的纯文本字符, 将输入框内的mention信息转为特定的xml元素
    /// 该方法仅供支持 @ user的业务方调用，因为 @ doc的转码逻辑在CCM业务模块内实现
    public func encodedStringWithMentionedUser() -> String {
        switch self.data {
        case .quickAction:
            let list = InlineAiInputTransformer.parseParamContents(attrStr: attributedString)
            let result = encodedString(components: list)
            return result
        case .freeInput(let components):
            let result = encodedString(components: components)
            return result
        }
    }
    
    private func encodedString(components: [InlineAIPanelModel.ParamContentComponent]) -> String {
        var string = ""
        for item in components {
            switch item {
            case .plainText(let str):
                string.append(str)
            case .mention(let mention):
                switch mention {
                case .doc(let title, _):
                    string.append(title) // 不做额外处理
                case .user(let name, let userID):
                    let xml = "<at type=\"0\" href=\"\" token=\"\(userID)\">@\(name)</at>"
                    string.append(xml)
                }
            }
        }
        return string
    }
}
