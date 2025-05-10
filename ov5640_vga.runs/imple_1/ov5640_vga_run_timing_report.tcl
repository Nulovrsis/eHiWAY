cd   "D:/Competition/eLinx3.0/bin/shell/bin"
set tclFile  "D:/Competition/eLinx3.0/bin/shell/bin/run_timing_report.tcl"
set dir "D:/ehiway"
set prj ov5640_vga
set topEntity ov5640_vga_640x480
set seriesName "eHiChip6"
set deviceName EQ6HL130
set ImpleName imple_1
source $tclFile
run_tming_report $dir $prj $topEntity $seriesName $deviceName $ImpleName
exit 0
