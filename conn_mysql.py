import json
import pymysql
from pymysql.cursors import DictCursor

def load_config():
    """Load configuration from JSON file."""
    with open('config.json', 'r') as f:
        config = json.load(f)
    return config['database']

def connect_db():
    """Obtain database connection"""
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
        print(f"Database connection failed: {e}")
        return None

if __name__ == '__main__':
    conn = connect_db()
    print(f"Database connection succeeded：{conn}")