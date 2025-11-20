import streamlit as st
import mysql.connector
import pandas as pd

# -----------------------------------------------------------
#  DATABASE CONNECTION
# -----------------------------------------------------------
def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="password", #password
        database="LostAndFoundDB",
        port=3306
    )

# -----------------------------------------------------------
#  STORED PROCEDURE EXECUTION (RELIABLE)
# -----------------------------------------------------------
def call_proc(proc_name, params=None):
    conn = get_connection()
    cur = conn.cursor()

    try:
        if params:
            placeholder = ",".join(["%s"] * len(params))
            sql = f"CALL {proc_name}({placeholder})"
            cur.execute(sql, tuple(params))
        else:
            sql = f"CALL {proc_name}()"
            cur.execute(sql)

        # Return any SELECT output from the procedure
        results = []
        try:
            for rs in cur.stored_results():
                results.append(rs.fetchall())
        except:
            pass

        conn.commit()
        return results

    except Exception:
        conn.rollback()
        raise

    finally:
        cur.close()
        conn.close()


# -----------------------------------------------------------
#  FETCH DataFrame
# -----------------------------------------------------------
def fetch_df(query):
    conn = get_connection()
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# -----------------------------------------------------------
#  USER AUTH
# -----------------------------------------------------------
def verify_user(email, password):
    conn = get_connection()
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT * FROM User WHERE Email=%s AND Password=%s", (email, password))
    user = cur.fetchone()
    cur.close()
    conn.close()
    return user


def register_user(name, email, phone, password):
    call_proc("AddNewUser", [name, email, phone, "User", password])


# -----------------------------------------------------------
#  STREAMLIT UI CONFIG
# -----------------------------------------------------------
st.set_page_config(page_title="Lost & Found Portal", page_icon="🎒", layout="wide")
st.title("🎒 Lost & Found Portal")


# -----------------------------------------------------------
#  SESSION CONTROL
# -----------------------------------------------------------
if "user" not in st.session_state:
    st.session_state.user = None

st.session_state.setdefault("claim_trigger", False)


# -----------------------------------------------------------
#  LOGIN / REGISTER
# -----------------------------------------------------------
if st.session_state.user is None:

    tab1, tab2 = st.tabs(["🔐 Login", "🆕 Register"])

    with tab1:
        st.subheader("Login")
        email = st.text_input("Email")
        password = st.text_input("Password", type="password")

        if st.button("Login"):
            user = verify_user(email, password)
            if user:
                st.session_state.user = user
                st.success(f"Welcome {user['Name']}!")
                st.rerun()
            else:
                st.error("Invalid credentials.")

    with tab2:
        st.subheader("Register")
        name = st.text_input("Full Name")
        remail = st.text_input("Email", key="reg_email")
        phone = st.text_input("Phone")
        rpass = st.text_input("Password", type="password", key="reg_pass")

        if st.button("Register"):
            try:
                register_user(name, remail, phone, rpass)
                st.success("User Registered! Please login.")
            except Exception as e:
                st.error(f"Error: {e}")

else:
    user = st.session_state.user

    st.sidebar.write(f"👋 Logged in as **{user['Name']} ({user['Email']})**")
    if st.sidebar.button("🚪 Logout"):
        st.session_state.user = None
        st.rerun()

    menu = st.sidebar.radio("Menu", [
        "Report Lost Item", "Report Found Item", "Create Claim",
        "View Lost Items", "View Found Items", "View Claims", "System Logs"
    ])


    # -----------------------------------------------------------
    #  REPORT LOST ITEM
    # -----------------------------------------------------------
    if menu == "Report Lost Item":
        st.header("🧳 Report Lost Item")

        desc = st.text_area("Item Description")
        cat = st.selectbox("Category", [("1", "Wallet"), ("2", "Mobile"), ("3", "Watch")],
                           format_func=lambda x: x[1])
        loc = st.selectbox("Location", [("1", "Library"), ("2", "Cafeteria"), ("3", "Auditorium")],
                           format_func=lambda x: x[1])

        if st.button("Submit Lost Item"):
            try:
                call_proc("AddLostItem", [user["UserID"], desc, int(loc[0]), int(cat[0])])
                st.success("Lost item reported successfully!")
                st.rerun()
            except Exception as e:
                st.error(f"Error: {e}")


    # -----------------------------------------------------------
    #  REPORT FOUND ITEM
    # -----------------------------------------------------------
    elif menu == "Report Found Item":
        st.header("🔎 Report Found Item")

        desc = st.text_area("Item Description")
        cat = st.selectbox("Category", [("1", "Wallet"), ("2", "Mobile"), ("3", "Watch")],
                           format_func=lambda x: x[1])
        loc = st.selectbox("Location", [("1", "Library"), ("2", "Cafeteria"), ("3", "Auditorium")],
                           format_func=lambda x: x[1])

        if st.button("Submit Found Item"):
            try:
                call_proc("AddFoundItem", [user["UserID"], desc, int(loc[0]), int(cat[0])])
                st.success("Found item reported successfully!")
                st.rerun()
            except Exception as e:
                st.error(f"Error: {e}")


    # -----------------------------------------------------------
    #  CREATE CLAIM
    # -----------------------------------------------------------
    elif menu == "Create Claim":
        st.header("📦 Create Claim")

        try:
            lost_df = fetch_df("SELECT LostItemID, Description FROM LostItem WHERE Status != 'Claimed';")
            found_df = fetch_df("SELECT FoundItemID, Description FROM FoundItem WHERE Status != 'Claimed';")

            if lost_df.empty or found_df.empty:
                st.info("No unclaimed Lost or Found items available.")
            else:
                lost_choice = st.selectbox(
                    "Select Lost Item",
                    lost_df.apply(lambda x: f"#{x.LostItemID} - {x.Description}", axis=1)
                )

                found_choice = st.selectbox(
                    "Select Found Item",
                    found_df.apply(lambda x: f"#{x.FoundItemID} - {x.Description}", axis=1)
                )

                if st.button("Create Claim"):
                    st.session_state.claim_trigger = True
                    st.session_state.lost_choice = lost_choice
                    st.session_state.found_choice = found_choice
                    st.rerun()

        except Exception as e:
            st.error(f"Error loading items: {e}")

        # Execute AFTER rerun (important)
        if st.session_state.claim_trigger:
            try:
                lid = int(st.session_state.lost_choice.split(" ")[0].replace("#", ""))
                fid = int(st.session_state.found_choice.split(" ")[0].replace("#", ""))
                uid = user["UserID"]

                result = call_proc("CreateClaim", [lid, fid, uid])

                # show stored proc message if exists
                if result:
                    msg = result[0][0][0]
                    st.success(str(msg))
                else:
                    st.success("Claim created successfully!")

                st.session_state.claim_trigger = False
                st.rerun()

            except Exception as e:
                st.error(f"Claim Error: {e}")
                st.session_state.claim_trigger = False


    # -----------------------------------------------------------
    #  VIEW LOST ITEMS
    # -----------------------------------------------------------
    elif menu == "View Lost Items":
        st.header("🧾 Lost Items")
        st.dataframe(fetch_df("SELECT * FROM LostItem ORDER BY LostItemID DESC;"))


    # -----------------------------------------------------------
    #  VIEW FOUND ITEMS
    # -----------------------------------------------------------
    elif menu == "View Found Items":
        st.header("🔍 Found Items")
        st.dataframe(fetch_df("SELECT * FROM FoundItem ORDER BY FoundItemID DESC;"))


    # -----------------------------------------------------------
    #  VIEW CLAIMS
    # -----------------------------------------------------------
    elif menu == "View Claims":
        st.header("📋 Claims")
        query = """
        SELECT c.ClaimID, c.LostItemID, c.FoundItemID,
               u.Name AS ClaimedBy, c.ClaimDate, c.Status
        FROM Claim c
        LEFT JOIN User u ON c.ClaimedBy = u.UserID
        ORDER BY c.ClaimID DESC;
        """
        st.dataframe(fetch_df(query))


    # -----------------------------------------------------------
    #  SYSTEM LOGS
    # -----------------------------------------------------------
    elif menu == "System Logs":
        st.header("🧠 System Logs")
        st.dataframe(fetch_df("SELECT * FROM SystemLog ORDER BY CreatedAt DESC;"))