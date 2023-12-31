//
//  PromptSearchUtils.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/19.
//  

import UIKit
import UniverseDesignColor

class PromptSearchUtils {
    
    var promptGroups: [InlineAIPanelModel.PromptGroups] = []
    
    var searchText = ""

    init() {}
    
    func update(promptGroups: [InlineAIPanelModel.PromptGroups]) {
        self.promptGroups = promptGroups
    }
    
    func search(searchText: String) -> [InlineAIPanelModel.PromptGroups] {
        self.searchText = searchText
        guard !searchText.isEmpty else {
            return promptGroups
        }
        var result: [InlineAIPanelModel.PromptGroups] = []
        
        let normalAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                               NSAttributedString.Key.foregroundColor: UDColor.textTitle]
        let hilightedAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                                NSAttributedString.Key.foregroundColor: UDColor.functionInfoContentDefault]
        for group in promptGroups {
            
            var child: [InlineAIPanelModel.Prompt] = []

            for prompt in group.prompts {
                let promptText = prompt.text
                
                let attributedStringResult = NSMutableAttributedString(string: promptText, attributes: normalAttributes)
                if promptText.contains(searchText) {
                    let inputTextLowercased = promptText.lowercased()
                    let searchTextLowercased = searchText.lowercased()
                    
                    var searchRange = inputTextLowercased.startIndex..<inputTextLowercased.endIndex
                    while let range = inputTextLowercased.range(of: searchTextLowercased, options: .caseInsensitive, range: searchRange) {
                        attributedStringResult.addAttributes(hilightedAttributes, range: NSRange(range, in: promptText))
                        searchRange = range.upperBound..<inputTextLowercased.endIndex
                    }
                    var promptNeeded = prompt
                    promptNeeded.update(attributedString: .init(attributedStringResult))
                    child.append(promptNeeded)
                }
            }
            
            if !child.isEmpty {
                result.append(InlineAIPanelModel.PromptGroups(title: group.title, prompts: child))
            }
        }
        return result
    }
}
