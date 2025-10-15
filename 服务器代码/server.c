#include "server.h"

struct {
	char number[32];
	char company[32];
} courier;

int do_login(char *buf) {
	char *number = buf;
	char *passwd = buf + strlen(buf) + 1;
	printf("number:%s\n", number);
	strcpy(courier.number, number);
	printf("passwd:%s\n", passwd);

	sqlite3 *db;
	int rc = sqlite3_open(DBFILENAME, &db);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "无法打开数据库：%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	char *sql = "SELECT * FROM couriers WHERE courier_phone = ? AND password = ? ;";
	sqlite3_stmt *stmt;

	if (sqlite3_prepare_v2(db, sql, -1, &stmt, 0) != SQLITE_OK) {
		fprintf(stderr, "无法准备声明：%s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	}
	sqlite3_bind_text(stmt, 1, number, -1, SQLITE_STATIC);//第一个?绑定手机号
	sqlite3_bind_text(stmt, 2, passwd, -1, SQLITE_STATIC);//第二个?绑定密码

	rc = sqlite3_step(stmt);//SQLITE_ROW表示查到了一行结果
	if (rc != SQLITE_ROW) {
		fprintf(stderr, "登录失败：%s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		strcpy(buf, "手机号或密码不正确");
		//清理statement 防止内存泄漏
		sqlite3_finalize(stmt);
		return -1;
	}

	strcpy(courier.company, (char *)sqlite3_column_text(stmt, 3) );
	printf("登录成功， 快递员属于 %s \n", courier.company );
	//清理statement 防止内存泄漏
	sqlite3_finalize(stmt);
	sqlite3_close(db);
	strcpy(buf, "ok");
	return 0;
}

int do_register(char *buf) {
	char *number = buf;
	char *passwd = buf + strlen(buf) + 1;
	char *company = passwd + strlen(passwd) + 1;
	printf("number:%s\n", number);
	printf("passwd:%s\n", passwd);
	printf("company:%s\n", company);

	sqlite3 *db;
	int rc = sqlite3_open(DBFILENAME, &db);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "无法打开数据库：%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	//准备sql语句
	//占位符？ 防止SQL注入
	char *sql = "INSERT INTO couriers (courier_phone, password, delivery_company) "
		"VALUES (?, ?, ?);";
	sqlite3_stmt *stmt;
	if (sqlite3_prepare_v2(db, sql, -1, &stmt, 0) != SQLITE_OK) {
		fprintf(stderr, "无法准备声明：%s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	}
	sqlite3_bind_text(stmt, 1, number, -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 2, passwd, -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 3, company, -1, SQLITE_STATIC);

	rc = sqlite3_step(stmt);
	if (rc != SQLITE_DONE) {
		fprintf(stderr, "插入语句失败：%s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		strcpy(buf, "注册失败，手机号已注册");
		//清理statement 防止内存泄漏
		sqlite3_finalize(stmt);
		return -1;
	}
	//清理statement 防止内存泄漏
	sqlite3_finalize(stmt);
	sqlite3_close(db);
	strcpy(buf, "ok");
	return 0;
}

int do_pickup(char *buf) {
	//查询取件码是否正确
	sqlite3 *db;
	char *pickup_code = buf;
	char *pickup_code1 = buf;
	//打开数据库
	int rc = sqlite3_open(DBFILENAME, &db);
	if (rc != SQLITE_OK) {
		sprintf(buf, "无法打开数据库：%s", sqlite3_errmsg(db));
		printf("%s\n", buf);
	}

	sqlite3_stmt *stmt;
	char *sql = "SELECT * FROM lockers WHERE pickup_code = ?";
	if (sqlite3_prepare_v2(db, sql, -1, &stmt, 0) != SQLITE_OK) {
		sprintf(buf, "查询语句错误：%s", sqlite3_errmsg(db));
		printf("%s\n", buf);
		sqlite3_close(db);
		return -1;
	}
	//绑定参数， SQLITE_TRANSIENT表示让 SQLite3 在内部为pickup_code 创建一个副本
	sqlite3_bind_text(stmt, 1, pickup_code, -1, SQLITE_TRANSIENT);
	rc = sqlite3_step(stmt);
	if(rc != SQLITE_ROW) {
		sprintf(buf, "查询失败: %s", sqlite3_errmsg(db));
		printf("%s\n", buf);
		strcpy(buf, "1");
		
		sqlite3_close(db);
		sqlite3_finalize(stmt);
		return -1;
	}
	
	int locker_id = sqlite3_column_int(stmt, 0);//获取结果集的整数数据
	printf("查询到柜子编号为%d 是取件码 %s 的快递\n", locker_id, pickup_code);
	sqlite3_finalize(stmt);

	//取出快递
	sql = sqlite3_mprintf("UPDATE records SET pickup_method = '取件码取件', "
			"pickup_time = datetime('now', 'localtime') "
			"WHERE pickup_code = %Q", pickup_code);
	char *err_msg = NULL;
	rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
	if (rc != SQLITE_OK) {
		sprintf(buf, "取件失败: %s", err_msg);
		strcpy(buf, "1");
		//printf("%s\n", buf);
		sqlite3_free(err_msg);
		sqlite3_free(sql);
		return -1;
	}

	printf("包裹提取成功\n");
	sqlite3_free(err_msg);
	sqlite3_free(sql);
	//sprintf(buf, "%d", locker_id);
	strcpy(buf, pickup_code);
	printf("%s\n", pickup_code1);
	sqlite3_close(db);
	return 0;
}

// 投递功能
int do_delivery(char *buf) {
	char *courier_number = buf + 1;
	char *recipient_phone = courier_number + strlen(courier_number) + 1;

	char *sizeText;
	switch(buf[0]) {
	case '0': sizeText = "小"; break;
	case '1': sizeText = "中"; break;
	case '2': sizeText = "大"; break;
	default: printf("大小错误\n");
	}

	printf("柜子的尺寸:%s\n", sizeText);
	printf("包裹号:%s\n", courier_number);
	printf("收件人手机号:%s\n", recipient_phone);

	sqlite3 *db;
	int rc = sqlite3_open(DBFILENAME, &db);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "无法打开数据库：%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	//准备sql语句
	//占位符？ 防止SQL注入
	char *sql = "SELECT id FROM lockers WHERE status = '空闲' AND "
		"size = ? LIMIT 1";
	sqlite3_stmt *stmt;
	if (sqlite3_prepare_v2(db, sql, -1, &stmt, 0) != SQLITE_OK) {
		fprintf(stderr, "无法准备声明：%s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	}
	sqlite3_bind_text(stmt, 1, sizeText, -1, SQLITE_STATIC);
	rc = sqlite3_step(stmt);
	if (rc != SQLITE_ROW) {
		fprintf(stderr, "没有找到合适的空闲柜子：%s\n", sqlite3_errmsg(db));
		strcpy(buf, "没有找到合适的空闲柜子");
		sqlite3_close(db);
		//清理statement 防止内存泄漏
		sqlite3_finalize(stmt);
		return -1;
	}
	int locker_id = sqlite3_column_int(stmt, 0);
	//清理statement 防止内存泄漏
	sqlite3_finalize(stmt);

	//更新该柜子状态为‘占用’
	sql = "UPDATE lockers SET status = '使用', "
		"package_no = ?, courier_phone = ?, delivery_company = ?,"
		"delivery_time = datetime('now', 'localtime'), "
		"recipient_phone = ?,"
		"pickup_code = printf('%08d', ABS(random() % 100000000)) "
		"WHERE id = ?";
	if (sqlite3_prepare_v2(db, sql, -1, &stmt, 0) != SQLITE_OK) {
		fprintf(stderr, "无法准备声明：%s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	}
	sqlite3_bind_text(stmt, 1, courier_number, -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 2, courier.number, -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 3, courier.company, -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 4, recipient_phone, -1, SQLITE_STATIC);
	sqlite3_bind_int(stmt, 5, locker_id);
	rc = sqlite3_step(stmt);
	if (rc != SQLITE_DONE) {
		fprintf(stderr, "更新柜子的状态失败:%s\n", sqlite3_errmsg(db));
		strcpy(buf, "更新柜子的状态失败\n");
		//清理statement 防止内存泄漏
		sqlite3_finalize(stmt);
		sqlite3_close(db);
		return -1;
	}

	printf("快递已存入  %d 柜子\n", locker_id);
	//清理statement 防止内存泄漏
	sqlite3_finalize(stmt);
	sqlite3_close(db);
	sprintf(buf, "%d", locker_id);
	return 0;
}

void init_lockers() {
	sqlite3 *db;
	char *err_msg = NULL;
	FILE *fp = fopen(DBFILENAME, "r");
	if(fp != NULL) {
		printf("数据库文件已存在, 无需创建.\n");
		fclose(fp);
		return;
	}

	int rc = sqlite3_open(DBFILENAME, &db);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "无法打开数据库：%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	//创建快递柜状态表
	char *sql = "CREATE TABLE lockers ("
		"id INTEGER PRIMARY KEY,"  //柜子编号
		"status TEXT CHECK(status IN ('占用', '使用', '空闲', '故障')) NOT NULL," //柜子状态
		"size TEXT CHECK(size IN ('大', '中', '小')) NOT NULL,"           //柜子的尺寸
		"package_no TEXT UNIQUE,"  //包裹号
		"courier_phone TEXT,"      //快递员手机号
		"delivery_company TEXT,"   //快递公司信息
		"delivery_time TEXT,"      //投递时间
		"recipient_phone TEXT,"     //收件人手机号
		"pickup_code TEXT"
		");";
	rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
	if(rc != SQLITE_OK) {
		fprintf(stderr, "创建表 lockers 失败：%s\n", sqlite3_errmsg(db));
		sqlite3_free(err_msg);
		exit(EXIT_FAILURE);
	} else {
		printf("表 lockers 创建成功\n");
	}

	//初始化 lockers 
	sql = "BEGIN TRANSACTION;";
	sqlite3_exec(db, sql, 0, 0, &err_msg);
	for(int i = 1; i < 21; i++) {
		switch(i) {
		case 1:
		case 11:
			sql ="INSERT INTO lockers (status, size) VALUES('空闲', '大');";
			break;
		case 2:
			sql ="INSERT INTO lockers (status, size) VALUES('空闲', '中');";
			break;
		case 12:
			sql ="INSERT INTO lockers (status, size) VALUES('占用', '中');";
			break;
		case 8:
		case 9:
		case 10:
		case 18:
		case 19:
		case 20:
			sql ="INSERT INTO lockers (status, size) VALUES('空闲', '中');";
			break;
		default:
			sql ="INSERT INTO lockers (status, size) VALUES('空闲', '小');";
		}
		rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
		if (rc != SQLITE_OK) {
			fprintf(stderr, "插入数据 失败：%s\n", sqlite3_errmsg(db));
			sqlite3_free(err_msg);
			sqlite3_exec(db, "ROLLBACK;", NULL, NULL, &err_msg);
			sqlite3_close(db);
			exit(EXIT_FAILURE);
		}
	}
	sql = "COMMIT;";
	rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "事务提交 失败：%s\n", sqlite3_errmsg(db));
		sqlite3_free(err_msg);
		sqlite3_exec(db, "ROLLBACK;", NULL, NULL, &err_msg);
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	} else {
		printf("成功插入20条数据\n");
	}
	//创建快递员登记表
	sql = "CREATE TABLE couriers ("
		"id INTEGER PRIMARY KEY AUTOINCREMENT,"
		"courier_phone TEXT UNIQUE,"
		"password TEXT,"
		"delivery_company TEXT"
		");";
	rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "创建快递员登记表 失败：%s\n", sqlite3_errmsg(db));
		sqlite3_free(err_msg);
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	}

	//创建投递记录表
	sql = "CREATE TABLE records ("
		"id INTEGER PRIMARY KEY AUTOINCREMENT,"     //记录编号
		"package_no TEXT,"         //包裹号
		"courier_phone TEXT,"      //快递员手机号
		"delivery_company TEXT,"   //快递公司信息
		"delivery_time TEXT,"      //投递时间
		"recipient_phone TEXT,"    //收件人手机号
		"pickup_code TEXT,"        //取件码  
		"pickup_time TEXT,"        //取件时间
		"pickup_method TEXT CHECK(pickup_method IN ('快递员回收', '管理员开柜', '取件码取件'))"
		");";
	rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "创建投递记录表 失败：%s\n", sqlite3_errmsg(db));
		sqlite3_free(err_msg);
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	}

	sql = "CREATE TRIGGER update_records "
		"AFTER UPDATE ON lockers FOR EACH ROW "
		"BEGIN "
			"INSERT INTO records (package_no, courier_phone, delivery_company, "
			"delivery_time, recipient_phone, pickup_code) "
			"SELECT NEW.package_no, NEW.courier_phone, NEW.delivery_company, "
			"NEW.delivery_time, NEW.recipient_phone, NEW.pickup_code "
			"WHERE NEW.package_no IS NOT NULL;"
		"END;";//new的数据来自于locker中
	rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "触发器 update_records 创建 失败：%s\n", sqlite3_errmsg(db));
		sqlite3_free(err_msg);
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	}

	sql = "CREATE TRIGGER update_lockers "
		"AFTER UPDATE OF pickup_code, pickup_method ON records FOR EACH ROW BEGIN "
		"UPDATE lockers SET package_no = NULL, courier_phone = NULL, "
		"delivery_company = NULL, delivery_time = NULL, recipient_phone = NULL, pickup_code = NULL, "
		"status = '空闲' WHERE lockers.package_no = OLD.package_no; END; ";
	rc = sqlite3_exec(db, sql, 0, 0, &err_msg);
	if (rc != SQLITE_OK) {
		fprintf(stderr, "触发器 update_lockers 创建 失败：%s\n", sqlite3_errmsg(db));
		sqlite3_free(err_msg);
		sqlite3_close(db);
		exit(EXIT_FAILURE);
	}

	sqlite3_close(db);
}
