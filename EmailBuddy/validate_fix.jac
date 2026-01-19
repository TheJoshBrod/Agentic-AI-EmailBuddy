import sqlite3;
include service.server;

with entry {
    print("--- Verifying vec0.so loading ---");
    try {
        conn = sqlite3.connect("vectorDB.db");
        conn.enable_load_extension(True);
        # mimic the path used in the fix
        conn.load_extension("service/vec0.so");
        print("Success: service/vec0.so loaded.");
    } except Exception as e {
        print(f"Error loading extension: {e}");
    }

    print("\n--- Verifying backend walkers ---");
    try {
        # Check if walker is defined
        print(f"Walker ask_email detected: {ask_email}");
        print("Success: Backend components connected.");
    } except Exception as e {
        print(f"Error detecting walker: {e}");
    }
}
