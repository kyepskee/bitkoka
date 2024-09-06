main=".koka/v3.1.2/js-debug-3eb290/bittorrent__main.mjs"
koka --target=jsnode bittorrent.kk
gawk -i inplace 'NR==5{print "import * as $peer from \"./peer.mjs\";"}1' $main
node $main
