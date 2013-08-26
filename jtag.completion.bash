complete -F get_jtag_targets jtag
function get_jtag_targets()
{
 if [ -z $2 ] ; then
     COMPREPLY=(`jtag help -c`)
 else
     COMPREPLY=(`jtag help -c $2`)
 fi
}
