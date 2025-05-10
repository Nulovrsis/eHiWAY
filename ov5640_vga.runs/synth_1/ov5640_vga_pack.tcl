cd   "D:/Competition/eLinx3.0/bin/shell/bin"
set tclFile  "D:/Competition/eLinx3.0/bin/shell/bin/run_pack.tcl"
set dir "D:/ehiway"
set prj ov5640_vga
set topEntity ov5640_vga_640x480
set seriesName "eHiChip6"
set deviceName "EQ6HL130"
set packageName "CSG484_H"
set synthName synth_1
source $tclFile
run_pack $dir $prj $topEntity $seriesName $deviceName $packageName $synthName
exit 0
