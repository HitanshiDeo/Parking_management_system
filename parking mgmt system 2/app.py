from flask import Flask, render_template, request, redirect, session, jsonify
from flask_mysqldb import MySQL
from datetime import datetime, timedelta
import hashlib
import os
import re


app = Flask(__name__)
app.secret_key = os.getenv('FLASK_SECRET_KEY', 'fallback_secret_key')

# MySQL configuration
app.config['MYSQL_HOST'] = '127.0.0.1'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'password'
app.config['MYSQL_DB'] = 'ParkingSystem'

mysql = MySQL(app)

# Utility function to hash passwords
def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

# Routes
@app.route('/')
def index():
    return render_template('index.html')



# Utility function to validate inputs
def is_valid_name(name):
    return re.match(r'^[A-Za-z\s]+$', name)

def is_valid_phone(phone_number):
    return re.match(r'^\d+$', phone_number)

def is_valid_usn(usn):
    return re.match(r'^[A-Za-z0-9]+$', usn)

def is_valid_email(email):
    return re.match(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$', email)

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        name = request.form['name']
        usn = request.form['usn']
        email = request.form['email']
        phone_number = request.form['phone_number']
        vehicle_type = request.form['vehicle_type']
        password = request.form['password']

        # Input validation
        if not is_valid_name(name):
            return jsonify({'status': 'error', 'message': "Invalid name. Name should contain only alphabets and spaces!"})
        if not is_valid_usn(usn):
            return jsonify({'status': 'error', 'message': "Invalid USN. USN should be alphanumeric!"})
        if not is_valid_email(email):
            return jsonify({'status': 'error', 'message': "Invalid email. Please provide a valid email address!"})
        if not is_valid_phone(phone_number):
            return jsonify({'status': 'error', 'message': "Invalid phone number. It should contain only numbers!"})
        if not password or len(password) < 6:
            return jsonify({'status': 'error', 'message': "Password should be at least 6 characters long!"})

        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM users WHERE email = %s", (email,))
        existing_user = cur.fetchone()

        if existing_user:
            cur.close()
            return jsonify({'status': 'error', 'message': "This email is already registered!"})

        # Hash password and store user details
        hashed_password = hash_password(password)
        cur.execute("""
            INSERT INTO users (name, usn, email, phone_number, vehicle_type, password) 
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (name, usn, email, phone_number, vehicle_type, hashed_password))
        mysql.connection.commit()
        cur.close()

        return jsonify({'status': 'success', 'redirect': '/login'})

    return render_template('register.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        # Input validation
        if not is_valid_email(email):
            return "Invalid email. Please provide a valid email address!"
        if not password:
            return "Password cannot be empty!"

        hashed_password = hash_password(password)
        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM users WHERE email = %s AND password = %s", (email, hashed_password))
        user = cur.fetchone()
        cur.close()

        if user:
            session['user_id'] = user[0]
            session['name'] = user[1]
            return redirect('/dashboard')
        else:
            return "Invalid credentials!"

    return render_template('login.html')

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect('/login')

    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM Slot")
    slots = cur.fetchall()
    cur.close()

    return render_template('dashboard.html', slots=slots, name=session['name'])

@app.route('/my_reservations')
def my_reservations():
    if 'user_id' not in session:
        return redirect('/login')

    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT Slot.Slot_ID, Slot.Slot_Type, Slot.Location, Slot.Availability, 
               reservations.timestamp, Slot.Location_ID, Slot.Reserved_For_15_Min
        FROM reservations 
        JOIN Slot ON reservations.Slot_ID = Slot.Slot_ID 
        WHERE reservations.user_id = %s
        ORDER BY reservations.timestamp DESC
    """, (session['user_id'],))
    
    reserved_slots = cur.fetchall()
    cur.close()

    return render_template('my_reservations.html', reserved_slots=reserved_slots)



@app.route('/reserve/<int:Slot_ID>', methods=['POST'])
def reserve(Slot_ID):
    if 'user_id' not in session:
        return redirect('/login')

    # Reserve the slot for 15 minutes
    cur = mysql.connection.cursor()

    # Check if the slot is available
    cur.execute("SELECT * FROM Slot WHERE Slot_ID = %s AND Availability = 'Available'", (Slot_ID,))
    slot = cur.fetchone()

    if slot:
        # Update slot to be reserved temporarily and record the current timestamp
        cur.execute("""
            UPDATE Slot
            SET Availability = 'Reserved', Reserved_For_15_Min = 'Yes', Date_and_Time = %s
            WHERE Slot_ID = %s
        """, (datetime.now(), Slot_ID))

        # Insert reservation entry
        cur.execute("""
            INSERT INTO reservations (user_id, Slot_ID, timestamp)
            VALUES (%s, %s, %s)
        """, (session['user_id'], Slot_ID, datetime.now()))
        mysql.connection.commit()

    cur.close()
    return redirect('/dashboard')
 

@app.route('/checkin/<int:Slot_ID>', methods=['POST'])
def checkin(Slot_ID):
    if 'user_id' not in session:
        return redirect('/login')

    cur = mysql.connection.cursor()

    # Update slot status to 'Occupied' and reset the temporary reservation
    cur.execute("""
        UPDATE Slot
        SET Availability = 'Occupied', Reserved_For_15_Min = 'No'
        WHERE Slot_ID = %s
    """, (Slot_ID,))
    mysql.connection.commit()

    cur.execute("""
        UPDATE reservations 
        SET Checkin_Time = %s 
        WHERE user_id = %s AND Slot_ID = %s 
        ORDER BY timestamp DESC LIMIT 1
    """, (datetime.now(), session['user_id'], Slot_ID))
    mysql.connection.commit()
    

    cur.close()
    return redirect('/dashboard')


@app.route('/checkout/<int:Slot_ID>', methods=['POST'])
def checkout(Slot_ID):
    if 'user_id' not in session:
        return redirect('/login')

    cur = mysql.connection.cursor()

    # Update slot status to 'Available' and reset the temporary reservation
    cur.execute("""
        UPDATE Slot
        SET Availability = 'Available', Reserved_For_15_Min = 'No'
        WHERE Slot_ID = %s
    """, (Slot_ID,))
    mysql.connection.commit()

    cur.execute("""
        UPDATE reservations 
        SET Checkout_Time = %s 
        WHERE user_id = %s AND Slot_ID = %s 
        ORDER BY timestamp DESC LIMIT 1
    """, (datetime.now(), session['user_id'], Slot_ID))

    mysql.connection.commit()
    cur.close()
    return redirect('/dashboard')

@app.route('/refresh_slots')
def refresh_slots():
    cur = mysql.connection.cursor()
    cur.execute("SELECT Slot_ID, Slot_Type, Location, Availability FROM Slot")
    slots = cur.fetchall()
    cur.close()

    # Convert slots data into a list of dictionaries
    slots_data = [{
        'Slot_ID': slot[0],
        'Slot_Type': slot[1],
        'Location': slot[2],
        'Availability': slot[3],
    } for slot in slots]

    return jsonify(slots_data)

@app.route('/logout')
def logout():
    session.clear()
    return redirect('/')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
