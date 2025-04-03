from conn_mysql import connect_db
import pymysql

def list_vendors():
    """显示所有供应商及实时评分（包含无评分供应商）"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT v.vendor_id, v.business_name, v.geographical_presence, 
                       COALESCE(vs.feedback_score, '暂无评分') AS score
                FROM Vendor v
                LEFT JOIN VendorScores vs ON v.vendor_id = vs.vendor_id
                """)
            vendors = cursor.fetchall()
            print("\n======= 供应商列表 =======")
            for vendor in vendors:
                print(f"ID: {vendor[0]}, 名称: {vendor[1]}, 地区: {vendor[2]}, 评分: {vendor[3]}")
    finally:
        conn.close()

def add_vendor(vendor_id, name, region):
    """添加新供应商"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO Vendor (vendor_id, business_name, geographical_presence) VALUES (%s, %s, %s)",
                (vendor_id, name, region)
            )
            conn.commit()
            print(f"供应商 {name} 添加成功！")
    except pymysql.IntegrityError:
        print("错误：供应商ID已存在！")
    finally:
        conn.close()


if __name__ == '__main__':
    list_vendors()