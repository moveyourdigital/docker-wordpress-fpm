RESET MASTER;

SET GLOBAL max_connections=1000;
SET GLOBAL gtid_strict_mode=ON;

CREATE USER 'maxscale'@'%' IDENTIFIED BY 'change_this_password';
GRANT ALL ON *.* TO 'maxscale'@'%' WITH GRANT OPTION;