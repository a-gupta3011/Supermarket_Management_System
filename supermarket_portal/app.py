import os
from flask import Flask, render_template, request, redirect, session, flash, url_for
import mysql.connector
from mysql.connector import errors as db_errors

app = Flask(__name__)
app.secret_key = os.urandom(24)

db_config = {
    'user':     'root',
    'password': 'root',
    'host':     '127.0.0.1',
    'database': 'SupermarketDB'
}

def get_db():
    return mysql.connector.connect(**db_config)

def query(sql, args=(), one=False):
    conn = get_db()
    cur = conn.cursor(dictionary=True)
    cur.execute(sql, args)
    rv = cur.fetchone() if one else cur.fetchall()
    cur.close()
    conn.close()
    return rv

@app.route('/', methods=['GET','POST'])
def login():
    if request.method == 'POST':
        user = request.form['username']
        pwd  = request.form['password']
        role = request.form['role']
        try:
            conn = mysql.connector.connect(
                host=db_config['host'],
                user=user, password=pwd,
                database=db_config['database']
            )
            conn.close()

            session.clear()
            session['user'] = user
            session['role'] = role

            role_map = {
                'branch_manager': 'branch_manager',
                'department_mgr': 'department_mgr',
                'cleaning_mgr':   'cleaning_mgr',
                'supplier_mgr':   'supplier_mgr',
                'cashier':        'bills',
                'inventory':      'inventory',
                'supplier':       'supplier',
                'analyst':        'analyst',
                'auditor':        'auditor'
            }
            return redirect(url_for(role_map.get(role, 'login')))

        except Exception as e:
            flash(f"Login failed: {e}", "error")

    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect('/')

# — Branch Manager —
@app.route('/branch_manager', methods=['GET','POST'])
def branch_manager():
    if session.get('role') != 'branch_manager':
        return redirect('/')
    try:
        conn = get_db()
        cur = conn.cursor(dictionary=True)

        if request.method == 'POST':
            if 'create_branch' in request.form:
                cur.execute(
                    "INSERT INTO Branch (name, location, supermarket_id) VALUES (%s, %s, 1)",
                    (request.form['name'], request.form['location'])
                )
                flash("Branch created", "success")
            elif 'update_branch' in request.form:
                cur.execute(
                    "UPDATE Branch SET name=%s, location=%s WHERE branch_id=%s",
                    (request.form['name'], request.form['location'], request.form['branch_id'])
                )
                flash("Branch updated", "success")
            elif 'delete_branch' in request.form:
                cur.execute(
                    "DELETE FROM Branch WHERE branch_id=%s",
                    (request.form['branch_id'],)
                )
                flash("Branch deleted", "success")

            if 'create_dept' in request.form:
                cur.execute(
                    "INSERT INTO Department (name, branch_id) VALUES (%s, %s)",
                    (request.form['dept_name'], request.form['dept_branch'])
                )
                flash("Department created", "success")
            elif 'update_dept' in request.form:
                cur.execute(
                    "UPDATE Department SET name=%s, branch_id=%s WHERE department_id=%s",
                    (request.form['dept_name'], request.form['dept_branch'], request.form['dept_id'])
                )
                flash("Department updated", "success")
            elif 'delete_dept' in request.form:
                cur.execute(
                    "DELETE FROM Department WHERE department_id=%s",
                    (request.form['dept_id'],)
                )
                flash("Department deleted", "success")

            conn.commit()

        branches    = query("SELECT * FROM Branch")
        departments = query("SELECT * FROM Department")

    except Exception as e:
        flash(f"Error: {e}", "error")
        branches, departments = [], []

    finally:
        cur.close()
        conn.close()

    return render_template(
        'branch_manager.html',
        branches=branches,
        departments=departments
    )

# — Department Manager —
@app.route('/department_mgr', methods=['GET','POST'])
def department_mgr():
    if session.get('role') != 'department_mgr':
        return redirect('/')
    try:
        conn = get_db()
        cur = conn.cursor(dictionary=True)

        if request.method == 'POST':
            if 'create_emp' in request.form:
                cur.execute(
                    "INSERT INTO Employee (name, role, salary, branch_id, department_id) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    (
                        request.form['name'],
                        request.form['role'],
                        request.form['salary'],
                        request.form['branch_id'],
                        request.form['department_id']
                    )
                )
                flash("Employee created", "success")
            elif 'update_emp' in request.form:
                cur.execute(
                    "UPDATE Employee SET name=%s, role=%s, salary=%s, branch_id=%s, department_id=%s "
                    "WHERE employee_id=%s",
                    (
                        request.form['name'],
                        request.form['role'],
                        request.form['salary'],
                        request.form['branch_id'],
                        request.form['department_id'],
                        request.form['employee_id']
                    )
                )
                flash("Employee updated", "success")
            elif 'delete_emp' in request.form:
                cur.execute(
                    "DELETE FROM Employee WHERE employee_id=%s",
                    (request.form['employee_id'],)
                )
                flash("Employee deleted", "success")

            conn.commit()

        employees = query("SELECT * FROM Employee")

    except Exception as e:
        flash(f"Error: {e}", "error")
        employees = []

    finally:
        cur.close()
        conn.close()

    return render_template('department_mgr.html', employees=employees)

# — Cleaning Manager —
@app.route('/cleaning_mgr', methods=['GET','POST'])
def cleaning_mgr():
    if session.get('role') != 'cleaning_mgr':
        return redirect('/')
    try:
        conn = get_db()
        cur = conn.cursor(dictionary=True)

        if request.method == 'POST':
            if 'create_company' in request.form:
                cur.execute(
                    "INSERT INTO Cleaning_Company (name, contact) VALUES (%s, %s)",
                    (request.form['company_name'], request.form['contact'])
                )
                flash("Company created", "success")
            elif 'update_company' in request.form:
                cur.execute(
                    "UPDATE Cleaning_Company SET name=%s, contact=%s WHERE company_id=%s",
                    (request.form['company_name'], request.form['contact'], request.form['company_id'])
                )
                flash("Company updated", "success")
            elif 'delete_company' in request.form:
                cur.execute(
                    "DELETE FROM Cleaning_Company WHERE company_id=%s",
                    (request.form['company_id'],)
                )
                flash("Company deleted", "success")

            if 'assign' in request.form:
                try:
                    cur.execute(
                        "INSERT INTO Branch_CleaningCompany (branch_id, company_id, service_frequency) "
                        "VALUES (%s, %s, %s)",
                        (
                            request.form['branch_id'],
                            request.form['company_id'],
                            request.form['service_frequency']
                        )
                    )
                    flash("Assignment saved", "success")
                except db_errors.IntegrityError:
                    flash("That assignment already exists.", "error")
            elif 'update_assign' in request.form:
                cur.execute(
                    "UPDATE Branch_CleaningCompany SET service_frequency=%s "
                    "WHERE branch_id=%s AND company_id=%s",
                    (
                        request.form['service_frequency'],
                        request.form['branch_id'],
                        request.form['company_id']
                    )
                )
                flash("Assignment updated", "success")
            elif 'delete_assign' in request.form:
                cur.execute(
                    "DELETE FROM Branch_CleaningCompany "
                    "WHERE branch_id=%s AND company_id=%s",
                    (
                        request.form['branch_id'],
                        request.form['company_id']
                    )
                )
                flash("Assignment deleted", "success")

            conn.commit()

        companies   = query("SELECT * FROM Cleaning_Company")
        assignments = query("SELECT * FROM Branch_CleaningCompany")

    except Exception as e:
        flash(f"Error: {e}", "error")
        companies, assignments = [], []

    finally:
        cur.close()
        conn.close()

    return render_template(
        'cleaning_mgr.html',
        companies=companies,
        assignments=assignments
    )

# — Supplier Manager —
@app.route('/supplier_mgr', methods=['GET','POST'])
def supplier_mgr():
    if session.get('role') != 'supplier_mgr':
        return redirect('/')
    try:
        conn = get_db()
        cur = conn.cursor(dictionary=True)

        if request.method == 'POST':
            if 'create_supplier' in request.form:
                cur.execute(
                    "INSERT INTO Supplier (name, contact) VALUES (%s, %s)",
                    (request.form['supplier_name'], request.form['contact'])
                )
                flash("Supplier created", "success")
            elif 'update_supplier' in request.form:
                cur.execute(
                    "UPDATE Supplier SET name=%s, contact=%s WHERE supplier_id=%s",
                    (
                        request.form['supplier_name'],
                        request.form['contact'],
                        request.form['supplier_id']
                    )
                )
                flash("Supplier updated", "success")
            elif 'delete_supplier' in request.form:
                cur.execute(
                    "DELETE FROM Supplier WHERE supplier_id=%s",
                    (request.form['supplier_id'],)
                )
                flash("Supplier deleted", "success")

            if 'create_product' in request.form:
                cur.execute(
                    "INSERT INTO Product (name, category, price, supplier_id) VALUES (%s, %s, %s, %s)",
                    (
                        request.form['product_name'],
                        request.form['category'],
                        request.form['price'],
                        request.form['supplier_id']
                    )
                )
                flash("Product created", "success")
            elif 'update_product' in request.form:
                cur.execute(
                    "UPDATE Product SET name=%s, category=%s, price=%s, supplier_id=%s "
                    "WHERE product_id=%s",
                    (
                        request.form['product_name'],
                        request.form['category'],
                        request.form['price'],
                        request.form['supplier_id'],
                        request.form['product_id']
                    )
                )
                flash("Product updated", "success")
            elif 'delete_product' in request.form:
                cur.execute(
                    "DELETE FROM Product WHERE product_id=%s",
                    (request.form['product_id'],)
                )
                flash("Product deleted", "success")

            conn.commit()

        suppliers = query("SELECT * FROM Supplier")
        products  = query("SELECT * FROM Product")

    except Exception as e:
        flash(f"Error: {e}", "error")
        suppliers, products = [], []

    finally:
        cur.close()
        conn.close()

    return render_template(
        'supplier_mgr.html',
        suppliers=suppliers,
        products=products
    )

# — Cashier: Create Bill —
@app.route('/bills', methods=['GET','POST'])
def bills():
    if session.get('role') != 'cashier':
        return redirect('/')
    try:
        conn = get_db()
        cur = conn.cursor(dictionary=True)

        if request.method == 'POST' and 'create' in request.form:
            cur.execute(
                "INSERT INTO Billing (customer_id, branch_id, billing_date, payment_method) "
                "VALUES (%s, 1, CURDATE(), %s)",
                (
                    request.form['customer_id'],
                    request.form['payment_method']
                )
            )
            bill_id = cur.lastrowid
            conn.commit()
            return redirect(url_for('edit_bill', bill_id=bill_id))

        customers = query("SELECT customer_id, name FROM Customer")

    except Exception as e:
        flash(f"Error: {e}", "error")
        customers = []

    finally:
        cur.close()
        conn.close()

    return render_template('bills.html', customers=customers)

# — Cashier: Edit/Add Items to Bill —
@app.route('/bills/<int:bill_id>', methods=['GET','POST'])
def edit_bill(bill_id):
    if session.get('role') != 'cashier':
        return redirect('/')
    try:
        conn = get_db()
        cur = conn.cursor(dictionary=True)

        if request.method == 'POST':
            cur.execute(
                "INSERT INTO Billing_Product (billing_id, product_id, quantity) VALUES (%s, %s, %s)",
                (
                    bill_id,
                    request.form['product_id'],
                    request.form['quantity']
                )
            )
            cur.execute(
                "UPDATE Billing b "
                "JOIN Product p ON p.product_id=%s "
                "SET b.total_amount = b.total_amount + p.price * %s "
                "WHERE b.billing_id=%s",
                (
                    request.form['product_id'],
                    request.form['quantity'],
                    bill_id
                )
            )
            conn.commit()
            flash("Item added to bill", "success")

        bill     = query("SELECT * FROM Billing WHERE billing_id=%s", (bill_id,), one=True)
        items    = query(
            "SELECT p.name, bp.quantity, p.price, (bp.quantity * p.price) AS subtotal "
            "FROM Billing_Product bp "
            "JOIN Product p ON p.product_id = bp.product_id "
            "WHERE bp.billing_id=%s", (bill_id,)
        )
        products = query("SELECT product_id, name, price FROM Product")

    except Exception as e:
        flash(f"Error: {e}", "error")
        bill, items, products = None, [], []

    finally:
        cur.close()
        conn.close()

    return render_template(
        'edit_bill.html',
        bill=bill,
        items=items,
        products=products
    )

# — All Bills —
@app.route('/all_bills')
def all_bills():
    if session.get('role') not in ('cashier','analyst','auditor'):
        return redirect('/')

    # Recompute each bill’s total by summing its Billing_Product rows
    bills = query(
        """
        SELECT
          b.billing_id,
          c.name AS customer,
          b.billing_date,
          COALESCE(SUM(bp.quantity * p.price),0) AS total_amount,
          b.payment_method
        FROM Billing b
        JOIN Customer c ON c.customer_id = b.customer_id
        LEFT JOIN Billing_Product bp ON bp.billing_id = b.billing_id
        LEFT JOIN Product p ON p.product_id = bp.product_id
        GROUP BY b.billing_id, c.name, b.billing_date, b.payment_method
        ORDER BY b.billing_date DESC
        """
    )
    return render_template('all_bills.html', bills=bills)

# — Cashier: Print Bill —
@app.route('/print_bill/<int:bill_id>')
def print_bill(bill_id):
    if session.get('role') != 'cashier':
        return redirect('/')

    # Fetch bill header
    bill = query(
        "SELECT b.billing_id, c.name AS customer, b.billing_date "
        "FROM Billing b "
        "JOIN Customer c ON c.customer_id = b.customer_id "
        "WHERE b.billing_id = %s",
        (bill_id,), one=True
    )

    # Fetch items and compute subtotals
    items = query(
        "SELECT p.name, bp.quantity, p.price, "
        "(bp.quantity * p.price) AS subtotal "
        "FROM Billing_Product bp "
        "JOIN Product p ON p.product_id = bp.product_id "
        "WHERE bp.billing_id = %s",
        (bill_id,)
    )

    # Recalculate the total from the item subtotals
    total = sum(item['subtotal'] for item in items)

    return render_template('print_bill.html',
                           bill=bill,
                           items=items,
                           total=total)


# — Inventory Clerk —
@app.route('/inventory', methods=['GET','POST'])
def inventory():
    if session.get('role') != 'inventory':
        return redirect('/')
    try:
        conn = get_db()
        cur = conn.cursor(dictionary=True)

        if request.method == 'POST':
            cur.execute(
                "UPDATE Stock SET quantity=%s WHERE stock_id=%s",
                (request.form['quantity'], request.form['stock_id'])
            )
            conn.commit()
            flash("Stock updated", "success")

        stock = query(
            "SELECT s.stock_id, b.name AS branch, p.name AS product, s.quantity "
            "FROM Stock s "
            "JOIN Branch b ON b.branch_id = s.branch_id "
            "JOIN Product p ON p.product_id = s.product_id"
        )

    except Exception as e:
        flash(f"Error: {e}", "error")
        stock = []

    finally:
        cur.close()
        conn.close()

    return render_template('inventory.html', stock=stock)

# — Supplier Rep —
@app.route('/supplier')
def supplier():
    if session.get('role') != 'supplier':
        return redirect('/')
    products = query(
        "SELECT p.product_id, p.name, s.name AS supplier "
        "FROM Product p "
        "JOIN Supplier s ON p.supplier_id = s.supplier_id"
    )
    return render_template('supplier.html', products=products)

# — Analyst —
@app.route('/analyst')
def analyst():
    if session.get('role') != 'analyst':
        return redirect('/')
    summary = query(
        "SELECT b.name AS branch, SUM(bi.total_amount) AS total_sales "
        "FROM Billing bi "
        "JOIN Branch b ON b.branch_id = bi.branch_id "
        "GROUP BY bi.branch_id"
    )
    return render_template('analyst.html', summary=summary)

# — Auditor —
@app.route('/auditor')
def auditor():
    if session.get('role') != 'auditor':
        return redirect('/')
    depts  = query(
        "SELECT department_id, name, "
        "get_department_emp_count(department_id) AS emp_count "
        "FROM Department"
    )
    stocks = query(
        "SELECT branch_id, "
        "get_branch_stock_value(branch_id) AS stock_value "
        "FROM Branch"
    )
    return render_template('auditor.html', depts=depts, stocks=stocks)

if __name__ == '__main__':
    app.run(debug=True)
