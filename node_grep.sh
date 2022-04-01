read package
npm list -g --depth=1 > a.txt
grep $package a.txt
rm a.txt
