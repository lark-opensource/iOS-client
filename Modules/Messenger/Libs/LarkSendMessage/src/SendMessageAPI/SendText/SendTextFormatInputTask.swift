//
//  SendTextFormatInputTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/21.
//

import Foundation
import FlowChart // FlowChartTask
import RustPB // Basic_V1_RichText
import LarkCompatible // LarkFoundationExtension

public protocol SendTextFormatInputTaskContext: FlowChartContext {
}

public final class SendTextFormatInputTask<C: SendTextFormatInputTaskContext>: FlowChartTask<SendMessageProcessInput<SendTextModel>, SendMessageProcessInput<SendTextModel>, C> {
    override public var identify: String { "SendTextFormatInputTask" }

    public override func run(input: SendMessageProcessInput<SendTextModel>) {
        var output = input
        let content = input.model.content.trimCharacters(in: .whitespacesAndNewlines, postion: .tail)
        let parentId = input.parentMessage?.id ?? ""
        let rootId = RustSendMessageModule.getRootId(parentMessage: input.parentMessage, replyInThread: input.replyInThread)

        output.model.content = content
        output.rootId = rootId
        output.parentId = parentId
        input.sendMessageTracker?.beforeCreateQuasiMessage(context: input.context, processCost: nil)

        self.accept(.success(output))
    }
}

extension RustPB.Basic_V1_RichText {
    func trimCharacters(in set: CharacterSet, postion: LarkFoundationExtension<String>.TrimPostion = .both) -> RustPB.Basic_V1_RichText {
        var richText = self
        let leadSet: [LarkFoundationExtension<String>.TrimPostion] = [.both, .lead]
        // 只会处理第一个元素
        if leadSet.contains(postion), let firstElementId = richText.elementIds.first {
            richText = self.trimCharacters(richText: richText, elementId: firstElementId, set: set, lead: true)
        }
        // 只会处理最后一个元素
        let tailSet: [LarkFoundationExtension<String>.TrimPostion] = [.both, .tail]
        if tailSet.contains(postion), let lastElementId = richText.elementIds.last {
            richText = self.trimCharacters(richText: richText, elementId: lastElementId, set: set, lead: false)
        }

        richText.innerText = richText.innerText.lf.trimCharacters(in: set, postion: postion)
        return richText
    }

    /// 只会处理text元素
    private func trimCharacters(richText: RustPB.Basic_V1_RichText, elementId: String, set: CharacterSet, lead: Bool) -> RustPB.Basic_V1_RichText {
        var richText = richText
        guard var element = richText.elements[elementId] else { return richText }

        // 如果不是text，会递归遍历子元素的text
        if element.tag == .text {
            let content = element.property.text.content
            element.property.text.content = content.lf.trimCharacters(in: set, postion: lead ? .lead : .tail)
            richText.elements[elementId] = element
        } else if let childElementId = lead ? element.childIds.first : element.childIds.last {
            richText = trimCharacters(richText: richText, elementId: childElementId, set: set, lead: lead)
        }
        return richText
    }
}
