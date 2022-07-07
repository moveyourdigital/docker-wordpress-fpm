RESET MASTER;

SET GLOBAL max_connections=1000;
SET GLOBAL gtid_strict_mode=ON;

CHANGE MASTER TO MASTER_HOST='mariadb-nbg1', MASTER_PORT=3306, MASTER_USER='maxscale', MASTER_PASSWORD='change_this_password', MASTER_USE_GTID=slave_pos;

START SLAVE;