from conn_mysql import connect_db
import pymysql
from datetime import date

print("Welcome to the electronic shop!")

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

'''
产品搜索
'''
def search_products(keyword):
    """根据标签或名称搜索产品（个性化推荐）"""
    conn = connect_db()  # 仅获取连接对象
    if conn:
        try:
            cursor = conn.cursor()  # 在连接成功后创建游标
            cursor.execute("""
                SELECT * FROM Product 
                WHERE tag1 LIKE %s OR tag2 LIKE %s OR tag3 LIKE %s OR product_name LIKE %s
                ORDER BY listed_price DESC
            """, (f"%{keyword}%", f"%{keyword}%", f"%{keyword}%", f"%{keyword}%"))
            results = cursor.fetchall()
            print(f"\n======= 搜索 '{keyword}' 结果 =======")
            for product in results:
                print(f"ID: {product[0]}, 名称: {product[2]}, 价格: {product[3]}, 标签: {product[4]}/{product[5]}/{product[6]}")
        except pymysql.Error as e:
            print(f"数据库操作失败: {e}")
        finally:
            conn.close()  # 确保连接关闭


'''
产品管理
'''
def list_products_by_vendor(vendor_id):
    """显示某供应商的产品（带库存状态）"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM Product WHERE vendor_id = %s", (vendor_id,))
            products = cursor.fetchall()
            print(f"\n======= {vendor_id} 的产品列表 =======")
            for product in products:
                status = "有货" if product[7] > 0 else "缺货"
                print(
                    f"ID: {product[0]}, 名称: {product[2]}, 价格: {product[3]}, 标签: {product[4]}/{product[5]}/{product[6]}, 库存: {status}")
    finally:
        conn.close()

# 添加产品
def add_product(product_id, vendor_id, name, price, tags, inventory):
    """添加新产品（自动截取前3个标签）"""
    tags = (tags + [None, None, None])[:3]  # 确保最多3个标签
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO Product 
                (product_id, vendor_id, product_name, listed_price, tag1, tag2, tag3, inventory)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (product_id, vendor_id, name, price, tags[0], tags[1], tags[2], inventory))
            conn.commit()
            print(f"产品 {name} 添加成功！")
    except pymysql.IntegrityError:
        print("错误：产品ID已存在或供应商不存在！")
    finally:
        conn.close()

'''
订单管理
'''
def create_order(order_id, customer_id, product_list):
    """创建订单（缩短 order_detail_id）"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            conn.begin()
            # 检查客户是否存在
            cursor.execute("SELECT 1 FROM Customer WHERE customer_id = %s", (customer_id,))
            if not cursor.fetchone():
                raise ValueError("客户不存在！")
            # 插入订单
            cursor.execute(
                "INSERT INTO Orders (order_id, customer_id, order_date) VALUES (%s, %s, %s)",
                (order_id, customer_id, date.today())
            )

            # 插入订单详情并扣减库存
            for idx, (product_id, quantity) in enumerate(product_list, 1):
                cursor.execute("SELECT listed_price, inventory FROM Product WHERE product_id = %s FOR UPDATE",
                               (product_id,))
                result = cursor.fetchone()
                if not result:
                    raise ValueError(f"产品 {product_id} 不存在！")
                price, stock = result
                if stock < quantity:
                    raise ValueError(f"产品 {product_id} 库存不足！")

                # 生成简洁的 order_detail_id（示例：O20231002_1）
                detail_id = f"{order_id}_{idx}"  # 使用序号代替产品ID
                cursor.execute("""
                    INSERT INTO OrderDetail 
                    (order_detail_id, order_id, product_id, quantity, unit_price)
                    VALUES (%s, %s, %s, %s, %s)
                """, (detail_id, order_id, product_id, quantity, price))

                # 更新库存
                cursor.execute(
                    "UPDATE Product SET inventory = inventory - %s WHERE product_id = %s",
                    (quantity, product_id)
                )

            conn.commit()
            print(f"订单 {order_id} 创建成功！")
    except Exception as e:
        conn.rollback()
        print(f"订单创建失败: {e}")
    finally:
        conn.close()

def cancel_order(order_id):
    """取消订单（仅限未发货状态）"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            conn.begin()
            # 检查订单状态
            cursor.execute("SELECT status FROM Orders WHERE order_id = %s FOR UPDATE", (order_id,))
            result = cursor.fetchone()
            if not result:
                raise ValueError("订单不存在！")
            status = result[0]
            if status != '待处理':
                raise ValueError("订单已发货，无法取消！")
            # 恢复库存
            cursor.execute("SELECT product_id, quantity FROM OrderDetail WHERE order_id = %s", (order_id,))
            details = cursor.fetchall()
            for product_id, quantity in details:
                cursor.execute(
                    "UPDATE Product SET inventory = inventory + %s WHERE product_id = %s",
                    (quantity, product_id)
                )

            # 删除订单（级联删除详情）
            cursor.execute("DELETE FROM Orders WHERE order_id = %s", (order_id,))
            conn.commit()
            print(f"订单 {order_id} 已取消，库存已恢复！")
    except Exception as e:
        conn.rollback()
        print(f"取消订单失败: {e}")
    finally:
        conn.close()

def remove_product_from_order(order_id, product_id):
    """从订单中移除特定产品（仅限未发货状态）"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            conn.begin()
            # 检查订单状态
            cursor.execute("SELECT status FROM Orders WHERE order_id = %s FOR UPDATE", (order_id,))
            result = cursor.fetchone()
            if not result:
                raise ValueError("订单不存在！")
            status = result[0]
            if status != '待处理':
                raise ValueError("订单已发货，无法移除产品！")

            # 检查产品是否在订单中
            cursor.execute("SELECT quantity FROM OrderDetail WHERE order_id = %s AND product_id = %s", (order_id, product_id))
            result = cursor.fetchone()
            if not result:
                raise ValueError(f"产品 {product_id} 不在订单 {order_id} 中！")
            quantity = result[0]

            # 恢复库存
            cursor.execute("UPDATE Product SET inventory = inventory + %s WHERE product_id = %s", (quantity, product_id))

            # 删除订单详情记录
            cursor.execute("DELETE FROM OrderDetail WHERE order_id = %s AND product_id = %s", (order_id, product_id))

            conn.commit()
            print(f"产品 {product_id} 已从订单 {order_id} 中移除，库存已恢复！")
    except Exception as e:
        conn.rollback()
        print(f"移除产品失败: {e}")
    finally:
        conn.close()

def rate_product(order_id, product_id, rating):
    """对订单中的产品评分（0-5分）"""
    if rating < 0 or rating > 5:
        raise ValueError("评分必须在0到5之间！")
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                UPDATE OrderDetail 
                SET rating = %s 
                WHERE order_id = %s AND product_id = %s
            """, (rating, order_id, product_id))
            conn.commit()
            print(f"订单 {order_id} 的产品 {product_id} 评分成功！")
    except Exception as e:
        print(f"评分失败: {e}")
    finally:
        conn.close()


if __name__ == '__main__':
    # 1. 添加新供应商
    # add_vendor("V_XIAOMI", "小米", "中国")

    # 2. 添加新产品
    # add_product("P_XIAOMI_13", "V_XIAOMI", "小米13 Ultra", 5999.00, ["手机", "徕卡", "旗舰"], 100)

    # 3. 注册客户
    # conn = connect_db()
    # with conn.cursor() as cursor:
    #     cursor.execute(
    #         "INSERT INTO Customer (customer_id, contact_number, shipping_address) VALUES ('C006', '13800138006', '北京市朝阳区')")
    #     conn.commit()

    # 4. 下单并评分
    # create_order("O006", "C006", [("P_HUAWEI_MATE60", 1), ("P_FUJI_XS20", 1)])
    # rate_product("O006", "P_HUAWEI_MATE60", 4.5)
    # rate_product("O006", "P_FUJI_XS20", 4.7)

    # 5. 展示供应商评分
    # list_vendors()

    # 6. 取消订单测试
    # create_order("O007", "C001", [("P_HUAWEI_MATEVIEW", 1)])
    # cancel_order("O007")

    # 7. 搜索产品
    # search_products("防抖")

    # 假设已经创建了订单 O006，包含产品 P_HUAWEI_MATE60 和 P_FUJI_XS20
    # create_order("O006", "C006", [("P_HUAWEI_MATE60", 1), ("P_FUJI_XS20", 1)])
    # 从订单 O006 中移除产品 P_HUAWEI_MATE60
    # remove_product_from_order("O006", "P_HUAWEI_MATE60")