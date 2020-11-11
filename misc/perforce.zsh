export P4DIFF="vimdiff"
export P4EDITOR="vim"
export P4MERGE="~/.dotfiles/bin/p4merge"

function flexifi_view1() {
    export P4PORT="qctp422.qualcomm.com:1666"
    export P4USER=$USER
    export P4CLIENT="${USER}_flexifi_view1"
    export PROJECTS_HOME="/prj/qct/mtsg/sandiego/5g_users/highlander/${USER}/${USER}_flexifi_view1"
    cd $PROJECTS_HOME
}


