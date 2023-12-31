var=$(sed -n 1p rust-dep.conf)
./update-rust-lib.sh $var
