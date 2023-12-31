//
//  CommentTranslateInterface.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/3/30.
//  


import Foundation

public protocol CommentTranslationStore {
    
    var key: String { get }
}

public protocol CommentTranslationToolProtocol {
    func add(store: CommentTranslationStore)
    
    func remove(store: CommentTranslationStore)
    
    func contain(store: CommentTranslationStore) -> Bool 
}

