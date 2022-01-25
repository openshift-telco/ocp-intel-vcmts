#/bin/bash


TEXT=""
for i in {0..127}
do
   TEXT+="\"$i\" "
done

echo $TEXT