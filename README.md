# convert_video
Convert video's to H.265

Here are the parameters that are currently supported

//Not used yet, is hardcoded right now
EXT="mkv\\|avi\\|mp4\\|mov\\"

//Source if you don't provide one
SRC="/media/TV/Breaking Bad/Season 05/"

//Temporary destination 
DEST="/media/Pool2/Temp"

//Extension for final file
DEST_EXT=mkv

//Log file
LogFile="/home/files/Dropbox/Automator/Logs"

//Path to Handbrake CLI
HANDBRAKE_CLI=HandBrakeCLI

//Default quality
Quality=18

//Default Speed
Preset=medium

//Not used currently
MAXDEPTH="-maxdepth 0"

//Not used currently
SIZE="-size +5G"
