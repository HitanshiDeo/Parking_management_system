# 🚗 Parking Management System

A web-based **Parking Management System** built with **Flask (Python)** and **MySQL**, designed to manage student vehicles, parking slots, and reservations.

---

## 📌 Features
- 👤 **User registration & login** (students linked via USN).
- 🚘 **Vehicle management** (add and track student vehicles).
- 🅿️ **Parking slot allocation** with availability tracking.
- 📍 **Location-based slot organization**.
- 📆 **Reservation system** (check-in, check-out, reserved slots).
- 🔑 **Secure authentication** with email & password.

---

## 🗂️ Project Structure
```text
parking-management-system/
│── static/                  # Static assets (CSS, images, JS)
│   └── styles.css
│
│── templates/               # HTML templates (Jinja2)
│   ├── dashboard.html       # Dashboard after login
│   ├── index.html           # Homepage
│   ├── login.html           # Login page
│   ├── register.html        # Registration page
│   ├── slots.html           # Parking slots page
│   ├── locations.html       # Parking locations page
│   └── my_reservations.html # Reservations made by user
│
│── db/                      # Database schema
│   └── clgdb.sql   # SQL file for database setup
│
│── venv/                    # Python virtual environment (ignored in Git)
│
│── app.py                   # Main Flask application
│── requirements.txt         # Python dependencies
│── .gitignore               # Ignored files/folders (venv, __pycache__, etc.)
│── README.md                # Project documentation

# ⚙️ Installation & Setup

Follow these steps to set up the **Parking Management System** on your local machine:

---

## 1️. Clone the repository & Create Virtual Environment
```bash
# Clone the project
git clone https://github.com/your-username/parking-management-system.git
cd parking-management-system

# Create virtual environment
```bash
python -m venv venv

# Activate virtual environment
# For Linux/Mac
```bash
source venv/bin/activate
# For Windows
```bash
venv\Scripts\activate

2. Install Dependencies
```bash
pip install -r requirements.txt

3.Setup MySQL Database
Open MySQL and create a database using clgdb.sql

4.Update your database credentials in app.py
app.config['MYSQL_USER'] = 'your-username'
app.config['MYSQL_PASSWORD'] = 'your-password'
app.config['MYSQL_DB'] = 'parking_system'

5.Run the Application
```bash
python app.py



