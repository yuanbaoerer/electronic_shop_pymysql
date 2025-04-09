from conn_mysql import connect_db
import pymysql
from datetime import date

print("Welcome to the electronic shop!")

def list_vendors():
    """Display all vendors and their real-time ratings (including vendors without ratings)"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT v.vendor_id, v.business_name, v.geographical_presence, 
                       COALESCE(vs.feedback_score, 'No rating yet') AS score
                FROM Vendor v
                LEFT JOIN VendorScores vs ON v.vendor_id = vs.vendor_id
                """)
            vendors = cursor.fetchall()
            print("\n======= Vendor List =======")
            for vendor in vendors:
                print(f"ID: {vendor[0]}, Name: {vendor[1]}, Region: {vendor[2]}, Rating: {vendor[3]}")
    finally:
        conn.close()

def add_vendor(vendor_id, name, region):
    """Add a new vendor"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO Vendor (vendor_id, business_name, geographical_presence) VALUES (%s, %s, %s)",
                (vendor_id, name, region)
            )
            conn.commit()
            print(f"Vendor {name} added successfully!")
    except pymysql.IntegrityError:
        print("Error: Vendor ID already exists!")
    finally:
        conn.close()

'''
Product Search
'''
def search_products(keyword):
    """Search for products by tag or name (personalized recommendation)"""
    conn = connect_db()  # Only get the connection object
    if conn:
        try:
            cursor = conn.cursor()  # Create a cursor after the connection is successful
            cursor.execute("""
                SELECT * FROM Product 
                WHERE tag1 LIKE %s OR tag2 LIKE %s OR tag3 LIKE %s OR product_name LIKE %s
                ORDER BY listed_price DESC
            """, (f"%{keyword}%", f"%{keyword}%", f"%{keyword}%", f"%{keyword}%"))
            results = cursor.fetchall()
            print(f"\n======= Search results for '{keyword}' =======")
            for product in results:
                print(f"ID: {product[0]}, Name: {product[2]}, Price: {product[3]}, Tags: {product[4]}/{product[5]}/{product[6]}")
        except pymysql.Error as e:
            print(f"Database operation failed: {e}")
        finally:
            conn.close()  # Ensure the connection is closed


'''
Product Management
'''
def list_products_by_vendor(vendor_id):
    """Display products of a certain vendor (with inventory status)"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM Product WHERE vendor_id = %s", (vendor_id,))
            products = cursor.fetchall()
            print(f"\n======= Product List of {vendor_id} =======")
            for product in products:
                status = "In stock" if product[7] > 0 else "Out of stock"
                print(
                    f"ID: {product[0]}, Name: {product[2]}, Price: {product[3]}, Tags: {product[4]}/{product[5]}/{product[6]}, Inventory: {status}")
    finally:
        conn.close()

# Add a product
def add_product(product_id, vendor_id, name, price, tags, inventory):
    """Add a new product (automatically intercept the first 3 tags)"""
    tags = (tags + [None, None, None])[:3]  # Ensure a maximum of 3 tags
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
            print(f"Product {name} added successfully!")
    except pymysql.IntegrityError:
        print("Error: Product ID already exists or vendor does not exist!")
    finally:
        conn.close()

'''
Order Management
'''
def create_order(order_id, customer_id, product_list):
    """Create an order (shorten the order_detail_id)"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            conn.begin()
            # Check if the customer exists
            cursor.execute("SELECT 1 FROM Customer WHERE customer_id = %s", (customer_id,))
            if not cursor.fetchone():
                raise ValueError("Customer does not exist!")
            # Insert the order
            cursor.execute(
                "INSERT INTO Orders (order_id, customer_id, order_date) VALUES (%s, %s, %s)",
                (order_id, customer_id, date.today())
            )

            # Insert order details and deduct inventory
            for idx, (product_id, quantity) in enumerate(product_list, 1):
                cursor.execute("SELECT listed_price, inventory FROM Product WHERE product_id = %s FOR UPDATE",
                               (product_id,))
                result = cursor.fetchone()
                if not result:
                    raise ValueError(f"Product {product_id} does not exist!")
                price, stock = result
                if stock < quantity:
                    raise ValueError(f"Product {product_id} is out of stock!")

                # Generate a concise order_detail_id (example: O20231002_1)
                detail_id = f"{order_id}_{idx}"  # Use the serial number instead of the product ID
                cursor.execute("""
                    INSERT INTO OrderDetail 
                    (order_detail_id, order_id, product_id, quantity, unit_price)
                    VALUES (%s, %s, %s, %s, %s)
                """, (detail_id, order_id, product_id, quantity, price))

                # Update inventory
                cursor.execute(
                    "UPDATE Product SET inventory = inventory - %s WHERE product_id = %s",
                    (quantity, product_id)
                )

            conn.commit()
            print(f"Order {order_id} created successfully!")
    except Exception as e:
        conn.rollback()
        print(f"Order creation failed: {e}")
    finally:
        conn.close()

def cancel_order(order_id):
    """Cancel an order (only for orders in the pending status)"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            conn.begin()
            # Check the order status
            cursor.execute("SELECT status FROM Orders WHERE order_id = %s FOR UPDATE", (order_id,))
            result = cursor.fetchone()
            if not result:
                raise ValueError("Order does not exist!")
            status = result[0]
            if status != 'Pending':
                raise ValueError("Order has been shipped and cannot be cancelled!")
            # Restore inventory
            cursor.execute("SELECT product_id, quantity FROM OrderDetail WHERE order_id = %s", (order_id,))
            details = cursor.fetchall()
            for product_id, quantity in details:
                cursor.execute(
                    "UPDATE Product SET inventory = inventory + %s WHERE product_id = %s",
                    (quantity, product_id)
                )

            # Delete the order (cascade delete details)
            cursor.execute("DELETE FROM Orders WHERE order_id = %s", (order_id,))
            conn.commit()
            print(f"Order {order_id} has been cancelled, and inventory has been restored!")
    except Exception as e:
        conn.rollback()
        print(f"Order cancellation failed: {e}")
    finally:
        conn.close()

def remove_product_from_order(order_id, product_id):
    """Remove a specific product from an order (only for orders in the pending status)"""
    conn = connect_db()
    if not conn: return
    try:
        with conn.cursor() as cursor:
            conn.begin()
            # Check the order status
            cursor.execute("SELECT status FROM Orders WHERE order_id = %s FOR UPDATE", (order_id,))
            result = cursor.fetchone()
            if not result:
                raise ValueError("Order does not exist!")
            status = result[0]
            if status != 'Pending':
                raise ValueError("Order has been shipped and cannot remove the product!")

            # Check if the product is in the order
            cursor.execute("SELECT quantity FROM OrderDetail WHERE order_id = %s AND product_id = %s", (order_id, product_id))
            result = cursor.fetchone()
            if not result:
                raise ValueError(f"Product {product_id} is not in order {order_id}!")
            quantity = result[0]

            # Restore inventory
            cursor.execute("UPDATE Product SET inventory = inventory + %s WHERE product_id = %s", (quantity, product_id))

            # Delete the order detail record
            cursor.execute("DELETE FROM OrderDetail WHERE order_id = %s AND product_id = %s", (order_id, product_id))

            conn.commit()
            print(f"Product {product_id} has been removed from order {order_id}, and inventory has been restored!")
    except Exception as e:
        conn.rollback()
        print(f"Product removal failed: {e}")
    finally:
        conn.close()

def rate_product(order_id, product_id, rating):
    """Rate a product in an order (0-5 points)"""
    if rating < 0 or rating > 5:
        raise ValueError("Rating must be between 0 and 5!")
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
            print(f"Product {product_id} in order {order_id} has been rated successfully!")
    except Exception as e:
        print(f"Rating failed: {e}")
    finally:
        conn.close()


if __name__ == '__main__':
    # # 1. add a new vendor
    # add_vendor("V_XIAOMI", "Xiaomi", "China")
    # # 2. add new product
    # add_product("P_XIAOMI_13", "V_XIAOMI", "Xiaomi 13 Ultra", 5999.00, ["Phone", "Leica", "Flagship"], 100)

    # 3.
    # conn = connect_db()
    # with conn.cursor() as cursor:
    #     cursor.execute(
    #         "INSERT INTO Customer (customer_id, contact_number, shipping_address) VALUES ('C006', '13800138006', 'Chaoyang District, Beijing')")
    #     conn.commit()
    #
    # # 4. Order and rate
    # create_order("O006", "C006", [("P_HUAWEI_MATE60", 1), ("P_FUJI_XS20", 1)])
    # rate_product("O006", "P_HUAWEI_MATE60", 4.5)
    # rate_product("O006", "P_FUJI_XS20", 4.7)

    # # 5. show the rating of vendors
    # list_vendors()

    # # 6. cancel order
    # create_order("O007", "C001", [("P_HUAWEI_MATEVIEW", 1)])
    # cancel_order("O007")

    # 7. remove product from O006
    # remove_product_from_order("O006", "P_HUAWEI_MATE60")
    #
    # # 8. search products according to keywords
    # search_products("Anti-shake")