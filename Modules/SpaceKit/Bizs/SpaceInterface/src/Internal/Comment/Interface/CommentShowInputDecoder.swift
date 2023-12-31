//
//  CommentShowInputDecoder.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/4/3.
//  


import Foundation

public protocol CommentShowInputDecoder {
    func decode(data: Data) -> CommentInputModelType?
}
