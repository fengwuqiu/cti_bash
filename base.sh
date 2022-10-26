#!/bin/bash
#---------------------参数定义--------------------#
my_path=$(readlink -f $(dirname $0))
version_type=$HOME/cti-launch/boot_sh # 车辆1.2
version_type_=$HOME/cti_ade_home      # 车辆3.0
paramter_name=cti-config
paramter_url="https://gitee.com/ctinav/$paramter_name.git" #全局配置地址
cti_config=cti-config
cti_launch=cti_launch
init_dir=cti_install_init
ros_type=humble
apt_path=/etc/apt/apt.conf.d
source_path=/etc/apt/sources.list.d
mysql_username="root" #mysql 帐号密码
mysql_password=123456
#--------------------------------------------
#--车辆编号--
function get_robot_number() {
    while [ true ]; do
        robot_number=$(whiptail --title "参数获取" --inputbox "请输入正确的车辆编号：" 10 60 00303 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
            echo "输入的车辆编号:$robot_number"
            number=$(echo $robot_number | grep -E "^[0A][0-9]{4,4}$")
            if [ $? -eq 0 ]; then
                whiptail --title="注意" --msgbox "参数输入成功！" 10 60
                break
            else
                whiptail --title="错误" --msgbox "参数输入格式有误:$robot_number,请重新输入！" 10 60
            fi
        else
            exit 1
        fi
    done
}

#--硬件版本--
function get_robot_version() {
    while [ true ]; do
        hardware_ver=$(whiptail --title "参数获取" --inputbox "请输入正确的硬件版本号：" 10 60 v6.1 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
            echo "输入硬件版本号:$hardware_ver"
            ver=$(echo $hardware_ver | grep -E "^v[0-9]{1,}\.[0-9]{1,}$")
            if [ $? -eq 0 ]; then
                whiptail --title="注意" --msgbox "参数输入成功！" 10 60
                break
            else
                whiptail --title="错误" --msgbox "参数输入格式有误:$hardware_ver,请重新输入！" 10 60
            fi
        else
            exit 1
        fi
    done
}
#镜像源更新
function source_update() {
    if [ ! -f $source_path/ros-latest.list ]; then
        whiptail --title="错误" --msgbox "不存在$source_path/ros-latest.list文件！！！" 10 60
        exit 1
    fi
    {
        echo "0"
        sleep 1
        grep "http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/" $source_path/ros-latest.list
        if [ $? -ne 0 ]; then
            grep "http://packages.ros.org/ros/ubuntu" $source_path/ros-latest.list
            if [ $? -ne 0 ]; then
                echo "30"
                sleep 1
                sudo sh -c '. /etc/lsb-release && echo "deb http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ lsb_release -cs` main" > /etc/apt/sources.list.d/ros-latest.list'
                echo "60"
                sleep 1
                if [ $? -eq 0 ]; then
                    sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
                    if [ $? -eq 0 ]; then
                        sudo apt-get update
                    fi
                    echo "80"
                    sleep 1
                fi
            fi
        fi
        echo "100"
        sleep 1
    } |
        whiptail --gauge "正在镜像源更新..." 6 60 0
    if [ $? -ne 0 ]; then
        whiptail --title="错误" --msgbox "进度被取消！镜像源更新失败！" 10 60
    fi
    sync
}

#用户组更新
function usergroup_update() {
    {
        echo "0"
        sleep 1
        echo "# 正在添加用户组"
        echo "50"
        sleep 1
        sudo usermod -aG dialout $USER
        sudo usermod -aG audio $USER
        sudo usermod -aG video $USER
        echo "100"
        sleep 1
    } |
        whiptail --gauge "正在添加用户组..." 6 60 0
    if [ $? -ne 0 ]; then
        whiptail --title="错误" --msgbox "进度被取消！添加用户组失败！" 10 60
    fi
}
#显卡驱动修复
function nvidia_repair() {
    {
        echo "0"
        sleep 1
        sudo apt install dkms
        sudo dkms install -m nvidia -v 460.84
        echo "50"
        sleep 1
        if [ -e $apt_path/10periodic ]; then
            sudo sed -i "s/1/0/g" $apt_path/10periodic
        fi
        echo "100"
        sleep 1
    } |
        whiptail --gauge "正在升级显卡驱动..." 6 60 0
    if [ $? -ne 0 ]; then
        whiptail --title="错误" --msgbox "升级被取消，显卡驱动修复失败！" 10 60
    fi
}

#依赖库更新
function depend_update() {
    {
        echo "0"
        sleep 1
        sudo chmod u+x $my_path/depend.sh
        echo "50"
        sleep 1
        $my_path/depend.sh
        echo "100"
        sleep 1
    } |
        whiptail --gauge "正在安装可安装依赖..." 6 60 0
    if [ $? -ne 0 ]; then
        whiptail --title="错误" --msgbox "更新被取消！依赖安装失败！" 10 60
    fi
}

#frp服务配置
function frpservice_update() {
    if [ ! -f /etc/cti-frpc.ini ]; then
        whiptail --title="错误" --msgbox "/etc/cti-frpc.ini文件不存在！" 10 60
        exit 1
    fi
    robot_n=$1
    if [ ! $robot_n ]; then
        get_robot_number
        robot_n=$robot_number
    fi
    first_char=${robot_n:0:1}
    if [[ $first_char = "A" ]]; then
        frpc_port=2${robot_n:1}
    else
        frpc_port=16${robot_n:2}
    fi
    frp_name=sunny-$robot_n-ssh
    echo "车辆frp名称:$frp_name 端口号:$frpc_port"
    robot_frp_name=$(cat /etc/cti-frpc.ini | grep -E "^\[.*\]$")
    if [ ! $robot_frp_name ]; then
        whiptail --title="错误" --msgbox "/etc/cti-frpc.ini文件内容异常！" 10 60
        exit 1
    fi
    robot_frp_port=$(cat /etc/cti-frpc.ini | grep "remote_port" | awk '{print $3}')
    if [ ! $robot_frp_port ]; then
        whiptail --title="错误" --msgbox "/etc/cti-frpc.ini文件内容异常！" 10 60
        exit 1
    fi
    #--------------------------------------------
    {
        echo "0"
        sleep 1
        robot_frp_name=${robot_frp_name##*[}
        robot_frp_name=${robot_frp_name%%]*}
        echo "40"
        sleep 1
        sudo sed -i "s|$robot_frp_name|$frp_name|" /etc/cti-frpc.ini
        echo "70"
        sleep 1
        sudo sed -i "s|$robot_frp_port|$frpc_port|" /etc/cti-frpc.ini
        echo "100"
        sleep 1
    } |
        whiptail --gauge "正在配置frp服务..." 6 60 0
    if [ $? -ne 0 ]; then
        whiptail --title="错误" --msgbox "更新被取消！frp服务更新失败！" 10 60
    fi
    sync
}

#version文件修改
function version_file_update() {
    robot_n=$1

    if [ ! $robot_n ]; then
        get_robot_number
        robot_n=$robot_number
    fi

    robot_v=$2
    if [ ! $robot_v ]; then
        get_robot_version
        robot_v=$hardware_ver

    fi
    version_path=$3 #version_type版本路径

    hw_ver=${robot_v%%.*}
    hw_nver=${robot_v##*.}
    echo "version文件更新,车辆编号:$robot_n 硬件版本:$hw_ver 版本序号:$hw_nver"
    {
        echo "0"
        sleep 1
        if [ -f $version_path/version ]; then
            echo "30"
            sleep 1
            cti_hver=$(cat $version_path/version | awk -F: '{print $1}')
            cti_env=$(cat $version_path/version | awk -F: '{print $2}')
            cti_nver=$(cat $version_path/version | awk -F: '{print $3}')
            cti_robot_n=$(cat $version_path/version | awk -F: '{print $4}')
            echo "50"
            sleep 1
            sed -i "s|$cti_hver|$hw_ver|g" $version_path/version
            sed -i "s|$cti_nver|$hw_nver|g" $version_path/version
            sed -i "s|$cti_robot_n|$robot_n|g" $version_path/version
            echo "70"
            sleep 1
        else
            echo "30"
            sleep 1
            mkdir -p $version_path
            touch $version_path/version
            cat /dev/null >$version_path/version
            echo "50"
            sleep 1
            echo "$hw_ver:wkyc:$hw_nver:$robot_n" >>$version_path/version
            chmod 664 $version_path/version
            echo "70"
            sleep 1
        fi
        echo "100"
        sleep 1
    } |
        whiptail --gauge "正在更新文件信息..." 6 60 0
    if [ $? -ne 0 ]; then
        whiptail --title="错误" --msgbox "更新被取消！version文件更新失败！" 10 60
    fi
    sync
}

#获取robot  number和version
function get_number_version() {

    get_robot_number
    robot_n=$robot_number
    get_robot_version
    robot_v=$hardware_ver
}

#系统参数配置更新
function sys_paramter_update() {
    robot_v=$1
    if [ ! $robot_v ]; then
        get_robot_version
        robot_v=$hardware_ver
    fi
    hw_ver=${robot_v%%.*}
    hw_nver=${robot_v##*.}
    if [ $hw_ver = "v6" ] && [ $hw_nver = "5" ]; then
        config_hver=$robot_v
    else
        config_hver=$hw_ver
    fi
    echo "配置版本号为：$config_hver"
    cd /tmp
    {
        echo "0"
        sleep 1
        if [ -d /tmp/$paramter_name ]; then
            rm -rf /tmp/$paramter_name
        fi
        echo "25"
        sleep 1
        git clone --depth=1 $paramter_url --branch $config_hver
        echo "50"
        sleep 1
        if [ -d /tmp/$paramter_name ]; then
            echo "70"
            sleep 1
            cp -rf /tmp/$paramter_name $HOME/
            rm -rf /tmp/$paramter_name
            echo "100"
            sleep 1
        fi
    } |
        whiptail --gauge "正在更新config版本..." 6 60 0
    if [ $? -ne 0 ]; then
        whiptail --title="错误" --msgbox "更新被取消！config文件更新进程失败！" 10 60
    fi
    cd $my_path
    sync
}

#系统版本安装
function system_install() {
    if [ ! -f $my_path/cti_upgrade ]; then
        whiptail --title="错误" --msgbox "未发现升级工具,请确认！" 10 60
        exit 1
    fi
    if [ -f $HOME/install/version ]; then
        pre_software_ver=$(cat $HOME/install/version)
    fi
    whiptail --title="注意" --msgbox "将进入操作命令窗口，输入账号密码！" 10 60
    sudo $my_path/cti_upgrade -s
    if [ -f $HOME/install/version ]; then
        software_ver=$(cat $HOME/install/version)
    fi
    whiptail --title="注意" --msgbox "升级前版本:$pre_software_ver 升级后版本:$software_ver！" 10 60
    sudo ldconfig
}

#更新docker镜像
function docker_image_update() {

    # 更新最新的导航release发行镜像
    docker pull dockerimages.ctirobot.com:8443/cti_ade_humble:release_latest &&
        docker tag dockerimages.ctirobot.com:8443/cti_ade_humble:release_latest cti_ade_humble:latest

    echo " 更新docker镜像成功 "

}

#"下载配置文件"
function dir_download() {
    cd ${version_type_} #进入cti_ade_home目录下

    if [ -d "${cti_launch}" ]; then
        rm -rf ${cti_launch}
    fi
    git clone -b ${ros_type} https://gitee.com/ctinav/cti_launch.git

    if [ -d "${cti_config}" ]; then
        rm -rf ${cti_config}
    fi
    git clone -b ${ros_type} https://gitee.com/ctinav/cti-config.git
    cd
}

function dir_updated() {
    cd ${version_type_} #进入cti_ade_home目录下

    #不进行删除,进行更新处理
    if [ ! -d "${cti_launch}" ]; then
        git clone -b ${ros_type} https://gitee.com/ctinav/cti_launch.git
    else
        cd ${cti_launch}
        git pull origin master
    fi
    cd
    # config配置更新,不允许删除,不允许更改cali文件夹内文件
    cd ${version_type_}
    if [ -d "${cti_config}" ]; then
        cd ${cti_config}
        git pull origin master
    fi
    cd
}

# 系统包安装
function system_pkg_install() {
    cd ${version_type_} #进入cti_ade_home目录下

    if [ ! -d "${init_dir}" ]; then
        rm -rf ${init_dir}
    fi
    git clone -b ${ros_type} https://gitee.com/ctinav/cti_install_init.git

    while [ $? -gt 0 ]; do
        if [ ! -f "$init_dir" ]; then
            rm -rf $init_dir
        fi
        git clone -b ${ros_type} https://gitee.com/ctinav/cti_install_init.git
    done

    cd ${version_type_}/${init_dir} #进入cti_ade_home目录下

    sudo -s dpkg -i *.deb # 安装系统包
    [ $? -eq 0 ] && echo "安装系统包成功" || echo "安装系统包失败"

    rm -rf ${version_type_}/${init_dir} #删除cti_install_init目录
    echo " 删除安装文件夹成功"

    sync
}

# 本地数据库创建
function mysql_create() {

    #车辆id映射mysql端口
    # echo "robot_id:" $(cat /home/neousys/cti_ade_home/version)
    # robot_id=2$(cat /home/neousys/cti_ade_home/version | awk '{split($1,arr,":A"); print arr[2]}')   #  :A
    robot_id=2$(cat /home/neousys/cti_ade_home/version | awk -F ":A" '{print $NF}')
    echo $robot_id

    #创建并挂载mysql_docker容器
    docker run -d --restart=always --name mysql -v ${version_type_}/mysql/conf:/etc/mysql/conf.d \
        -v ${version_type_}/mysql/data:/var/lib/mysql -v ${version_type_}/mysql/log:/var/log/mysql/ \
        -p $robot_id:3306 -e MYSQL_ROOT_PASSWORD=${mysql_password} -d mysql:5.7

    [ $? -eq 0 ] && echo "创建mysql_docker成功" || echo "创建mysql_docker失败"

    docker restart mysql
    docker cp /usr/share/zoneinfo/Asia/Shanghai mysql:/usr/share/zoneinfo/Asia # 设置docker数据库时间
    docker exec -i mysql bash <<EOF
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime           
EOF
    [ $? -eq 0 ] && echo "set time success" || echo " set time success fail"

    docker restart mysql
    sleep 1
    docker exec -i mysql bash <<EOF
        mysql -u $mysql_username -p$mysql_password
        create database qfw_test
EOF
    [ $? -eq 0 ] && echo "创建数据库成功" || echo "创建数据库失败"

    docker exec -i mysql bash <<EOF
mysql -u $mysql_username -p$mysql_password
use qfw_test;
CREATE TABLE sch_state (
record_id bigint(20) NOT NULL AUTO_INCREMENT,
task_id varchar(100) DEFAULT NULL,
execute_times tinyint(1) DEFAULT NULL,
begin_time varchar(100) NOT NULL,
task_type varchar(20) NOT NULL,
fail_repeat tinyint(1) DEFAULT NULL,
interrupt_repeat tinyint(1) DEFAULT NULL,
msg_id varchar(100) DEFAULT NULL,
command_type varchar(20) NOT NULL,
state int(11) DEFAULT NULL,
command_mode varchar(20) DEFAULT NULL,
stamp int(11) DEFAULT NULL,
latitude double DEFAULT NULL,
longitude double NOT NULL,
altitude double DEFAULT NULL,
orientation double DEFAULT NULL,
waypoint_id varchar(100) DEFAULT NULL,
waypoint_rule varchar(20) DEFAULT NULL,
waypoint_type varchar(20) DEFAULT NULL,
area double DEFAULT NULL,
efficiency int(11) DEFAULT NULL,
progress int(11) DEFAULT NULL,
coverage_rate int(11) DEFAULT NULL,
mission_time double DEFAULT NULL,
pose_pos_x float DEFAULT NULL,
pose_pos_y float DEFAULT NULL,
pose_pos_z float DEFAULT NULL,
pose_orient_x float DEFAULT NULL,
pose_orient_y float DEFAULT NULL,
pose_orient_z float DEFAULT NULL,
pose_orient_w float DEFAULT NULL,
qr varchar(100) DEFAULT NULL,
hive_qr varchar(100) DEFAULT NULL,
dock_qr varchar(100) DEFAULT NULL,
rfid varchar(100) DEFAULT NULL,
hive_type varchar(100) DEFAULT NULL,
hive_device varchar(100) DEFAULT NULL,
spacing double DEFAULT NULL,
offset int(10) DEFAULT NULL,
position int(10) DEFAULT NULL,
sweep_mode varchar(20) DEFAULT NULL,
spray varchar(20) DEFAULT NULL,
zoneid varchar(20) DEFAULT NULL,
lidopen_level varchar(20) DEFAULT NULL,
avoid_mode varchar(20) DEFAULT NULL,
recoup_mode varchar(20) DEFAULT NULL,
sweep_speed_level varchar(20) DEFAULT NULL,
breakpoint varchar(20) DEFAULT NULL,
created_time int(64) NOT NULL,
time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
loop_times int(11) DEFAULT NULL,
closed_run_day int(20) NOT NULL,
monday tinyint(1) DEFAULT NULL,
tuesday tinyint(1) DEFAULT NULL,
wednesday tinyint(1) DEFAULT NULL,
thursday tinyint(1) DEFAULT NULL,
friday tinyint(1) DEFAULT NULL,
saturday tinyint(1) DEFAULT NULL,
sunday tinyint(1) DEFAULT NULL,
create_time_str varchar(20) DEFAULT NULL,
PRIMARY KEY (record_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
EOF
    [ $? -eq 0 ] && echo "创建数据表成功" || echo "创建数据表失败"

}

function depend_install() {
    cd
    if [ ! -d "cti_bash" ]; then
        cd
        git clone https://gitee.com/ctinav/cti_bash.git
        ./cti_bash/depend_ros2.sh
        [ $? -eq 0 ] && echo "安装依赖成功" || echo "安装依赖失败"
    else
        cd
        ./cti_bash/depend_ros2.sh
        [ $? -eq 0 ] && echo "安装依赖成功" || echo "安装依赖失败"
    fi

}

function run() {
    #---------------------选择所需功能-----------------#

    listtype=$(whiptail --title "功能选择列表" --menu "选择车辆类型：" 15 60 4 \
        "1" "阳光车辆1.2版本新车配置 " \
        "2" "阳光车辆3.0版本新车配置 " 3>&1 1>&2 2>&3)

    echo "你的选择$listtype.并继续更新."
    case $listtype in
    1)
        listchose=$(whiptail --title "功能选择列表" --menu "请选择你想操作的项目：" 15 60 4 \
            "1" "初始新车配置" \
            "2" "系统版本升级" \
            "3" "车辆参数更新" \
            "4" "硬件版本修改" \
            "5" "frp服务配置" \
            "6" "依赖库更新" \
            "7" "更新用户组" \
            "8" "镜像源更新" \
            "9" "显卡驱动修复" 3>&1 1>&2 2>&3)

        whiptail --title "请确认你的选择" --yesno "你目前选择的配置项$listchose,是否继续？" 10 60
        if [ $? -ne 0 ]; then
            echo "选择退出"
            exit 1
        fi
        echo "你的选择$listchose.并继续更新."
        case $listchose in
        1)
            while [ true ]; do
                get_robot_number
                get_robot_version
                whiptail --title "配置信息确认" --yes-button "继续" --no-button "返回" --yesno "请确认以下信息是否输入有误? \
                          车端号:$robot_number \
                          硬件版本:$hardware_ver" 10 60
                if [[ $? -eq 0 ]]; then
                    break
                else
                    whiptail --title="注意" --yesno "进入重新输入界面" 10 60
                    if [[ $? -ne 0 ]]; then
                        exit 0
                    fi
                    echo "重新输入"
                fi
            done
            system_install
            sys_paramter_update $hardware_ver
            version_file_update $robot_number $hardware_ver $version_type
            frpservice_update $robot_number
            depend_update
            usergroup_update
            source_update
            ;;
        2)
            system_install
            ;;
        3)
            sys_paramter_update
            ;;
        4)
            get_number_version
            version_file_update $robot_number $hardware_ver $version_type
            ;;
        5)
            frpservice_update
            ;;
        6)
            depend_update
            ;;
        7)
            usergroup_update
            ;;
        8)
            source_update
            ;;
        9)
            nvidia_repair
            ;;
        *)
            echo "没有该选项"
            ;;
        esac
        ;;
    2)
        listchose_=$(
            whiptail --title "功能选择列表" --menu "请选择你想操作的项目：" 15 60 4 \
                "1" "初始新车配置" \
                "2" "(导航升级)docker镜像更新" \
                "3" "(参数文件)配置文件更新(慎点)" \
                "4" "frp包安装(慎点)" \
                "5" "硬件版本修改" \
                "6" "frp服务配置" \
                "7" "本地数据库创建" \
                "8" "安装依赖" 3>&1 1>&2 2>&3)

        whiptail --title "请确认你的选择" --yesno "你目前选择的配置项$listchose_,是否继续？" 10 60
        if [ $? -ne 0 ]; then
            echo "选择退出"
            exit 1
        fi
        echo "你的选择$listchose_.并继续更新."
        case $listchose_ in
        1)
            whiptail --title "注意" --yes-button "继续" --no-button "返回" --yesno "即将清空车辆所有信息,重新进行车辆初始化配置,会导致所有标定后的数据清空,是否继续执行?" 10 60
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
            while [ true ]; do
                get_robot_number
                get_robot_version
                whiptail --title "配置信息确认" --yes-button "继续" --no-button "返回" --yesno "请确认以下信息是否输入有误? \
                          车端号:$robot_number \
                          硬件版本:$hardware_ver" 10 60
                if [[ $? -eq 0 ]]; then
                    break
                else
                    whiptail --title="注意" --yesno "进入重新输入界面" 10 60
                    if [[ $? -ne 0 ]]; then
                        exit 0
                    fi
                    echo "重新输入"
                fi
            done
            docker_image_update
            dir_download
            system_pkg_install
            version_file_update $robot_number $hardware_ver $version_type_
            frpservice_update
            mysql_create
            depend_install
            ;;
        2)
            whiptail --title "注意" --yes-button "继续" --no-button "返回" --yesno "即将进行导航版本单独更新,是否继续执行?" 10 60
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
            docker_image_update
            ;;
        3)
            whiptail --title "注意" --yes-button "继续" --no-button "返回" --yesno "（慎选）雷达以及车辆基础配置文件以及launch文件即将被修改,雷达校准文件不变,是否继续执行?" 10 60
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
            dir_updated
            ;;
        4)
            whiptail --title "注意" --yes-button "继续" --no-button "返回" --yesno "（慎选）frp配置即将被覆盖,是否继续执行?" 10 60
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
            system_pkg_install
            ;;
        5)
            whiptail --title "注意" --yes-button "继续" --no-button "返回" --yesno "硬件版本信息即将被修改,是否继续执行?" 10 60
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
            get_number_version
            version_file_update $robot_number $hardware_ver $version_type_
            ;;
        6)
            whiptail --title "注意" --yes-button "继续" --no-button "返回" --yesno "（慎选）远程连接配置文件即将被修改,是否继续执行?" 10 60
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
            frpservice_update
            ;;
        7)
            whiptail --title "注意" --yes-button "继续" --no-button "返回" --yesno "即将重新创建数据库,是否继续执行?" 10 60
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
            mysql_create
            ;;
        8)
            whiptail --title "注意" --yes-button "继续" --no-button "返回" --yesno "即将重新安装依赖信息,是否继续执行?" 10 60
            if [[ $? -ne 0 ]]; then
                exit 1
            fi
            depend_install
            ;;
        *)
            echo "没有该选项"
            ;;

        esac
        ;;

    esac
}
#---------------------RUN-------------------------#
sudo date
run
sleep 3

if [ -d ${HOME}/cti_bash ]; then
    rm -rf ${HOME}/cti_bash
fi

whiptail --title "重启" --yesno "配置完成是否重启车辆？" 10 60
if [ $? -eq 0 ]; then
    echo "选择重启"
    # sudo reboot
fi

sync
