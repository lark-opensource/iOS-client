import os
import pathlib
import sys
dir_path = pathlib.Path(__file__).parent.absolute()
cmd = str(dir_path) + "/swiftlint &> 1.txt"
os.system(cmd)
f = open("1.txt")
warnings = f.read()
print(warnings)
f.close()
os.system("rm -rf 1.txt")
sub_str = "Done linting! Found 0 violations"
if sub_str in warnings:
    print("exit 1")
    sys.exit(1)

else:
    print("exit 2")
    sys.exit(2)


