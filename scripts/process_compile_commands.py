import json
import os
import subprocess
import json
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("-repo_dir", help="Path to the repository directory")
parser.add_argument("-compile_commands_file", help="Path to the compile commands file")
parser.add_argument("-target_branch", help="Target branch")
parser.add_argument("-source_branch", help="Source branch")
parser.add_argument("-output", help="Output file name")
parser.add_argument("-test_command", help="Test ouput command", default= "false")

args = parser.parse_args()

repo_dir = args.repo_dir
json_file = args.compile_commands_file
source_branch = args.source_branch
target_branch = args.target_branch
output = args.output
test_command = args.test_command

print(f'输入参数: repo_dr {repo_dir}, compile_commands_file {json_file}, target_branch {target_branch}, source_branch {source_branch} output {output}')

os.chdir(repo_dir)

merge_base = subprocess.getoutput(
    f'git merge-base {source_branch} {target_branch}').strip()
print(f"Merge base: {merge_base}")
changed_files = subprocess.getoutput(
    f'git diff --name-only {source_branch} {merge_base}').split("\n")
print(f"本次MR变更的文件: {changed_files}")

with open(json_file) as file:
    data = json.load(file)

prcocessed_data = []

print(f'遍历compile_commands(一共{len(data)}个元素),过滤出变更的文件...')
for item in data:
    # 判断item的file or files字段，判断其中的文件是否在本次MR的变更文件中
    # 如果在变更文件，则将item加入到prcocessed_data中
    temp_files = []    
    if "file" in item:
        temp_files = [item["file"]]
    elif "files" in item:
        files_value = item["files"]
        temp_files = files_value.split(",")
        
    for file in temp_files:
        if file.startswith("external/") or "/external/" in file:
            real_file = file.split("external/")[-1]
        else:
            real_file = file
        
        for changed_file in changed_files:
            if changed_file.endswith(real_file):
                prcocessed_data.append(item)

print(f'将过滤出来的commands(一共{len(prcocessed_data)}个元素),从bazel wrap的命令，替换成系统命令')
final_result = []
for item in prcocessed_data:
    #bitsky生成的compile_commands.json需要处理下
    #1. 将bazel wrap的工具链，替换成原生的
    #2. 去掉 DEBUG_PREFIX_MAP_PWD=. 参数
    #3. 如果有sub_commands字段，则将sub_commands字段中每一个元素展开

    items_to_process = []
    # 展开sub_commands
    if "sub_commands" in item:
        for sub_command in item["sub_commands"]:
            temp_item = item.copy()
            temp_item["command"] = sub_command
            temp_item.pop("sub_commands")
            items_to_process.append(temp_item)
    else:
        items_to_process = [item]

   # 替换编译命令
    for item in items_to_process:
        command = item['command']
        new_commands_arr = []
        for command_component in command.split(' '):
            if command_component.endswith("wrapped_clang"):
                new_commands_arr.append("clang")
            elif command_component == "DEBUG_PREFIX_MAP_PWD=.":
                continue
            else:
                new_commands_arr.append(command_component)
        new_commands_str = ' '.join(new_commands_arr)
        item['command'] = new_commands_str
        final_result.append(item)

print(f'处理完毕，一共{len(final_result)}个command，输出到{output}中...')
with open(output, 'w') as f:
    json.dump(final_result, f)

if test_command == 'true':
    print(f'测试输出的compile_commands，是否可以正常运行...')    
    with open(output) as file:
        data = json.load(file)
        print(f'一共需要测试{len(data)}个命令')
        for index, item in enumerate(data):
            print(f'测试第{index}个命令.......')            
            command = item["command"]
            dir = item["directory"]
            try:
                old_path = os.getcwd()
                os.chdir(dir)
                subprocess.run(command, shell=True, check=True)
                os.chdir(old_path)
                print(f"执行第{index}个指令成功")
            except subprocess.CalledProcessError:
                print(f"执行第{index}个执行失败")
                # print("失败的指令为:")
                # print(command)