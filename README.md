# 📘 Lost & Found Management System

A complete Lost & Found Web Application built using **Python Streamlit** and **MySQL**, allowing users to report lost items, report found items, create claims, and view system logs.

---

## 🚀 Features

### 🔐 Authentication
- User registration  
- Login system  
- Session-based authentication  

### 🎒 Lost Item Reporting
- User reports items they lost  
- Category & location selection  

### 🔎 Found Item Reporting
- Users report found items  
- System automatically logs entries  

### 📦 Claim Creation
- Match a lost item with a found item  
- Claim status stored in DB  
- Prevents duplicate claim creation  

### 📋 View Sections
- View all lost items  
- View all found items  
- View claims with user details  
- System logs view (Admin purpose)

### 🗄️ Database Features
- Tables (DDL)  
- Inserts (DML)  
- Stored Procedures  
- Triggers  
- Functions  
- Complex SQL queries  

---

## 🗂️ Project Structure

```
lost-found-system/
│
├── app.py
├── requirements.txt
│
├── lost_found_system.sql   # Full SQL Code
│
└── README.md
```

---

## 🛠️ Installation

### 1. Install dependencies
```
pip install -r requirements.txt
```

### 2. Import database
Import the full SQL:

```
lost_found_system.sql
```

Run it in MySQL Workbench.

### 3. Run the Streamlit App
```
streamlit run app.py
```

---

## 🧰 Tech Stack

- **Frontend:** Python Streamlit  
- **Backend:** MySQL  
- **Connector:** mysql-connector-python  
- **Data:** Pandas  

---

## 📚 References
- Streamlit Documentation  
- Python Docs  
- MySQL Documentation  