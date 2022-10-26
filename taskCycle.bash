#!/bin/bash
passWord=$1
USERHOME=$HOME/cti_ade_home
JQ_EXEC=`which jq`
echo "c$passWord" | sudo -S apt-get install jq -y

function judeTXT() {
    TaskName=$1
    if [[ ! -e $USERHOME/waypoint.json ]]; then
        echo "缺少点位信息文件"
        exit 1
    fi
    FILTER=".baseWaypoints[].altitude"
    # id=$(cat $FILE_PATH | ${JQ_EXEC} .menu.id | sed 's/\"//g')
    # bbb=$(jq '.baseWaypoints[]' $USERHOME/waypoint.json)
    names=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.baseWaypoints[].name' | sed 's/\"//g')
    altitudes=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.baseWaypoints[].altitude' | sed 's/\"//g')
    latitudes=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.baseWaypoints[].latitude' | sed 's/\"//g')
    longitudes=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.baseWaypoints[].longitude' | sed 's/\"//g')
    directions=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.baseWaypoints[].direction' | sed 's/\"//g')
    ids=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.baseWaypoints[].id' | sed 's/\"//g')
    waypointTypes=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.baseWaypoints[].waypointType' | sed 's/\"//g')

    CleanNames=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.sweepWaypoints[].name' | sed 's/\"//g')
    CleanAltitudes=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.sweepWaypoints[].altitude' | sed 's/\"//g')
    CleanLatitudes=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.sweepWaypoints[].latitude' | sed 's/\"//g')
    CleanLongitudes=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.sweepWaypoints[].longitude' | sed 's/\"//g')
    CleanDirections=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.sweepWaypoints[].direction' | sed 's/\"//g')
    CleanIds=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.sweepWaypoints[].id' | sed 's/\"//g')
    CleanWaypointTypes=$(cat $USERHOME/waypoint.json | ${JQ_EXEC} '.sweepWaypoints[].waypointType' | sed 's/\"//g')

    echo "names: "${names}
    echo "clean_names: "${Cleannames} 
    # arr=$names
    #数组
    namearr=($names)
    altarr=($altitudes)
    latarr=($latitudes)
    longarr=($longitudes)
    direcarr=($directions)
    idarr=($ids)
    typearr=($waypointTypes)

    CleanNamearr=($CleanNames)
    CleanAltarr=($CleanAltitudes)
    CleanLatarr=($CleanLatitudes)
    CleanLongarr=($CleanLongitudes)
    CleanDirecarr=($CleanDirections)
    CleanIdarr=($CleanIds)
    CleanTypearr=($CleanWaypointTypes)
    # array=(${str// / })
    # FILTER_ARRAY=(${FILTER//./ })
    
    AllNamearr=(${namearr[@]} ${CleanNamearr[*]})
    AllAltarr=(${altarr[@]} ${CleanAltarr[*]})
    AllLatarr=(${latarr[@]} ${CleanLatarr[*]})
    AllLongarr=(${longarr[@]} ${CleanLongarr[*]})
    AllDirecarr=(${direcarr[@]} ${CleanDirecarr[*]})
    AllIdarr=(${idarr[@]} ${CleanIdarr[*]})
    AllTypearr=(${typearr[@]} ${CleanTypearr[*]})

    num=0
    index=0
    for a in ${AllNamearr[*]}
    do
        numarr[$num]="$index"
        numarr[$num+1]="$a"
        ((index++))
        num=$(($num+2))
    done

    Cleannum=0
    Cleanindex=0
    for a in ${CleanNamearr[*]}
    do
        Cleannumarr[$Cleannum]="$Cleanindex"
        Cleannumarr[$Cleannum+1]="$a"
        ((Cleanindex++))
        Cleannum=$(($Cleannum+2))
    done
    echo "num: "${#AllNamearr[*]}
    echo "num: "${#AllAltarr[*]}
    echo "num: "${#AllLatarr[*]}
    echo "num: "${#AllLongarr[*]}
    echo "num: "${#AllDirecarr[*]}
    echo "num: "${#AllIdarr[*]}
    echo "num: "${#AllTypearr[*]}
    # echo $waypointTypes
}

function createTaskJson() {
    jsonType=$1
    if [[ -e $USERHOME/taskCycle.json ]]; then
        echo "exited"
        exit 0
    fi
    echo "home: "$USERHOME
    echo "type: "$jsonType
    if [[ $jsonType == "MOVE" ]]; then
        cd $USERHOME && touch taskCycle.json
        echo "{" > $USERHOME/taskCycle.json
        echo "  \"altitude\" : $altitude," >> $USERHOME/taskCycle.json
        echo "  \"latitude\" : $latitude," >> $USERHOME/taskCycle.json
        echo "  \"longitude\" : $longitude," >> $USERHOME/taskCycle.json
        echo "  \"orientation\" : $orientation," >> $USERHOME/taskCycle.json
        echo "  \"commandType\" : \"$commandType\"," >> $USERHOME/taskCycle.json
        echo "  \"waypointId\" : \"$waypointId\"," >> $USERHOME/taskCycle.json
        echo "  \"waypointRule\" : \"\"," >> $USERHOME/taskCycle.json
        echo "  \"target_altitude\" : $target_altitude," >> $USERHOME/taskCycle.json
        echo "  \"target_latitude\" : $target_latitude," >> $USERHOME/taskCycle.json
        echo "  \"target_longitude\" : $target_longitude," >> $USERHOME/taskCycle.json
        echo "  \"target_orientation\" : $target_orientation," >> $USERHOME/taskCycle.json
        echo "  \"target_commandType\" : \"$target_commandType\"," >> $USERHOME/taskCycle.json
        echo "  \"target_waypointId\" : \"$target_waypointId\"," >> $USERHOME/taskCycle.json
        echo "  \"target_waypointRule\" : \"\"," >> $USERHOME/taskCycle.json
        echo "  \"waypointType\" : \"$waypointType\"," >> $USERHOME/taskCycle.json
        echo "  \"iterations\" : $iterations" >> $USERHOME/taskCycle.json
        echo "}" >> $USERHOME/taskCycle.json
    else
        #cd $USERHOME && touch taskCycle.json
        touch $USERHOME/taskCycle.json
        echo "start write"
        echo "{" > $USERHOME/taskCycle.json
        echo "  \"altitude\" : $altitude," >> $USERHOME/taskCycle.json
        echo "  \"latitude\" : $latitude," >> $USERHOME/taskCycle.json
        echo "  \"longitude\" : $longitude," >> $USERHOME/taskCycle.json
        echo "  \"orientation\" : $orientation," >> $USERHOME/taskCycle.json
        echo "  \"commandType\" : \"$commandType\"," >> $USERHOME/taskCycle.json
        echo "  \"waypointId\" : \"$waypointId\"," >> $USERHOME/taskCycle.json
        echo "  \"waypointRule\" : \"\"," >> $USERHOME/taskCycle.json
        echo "  \"waypointType\" : \"$waypointType\"," >> $USERHOME/taskCycle.json
        echo "  \"spray\" : \"$spray\"," >> $USERHOME/taskCycle.json
        echo "  \"iterations\" : $iterations" >> $USERHOME/taskCycle.json
        echo "}" >> $USERHOME/taskCycle.json
    fi
}

function runSetTask() {
    judeTXT
    spary=""
    listTask=$(whiptail --title "任务选择" --menu "选择即将进行的任务：" 15 60 4 \
        "1" "倾倒任务 " \
        "2" "清扫任务 " \
        "3" "移动任务 " 3>&1 1>&2 2>&3)
    echo "你的选择$listTask.并继续更新."
    case $listTask in
    1)
        #类型
        commandType="POUR"
        #点位
        listInfo=$(whiptail --title "Operations" --menu "选择倾倒的点位" 15 60 4 "${numarr[@]}" 3>&1 1>&2 2>&3)
        echo "----:$listInfo"
        waypointName=${AllNamearr[$listInfo]}
        echo "你的选择$waypointName.并继续更新."
        altitude=${AllAltarr[listInfo]}
        latitude=${AllLatarr[listInfo]}
        longitude=${AllLongarr[listInfo]}
        orientation=${AllDirecarr[listInfo]}
        waypointId=${AllIdarr[listInfo]}
        waypointType=${AllTypearr[listInfo]}
        ;;
    2)
        commandType="SWEEP"
        listInfo=$(whiptail --title "Operations" --menu "选择清扫的点位" 15 60 4 "${Cleannumarr[@]}" 3>&1 1>&2 2>&3)
        waypointName=${CleanNamearr[$listInfo]}
        echo "你的选择$waypointName.并继续更新."
        altitude=${CleanAltarr[listInfo]}
        latitude=${CleanLatarr[listInfo]}
        longitude=${CleanLongarr[listInfo]}
        orientation=${CleanDirecarr[listInfo]}
        waypointId=${CleanIdarr[listInfo]}
        waypointType=${CleanTypearr[listInfo]}
        #喷水开关
        sparyswitch=$(whiptail --title "Operations" --menu "选择是否打开喷水" 15 60 4 \
                        "1" "开" \
                        "2" "关" 3>&1 1>&2 2>&3)
        case $sparyswitch in
        1)
            spray="ON"
            ;;
        2)
            spray="OFF"
            ;;
        *)
            echo "没有该选项"
            ;;
        esac
        ;;
    3)
        commandType="MOVE"
        #第一个点
        listInfo=$(whiptail --title "Operations" --menu "选择移动的第一个点" 15 60 4 "${numarr[@]}" 3>&1 1>&2 2>&3)
        echo "----:$listInfo"
        waypointName=${AllNamearr[$listInfo]}
        echo "你的选择$waypointName.并继续更新."
        altitude=${AllAltarr[listInfo]}
        latitude=${AllLatarr[listInfo]}
        longitude=${AllLongarr[listInfo]}
        orientation=${AllDirecarr[listInfo]}
        waypointId=${AllIdarr[listInfo]}
        waypointType=${AllTypearr[listInfo]}
        #第二个点
        listpointtwo=$(whiptail --title "Operations" --menu "选择移动的第二个点" 15 60 4 "${numarr[@]}" 3>&1 1>&2 2>&3)
        echo "----:$listpointtwo"
        waypointName=${AllNamearr[$listpointtwo]}
        echo "你的选择$waypointName.并继续更新."
        target_altitude=${AllAltarr[listpointtwo]}
        target_latitude=${AllLatarr[listpointtwo]}
        target_longitude=${AllLongarr[listpointtwo]}
        target_orientation=${AllDirecarr[listpointtwo]}
        target_waypointId=${AllIdarr[listpointtwo]}
        # waypointType=${AllTypearr[listpointtwo]}
        ;;
    *)
        echo "没有该选项"
        ;;
    esac
     
    #循环
    iterationFlag=0
    while [ $iterationFlag -eq 0 ]
    do
        taskIterations=$(whiptail --title "循环次数设置" --inputbox "请输入正确的循环次数：" 10 60 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
            echo "循环次数为:$taskIterations"
            expr $taskIterations + 1 &> /dev/null
            if [ $? -ne 0 ]; then
                whiptail --title="错误" --msgbox "参数输入格式有误:$taskIterations,输入内容必须为数字,请重新输入！" 10 60
                iterationFlag=0
                echo "输入内容必须为数字!"
            fi
            if [ $taskIterations -le 0 ]; then
                whiptail --title="错误" --msgbox "参数输入格式有误:$taskIterations,输入内容必须为非零的正整数,请重新输入！" 10 60
                iterationFlag=0
                echo "输入内容必须为非零的正整数!"
            else
                whiptail --title="注意" --msgbox "参数输入成功！" 10 60
                iterationFlag=1
            fi
        else
            echo "设置出错!"
            exit 1
        fi
        iterations=$taskIterations
    done
    createTaskJson $commandType
}

#-------------------------------------------------------------
# judeTXT
runSetTask