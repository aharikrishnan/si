find data/ -name merged.csv -exec git add -f '{}' \;
find . -size 2c -exec rm '{}' \;

