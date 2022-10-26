#!/bin/bash

time_now=`date '+%Y-%m-%d-%H:%M:%S'`
echo "time_now: "$time_now
username="root" 
password=123456
echo "robot_id: " `cat /home/neousys/cti_ade_home/version`

robot_id=2$(cat /home/neousys/cti_ade_home/version| awk '{split($1,arr,":A"); print arr[2]}')
echo $robot_id
echo "创建mysql_docker"
docker run -d --restart=always --name mysql -v  /home/neousys/cti_ade_home/mysql/conf:/etc/mysql/conf.d \
-v /home/neousys/cti_ade_home/mysql/data:/var/lib/mysql -v /home/neousys/cti_ade_home/mysql/log:/var/log/mysql/ \
-p $robot_id:3306  -e MYSQL_ROOT_PASSWORD=123456  -d  mysql:5.7

docker restart mysql
sleep 1
docker exec -i mysql bash   <<EOF 
mysql -u $username -p$password
use mysql;
set global time_zone = 'Asia/Shanghai';
EOF
[ $? -eq 0 ] && echo "set time success"  || echo " set time success fail"

docker exec -i mysql bash   <<EOF 
mysql -u $username -p$password
create database qfw_test;
EOF
[ $? -eq 0 ] && echo "创建数据库成功"  || echo "创建数据库失败"

docker exec -i mysql bash   <<EOF 
mysql -u $username -p$password
use qfw_test;
CREATE TABLE sch_state(
record_id bigint(20) NOT NULL AUTO_INCREMENT ,\
task_id varchar(100) DEFAULT NULL ,\
execute_times tinyint(1) DEFAULT NULL ,\
begin_time varchar(100) NOT NULL ,\
task_type varchar(20) NOT NULL ,\
fail_repeat tinyint(1) DEFAULT NULL ,\
interrupt_repeat tinyint(1) DEFAULT NULL ,\
msg_id varchar(100) DEFAULT NULL ,\
command_type varchar(20) NOT NULL ,\
state int(11) DEFAULT NULL ,\
command_mode varchar(20) DEFAULT NULL ,\
stamp int(11) DEFAULT NULL ,\
latitude double DEFAULT NULL ,\
longitude double NOT NULL ,\
altitude double DEFAULT NULL ,\
orientation double DEFAULT NULL ,\
waypoint_id varchar(100) DEFAULT NULL ,\
waypoint_rule varchar(20) DEFAULT NULL ,\
waypoint_type varchar(20) DEFAULT NULL ,\
pose_pos_x float DEFAULT NULL ,\
pose_pos_y float DEFAULT NULL ,\
pose_pos_z float DEFAULT NULL ,\
pose_orient_x float DEFAULT NULL ,\
pose_orient_y float DEFAULT NULL ,\
pose_orient_z float DEFAULT NULL ,\
pose_orient_w float DEFAULT NULL ,\
qr varchar(100) DEFAULT NULL ,\
hive_qr varchar(100) DEFAULT NULL ,\
dock_qr varchar(100) DEFAULT NULL ,\
rfid varchar(100) DEFAULT NULL ,\
hive_type varchar(100) DEFAULT NULL ,\
hive_device varchar(100) DEFAULT NULL ,\
spacing double DEFAULT NULL ,\
offset int(10) DEFAULT NULL ,\
position int(10) DEFAULT NULL ,\
sweep_mode varchar(20) DEFAULT NULL ,\
spray varchar(20) DEFAULT NULL ,\
zoneid varchar(20) DEFAULT NULL ,\
lidopen_level varchar(20) DEFAULT NULL ,\
avoid_mode varchar(20) DEFAULT NULL ,\
recoup_mode varchar(20) DEFAULT NULL ,\
sweep_speed_level varchar(20) DEFAULT NULL ,\
breakpoint varchar(20) DEFAULT NULL ,\
created_time int(64) NOT NULL ,\
time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ,\
loop_times int(11) DEFAULT NULL ,\
closed_run_day int(20) NOT NULL ,\
monday tinyint(1) DEFAULT NULL ,\
tuesday tinyint(1) DEFAULT NULL ,\
wednesday tinyint(1) DEFAULT NULL ,\
thursday tinyint(1) DEFAULT NULL ,\
friday tinyint(1) DEFAULT NULL ,\
saturday tinyint(1) DEFAULT NULL ,\
sunday tinyint(1) DEFAULT NULL ,\
create_time_str varchar(20) DEFAULT NULL ,\
  PRIMARY KEY (record_id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
EOF

[ $? -eq 0 ] && echo "创建数据表成功"  || echo "创建数据表失败"


