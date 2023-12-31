# UAST Script Directory

This directory is used to store scripts related to Universal Abstract Syntax Tree (UAST).

UAST document: [CodeGraphQL 方案](https://bytedance.feishu.cn/wiki/wikcnRXvvthRfVJEUijXM06oL7g)

## File Summary

- `path_config.json`: This file contains a mapping of paths to modules.
- `validate_path_config.rb`: This script is used to validate whether `path_config.json` matches `modules.json`. If someone adds or modifies some modules in the repository, `path_config.json` should also be updated accordingly.

## Others

### path\_config.json

The following special paths have been specially processed.

1. ECOProbeMeta -> Modules/OPMonitor/
2. LarkOpenCombine, LarkOpenCombineDispatch, LarkOpenCombineFoundation -> Modules/Infra/Libs/Combine/OpenCombine/
3. LibArchiveKit -> Modules/LibArchive/
4. SKFoundation\_Tests -> Modules/SpaceKit/Libs/SKFouncation/ (ignore this module)

## TODO

1. Consider whether to ignore modules that are pure Swift.

