# 8 Week SQL Challenge — Learning Portfolio

This repository contains my solutions to the **8 Week SQL Challenge**
by Danny Ma (Data With Danny).

The challenge consists of a series of structured business case studies
designed to improve SQL proficiency and analytical thinking.

🔗 Official challenge:
https://8weeksqlchallenge.com/

---

## 🎯 Purpose of This Repository

The main goals of this repository are to:

- demonstrate my level of SQL proficiency 
- practice writing SQL queries to solve business problems  
- practice extracting meaningful business insights from data 
- learn and apply new SQL concepts and techniques  
- strengthen analytical thinking and problem decomposition  
- practice extracting meaningful business insights from data  
- **indicate self-driven learning**: actively practicing new SQL techniques beyond what is taught in formal courses  

This is a **learning-focused portfolio** intended to showcase my
approach to problem-solving, not an original data project.

---

## 🛠 Tools

- **MySQL**

---

## 📂 Repository Structure

Each case study is organised in its own folder and contains:

- SQL scripts to **create tables and insert data**
- a SQL file with **solutions to the case questions**
- a README file with:
  - a brief case description
  - explanation of my thought process
  - SQL queries
  - query outputs
  - key insights

  ---

## 📌 Case Studies

- 📁 [Case 01 — Danny’s Diner](./case_study1_dannys_diner)
- 📁 [Case 02 — Pizza Runner](./case_study2%20_pizza_runner)
- 📁 [Case 03 — Foodie-Fi](./case_study3_foodie_fi)

---

## 📈 Current Status

✅ Completed: **3 / 8** case studies  
🚧 In progress — this repository is actively updated

---

## 🧠 Key Skills Practiced

- Writing complex SQL queries using:
  - JOINs
  - GROUP BY
  - Window Functions
  - CASE WHEN
  - Common Table Expressions (CTEs)
- Translating business questions into SQL logic
- Interpreting query results and extracting insights
- Communicating technical solutions clearly

---

## 📚 Lessons Learned

Through these case studies, I improved my ability to **think about
business problems in SQL**, especially problems I previously tended
to solve using Python or R.

### New concepts and techniques learned:

1. **Splitting comma-separated values into rows**  
   Using `JSON_ARRAY()` and `JSON_TABLE()` to transform values like  
   `1,2,3,4` into multiple rows, with one value per row.

2. **Generating multiple rows from a single row using recursive queries**  
   Applying recursive CTEs to expand data and simulate iterative logic
   directly in SQL.

These techniques significantly expanded my understanding of SQL as
a powerful analytical tool, not just a querying language.

---

## ✍️ Notes

- All SQL solutions are written by me.
- Business questions and datasets are provided by the challenge.
- The focus is on clarity, reasoning, and explainability rather than
  the shortest possible queries.