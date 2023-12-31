//
//  CompileMetrics.swift
//  Calendar_Cloud
//
//  Created by Rico on 2021/4/20.
//

import Foundation
import ArgumentParser

struct Calendar: ParsableCommand {
    static var configuration = CommandConfiguration(
        // Optional abstracts and discussions are used for help output.
        abstract: "Calendar iOS 工程脚本",

        // Commands can define a version for automatic '--version' support.
        version: "1.0.0",

        // Pass an array to `subcommands` to set up a nested tree of subcommands.
        // With language support for type-level introspection, this could be
        // provided by automatically finding nested `ParsableCommand` types.
        subcommands: [Compile.self],

        // A default subcommand, when provided, is automatically selected if a
        // subcommand is not given on the command line.
        defaultSubcommand: Compile.self)
}
