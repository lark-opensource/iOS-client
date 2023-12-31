#!/usr/bin/env python3

import argparse
import os
from pathlib import Path
import re


def load_i18ns(file, module):
    result = set()
    is_start = False
    with open(file, 'r') as f:
        for line in f:
            s = line.strip()
            if is_start:
                if s == 'config:':
                    return result
                m = re.match(r'- (\w+)', s)
                if m:
                    result.add(m.group(1))
            elif s == f'{module}:':
                is_start = True
    return result


def find_usage(i18n_keys: set, root_dir):
    left_keys = i18n_keys
    for root, dirs, files in os.walk(root_dir):
        for file_name in files:
            if file_name == 'BundleI18n.swift' or not file_name.endswith('.swift'):
                continue
            file_path = Path(root, file_name)
            used_keys = set()
            with open(file_path, 'r') as f:
                for line in f:
                    for x in left_keys:
                        if x in line:
                            used_keys.add(x)
            left_keys.difference_update(used_keys)
            if len(left_keys) == 0:
                return left_keys
    return left_keys


def replace_i18ns(file, module, unused_i18n_keys):
    lines = list()
    is_start = False
    is_end = False
    with open(file, 'r') as f:
        for line in f:
            lines.append(line)
            if is_end:
                continue
            elif is_start:
                s = line.strip()
                if s == 'config:':
                    is_end = True
                else:
                    m = re.match(r'- (\w+)', s)
                    if m and m.group(1) in unused_i18n_keys:
                        lines.remove(line)
            elif line.strip() == f'{module}:':
                is_start = True
    with open(file, 'w+') as f:
        f.writelines(lines)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.usage = 'delete_unused_i18n.py [root_path] [module_name]'
    parser.add_argument('root_path', help='ByteView.iOS path')
    parser.add_argument('module_name', help='module name')
    args = parser.parse_args()
    root_path = args.root_path
    module_name = args.module_name
    print(f'start run in {root_path}, module = {module_name}')
    keys_file = Path(f'{root_path}/Modules/{module_name}/configurations/i18n/i18n.strings.yaml')
    vc_dir = Path(f'{root_path}/Modules/{module_name}')
    keys = load_i18ns(keys_file, module_name)
    unused_keys = find_usage(keys, vc_dir)
    for ix in unused_keys:
        print(ix)
    print(f'\ntotal count = {len(unused_keys)}')
    replace_i18ns(keys_file, module_name, unused_keys)


