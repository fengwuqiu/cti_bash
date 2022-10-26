#!/bin/bash

#---------------------参数定义--------------------#
DIRNAME=install
INSTALLNAME=install
PACKAGETYPE=install
INSTALLNAMELIST=.cti_installed.list
INSTALLNAMELISTPATCH=.cti_installed_patch.list

current_path=$HOME/cti-launch/boot_sh
apt_path=/etc/apt/apt.conf.d
start_flag=0
files="cti-config"
my_path=$(readlink -f  $(dirname $0))
upgrade_path=/usr/bin

#修改配置文件参数，修改版本车辆序号
robot_n="0"                 #机器序号
config_path=/etc            #cti-frpc.ini 文件路径
remote_name="remote_port"   #参数名
oldValue=0                  #旧的参数值
cti_env="sty"               #部署环境（暂时指定）
cti_hver="v6"               #硬件版本
cti_nver="0"                #序列号

#-----------------------------
#循环获取正确参数
#获取车子序号（大小写）
#硬件版本号（大小写）帐号，密码
#----------------------------
in_flag=0
while [ $in_flag -eq 0 ]
do
    robot_while=0
    while [ $robot_while -eq 0 ]
    do
        robotnumber=$(whiptail --title "参数获取" --inputbox "请输入正确的车子序号：" 10 60 如:00303 3>&1 1>&2 2>&3)
        numberflag=$?
        LENGTH_NUMB=`echo $robotnumber|awk '{print length($0)}'`
        FIRSTSTRING=${robotnumber:0:1}
        echo "首字符：$FIRSTSTRING"
        if [[ $FIRSTSTRING != "0" ]] && [[ $FIRSTSTRING != "A" ]]; then
            whiptail --title="错误!" --msgbox "参数输入格式有误:$robotnumber,请重新输入并注意大小写！！！" 10 60
            robot_while=0
        elif [[ $LENGTH_NUMB -ne 5 ]]; then
            whiptail --title="错误!" --msgbox "参数输入格式有误:$robotnumber,请重新输入并注意大小写！！！" 10 60
            robot_while=0
        else
            whiptail --title="注意" --msgbox "参数输入成功！" 10 60
            robot_while=1
        fi   
    done

    hver_flag=0
    while [ $hver_flag -eq 0 ]
    do
        current_hver=$(whiptail --title "参数获取" --inputbox "请输入正确的硬件版本号：" 10 60 如:v6.1 3>&1 1>&2 2>&3)
        hverflag=$?
        FIRSTSTRING_HVER=${current_hver:0:1}
        echo "首字符：$FIRSTSTRING_HVER"
        # current_batch=$(whiptail --title "参数获取" --inputbox "请输入正确的批次号：" 10 60 如:W 3>&1 1>&2 2>&3)
        # username=$(whiptail --title "参数获取" --inputbox "请输入正确的git帐号：" 10 60 如:robot 3>&1 1>&2 2>&3)
        # password=$(whiptail --title "参数获取" --inputbox "请输入正确的git密码：" 10 60 如:robot666 3>&1 1>&2 2>&3) 
        if [[ $FIRSTSTRING_HVER != "v" ]]; then
            whiptail --title="错误!" --msgbox "参数输入格式有误:$current_hver,请重新输入并注意大小写！！！" 10 60
            hver_flag=0
        else
            whiptail --title="注意" --msgbox "参数输入成功！" 10 60
            hver_flag=1
        fi
    done

    if [[ $hverflag = 0 ]]; then
        whiptail --title "配置信息确认" --yes-button "继续" --no-button "返回"  --yesno "请确认以下信息是否输入有误? \
                        车端号:$robotnumber \
                        硬件版本:$current_hver" 10 60
        infoflag=$?
        if [[ $infoflag = 0 ]]; then
            whiptail --title="注意" --msgbox "参数获取成功，即将进行下一步。" 10 60
            in_flag=1
        else
            whiptail --title="注意" --msgbox "进入重新输入界面！" 10 60
            in_flag=0
        fi
    fi
done

hardware_hver=${current_hver%%.*}
echo "硬件版本号为：$hardware_hver"
current_nver=${current_hver##*.}
echo "硬件版本序列号为：$current_nver"

if [ $hardware_hver = "v6" ] && [ $current_nver = "5" ]; then
    config_hver=$current_hver
    echo "配置版本号为：$config_hver"
else
    config_hver=$hardware_hver
    echo "配置版本号为：$config_hver"
fi

#————————————开头判断车子端口号以及序号————————————#
robot_patch=$robotnumber
if [[ $FIRSTSTRING = "0" ]]; then
    ROBOTSTRING=${robotnumber:2}
    echo "车子序列号：$ROBOTSTRING"
    robothost=16$ROBOTSTRING
else
    ROBOTSTRING=${robotnumber:1}
    echo "车子序列号：$ROBOTSTRING"
    robothost=2$ROBOTSTRING
fi
#————————————长度判断车子端口号以及序号————————————#
# robot_patch=$robotnumber
# robotpass="c$robotnumber"
# LENGTH=`echo $robotnumber|awk '{print length($0)}'`
# if [[ $LENGTH -eq 4 ]]; then
#     robothost=2$robotnumber
#     robot_patch=$current_batch$robotnumber
# elif [[ $LENGTH -eq 3 ]]; then
#     robothost=16$robotnumber
# elif [[ $LENGTH -eq 2 ]]; then
#     robothost=160$robotnumber
# else
#     robothost=1600$robotnumber
# fi
#————————————大小判断车子端口号以及序号————————————#
# if [[ $robotnumber -ge 100 ]] && [[ $robotnumber -le 999 ]]; then
#     robothost=16$robotnumber
# elif [[ $robotnumber -le 99 ]]; then
#     robothost=160$robotnumber
# else
#     robothost=2$robotnumber
# fi

echo $robothost
address="https://gitee.com/ctinav/cti-config.git"

#docker路径
DODEB_PATH=$HOME/install/docker
DOCK_PATH=$HOME/install

mirrorpath=/etc/apt/sources.list.d
mirrorInfo="http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/"
mirrorInfo2="http://packages.ros.org/ros/ubuntu"

#判断init是否为最新，安装后一定要将旧的删除
dpkgpath=$HOME/install
initpath=/etc/init.d
oldfile="ppp_auto_4g"
#---------------------参数定义--------------------#

#---------------------导航定义--------------------#
function parsename(){
    filename=$(echo $1 | cut -f 1 -d "_")
    filename=${filename%%.*}
    #filename=${filename,,}
}

#卸载所有传参
function dpkg_uninstall(){
    sudo dpkg --purge $@ 
}

#安装所有传参
function dpkg_install(){
    sudo dpkg -i $@
    #安装依赖
    # for file in $@; do
    #     filedepends=$(dpkg --info $file | grep "Depends" | sed s/[[:space:]]//g | cut -f 2 -d ":")
    #     filedepends=(${filedepends//,/ })
    #     if [ 0 -lt ${#filedepends[*]} ]; then
    #         echo "依赖 ${filedepends[*]}."
    #         apt_install ${filedepends[*]}
    #     fi
    # done
}

#检查安装文件
function checkfile(){
    if [ ! -f $1 ]; then
        echo "未发现$1."
        return 2
    fi
    filename=$(dpkg --info $1 | grep "Package" | sed s/[[:space:]]//g | cut -f 2 -d ":")
    fileversion=$(dpkg --info $1 | grep "Version"  | sed s/[[:space:]]//g | cut -f 2 -d ":")
    filearch=$(dpkg --info $1 | grep "Architecture"  | sed s/[[:space:]]//g | cut -f 2 -d ":")
    echo "需安装$1信息:name:$filename version:$fileversion arch:$filearch."
    if [ "" == "$filename" ]; then
        echo "文件包名异常."
        return 3
    fi
    info=$(dpkg -l | grep $filename | tr -s ' ')
    if [ "" == "$info" ]; then
        unset check_softversion
        unset check_filearch
        echo "未安装过$1"
    else
        check_softversion=$(echo $info | cut -d ' ' -f 3)
        check_filearch=$(echo $info | cut -d ' ' -f 4)
        echo "已安装$filename信息:(version:$check_softversion arch:$check_filearch)."
    fi
    
    echo "check version:$fileversion == $check_softversion?"
    if [ "$fileversion" = "$check_softversion" ]; then
        return 1
    fi
    return 0
}

#初始化配置参数
function initSYSTEM(){
    if [ -d "$1" ]; then
        echo "初始化参数配置."
        init_files=$(ls $1 | grep ".deb")
        for init_file in $init_files; do
            echo "初始化配置文件$init_file."
            dpkg_install $1/$init_file 
        done
    fi
}

#获取软件安装包
function getDEB(){
    # cd $HOME 
    #--bak
    if [ -d "$HOME/$INSTALLNAME" ]; then
        if [ -f "$HOME/$INSTALLNAME.tar" ]; then
            sudo rm -r $HOME/$INSTALLNAME.tar
        fi
        sudo tar cvf $HOME/$INSTALLNAME.tar $HOME/$INSTALLNAME > /dev/null
        sudo rm -r $HOME/$INSTALLNAME
    fi
    echo "$DIRNAME"
    if [ -d "$HOME/$DIRNAME" ]; then
        sudo rm -r $HOME/$DIRNAME
    fi
#:<<eof
    echo "获取远程文件,please wait... "
    git clone https://gitee.com/ctinav/$DIRNAME.git
    mv $DIRNAME $HOME
#eof
    sync
    if [ ! -e "$HOME/$DIRNAME" ]; then
        if [ -f "$HOME/$INSTALLNAME.tar" ]; then
            tar xvf $HOME/$INSTALLNAME.tar > /dev/null
        fi
        echo "下载$DIRNAME失败."
        # cd $CURPWD
        exit -1
    fi
    mv $HOME/$DIRNAME $HOME/$INSTALLNAME
    # cd $CURPWD
}

#更新系统
function updateSYSTEM(){
    PACKAGEDIR=$1
    #检测安装
    install_files=$(ls $PACKAGEDIR | grep ".deb")
    if [ ! -d $PACKAGEDIR ] || [ "" == "$install_files" ]; then
        echo "$PACKAGEDIR目录未找到任何deb文件.安装失败!"
        return -1
    fi
    
    if [ ! -e $PACKAGEDIR/init ]; then
        PACKAGETYPE=install_patch
        INSTALLNAME=install_patch
    fi

    #first uninstall unuse node
    if [ $PACKAGETYPE =  "install_patch" ]; then
        #已安装的软件
        if [  -f "$HOME/$INSTALLNAMELISTPATCH" ]; then
            installed_files=$(cat $HOME/$INSTALLNAMELISTPAT1CH)
        else
            # initSYSTEM $PACKAGEDIR/init
            touch $HOME/$INSTALLNAMELISTPATCH
        fi

        echo "seach unusefull software and umount,please waiting..."
        for installed_file in $installed_files; do
            parsename $installed_file
            unusefilename=$filename
            check=$(echo $install_files | grep "$unusefilename")
            if [ "" == "$check" ]; then
                unupgrade_array[${#unupgrade_array[*]}]=$unusefilename
            fi
        done

        cat /dev/null > $HOME/$INSTALLNAMELISTPATCH
    else
        #已安装的软件
        if [  -f "$HOME/$INSTALLNAMELIST" ]; then
            installed_files=$(cat $HOME/$INSTALLNAMELIST)
        else
            initSYSTEM $PACKAGEDIR/init
            touch $HOME/$INSTALLNAMELIST
        fi

        echo "seach unusefull software and umount,please waiting..."
        for installed_file in $installed_files; do
            parsename $installed_file
            unusefilename=$filename
            check=$(echo $install_files | grep "$unusefilename")
            if [ "" == "$check" ]; then
                unusefile_array[${#unusefile_array[*]}]=$unusefilename
            fi
        done
        if [ 0 -lt ${#unusefile_array[*]} ]; then
            echo "卸载多余软件 ${unusefile_array[*]}."
            dpkg_uninstall ${unusefile_array[*]}
        fi
        cat /dev/null > $HOME/$INSTALLNAMELIST
    fi
    
    # cat /dev/null > $HOME/$INSTALLNAMELIST
    echo "开始安装$PACKAGEDIR"
    #second start  
    for install_file in $install_files; do
        checkfile $PACKAGEDIR/$install_file
        ret=$?
        if [ 0 -eq $ret ]; then
            installed_array[${#installed_array[*]}]=$PACKAGEDIR/$install_file
	    echo "安装列表------$install_file------"
        elif [ 1 -eq $ret ]; then
            echo "$install_file is the newest version."
        else 
            echo "$install_file安装异常."
            continue
        fi
        if [ $PACKAGETYPE =  "install_patch" ]; then
            echo $install_file >> $HOME/$INSTALLNAMELISTPATCH
        else
            echo $install_file >> $HOME/$INSTALLNAMELIST
        fi
    done
    if [ 0 -lt ${#installed_array[*]} ]; then 
        echo "安装 ${installed_array[*]}."
        dpkg_install ${installed_array[*]}
    fi
    # apt-get install -f -y
    return 0
}
#---------------------导航定义--------------------#

#---------------------函数定义--------------------#
#版本更新
function funVersion(){
    DIRNAME=cti_install
    # if [ ! -z "$2" ]; then
    #     DIRNAME=$2
    # fi
    echo "下载$DIRNAME更新."
    if [ $DIRNAME = "cti_install_patch" ]; then
        INSTALLNAME=install_patch
    fi
    getDEB
    echo "$HOME/$INSTALLNAME"
    updateSYSTEM $HOME/$INSTALLNAME
    if [ 0 -eq $? ]; then
        echo "安装成功."
    else
        echo "安装失败."
    fi
    # echo "*********************************"
    # if [ -e $HOME/cti_install ]; then
    #     sudo rm -rf $HOME/cti_install
    # fi
    # if [ -e $HOME/install ]; then
    #     sudo rm -rf $HOME/install
    # fi
    # sudo git clone https://gitee.com/ctinav/cti_install.git
    # sudo mv $my_path/cti_install $HOME
    # sudo dpkg -i $HOME/cti_install/init/*.deb
    # sudo dpkg -i $HOME/cti_install/*.deb
    # sudo mv $HOME/cti_install $HOME/install

    # echo "开始docker安装."
    # if [[ -e $DODEB_PATH ]]; then
    #     echo "docker deb is eist."
    #     # dockID=$(docker ps -a | grep cti_perception | awk '{print $1}') #短ID
    #     dockID=$(docker inspect -f '{{.ID}}' cti_perception)   #长ID
    #     echo "dockerID号为：$dockID"
    #     docker start $dockID
        
    #     apt-get install expect -y
    #     echo "expect交互已安装."
    #     expect $DODEB_PATH/docker_mkdir.sh $dockID
    #     docker cp "$DODEB_PATH" $dockID:/workspace/install/
    #     # docker cp "$DOCK_PATH/entrypoint.sh" $dockID:/workspace/
    #     echo "deb包已迁移到docker容器内."
    #     expect $DODEB_PATH/docker_ex.sh $dockID
    #     #docker dpkg -i $dockID/install/*deb
    # else
    #     echo "不存在docker-deb包，安装失败."
    # fi
}

#配置cti环境
function ctiEnv() {
    env_dir=/opt/cti
    if [ -d $env_dir ]; then
        ros_distros=$(ls $env_dir)
        for ros_distro in $ros_distros; do
            if [ -f $env_dir/$ros_distro/setup.bash ]; then
                grep "source ${env_dir}/${ros_distro}/setup.bash" $HOME/.bashrc
                if [ $? -eq 0 ]; then 
                    echo ".baserc had source setup.bash!" 
                    whiptail --title="提示" --msgbox "环境配置成功" 10 60
                else 
                    echo ".baserc have not source setup.bash!"
                    whiptail --title="错误" --msgbox "环境配置失败！！！" 10 60
                    echo "source ${env_dir}/${ros_distro}/setup.bash" >> $HOME/.bashrc
                fi
            fi
        done
    fi
    echo "配置环境完成."
}

#版本升级
function funInstall(){
    sudo cti_upgrade -s cti_install
    if [ -e $HOME/install ]; then
        whiptail --title="提示" --msgbox "版本更新成功" 10 60
    else
        whiptail --title="错误" --msgbox "版本更新被打断，更新失败" 10 60
    fi
}

#config配置更新
function funConfig(){
    {    
    echo "0" ; sleep 1
    if [ 0 -eq $start_flag ]; then
        if [ -e $HOME/$files ]; then
            rm -rf $HOME/$files
            echo "# 移除config文件" ; sleep 1
            echo "20" ; sleep 1
        else
            echo "# config文件不存在" ; sleep 1
            echo "20" ; sleep 1
        fi
        start_flag=0
        # echo "# 安装expect工具." ; sleep 1
        # echo "40" ; sleep 1
        # sudo apt-get install expect -y
        echo "# 正在更新config配置文件，查看vmap文件" ; sleep 1
        echo "50" ; sleep 1
        git clone $address --branch $config_hver #启动expect
        mv $files $HOME
        if [ -e $my_path/topic_state.yaml ]; then
            mv $my_path/topic_state.yaml $HOME/cti-launch/config
            if [ ! -e $HOME/cti-launch/config/topic_state.yaml ]; then
                whiptail --title="错误" --msgbox "配置文件移动失败！" 10 60
            fi
        fi
        if [ -e $HOME/$files ]; then
            echo "# 文件路径修改完成，更新完成" ; sleep 1
            echo "80"
        else
            # sudo apt-get install expect -y
            echo "# 文件读取失败，重新手动更新" ; sleep 1
            echo "70"
            # expect $my_path/sshstart.sh #启动expect
            # expect 安装失败，判断硬件版本信息重新下拉config文件
            git clone $address --branch $config_hver
            mv $files $HOME
            if [ -e $HOME/$files ]; then
                start_flag=0
                echo "# 手动更新成功" ; sleep 1
                echo "80" ; sleep 1
            else
                start_flag=1
                whiptail --title="错误" --msgbox "更新失败！" 10 60
                echo "手动更新失败" ; sleep 1
                echo "80" ; sleep 1
            fi
        fi
    else
        start_flag=1
        echo "# config文件无法更新！！！" ; sleep 1
        echo "80" ; sleep 1
    fi
    echo "# 文件更新进程已完成" ; sleep 1
    echo "100" ; sleep 1
    } |
    whiptail --gauge "正在更新config版本..." 6 60 0
    configflag=$?
    if [ $configflag = 0 ]; then
        whiptail --title="注意" --msgbox "config文件更新进程已完成！" 10 60
    else
        whiptail --title="错误" --msgbox "更新被取消！config文件更新进程失败！" 10 60
    fi
}

#version文件修改
function funVerfile(){
    {    
    echo "0" ; sleep 1
    if [ -f $current_path/version ]; then
        cti_hver=$(cat $current_path/version | awk -F: '{print $1}')
        cti_env=$(cat $current_path/version | awk -F: '{print $2}')
        cti_nver=$(cat $current_path/version | awk -F: '{print $3}')
        robot_n=$(cat $current_path/version | awk -F: '{print $4}')
        if [ $cti_hver != $hardware_hver ]; then
            sed -i "s|$cti_hver|$hardware_hver|g" $current_path/version
            echo "# 硬件版本已更改." ; sleep 1
            echo "30" ; sleep 1
        else
            echo "# 硬件版本不需要更改." ; sleep 1
            echo "30" ; sleep 1
        fi
        if [ $cti_nver != $current_nver ]; then
            sed -i "s|$cti_nver|$current_nver|g" $current_path/version
            echo "50" ; sleep 1
        else
            echo "# 不需要更改." ; sleep 1
            echo "50" ; sleep 1
        fi
        if [ $robot_n != $robot_patch ]; then
            # old_n=$robot_n
            # robot_n=$robot_patch
            sed -i "s|$robot_n|$robot_patch|g" $current_path/version #修改替换
            echo "# 机器序号已更改." ; sleep 1
            echo "70" ; sleep 1
        else
            old_n=$robot_n
            echo "# 机器序号不需要更改." ; sleep 1
            echo "70" ; sleep 1
        fi
    else
        echo "# 文件不存在，正在创建..." ; sleep 1
        echo "30" ; sleep 1
        touch $current_path/version
        cat /dev/null > $current_path/version
        echo "$hardware_hver:$cti_env:$current_nver:$robot_patch" >> $current_path/version
        chmod 664 $current_path/version
        echo "# 文件创建完成." ; sleep 1
        echo "70" ; sleep 1
    fi
    echo "# 文件更新完成." ; sleep 1
    echo "100" ; sleep 1
    } |
    whiptail --gauge "正在更新文件信息..." 6 60 0
    versionflag=$?
    if [ $versionflag = 0 ]; then
        whiptail --title="注意" --msgbox "version文件更新成功！" 10 60
    else
        whiptail --title="错误" --msgbox "更新被取消！version文件更新失败！" 10 60
    fi
}

#frp服务配置
function funFrpconfig(){
    {    
    echo "0" ; sleep 1
    if [ -e $config_path/cti-frpc.ini ]; then
        robot_n=$(cat $config_path/cti-frpc.ini | awk -F - '{print $2}')
        oldValue=$(cat $config_path/cti-frpc.ini | grep $remote_name | awk '{print $3}') #默认空格为分隔符
        if [ $robot_n != $robot_patch ]; then
            # old_n=$robot_n
            # robot_n=$robot_patch
            # whiptail --title="注意" --msgbox "选择ok后，请在终端根据指令提示输入帐号密码" 10 60
            sudo sed -i "s|$robot_n|$robot_patch|" $config_path/cti-frpc.ini
            echo "# 机器序号已更改." ; sleep 1
            echo "30" ; sleep 1
        else
            old_n=$robot_n
            echo "# 机器序号不需要更改." ; sleep 1
            echo "30" ; sleep 1
        fi
        if [ $oldValue -ne $robothost ]; then
            # whiptail --title="注意" --msgbox "选择ok后，请在终端根据指令提示输入帐号密码" 10 60
            sudo sed -i "s|remote_port = $oldValue|remote_port = $robothost|" $config_path/cti-frpc.ini
            echo "# 端口号已更改." ; sleep 1
            echo "70" ; sleep 1
        else
            echo "# 端口号不需要更改." ; sleep 1
            echo "70" ; sleep 1
        fi
    else 
        whiptail --title="错误" --msgbox "frpc文件不存在！！！" 10 60
        echo "frpc不存在，请重新更新！"
    fi
    echo "# frp文件更新完成." ; sleep 1
    echo "100" ; sleep 1
    } |
    whiptail --gauge "正在配置frp文件..." 6 60 0
    frpflag=$?
    if [ $frpflag = 0 ]; then
        whiptail --title="注意" --msgbox "frp文件更新成功！" 10 60
    else
        whiptail --title="错误" --msgbox "更新被取消！frp文件更新失败！" 10 60
    fi
}

#依赖安装
function funDepend(){
    {    
    echo "0" ; sleep 1
    echo "# 正在更新，请稍等..." ; sleep 1
    echo "10" ; sleep 1
    $my_path/depend.sh > $HOME/dependmsg.log
    echo "# 更新完成，正在检测结果..." ; sleep 1
    echo "50" ; sleep 1
    echo "# 完成."
    echo "100" ; sleep 1
    } |
    whiptail --gauge "正在安装可安装依赖..." 6 60 0
    dependflag=$?
    if [ $dependflag = 0 ]; then
        whiptail --title="注意" --msgbox "依赖安装成功！" 10 60
    else
        whiptail --title="错误" --msgbox "更新被取消！依赖安装失败！" 10 60
    fi
}

#init初始化更新
function funInitupdate(){
    {    
    echo "0" ; sleep 1
    if [ -e $initpath/$oldfile ]; then
        whiptail --title="错误" --msgbox "init为旧版本，请联系开发人员升级" 10 60
        echo "# 检测车辆为旧版本初始化状态，待更新" ; sleep 1
        echo "10" ; sleep 1
        echo "# 移除车辆init旧版本" ; sleep 1
        echo "30" ; sleep 1
        sudo dpkg -r cti-initsysconfig
        echo "# 安装最新base包" ; sleep 1
        echo "40" ; sleep 1
        sudo dpkg -i cti-base_*
        echo "# 安装最新init包" ; sleep 1
        echo "50" ; sleep 1
        sudo dpkg -i $dpkgpath/init/cti-init_*
        echo "# 安装最新startup包" ; sleep 1
        echo "60" ; sleep 1
        sudo dpkg -i $dpkgpath/init/cti-startup_*
        if [ -e $initpath/cti-startup ]; then
            echo "# 安装成功，移除旧版本init包" ; sleep 1
            echo "70" ; sleep 1
            sudo rm -rf $initpath/$oldfile
            if [ ! -e $initpath/$oldfile ]; then
                echo "# 旧版本移除成功！" ; sleep 1
                echo "80" ; sleep 1
            else
                whiptail --title="错误" --msgbox "旧版本移除失败！" 10 60
                echo "# 旧版本移除失败！" ; sleep 1
                echo "80" ; sleep 1
            fi
        else
            whiptail --title="错误" --msgbox "安装失败！" 10 60
            echo "# 安装失败！即将退出更新流程！" ; sleep 1
            echo "70" ; sleep 1
        fi
    else
        echo "# 检测车辆为最新版本，不需要进行更新" ; sleep 1
        echo "50" ; sleep 1
    fi
    echo "# 更新完成" ; sleep 1
    echo "100" ; sleep 1
    } |
    whiptail --gauge "正在更新init版本..." 6 60 0
    initflag=$?
    if [ $initflag = 0 ]; then
        whiptail --title="注意" --msgbox "init更新成功！" 10 60
    else
        whiptail --title="错误" --msgbox "更新被取消！init更新失败！" 10 60
    fi
}

#用户组添加
function funGroupadd(){
    {    
    echo "0" ; sleep 1
    echo "# 正在添加用户组" ; sleep 1
    echo "50" ; sleep 1
    sudo usermod -aG video neousys
    echo "# 添加用户组完成" ; sleep 1
    echo "100" ; sleep 1
    } |
    whiptail --gauge "正在添加用户组..." 6 60 0
    groupflag=$?
    if [ $groupflag = 0 ]; then
        whiptail --title="注意" --msgbox "添加用户组成功！" 10 60
    else
        whiptail --title="错误" --msgbox "进度被取消！添加用户组失败！" 10 60
    fi
}

#镜像更新
function funMirrorscheck(){
    # {
    echo "0" ; sleep 1
    if [ -e $mirrorpath/ros-latest.list ]; then
        grep $mirrorInfo $mirrorpath/ros-latest.list
        if [ $? -eq 0 ]; then
            echo "# 镜像版本正确" ; sleep 1
            echo "50" ; sleep 1
        else
            grep $mirrorInfo2 $mirrorpath/ros-latest.list
            if [ $? -eq 0 ]; then
                echo "# 镜像版本正确" ; sleep 1
                echo "50" ; sleep 1
                whiptail --title="提示" --msgbox "镜像版本正确！无需更新！" 10 60
            else
                echo "# 镜像版本错误" ; sleep 1
                echo "40" ; sleep 1
                whiptail --title="错误" --msgbox "镜像版本错误！正在进行更新！" 10 60
                echo "# 镜像正在更新" ; sleep 1
                echo "60" ; sleep 1
                sudo sh -c '. /etc/lsb-release && echo "deb http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ `lsb_release -cs` main" > /etc/apt/sources.list.d/ros-latest.list'
                if [ $? -eq 0 ]; then
                    sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
                    if [ $? -eq 0 ]; then
                        sudo apt-get update
                    else
                        whiptail --title="错误" --msgbox "镜像版本更新失败！！！" 10 60 
                    fi
                fi
            fi
        fi
    else
        whiptail --title="错误" --msgbox "不存在list文件！！！" 10 60
    fi
    echo "# 镜像检查更新完成" ; sleep 1
    echo "100" ; sleep 1
    # } |
    # whiptail --gauge "镜像检查更新中..." 6 60 0
    # mirrorflag=$?
    # if [ $mirrorflag = 0 ]; then
    #     whiptail --title="注意" --msgbox "镜像检查更新完毕！" 10 60
    # else
    #     whiptail --title="错误" --msgbox "镜像检查更新失败！" 10 60
    # fi
} 

#显卡驱动升级
function funNvidiaUpdate(){
    {    
    echo "0" ; sleep 1
    sudo apt install dkms
    echo "25" ; sleep 1
    sudo dkms install -m nvidia -v 460.84
    echo "50" ; sleep 1
    if [ -e $apt_path/10periodic ]; then
        sudo sed -i "s/1/0/g" $apt_path/10periodic
    fi
    echo "100" ; sleep 1
    } |
    whiptail --gauge "正在升级显卡驱动..." 6 60 0
    nvidiaflag=$?
    if [ $nvidiaflag = 0 ]; then
        whiptail --title="注意" --msgbox "升级显卡驱动成功！" 10 60
    else
        whiptail --title="错误" --msgbox "升级被取消，升级显卡驱动失败！" 10 60
    fi
}
#---------------------函数定义--------------------#

#-------------------选择所需功能------------------#
#功能选择列表
listchose=$(whiptail --title "功能选择列表" --menu "请选择你想更新的项目：" 15 60 4 \
            "1" "新车配置（All）" \
            "2" "版本升级" \
            "3" "config配置更新" \
            "4" "version文件修改" \
            "5" "frp服务配置" \
            "6" "安装依赖" \
            "7" "init初始化更新" \
            "8" "添加用户组" \
            "9" "镜像更新" \
            "10" "显卡驱动升级" 3>&1 1>&2 2>&3)
if [[ $listchose = "1" ]]; then
    whiptail --title "新车配置" --yesno "你确定现在进行新车配置吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funMirrorscheck
        funVersion
        ctiEnv
        funConfig
        funVerfile
        funFrpconfig
        funDepend
        # funInitupdate
        funGroupadd
        funNvidiaUpdate
        sudo ldconfig
    else    
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "2" ]]; then     #升级软件版本
    whiptail --title "config配置更新" --yesno "你确定现在进行Config配置更新吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funInstall
        funDepend
        funFrpconfig
        sudo ldconfig
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "3" ]]; then     #config配置更新
    whiptail --title "config配置更新" --yesno "你确定现在进行Config配置更新吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funConfig
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "4" ]]; then    #version文件修改
    whiptail --title "version文件修改" --yesno "你确定现在进行Version文件修改吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funVerfile
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "5" ]]; then   #配置frp服务
    whiptail --title "安装配置frp服务依赖" --yesno "你确定现在进行Frp配置更新吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funFrpconfig
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "6" ]]; then    #安装依赖
    whiptail --title "安装依赖" --yesno "你确定现在进行依赖安装吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funDepend
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "7" ]]; then   #init初始化更新
    whiptail --title "init初始化更新" --yesno "你确定现在进行Init初始化更新吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funInitupdate
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "8" ]]; then   #添加用户组
    whiptail --title "添加用户组" --yesno "你确定现在进行用户组添加吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funGroupadd
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "9" ]]; then
    whiptail --title "镜像更新" --yesno "你确定现在进行镜像更新吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funMirrorscheck
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
elif [[ $listchose = "10" ]]; then
    whiptail --title "显卡驱动升级" --yesno "你确定现在进行显卡驱动升级吗？" 10 60
    questionflag=$?
    if [ $questionflag = 0 ]; then
        funNvidiaUpdate
    else
        whiptail --title="注意" --msgbox "已取消更新！！！" 10 60
    fi
else
    echo "未选择任何功能项目."
fi
#---------------------选择所需功能-----------------#

#------------------------移除---------------------#
# rm -rf $HOME/cti_bash

sync
sync
sync