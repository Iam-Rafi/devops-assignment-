import streamlit as st
import pandas as pd
import plotly.express as px
from datetime import date

st.set_page_config(page_title="Bike Sales Dashboard", page_icon="🏍️", layout="wide")

# Demo data
DATA = [
    {"Date":"2026-01-05","Brand":"Yamaha","Model":"MT-15","Category":"Street","City":"Bengaluru","Units":8,"Price":165000},
    {"Date":"2026-01-08","Brand":"Royal Enfield","Model":"Classic 350","Category":"Cruiser","City":"Mysuru","Units":6,"Price":195000},
    {"Date":"2026-01-15","Brand":"Honda","Model":"CB350","Category":"Retro","City":"Bengaluru","Units":5,"Price":210000},
    {"Date":"2026-02-03","Brand":"KTM","Model":"Duke 390","Category":"Street","City":"Hyderabad","Units":7,"Price":310000},
    {"Date":"2026-02-10","Brand":"TVS","Model":"Apache RTR 200","Category":"Street","City":"Chennai","Units":10,"Price":155000},
    {"Date":"2026-02-18","Brand":"Bajaj","Model":"Dominar 400","Category":"Touring","City":"Pune","Units":4,"Price":235000},
    {"Date":"2026-03-02","Brand":"Yamaha","Model":"R15 V4","Category":"Sport","City":"Bengaluru","Units":9,"Price":185000},
    {"Date":"2026-03-11","Brand":"Royal Enfield","Model":"Himalayan 450","Category":"Adventure","City":"Delhi","Units":5,"Price":285000},
    {"Date":"2026-03-21","Brand":"Honda","Model":"Activa 125","Category":"Scooter","City":"Mumbai","Units":14,"Price":110000},
    {"Date":"2026-04-04","Brand":"TVS","Model":"Ronin","Category":"Retro","City":"Kochi","Units":6,"Price":165000},
    {"Date":"2026-04-12","Brand":"KTM","Model":"RC 390","Category":"Sport","City":"Pune","Units":3,"Price":320000},
    {"Date":"2026-04-27","Brand":"Bajaj","Model":"Pulsar N250","Category":"Street","City":"Hyderabad","Units":11,"Price":170000},
]

df = pd.DataFrame(DATA)
df["Date"] = pd.to_datetime(df["Date"])
df["Revenue"] = df["Units"] * df["Price"]

st.title("🏍️ Bike Sales Management & Analytics")
st.caption("Python + Streamlit demo application — container-ready for Docker deployment.")

with st.sidebar:
    st.header("Filters")
    brands = st.multiselect("Brand", sorted(df["Brand"].unique()), default=sorted(df["Brand"].unique()))
    categories = st.multiselect("Category", sorted(df["Category"].unique()), default=sorted(df["Category"].unique()))
    cities = st.multiselect("City", sorted(df["City"].unique()), default=sorted(df["City"].unique()))
    min_date, max_date = df["Date"].min().date(), df["Date"].max().date()
    dates = st.date_input("Date range", value=(min_date, max_date), min_value=min_date, max_value=max_date)

filtered = df[
    df["Brand"].isin(brands) &
    df["Category"].isin(categories) &
    df["City"].isin(cities)
]
if isinstance(dates, tuple) and len(dates) == 2:
    filtered = filtered[(filtered["Date"].dt.date >= dates[0]) & (filtered["Date"].dt.date <= dates[1])]

c1, c2, c3, c4 = st.columns(4)
c1.metric("Units Sold", f"{filtered['Units'].sum():,}")
c2.metric("Revenue", f"₹{filtered['Revenue'].sum()/1e5:,.1f} L")
c3.metric("Avg. Bike Price", f"₹{filtered['Price'].mean():,.0f}" if not filtered.empty else "₹0")
c4.metric("Orders / Records", f"{len(filtered):,}")

st.divider()

left, right = st.columns(2)
with left:
    st.subheader("Revenue by Brand")
    if not filtered.empty:
        chart = filtered.groupby("Brand", as_index=False)["Revenue"].sum().sort_values("Revenue", ascending=False)
        st.plotly_chart(px.bar(chart, x="Brand", y="Revenue", text_auto=".2s"), use_container_width=True)
with right:
    st.subheader("Units by Category")
    if not filtered.empty:
        chart = filtered.groupby("Category", as_index=False)["Units"].sum().sort_values("Units", ascending=False)
        st.plotly_chart(px.pie(chart, names="Category", values="Units", hole=.4), use_container_width=True)

st.subheader("Sales Trend")
if not filtered.empty:
    trend = filtered.groupby("Date", as_index=False)["Revenue"].sum()
    st.plotly_chart(px.line(trend, x="Date", y="Revenue", markers=True), use_container_width=True)

st.subheader("Sales Records")
display = filtered.copy()
display["Date"] = display["Date"].dt.strftime("%Y-%m-%d")
display["Price"] = display["Price"].map(lambda x: f"₹{x:,.0f}")
display["Revenue"] = display["Revenue"].map(lambda x: f"₹{x:,.0f}")
st.dataframe(display, use_container_width=True, hide_index=True)

csv = filtered.to_csv(index=False).encode("utf-8")
st.download_button("⬇️ Download filtered sales CSV", csv, "bike_sales.csv", "text/csv")

