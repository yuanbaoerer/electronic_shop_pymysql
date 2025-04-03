## Readme

#### **Overview**

This electronic store management system is a project based on Python and MySQL, offering functions such as vendor management, product search and management, and order management. It uses the `pymysql` library to interact with the MySQL database.

#### Environmental Requiremens

- Python 3.9
- MySQL version 5.7 or higher
- `pymysql` library

#### Code run steps

1. **Clone the Project**

   First, clone the project to your local machine:

   ```bash
   git clone https://github.com/yuanbaoerer/electronic_shop_pymysql.git
   ```

2. **Build database**

   The database is built using the `electronic_shop.sql` file, which contains SQL statements to create the database, table structure, and insert the initial data.

3. **Install Dependencies**

   Install the required dependencies using `pip`:

   ```bash
   pip install pymysql
   ```

4. **Configure Database Information**

   Open the `config.json` file and modify the database configuration information according to your actual situation:

   ```json
   {
       "database": {
           "host": "localhost",
           "user": "root",
           "password": "123456",
           "db": "electronics_shop",
           "port": 3306,
           "charset": "utf8mb4"
       }
   }
   ```

   - `host`: The database host address, usually `localhost`.
   - `user`: The database username.
   - `password`: The database user password.
   - `db`: The name of the database to connect to.
   - `port`: The database port number, with the default being `3306`.
   - `charset`: The character set, it is recommended to use `utf8mb4`.

5. **Run the Code**

   **Test Database Connection**

   Run the `conn_mysql.py` file to test if the database connection is successful.

   If the connection is successful, the database connection object will be output; if it fails, an error message will be output.

   **Electronic Store Management System**

   Run the `electronic_shop.py` file to use the various functional functions defined in it.

   1. `list_vendors()`

   - **Function**: Display all vendors and their real - time scores (including vendors without scores).

   2. `add_vendor(vendor_id, name, region)`

   - **Function**: Add a new vendor. If the vendor ID already exists, an error message will be displayed.

   3. `search_products(keyword)`

   - **Function**: Search for products based on tags or names for personalized recommendations. The search results are sorted in descending order of the listed price.

   4. `list_products_by_vendor(vendor_id)`

   - **Function**: Display the products of a specific vendor along with their inventory status (in stock or out of stock).

   5. `add_product(product_id, vendor_id, name, price, tags, inventory)`

   - **Function**: Add a new product and automatically truncate the first 3 tags. If the product ID already exists or the vendor does not exist, an error message will be displayed.

   6. `create_order(order_id, customer_id, product_list)`

   - **Function**: Create an order and shorten the `order_detail_id`. It will check if the customer exists, if the products exist, and if the inventory is sufficient. If any condition is not met, an error will be thrown. The inventory of the corresponding products will be reduced when creating the order.

   7. `cancel_order(order_id)`

   - **Function**: Cancel an order, only available for orders in the pending status. The inventory of the corresponding products will be restored when canceling the order.

   8.`remove_product_from_order(order_id, product_id)`

   - **Function**: Remove a specific product from an order, only available for orders in the pending status. The inventory of the corresponding product will be restored when removing the product.

   9. `rate_product(order_id, product_id, rating)`

   - **Function**: Rate a product in an order, with a rating range of 0 - 5 points. If the rating is out of this range, an error will be thrown.

   In the `if __name__ == '__main__':` section of the `electronic_shop.py` file, some sample code has been provided. You can uncomment the corresponding code to test different functions, such as adding a vendor, adding a product, creating an order, etc.