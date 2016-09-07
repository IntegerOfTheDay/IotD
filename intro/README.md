This is how I made it work. There certainly are better ways.

Step 1: install Image::Magick perl modules
Step 2: clean up from previous runs because you missed step 6 the last time. rm ./*.png
Step 3: run trace.pl with two parameters, the increment and the total number of points
Step 4: curse at Image::Magic for creating duplicates, remove those with "rm ./*-1.png"
Step 5: animate with back-and-forth action: convert -delay 4x120 ./*.png `ls -r ./*png` output.gif 
Step 6: remove the intermediate .png files with rm *png 
