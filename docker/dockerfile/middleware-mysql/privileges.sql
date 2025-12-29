grant all privileges on *.* to root@'%' identified by 'q1w2e3r4' ;
grant all privileges on *.* to root@'localhost' identified by 'q1w2e3r4' ;

grant all privileges on `xxl_job`.* to 'xxljob'@'%' identified by 'xxljob';
GRANT ALL PRIVILEGES ON `nacos_config`.* TO 'nacos'@'%' identified by 'nacos';

flush privileges;