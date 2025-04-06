import json
import pymysql
from pymysql.cursors import DictCursor

def load_config():
    """从JSON文件加载配置"""
    with open('config.json', 'r') as f:
        config = json.load(f)
    return config['database']

def connect_db():
    """获取数据库连接"""
    config = load_config()
    try:
        conn = pymysql.connect(
            host=config['host'],
            user=config['user'],
            password=config['password'],
            database=config['db'],
            port=config['port'],
            charset=config['charset'],
            # cursorclass=DictCursor
        )
        return conn
    except pymysql.Error as e:
        print(f"数据库连接失败: {e}")
        return None

if __name__ == '__main__':
    conn = connect_db()
    print(f"数据库连接成功：{conn}")