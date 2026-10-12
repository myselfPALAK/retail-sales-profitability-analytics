#!/usr/bin/env python3
"""
Retail Sales & Profitability Analytics - SQL Benchmark & Test Runner
===================================================================
Executes all SQL query files in sql/ against retail_analytics.db
Validates query syntax, logs execution time, and tests analytical queries.
"""

import os
import time
import sqlite3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL_DIR = os.path.join(BASE_DIR, "sql")
DB_PATH = os.path.join(BASE_DIR, "retail_analytics.db")

def run_benchmarks():
    print("=" * 70)
    print("Executing SQL Test Suite & Performance Benchmarks")
    print(f"Target Database: {DB_PATH}")
    print("=" * 70)
    
    if not os.path.exists(DB_PATH):
        raise FileNotFoundError(f"Database file not found at {DB_PATH}")
        
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    # In-memory test connection for testing schema creation script (01)
    mem_conn = sqlite3.connect(":memory:")
    mem_cur = mem_conn.cursor()
    
    sql_files = sorted([f for f in os.listdir(SQL_DIR) if f.endswith(".sql")])
    
    total_queries = 0
    passed_queries = 0
    
    for filename in sql_files:
        filepath = os.path.join(SQL_DIR, filename)
        print(f"\n[Testing File] {filename}")
        
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Parse individual SQL statements separated by semicolon
        raw_statements = [s.strip() for s in content.split(";") if s.strip()]
        
        # Use mem_cur for 01_schema_definition to avoid wiping the populated database
        target_cur = mem_cur if filename.startswith("01_") else cur
        
        for idx, statement in enumerate(raw_statements, 1):
            cleaned = "\n".join([line for line in statement.splitlines() if not line.strip().startswith("--")]).strip()
            if not cleaned:
                continue
                
            total_queries += 1
            t_start = time.perf_counter()
            try:
                target_cur.execute(statement)
                rows = target_cur.fetchall()
                t_elapsed = (time.perf_counter() - t_start) * 1000 # ms
                passed_queries += 1
                row_info = f"({len(rows)} rows returned)" if target_cur.description else "(executed DDL/DML)"
                print(f"  ✓ Statement {idx:02d} executed successfully in {t_elapsed:.2f} ms {row_info}")
            except Exception as e:
                print(f"  ✗ Statement {idx:02d} FAILED:")
                print(f"    Error: {e}")
                print(f"    Statement Preview:\n{statement[:200]}...")
                
    conn.commit()
    conn.close()
    mem_conn.close()
    
    print("\n" + "=" * 70)
    print(f"SQL Benchmark Summary: {passed_queries}/{total_queries} statements succeeded.")
    print("=" * 70)
    return passed_queries == total_queries

if __name__ == "__main__":
    success = run_benchmarks()
    if not success:
        exit(1)
