import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class MobileAppDatabase {
  MobileAppDatabase._();

  static final MobileAppDatabase instance = MobileAppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'supermarket_mobile_v2.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA busy_timeout = 5000');
        await db.execute('PRAGMA journal_mode = WAL');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedData(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE session (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        role_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        fullname TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        role_id INTEGER NOT NULL,
        id_card TEXT,
        phone TEXT,
        address TEXT,
        dob TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        avatar TEXT,
        last_login TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (role_id) REFERENCES roles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_name TEXT NOT NULL,
        company_name TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE discounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        percent REAL NOT NULL,
        min_order_amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        points INTEGER NOT NULL DEFAULT 0,
        total_purchases INTEGER NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0.0,
        discount_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (discount_id) REFERENCES discounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT,
        product_name TEXT NOT NULL,
        product_batch TEXT,
        description TEXT,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        qty_cartons INTEGER DEFAULT 0,
        in_stock INTEGER NOT NULL DEFAULT 0,
        supplier_id INTEGER,
        category_id INTEGER,
        mft_date TEXT,
        expiry_date TEXT,
        status TEXT NOT NULL DEFAULT 'In Stock',
        image_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        discount_id INTEGER,
        percent REAL,
        fixed_amount REAL,
        min_order_amount REAL NOT NULL,
        valid_from TEXT,
        valid_to TEXT,
        usage_limit INTEGER,
        used_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        sales_point TEXT NOT NULL,
        open_time TEXT NOT NULL,
        close_time TEXT,
        initial_cash REAL NOT NULL,
        total_cash_end REAL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_no TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        customer_phone TEXT,
        customer_name TEXT,
        cashier_id INTEGER NOT NULL,
        sales_point TEXT NOT NULL DEFAULT 'Main Store',
        shift_id INTEGER,
        order_date TEXT NOT NULL,
        order_time TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_id INTEGER,
        voucher_id INTEGER,
        discount_percent REAL NOT NULL DEFAULT 0.0,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        total_payable REAL NOT NULL,
        paid REAL NOT NULL,
        balance REAL NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Paid',
        pay_due_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        qty INTEGER NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES sales_orders (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE password_reset_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        email TEXT NOT NULL,
        token TEXT NOT NULL,
        otp TEXT NOT NULL,
        expires_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedData(Database db) async {
    // Roles
    await db.insert('roles', {'id': 1, 'name': 'ADMIN'});
    await db.insert('roles', {'id': 2, 'name': 'MANAGER'});
    await db.insert('roles', {'id': 3, 'name': 'CASHIER'});

    // Users (Default passwords: username itself or 123456)
    await db.insert('users', {
      'id': 1,
      'username': 'admin01',
      'password_hash': 'admin01',
      'fullname': 'Admin One',
      'email': 'admin01@supermarket.com',
      'role_id': 1,
      'id_card': 'ID100001',
      'phone': '0901000001',
      'address': '123 Main St',
      'dob': '1990-01-01',
      'status': 'active',
      'avatar': 'https://img.local/admin01.png',
      'last_login': '2026-03-12 08:00:00',
      'created_at': '2026-03-01 09:00:00',
      'updated_at': '2026-03-12 08:00:00',
    });

    await db.insert('users', {
      'id': 2,
      'username': 'manager01',
      'password_hash': 'manager01',
      'fullname': 'Manager One',
      'email': 'manager01@supermarket.com',
      'role_id': 2,
      'id_card': 'ID100002',
      'phone': '0901000002',
      'address': '456 Market St',
      'dob': '1992-02-02',
      'status': 'active',
      'avatar': 'https://img.local/manager01.png',
      'last_login': '2026-03-12 08:10:00',
      'created_at': '2026-03-01 09:05:00',
      'updated_at': '2026-03-12 08:10:00',
    });

    await db.insert('users', {
      'id': 3,
      'username': 'cashier01',
      'password_hash': 'cashier01',
      'fullname': 'Cashier One',
      'email': 'cashier01@supermarket.com',
      'role_id': 3,
      'id_card': 'ID100003',
      'phone': '0901000003',
      'address': '789 Central St',
      'dob': '1995-03-03',
      'status': 'active',
      'avatar': 'https://img.local/cashier01.png',
      'last_login': '2026-03-12 08:20:00',
      'created_at': '2026-03-01 09:10:00',
      'updated_at': '2026-03-12 08:20:00',
    });

    await db.insert('users', {
      'id': 4,
      'username': 'cashier02',
      'password_hash': 'cashier02',
      'fullname': 'Cashier Two',
      'email': 'cashier02@supermarket.com',
      'role_id': 3,
      'id_card': 'ID100004',
      'phone': '0901000004',
      'address': '321 River St',
      'dob': '1998-04-04',
      'status': 'active',
      'avatar': 'https://img.local/cashier02.png',
      'last_login': '2026-03-12 08:30:00',
      'created_at': '2026-03-01 09:15:00',
      'updated_at': '2026-03-12 08:30:00',
    });

    // Discounts
    await db.insert('discounts', {
      'id': 1,
      'name': 'Holiday 5',
      'percent': 5.0,
      'min_order_amount': 100000.0,
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'created_at': '2026-01-01 00:00:00',
      'updated_at': '2026-03-01 08:00:00',
    });
    await db.insert('discounts', {
      'id': 2,
      'name': 'Weekend 10',
      'percent': 10.0,
      'min_order_amount': 200000.0,
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'created_at': '2026-01-01 00:00:00',
      'updated_at': '2026-03-01 08:05:00',
    });
    await db.insert('discounts', {
      'id': 3,
      'name': 'New Member 3',
      'percent': 3.0,
      'min_order_amount': 50000.0,
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'created_at': '2026-01-01 00:00:00',
      'updated_at': '2026-03-01 08:10:00',
    });
    await db.insert('discounts', {
      'id': 4,
      'name': 'Big Sale 15',
      'percent': 15.0,
      'min_order_amount': 500000.0,
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'created_at': '2026-01-01 00:00:00',
      'updated_at': '2026-03-01 08:15:00',
    });
    await db.insert('discounts', {
      'id': 5,
      'name': 'Lucky Day 7',
      'percent': 7.0,
      'min_order_amount': 150000.0,
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'created_at': '2026-01-01 00:00:00',
      'updated_at': '2026-03-01 08:20:00',
    });

    // Customers
    await db.insert('customers', {
      'id': 1,
      'name': 'Nguyen Van A',
      'phone': '0900000001',
      'points': 120,
      'total_purchases': 10,
      'total_amount': 2500000.0,
      'discount_id': 1,
      'created_at': '2026-02-01 10:00:00',
      'updated_at': '2026-03-10 09:00:00',
    });
    await db.insert('customers', {
      'id': 2,
      'name': 'Tran Thi B',
      'phone': '0900000002',
      'points': 80,
      'total_purchases': 6,
      'total_amount': 1400000.0,
      'discount_id': 2,
      'created_at': '2026-02-02 10:00:00',
      'updated_at': '2026-03-10 09:05:00',
    });
    await db.insert('customers', {
      'id': 3,
      'name': 'Le Van C',
      'phone': '0900000003',
      'points': 20,
      'total_purchases': 2,
      'total_amount': 300000.0,
      'discount_id': null,
      'created_at': '2026-02-03 10:00:00',
      'updated_at': '2026-03-10 09:10:00',
    });
    await db.insert('customers', {
      'id': 4,
      'name': 'Pham Thi D',
      'phone': '0900000004',
      'points': 60,
      'total_purchases': 4,
      'total_amount': 900000.0,
      'discount_id': 3,
      'created_at': '2026-02-04 10:00:00',
      'updated_at': '2026-03-10 09:15:00',
    });
    await db.insert('customers', {
      'id': 5,
      'name': 'Do Van E',
      'phone': '0900000005',
      'points': 0,
      'total_purchases': 0,
      'total_amount': 0.0,
      'discount_id': null,
      'created_at': '2026-02-05 10:00:00',
      'updated_at': '2026-03-10 09:20:00',
    });

    // Suppliers
    await db.insert('suppliers', {
      'id': 1,
      'supplier_name': 'Fresh Farm',
      'company_name': 'Fresh Farm Co',
      'email': 'contact@freshfarm.com',
      'phone': '0281111111',
      'address': '12 Green St',
      'status': 'active',
      'created_at': '2026-01-05 09:00:00',
      'updated_at': '2026-03-01 10:00:00',
    });
    await db.insert('suppliers', {
      'id': 2,
      'supplier_name': 'Daily Food',
      'company_name': 'Daily Food Ltd',
      'email': 'sales@dailyfood.com',
      'phone': '0282222222',
      'address': '34 Market St',
      'status': 'active',
      'created_at': '2026-01-06 09:00:00',
      'updated_at': '2026-03-01 10:05:00',
    });
    await db.insert('suppliers', {
      'id': 3,
      'supplier_name': 'Best Drink',
      'company_name': 'Best Drink Inc',
      'email': 'hello@bestdrink.com',
      'phone': '0283333333',
      'address': '56 River St',
      'status': 'active',
      'created_at': '2026-01-07 09:00:00',
      'updated_at': '2026-03-01 10:10:00',
    });
    await db.insert('suppliers', {
      'id': 4,
      'supplier_name': 'Office Goods',
      'company_name': 'Office Goods JSC',
      'email': 'team@officegoods.com',
      'phone': '0284444444',
      'address': '78 Lake St',
      'status': 'deactive',
      'created_at': '2026-01-08 09:00:00',
      'updated_at': '2026-03-01 10:15:00',
    });
    await db.insert('suppliers', {
      'id': 5,
      'supplier_name': 'Snack Hub',
      'company_name': 'Snack Hub Co',
      'email': 'info@snackhub.com',
      'phone': '0285555555',
      'address': '90 Sun St',
      'status': 'active',
      'created_at': '2026-01-09 09:00:00',
      'updated_at': '2026-03-01 10:20:00',
    });

    // Categories
    await db.insert('categories', {
      'id': 1,
      'name': 'Beverages',
      'status': 'active',
      'created_at': '2026-01-10 09:00:00',
      'updated_at': '2026-03-01 11:00:00',
    });
    await db.insert('categories', {
      'id': 2,
      'name': 'Food',
      'status': 'active',
      'created_at': '2026-01-10 09:05:00',
      'updated_at': '2026-03-01 11:05:00',
    });
    await db.insert('categories', {
      'id': 3,
      'name': 'Dairy',
      'status': 'active',
      'created_at': '2026-01-10 09:10:00',
      'updated_at': '2026-03-01 11:10:00',
    });
    await db.insert('categories', {
      'id': 4,
      'name': 'Stationery',
      'status': 'active',
      'created_at': '2026-01-10 09:15:00',
      'updated_at': '2026-03-01 11:15:00',
    });
    await db.insert('categories', {
      'id': 5,
      'name': 'Snacks',
      'status': 'active',
      'created_at': '2026-01-10 09:20:00',
      'updated_at': '2026-03-01 11:20:00',
    });

    // Products
    await db.insert('products', {
      'id': 1,
      'barcode': '893000000001',
      'product_name': 'Coca Cola 330ml',
      'product_batch': 'BATCH-COKE-01',
      'description': 'Can drink',
      'cost_price': 7000.0,
      'selling_price': 10000.0,
      'qty_cartons': 20,
      'in_stock': 240,
      'supplier_id': 3,
      'category_id': 1,
      'mft_date': '2026-01-01',
      'expiry_date': '2027-01-01',
      'status': 'In Stock',
      'image_url': 'https://img.local/products/coke.png',
      'created_at': '2026-01-15 08:00:00',
      'updated_at': '2026-03-05 08:00:00',
    });
    await db.insert('products', {
      'id': 2,
      'barcode': '893000000002',
      'product_name': 'Instant Noodles',
      'product_batch': 'BATCH-NOODLE-01',
      'description': 'Pack of noodles',
      'cost_price': 3500.0,
      'selling_price': 5000.0,
      'qty_cartons': 30,
      'in_stock': 360,
      'supplier_id': 2,
      'category_id': 2,
      'mft_date': '2026-01-10',
      'expiry_date': '2026-12-31',
      'status': 'In Stock',
      'image_url': 'https://img.local/products/noodle.png',
      'created_at': '2026-01-15 08:10:00',
      'updated_at': '2026-03-05 08:10:00',
    });
    await db.insert('products', {
      'id': 3,
      'barcode': '893000000003',
      'product_name': 'Fresh Milk 1L',
      'product_batch': 'BATCH-MILK-01',
      'description': 'Milk box',
      'cost_price': 22000.0,
      'selling_price': 28000.0,
      'qty_cartons': 10,
      'in_stock': 120,
      'supplier_id': 1,
      'category_id': 3,
      'mft_date': '2026-02-01',
      'expiry_date': '2026-08-01',
      'status': 'In Stock',
      'image_url': 'https://img.local/products/milk.png',
      'created_at': '2026-01-15 08:20:00',
      'updated_at': '2026-03-05 08:20:00',
    });
    await db.insert('products', {
      'id': 4,
      'barcode': '893000000004',
      'product_name': 'Notebook A5',
      'product_batch': 'BATCH-NOTE-01',
      'description': 'Paper notebook',
      'cost_price': 12000.0,
      'selling_price': 18000.0,
      'qty_cartons': 15,
      'in_stock': 150,
      'supplier_id': 4,
      'category_id': 4,
      'mft_date': '2026-01-05',
      'expiry_date': '2028-01-05',
      'status': 'In Stock',
      'image_url': 'https://img.local/products/notebook.png',
      'created_at': '2026-01-15 08:30:00',
      'updated_at': '2026-03-05 08:30:00',
    });
    await db.insert('products', {
      'id': 5,
      'barcode': '893000000005',
      'product_name': 'Potato Chips',
      'product_batch': 'BATCH-CHIP-01',
      'description': 'Snack bag',
      'cost_price': 8000.0,
      'selling_price': 12000.0,
      'qty_cartons': 25,
      'in_stock': 300,
      'supplier_id': 5,
      'category_id': 5,
      'mft_date': '2026-02-15',
      'expiry_date': '2026-09-15',
      'status': 'In Stock',
      'image_url': 'https://img.local/products/chips.png',
      'created_at': '2026-01-15 08:40:00',
      'updated_at': '2026-03-05 08:40:00',
    });

    // Vouchers
    await db.insert('vouchers', {
      'id': 1,
      'code': 'SAVE5',
      'discount_id': 1,
      'percent': null,
      'fixed_amount': null,
      'min_order_amount': 100000.0,
      'valid_from': '2026-03-01',
      'valid_to': '2026-12-31',
      'usage_limit': 1000,
      'used_count': 120,
      'status': 'active',
      'created_at': '2026-03-01 09:00:00',
      'updated_at': '2026-03-10 10:00:00',
    });
    await db.insert('vouchers', {
      'id': 2,
      'code': 'SAVE10',
      'discount_id': 2,
      'percent': null,
      'fixed_amount': null,
      'min_order_amount': 200000.0,
      'valid_from': '2026-03-01',
      'valid_to': '2026-12-31',
      'usage_limit': 500,
      'used_count': 80,
      'status': 'active',
      'created_at': '2026-03-01 09:05:00',
      'updated_at': '2026-03-10 10:05:00',
    });
    await db.insert('vouchers', {
      'id': 3,
      'code': 'FIX20000',
      'discount_id': null,
      'percent': null,
      'fixed_amount': 20000.0,
      'min_order_amount': 150000.0,
      'valid_from': '2026-03-01',
      'valid_to': '2026-12-31',
      'usage_limit': 300,
      'used_count': 25,
      'status': 'active',
      'created_at': '2026-03-01 09:10:00',
      'updated_at': '2026-03-10 10:10:00',
    });
    await db.insert('vouchers', {
      'id': 4,
      'code': 'NEW3',
      'discount_id': 3,
      'percent': null,
      'fixed_amount': null,
      'min_order_amount': 50000.0,
      'valid_from': '2026-03-01',
      'valid_to': '2026-12-31',
      'usage_limit': 1000,
      'used_count': 10,
      'status': 'active',
      'created_at': '2026-03-01 09:15:00',
      'updated_at': '2026-03-10 10:15:00',
    });
    await db.insert('vouchers', {
      'id': 5,
      'code': 'OFF5000',
      'discount_id': null,
      'percent': null,
      'fixed_amount': 5000.0,
      'min_order_amount': 50000.0,
      'valid_from': '2026-03-01',
      'valid_to': '2026-12-31',
      'usage_limit': null,
      'used_count': 5,
      'status': 'active',
      'created_at': '2026-03-01 09:20:00',
      'updated_at': '2026-03-10 10:20:00',
    });

    // Shifts
    await db.insert('shifts', {
      'id': 1,
      'user_id': 3,
      'sales_point': 'Store One',
      'open_time': '2026-03-12 07:00:00',
      'close_time': '2026-03-12 15:00:00',
      'initial_cash': 500000.0,
      'total_cash_end': 2300000.0,
      'status': 'closed',
      'created_at': '2026-03-12 06:50:00',
      'updated_at': '2026-03-12 15:05:00',
    });
    await db.insert('shifts', {
      'id': 2,
      'user_id': 4,
      'sales_point': 'Store Two',
      'open_time': '2026-03-12 07:30:00',
      'close_time': '2026-03-12 15:30:00',
      'initial_cash': 400000.0,
      'total_cash_end': 1800000.0,
      'status': 'closed',
      'created_at': '2026-03-12 07:20:00',
      'updated_at': '2026-03-12 15:35:00',
    });
    await db.insert('shifts', {
      'id': 3,
      'user_id': 3,
      'sales_point': 'Counter A',
      'open_time': '2026-03-13 07:00:00',
      'close_time': null,
      'initial_cash': 300000.0,
      'total_cash_end': null,
      'status': 'open',
      'created_at': '2026-03-13 06:50:00',
      'updated_at': '2026-03-13 07:00:00',
    });
    await db.insert('shifts', {
      'id': 4,
      'user_id': 4,
      'sales_point': 'Counter B',
      'open_time': '2026-03-13 07:30:00',
      'close_time': null,
      'initial_cash': 350000.0,
      'total_cash_end': null,
      'status': 'open',
      'created_at': '2026-03-13 07:20:00',
      'updated_at': '2026-03-13 07:30:00',
    });
    await db.insert('shifts', {
      'id': 5,
      'user_id': 3,
      'sales_point': 'Store Three',
      'open_time': '2026-03-11 08:00:00',
      'close_time': '2026-03-11 16:00:00',
      'initial_cash': 450000.0,
      'total_cash_end': 2100000.0,
      'status': 'closed',
      'created_at': '2026-03-11 07:50:00',
      'updated_at': '2026-03-11 16:05:00',
    });

    // Orders
    await db.insert('sales_orders', {
      'id': 1,
      'order_no': 'ORD-0001',
      'customer_id': 1,
      'customer_phone': '0900000001',
      'customer_name': 'Nguyen Van A',
      'cashier_id': 3,
      'sales_point': 'Store One',
      'shift_id': 1,
      'order_date': '2026-03-12',
      'order_time': '09:10:00',
      'subtotal': 100000.0,
      'discount_id': 1,
      'voucher_id': 1,
      'discount_percent': 5.0,
      'discount_amount': 5000.0,
      'total_payable': 95000.0,
      'paid': 95000.0,
      'balance': 0.0,
      'payment_method': 'Cash',
      'status': 'Paid',
      'pay_due_date': null,
      'created_at': '2026-03-12 09:10:00',
      'updated_at': '2026-03-12 09:10:00',
    });

    await db.insert('sales_orders', {
      'id': 2,
      'order_no': 'ORD-0002',
      'customer_id': 2,
      'customer_phone': '0900000002',
      'customer_name': 'Tran Thi B',
      'cashier_id': 3,
      'sales_point': 'Store One',
      'shift_id': 1,
      'order_date': '2026-03-12',
      'order_time': '10:20:00',
      'subtotal': 250000.0,
      'discount_id': 2,
      'voucher_id': 2,
      'discount_percent': 10.0,
      'discount_amount': 25000.0,
      'total_payable': 225000.0,
      'paid': 200000.0,
      'balance': 25000.0,
      'payment_method': 'Transfer',
      'status': 'Pending',
      'pay_due_date': '2026-03-20',
      'created_at': '2026-03-12 10:20:00',
      'updated_at': '2026-03-12 10:20:00',
    });

    await db.insert('sales_orders', {
      'id': 3,
      'order_no': 'ORD-0003',
      'customer_id': null,
      'customer_phone': null,
      'customer_name': 'Guest',
      'cashier_id': 4,
      'sales_point': 'Store Two',
      'shift_id': 2,
      'order_date': '2026-03-12',
      'order_time': '11:30:00',
      'subtotal': 120000.0,
      'discount_id': null,
      'voucher_id': 5,
      'discount_percent': 0.0,
      'discount_amount': 5000.0,
      'total_payable': 115000.0,
      'paid': 115000.0,
      'balance': 0.0,
      'payment_method': 'Card',
      'status': 'Paid',
      'pay_due_date': null,
      'created_at': '2026-03-12 11:30:00',
      'updated_at': '2026-03-12 11:30:00',
    });

    await db.insert('sales_orders', {
      'id': 4,
      'order_no': 'ORD-0004',
      'customer_id': 4,
      'customer_phone': '0900000004',
      'customer_name': 'Pham Thi D',
      'cashier_id': 4,
      'sales_point': 'Store Two',
      'shift_id': 2,
      'order_date': '2026-03-12',
      'order_time': '14:00:00',
      'subtotal': 600000.0,
      'discount_id': 4,
      'voucher_id': null,
      'discount_percent': 15.0,
      'discount_amount': 90000.0,
      'total_payable': 510000.0,
      'paid': 300000.0,
      'balance': 210000.0,
      'payment_method': 'POS',
      'status': 'Pending',
      'pay_due_date': '2026-03-25',
      'created_at': '2026-03-12 14:00:00',
      'updated_at': '2026-03-12 14:00:00',
    });

    await db.insert('sales_orders', {
      'id': 5,
      'order_no': 'ORD-0005',
      'customer_id': 3,
      'customer_phone': '0900000003',
      'customer_name': 'Le Van C',
      'cashier_id': 3,
      'sales_point': 'Store Three',
      'shift_id': 5,
      'order_date': '2026-03-11',
      'order_time': '15:40:00',
      'subtotal': 180000.0,
      'discount_id': 3,
      'voucher_id': 4,
      'discount_percent': 3.0,
      'discount_amount': 5400.0,
      'total_payable': 174600.0,
      'paid': 174600.0,
      'balance': 0.0,
      'payment_method': 'Cash',
      'status': 'Paid',
      'pay_due_date': null,
      'created_at': '2026-03-11 15:40:00',
      'updated_at': '2026-03-11 15:40:00',
    });

    // Order items
    await db.insert('order_items', {
      'id': 1,
      'order_id': 1,
      'product_id': 1,
      'product_name': 'Coca Cola 330ml',
      'unit_price': 10000.0,
      'qty': 10,
      'amount': 100000.0,
    });
    await db.insert('order_items', {
      'id': 2,
      'order_id': 2,
      'product_id': 3,
      'product_name': 'Fresh Milk 1L',
      'unit_price': 28000.0,
      'qty': 5,
      'amount': 140000.0,
    });
    await db.insert('order_items', {
      'id': 3,
      'order_id': 3,
      'product_id': 5,
      'product_name': 'Potato Chips',
      'unit_price': 12000.0,
      'qty': 10,
      'amount': 120000.0,
    });
    await db.insert('order_items', {
      'id': 4,
      'order_id': 4,
      'product_id': 4,
      'product_name': 'Notebook A5',
      'unit_price': 18000.0,
      'qty': 20,
      'amount': 360000.0,
    });
    await db.insert('order_items', {
      'id': 5,
      'order_id': 5,
      'product_id': 2,
      'product_name': 'Instant Noodles',
      'unit_price': 5000.0,
      'qty': 36,
      'amount': 180000.0,
    });

    // Reset tokens
    await db.insert('password_reset_tokens', {
      'id': 1,
      'user_id': 1,
      'email': 'admin01@supermarket.com',
      'token': 'prt_admin_0001',
      'otp': '111111',
      'expires_at': '2099-12-31 23:59:59',
    });
    await db.insert('password_reset_tokens', {
      'id': 2,
      'user_id': 2,
      'email': 'manager01@supermarket.com',
      'token': 'prt_manager_0001',
      'otp': '222222',
      'expires_at': '2099-12-31 23:59:59',
    });
    await db.insert('password_reset_tokens', {
      'id': 3,
      'user_id': 3,
      'email': 'cashier01@supermarket.com',
      'token': 'prt_cashier01_0001',
      'otp': '333333',
      'expires_at': '2099-12-31 23:59:59',
    });
    await db.insert('password_reset_tokens', {
      'id': 4,
      'user_id': 4,
      'email': 'cashier02@supermarket.com',
      'token': 'prt_cashier02_0001',
      'otp': '444444',
      'expires_at': '2099-12-31 23:59:59',
    });
  }
}
